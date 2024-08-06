#!/bin/bash

# Function to check if an interface already exists
interface_exists() {
  ip link show | grep -q "$1"
}

# Function to print colored messages
print_color() {
  local color="$1"
  local message="$2"
  echo -e "\e[${color}m${message}\e[0m"
}

# Function to ensure /etc/rc.local has correct shebang and exit 0
ensure_rc_local_format() {
  local rc_local="/etc/rc.local"

  # Ensure shebang is at the top
  if ! head -n 1 "$rc_local" | grep -q '^#!/bin/bash'; then
    print_color "31" "Adding shebang to $rc_local."
    sudo bash -c "echo '#!/bin/bash' > $rc_local"
  fi

  # Ensure exit 0 is at the end
  if ! tail -n 1 "$rc_local" | grep -q '^exit 0'; then
    print_color "31" "Appending exit 0 to $rc_local."
    echo "exit 0" | sudo tee -a "$rc_local" > /dev/null
  fi

  # Make sure the file is executable
  sudo chmod +x "$rc_local"
}

# Function to create and configure rc-local service
configure_rc_local_service() {
  local service_file="/etc/systemd/system/rc-local.service"

  print_color "36" "Creating and configuring rc-local service..."

  # Check if the service file exists and attempt to start the service
  if [ -f "$service_file" ]; then
    print_color "36" "Attempting to restart rc-local service..."
    sudo systemctl restart rc-local

    # Check if service restart was successful
    if ! systemctl is-active --quiet rc-local; then
      print_color "31" "rc-local service failed to restart. Removing existing service file."
      sudo rm -f "$service_file"
    else
      print_color "32" "rc-local service is already running."
      return
    fi
  fi

  # Create or recreate the service file
  print_color "31" "Creating new rc-local service file."
  sudo tee "$service_file" > /dev/null <<EOF
[Unit]
Description=/etc/rc.local Compatibility
After=network.target

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
RemainAfterExit=yes
GuessMainPID=no

[Install]
WantedBy=multi-user.target
EOF

  # Ensure /etc/rc.local exists and is executable
  local rc_local="/etc/rc.local"
  if [ ! -f "$rc_local" ]; then
    print_color "31" "$rc_local does not exist. Creating it."
    sudo tee "$rc_local" > /dev/null <<EOF
#!/bin/bash
EOF
    sudo chmod +x "$rc_local"
  fi

  # Ensure proper format for /etc/rc.local
  ensure_rc_local_format

  # Reload systemd and enable the service
  print_color "36" "Reloading systemd and enabling rc-local service..."
  sudo systemctl daemon-reload
  sudo systemctl enable rc-local

  # Attempt to start the service
  print_color "36" "Starting rc-local service..."
  if ! sudo systemctl start rc-local; then
    print_color "31" "Failed to start rc-local service."
    sudo systemctl status rc-local
    exit 1
  fi

  # Check service status
  sudo systemctl status rc-local
}

# Function to make configuration permanent using rc.local
make_permanent() {
  local interface="$1"
  local remote_ip="$2"
  local local_ip="$3"
  local ipv6_address="$4"

  # Commands to add to /etc/rc.local
  local setup_cmds="ip tunnel add $interface mode sit remote $remote_ip local $local_ip
 ip -6 addr add $ipv6_address dev $interface
 ip link set $interface mtu 1480
 ip link set $interface up"

  # Check if /etc/rc.local exists and is executable
  local rc_local="/etc/rc.local"

  if [ ! -f "$rc_local" ]; then
    print_color "31" "$rc_local does not exist. Creating it."
    sudo tee "$rc_local" > /dev/null <<EOF
#!/bin/bash
EOF
    sudo chmod +x "$rc_local"
  fi

  # Ensure proper format for /etc/rc.local
  ensure_rc_local_format

  # Remove existing configuration for the interface from /etc/rc.local
  sudo sed -i "/^# Tunnel setup for $interface$/,+4d" "$rc_local"

  # Append new configuration before `exit 0`
  local tmp_rc_local=$(mktemp)
  awk '/^exit 0$/{print FILENAME " configured before exit 0"; exit 0}' "$rc_local" > "$tmp_rc_local"
  echo -e "# Tunnel setup for $interface\n$setup_cmds" | cat - "$tmp_rc_local" > "$rc_local"
  rm "$tmp_rc_local"

  # Re-check format after modifications
  ensure_rc_local_format

  # Configure the rc-local service
  configure_rc_local_service
}

# Function to remove a tunnel
remove_tunnel() {
  local tunnel_name="$1"

  if interface_exists "$tunnel_name"; then
    print_color "33" "Are you sure you want to delete the tunnel $tunnel_name? (y/n)"
    read -p "Enter your choice: " confirm_choice

    if [[ "$confirm_choice" =~ ^[Yy]$ ]]; then
      ip tunnel del "$tunnel_name"
      print_color "32" "Tunnel $tunnel_name has been deleted."

      # Remove from rc.local
      local rc_local="/etc/rc.local"
      sudo sed -i "/^# Tunnel setup for $tunnel_name$/,+4d" "$rc_local"
      sudo sed -i '/^exit 0$/d' "$rc_local"

      # Ensure proper format for /etc/rc.local
      ensure_rc_local_format

      print_color "32" "Tunnel $tunnel_name has been removed from $rc_local."
    else
      print_color "33" "Operation canceled."
    fi
  else
    print_color "31" "Tunnel $tunnel_name does not exist."
  fi
}

# Function to list all 6to4 tunnels
list_tunnels() {
  print_color "36" "Listing all 6to4 tunnels:"
  ip -o link show | awk -F': ' '{print $2}' | sed 's/@NONE$//'
}

# Detect distribution
if [ -f /etc/os-release ]; then
  . /etc/os-release
  distro=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
else
  distro="unknown"
fi

# Main menu loop
while true; do
  print_color "36" "Select an option:"
  print_color "36" "1. Iran"
  print_color "36" "2. Kharej"
  print_color "36" "3. List tunnels"
  print_color "36" "4. Remove tunnel"
  print_color "36" "5. Make tunnel permanent"
  print_color "36" "6. Configure rc-local service"
  print_color "36" "7. Exit"
  read -p "Enter your choice (1-7): " main_choice

  case $main_choice in
    1|2)
      # Common questions
      if [ "$main_choice" -eq 1 ]; then
        print_color "34" "You selected Iran. The first IP will be remote, and the second will be local."
        read -p "Enter the remote IPv4 address: " remote_ip
        read -p "Enter the local IPv4 address: " local_ip
      else
        print_color "34" "You selected Kharej. The first IP will be local, and the second will be remote."
        read -p "Enter the local IPv4 address: " local_ip
        read -p "Enter the remote IPv4 address: " remote_ip
      fi

      read -p "Enter the base IPv6 address (e.g., fdcc:c4da:bc9b::): " base_ipv6

      # Validate base IPv6 address
      if ! [[ $base_ipv6 =~ ^[0-9a-fA-F:]+::$ ]]; then
        print_color "31" "Invalid base IPv6 address format."
        exit 1
      fi

      # Generate a dynamic suffix for the IPv6 address and interface name
      suffix=$(printf '%04x' $((RANDOM % 65536)))
      ipv6_address="${base_ipv6}${suffix}/64"
      interface="6to4_tun__$suffix"

      if [ "$main_choice" -eq 2 ]; then
        read -p "Enter the name for the interface (ensure it's unique): " interface
      fi

      if interface_exists "$interface"; then
        print_color "31" "The interface name $interface is already in use. Please choose another name."
        exit 1
      fi

      # Create the tunnel
      print_color "32" "Creating tunnel $interface with remote $remote_ip and local $local_ip"
      if ! ip tunnel add "$interface" mode sit remote "$remote_ip" local "$local_ip"; then
        print_color "31" "Failed to create tunnel $interface."
        exit 1
      fi

      # Add IPv6 address
      print_color "32" "Adding IPv6 address $ipv6_address to $interface"
      if ! ip -6 addr add "$ipv6_address" dev "$interface"; then
        print_color "31" "Failed to add IPv6 address $ipv6_address."
        ip tunnel del "$interface"
        exit 1
      fi

      # Set MTU and bring the interface up
      print_color "32" "Setting MTU and bringing up the interface."
      if ! ip link set "$interface" mtu 1480 && ip link set "$interface" up; then
        print_color "31" "Failed to configure the interface $interface."
        ip -6 addr del "$ipv6_address" dev "$interface"
        ip tunnel del "$interface"
        exit 1
      fi

      # Make the tunnel permanent
      make_permanent "$interface" "$remote_ip" "$local_ip" "$ipv6_address"
      ;;
    3)
      list_tunnels
      ;;
    4)
      read -p "Enter the name of the tunnel to remove: " tunnel_name
      remove_tunnel "$tunnel_name"
      ;; 
    5)
      tunnels=$(list_tunnels)
      if [ -z "$tunnels" ]; then
        print_color "31" "No tunnels found."
      else
        print_color "34" "Available tunnels:"
        echo "$tunnels"
        read -p "Enter the name of the tunnel to make permanent: " tunnel_name
        
      if ! interface_exists "$tunnel_name"; then
        print_color "31" "Tunnel $tunnel_name does not exist."
        continue
      fi
      # Retrieve existing tunnel details
      remote_ip=$(ip tunnel show "$tunnel_name" | grep 'remote' | awk '{print $2}')
      local_ip=$(ip tunnel show "$tunnel_name" | grep 'local' | awk '{print $2}')
      ipv6_address=$(ip -6 addr show dev "$tunnel_name" | grep 'inet6' | awk '{print $2}')

      if [ -z "$remote_ip" ] || [ -z "$local_ip" ] || [ -z "$ipv6_address" ]; then
        print_color "31" "Could not retrieve tunnel details."
        continue
      fi

      make_permanent "$tunnel_name" "$remote_ip" "$local_ip" "$ipv6_address"
      ;;
    6)
      configure_rc_local_service
      ;;
    7)
      exit 0
      ;;
    *)
      print_color "31" "Invalid choice. Please enter a number between 1 and 7."
      ;;
  esac
done

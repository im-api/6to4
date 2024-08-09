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
    sudo sed -i '1s|^|#!/bin/bash\n|' "$rc_local"
  fi

  # Ensure sleep 10 is at the start only once
  if ! grep -q '^sleep 10' "$rc_local"; then
    print_color "31" "Adding sleep 10 to $rc_local."
    sudo sed -i '2s|^|sleep 10\n|' "$rc_local"
  fi

  # Ensure exit 0 is at the end
  if ! tail -n 1 "$rc_local" | grep -q '^exit 0'; then
    print_color "31" "Appending exit 0 to $rc_local."
    echo "exit 0" | sudo tee -a "$rc_local" > /dev/null
  fi
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
sleep 10
EOF
    sudo chmod +x "$rc_local"
  fi

  # Remove existing configuration for the interface from /etc/rc.local
  sudo sed -i "/^# Tunnel setup for $interface$/,/^exit 0$/d" "$rc_local"

  # Ensure only one shebang at the top
  if ! head -n 1 "$rc_local" | grep -q '^#!/bin/bash'; then
    print_color "31" "Adding shebang to $rc_local."
    sudo sed -i '1s|^|#!/bin/bash\n|' "$rc_local"
  fi

  # Ensure exit 0 is only at the end
  if ! tail -n 1 "$rc_local" | grep -q '^exit 0'; then
    echo "exit 0" | sudo tee -a "$rc_local" > /dev/null
  fi

  # Append new configuration before `exit 0`
  local tmp_rc_local=$(mktemp)
  awk '!/^exit 0$/' "$rc_local" > "$tmp_rc_local"
  echo -e "# Tunnel setup for $interface\n$setup_cmds" | cat - "$tmp_rc_local" > "$rc_local"
  rm "$tmp_rc_local"

  # Re-check format after modifications
  ensure_rc_local_format
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

# Function to create and configure rc-local service
configure_rc_local_service() {
  local service_file="/etc/systemd/system/rc-local.service"
  
  print_color "36" "Creating and configuring rc-local service..."

  # Check if the service file exists and attempt to start the service
  if [ -f "$service_file" ]; then
    print_color "36" "Attempting to start rc-local service..."
    sudo systemctl restart rc-local
    sleep 2 # Give it a moment to process

    if systemctl is-active --quiet rc-local; then
      print_color "32" "rc-local service started successfully."
      return
    else
      print_color "31" "rc-local service failed to start. Removing existing service file."
      sudo rm -f "$service_file"
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
  sudo systemctl daemon-reload
  sudo systemctl enable rc-local
  sudo systemctl start rc-local

  # Check service status
  sudo systemctl status rc-local
}

# Function to edit IPv4 addresses of an existing tunnel
edit_ipv4_addresses() {
  local tunnel_name="$1"
  local new_remote_ip="$2"
  local new_local_ip="$3"

  # Update the tunnel configuration
  if ! ip tunnel change "$tunnel_name" mode sit remote "$new_remote_ip" local "$new_local_ip"; then
    print_color "31" "Failed to update tunnel $tunnel_name."
    return 1
  fi

  print_color "32" "Tunnel $tunnel_name updated with new remote IP $new_remote_ip and local IP $new_local_ip."

  # Update /etc/rc.local if the configuration is permanent
  local rc_local="/etc/rc.local"
  if grep -q "# Tunnel setup for $tunnel_name" "$rc_local"; then
    sudo sed -i "/# Tunnel setup for $tunnel_name/,+4s/remote [0-9.]\+ local [0-9.]\+/remote $new_remote_ip local $new_local_ip/" "$rc_local"
    print_color "32" "Updated permanent configuration in $rc_local."
  fi

  return 0
}

# New function to show data of a tunnel
show_tunnel_data() {
  local tunnel_name="$1"

  if interface_exists "$tunnel_name"; then
    local remote_ip=$(ip tunnel show "$tunnel_name" | grep 'remote' | awk '{print $4}')
    local local_ip=$(ip tunnel show "$tunnel_name" | grep 'local' | awk '{print $6}')
    local ipv6_address=$(ip -6 addr show dev "$tunnel_name" | grep 'inet6' | awk '{print $2}')

    print_color "34" "Tunnel Data for $tunnel_name:"
    print_color "32" "Remote IPv4: $remote_ip"
    print_color "32" "Local IPv4: $local_ip"
    print_color "32" "IPv6 Address: $ipv6_address"
  else
    print_color "31" "Tunnel $tunnel_name does not exist."
  fi
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
  print_color "36" "7. Edit IPv4 addresses of existing tunnel"
  print_color "36" "8. Show data of a tunnel"
  print_color "36" "9. Exit"
  read -p "Enter your choice (1-9): " main_choice

  case $main_choice in
    1|2)
      # Common questions
      read -p "Enter the local IPv4 address: " local_ip
      read -p "Enter the remote IPv4 address: " remote_ip
      read -p "Enter the base IPv6 address (e.g., fdcc:c4da:bc9b::): " base_ipv6

      # Validate base IPv6 address
      if ! [[ $base_ipv6 =~ ^[0-9a-fA-F:]+::$ ]]; then
        print_color "31" "Invalid base IPv6 address format."
        continue
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
        continue
      fi

      # Create the tunnel
      print_color "32" "Creating tunnel $interface with remote $remote_ip and local $local_ip"
      if ! ip tunnel add "$interface" mode sit remote "$remote_ip" local "$local_ip"; then
        print_color "31" "Failed to create tunnel $interface."
        continue
      fi

      # Add IPv6 address
      print_color "32" "Adding IPv6 address $ipv6_address to $interface"
      if ! ip -6 addr add "$ipv6_address" dev "$interface"; then
        print_color "31" "Failed to add IPv6 address to $interface."
        continue
      fi

      # Configure MTU and bring up the interface
      print_color "32" "Setting MTU and bringing up $interface"
      if ! ip link set "$interface" mtu 1480; then
        print_color "31" "Failed to set MTU for $interface."
        continue
      fi

      if ! ip link set "$interface" up; then
        print_color "31" "Failed to bring up $interface."
        continue
      fi

      print_color "34" "Tunnel $interface has been set up with IPv6 address $ipv6_address."

      # Ask if the user wants to make the configuration permanent
      read -p "Do you want to make this configuration permanent? (y/n): " make_permanent_choice

      if [[ "$make_permanent_choice" =~ ^[Yy]$ ]]; then
        make_permanent "$interface" "$remote_ip" "$local_ip" "$ipv6_address"
        print_color "34" "Configuration has been made permanent."
      else
        print_color "33" "Configuration has not been made permanent."
      fi
      ;;

    3)
      list_tunnels
      ;;

    4)
      tunnels=$(list_tunnels)
      if [ -z "$tunnels" ]; then
        print_color "31" "No tunnels found."
      else
        print_color "34" "Available tunnels:"
        echo "$tunnels"
        read -p "Enter the name of the tunnel to remove: " tunnel_to_remove
        remove_tunnel "$tunnel_to_remove"
      fi
      ;;

    5)
      tunnels=$(list_tunnels)
      if [ -z "$tunnels" ]; then
        print_color "31" "No tunnels found."
      else
        print_color "34" "Available tunnels:"
        echo "$tunnels"
        read -p "Enter the name of the tunnel to make permanent: " tunnel_to_permanent

        # Extract configuration details for the chosen tunnel
        if interface_exists "$tunnel_to_permanent"; then
          remote_ip=$(ip tunnel show "$tunnel_to_permanent" | grep 'remote' | awk '{print $4}')
          local_ip=$(ip tunnel show "$tunnel_to_permanent" | grep 'local' | awk '{print $6}')
          ipv6_address=$(ip -6 addr show dev "$tunnel_to_permanent" | grep 'inet6' | awk '{print $2}')

          # Ensure extracted values are not empty
          if [ -z "$remote_ip" ] || [ -z "$local_ip" ] || [ -z "$ipv6_address" ]; then
            print_color "31" "Unable to retrieve complete configuration for $tunnel_to_permanent."
            continue
          fi

          make_permanent "$tunnel_to_permanent" "$remote_ip" "$local_ip" "$ipv6_address"
          print_color "34" "Configuration for $tunnel_to_permanent has been made permanent."
        else
          print_color "31" "Tunnel $tunnel_to_permanent does not exist."
        fi
      fi
      ;;

    6)
      configure_rc_local_service
      ;;

    7)
      tunnels=$(list_tunnels)
      if [ -z "$tunnels" ]; then
        print_color "31" "No tunnels found."
      else
        print_color "34" "Available tunnels:"
        echo "$tunnels"
        read -p "Enter the name of the tunnel to edit: " tunnel_to_edit

        if interface_exists "$tunnel_to_edit"; then
          read -p "Enter the new remote IPv4 address: " new_remote_ip
          read -p "Enter the new local IPv4 address: " new_local_ip

          edit_ipv4_addresses "$tunnel_to_edit" "$new_remote_ip" "$new_local_ip"
        else
          print_color "31" "Tunnel $tunnel_to_edit does not exist."
        fi
      fi
      ;;

    8)
      tunnels=$(list_tunnels)
      if [ -z "$tunnels" ]; then
        print_color "31" "No tunnels found."
      else
        print_color "34" "Available tunnels:"
        echo "$tunnels"
        read -p "Enter the name of the tunnel to show data for: " tunnel_to_show

        show_tunnel_data "$tunnel_to_show"
      fi
      ;;

    9)
      print_color "32" "Exiting..."
      exit 0
      ;;

    *)
      print_color "31" "Invalid option. Please enter a number between 1 and 9."
      ;;
  esac
done
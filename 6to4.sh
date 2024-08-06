#!/bin/bash

# Directory to store tunnel scripts
TUNNEL_DIR="$HOME/root/tunnels"

# Create the directory if it doesn't exist
mkdir -p "$TUNNEL_DIR"

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

# Function to create a script file for a tunnel
create_tunnel_script() {
  local interface="$1"
  local local_ip="$2"
  local remote_ip="$3"
  local ipv6_address="$4"

  local script_file="$TUNNEL_DIR/${interface}.sh"

  echo "#!/bin/bash" | sudo tee "$script_file" > /dev/null
  echo "ip tunnel add $interface mode sit remote $remote_ip local $local_ip" | sudo tee -a "$script_file" > /dev/null
  echo "ip -6 addr add $ipv6_address dev $interface" | sudo tee -a "$script_file" > /dev/null
  echo "ip link set $interface mtu 1480" | sudo tee -a "$script_file" > /dev/null
  echo "ip link set $interface up" | sudo tee -a "$script_file" > /dev/null

  sudo chmod +x "$script_file"
}

# Function to make configuration permanent
make_permanent() {
  local interface="$1"

  # Extract the local IP address from the link section
  local local_ip=$(ip addr show dev "$interface" | awk '/link\/sit/ {print $2}' | cut -d' ' -f1)

  # Extract the remote IP address from the link section
  local remote_ip=$(ip addr show dev "$interface" | awk '/link\/sit/ {print $3}' | cut -d' ' -f1)

  # Extract the IPv6 address
  local ipv6_address=$(ip -6 addr show dev "$interface" | awk '/inet6 / {print $2}' | cut -d'/' -f1)

  # Validate retrieved values
  if [ -z "$local_ip" ]; then
    print_color "$COLOR_YELLOW" "No IPv4 address found for the interface $interface. Proceeding with IPv6-only configuration."
  fi

  if [ -z "$remote_ip" ]; then
    print_color "$COLOR_RED" "Failed to retrieve remote IP for the tunnel $interface. Ensure the tunnel is properly configured."
    return 1
  fi

  if [ -z "$ipv6_address" ]; then
    print_color "$COLOR_RED" "Failed to retrieve IPv6 address for the tunnel $interface. Ensure the tunnel is properly configured."
    return 1
  fi

  create_tunnel_script "$interface" "$local_ip" "$remote_ip" "$ipv6_address"

  # Create or update systemd service
  if [ ! -f /etc/systemd/system/tunnel-setup.service ]; then
    sudo bash -c "cat > /etc/systemd/system/tunnel-setup.service <<EOF
[Unit]
Description=Set up tunnel interfaces

[Service]
Type=oneshot
ExecStart=/usr/local/bin/tunnel-setup.sh

[Install]
WantedBy=multi-user.target
EOF"
    sudo touch /usr/local/bin/tunnel-setup.sh
    sudo chmod +x /usr/local/bin/tunnel-setup.sh
  fi

  # Add all tunnel scripts to the service script
  {
    echo "#!/bin/bash"
    for script in "$TUNNEL_DIR"/*.sh; do
      [ -x "$script" ] && echo "$script"
    done
  } | sudo tee /usr/local/bin/tunnel-setup.sh > /dev/null

  sudo chmod +x /usr/local/bin/tunnel-setup.sh

  # Reload and enable the service
  sudo systemctl daemon-reload
  sudo systemctl enable tunnel-setup.service

  print_color "$COLOR_BLUE" "Tunnel configuration has been made permanent."
}

# Function to remove a tunnel script
remove_tunnel_script() {
  local interface="$1"

  local script_file="$TUNNEL_DIR/${interface}.sh"

  if [ -f "$script_file" ]; then
    sudo rm "$script_file"
    print_color "$COLOR_GREEN" "Removed script for tunnel $interface."
  else
    print_color "$COLOR_RED" "Script for tunnel $interface not found."
  fi

  # Update the systemd service file
  {
    echo "#!/bin/bash"
    for script in "$TUNNEL_DIR"/*.sh; do
      [ -x "$script" ] && echo "$script"
    done
  } | sudo tee /usr/local/bin/tunnel-setup.sh > /dev/null

  sudo chmod +x /usr/local/bin/tunnel-setup.sh
  sudo systemctl daemon-reload
}

# Function to list all 6to4 tunnels
list_tunnels() {
  print_color "$COLOR_BLUE" "Listing all 6to4 tunnels:"
  ip -o link show | awk -F': ' '{print $2}' | sed 's/@NONE$//'
}

# Function to remove a tunnel
remove_tunnel() {
  local tunnel_name="$1"
  local distro="$2"
  
  if interface_exists "$tunnel_name"; then
    print_color "$COLOR_YELLOW" "Are you sure you want to delete the tunnel $tunnel_name? (y/n)"
    read -p "Enter your choice: " confirm_choice
    
    if [[ "$confirm_choice" =~ ^[Yy]$ ]]; then
      ip tunnel del "$tunnel_name"
      print_color "$COLOR_GREEN" "Tunnel $tunnel_name has been deleted."

      remove_tunnel_script "$tunnel_name"

      if [[ "$distro" == "ubuntu" ]]; then
        # Remove from Netplan or /etc/network/interfaces
        if [ -d /etc/netplan ]; then
          local netplan_file="/etc/netplan/01-netcfg.yaml"
          sudo sed -i "/$tunnel_name/,+6d" "$netplan_file"
          sudo netplan apply
        else
          local interfaces_file="/etc/network/interfaces"
          sudo sed -i "/auto $tunnel_name/,+4d" "$interfaces_file"
          sudo systemctl restart networking
        fi
      elif [[ "$distro" == "centos" ]]; then
        # Remove the configuration file
        local ifcfg_file="/etc/sysconfig/network-scripts/ifcfg-$tunnel_name"
        sudo rm -f "$ifcfg_file"
        sudo systemctl restart network
      fi
      print_color "$COLOR_GREEN" "Tunnel $tunnel_name has been removed from the permanent configuration."
    else
      print_color "$COLOR_YELLOW" "Operation canceled."
    fi
  else
    print_color "$COLOR_RED" "Tunnel $tunnel_name does not exist."
  fi
}

# Detect distribution
if [ -f /etc/os-release ]; then
  . /etc/os-release
  distro=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
else
  distro="unknown"
fi

# Define color codes
COLOR_GREEN="32"
COLOR_RED="31"
COLOR_YELLOW="33"
COLOR_BLUE="34"
COLOR_CYAN="36"

# Main menu loop
while true; do
  print_color "$COLOR_CYAN" "Select an option:"
  print_color "$COLOR_CYAN" "1. Iran"
  print_color "$COLOR_CYAN" "2. Kharej"
  print_color "$COLOR_CYAN" "3. List tunnels"
  print_color "$COLOR_CYAN" "4. Remove tunnel"
  print_color "$COLOR_CYAN" "5. Make permanent"
  print_color "$COLOR_CYAN" "6. Exit"
  read -p "Enter your choice (1-6): " main_choice

  case $main_choice in
    1|2)
      # Common questions
      read -p "Enter the local IPv4 address: " local_ip
      read -p "Enter the remote IPv4 address: " remote_ip
      read -p "Enter the base IPv6 address (e.g., fdcc:c4da:bc9b::): " base_ipv6

      # Validate base IPv6 address
      if ! [[ $base_ipv6 =~ ^[0-9a-fA-F:]+::$ ]]; then
        print_color "$COLOR_RED" "Invalid base IPv6 address format."
        exit 1
      fi

      # Generate a dynamic suffix for the IPv6 address and interface name
      suffix=$(printf '%04x' $((RANDOM % 65536)))
      ipv6_address="${base_ipv6}${suffix}/64"

      # Determine the type of setup
      if [ "$main_choice" -eq 1 ]; then
        # Iran setup
        interface="6to4_tun__$suffix"  # Unique interface name using dynamic suffix

        if interface_exists "$interface"; then
          print_color "$COLOR_RED" "The interface name $interface is already in use. Please choose another name."
          exit 1
        fi

        # Create the tunnel
        print_color "$COLOR_GREEN" "Creating tunnel $interface with remote $remote_ip and local $local_ip"
        if ! ip tunnel add "$interface" mode sit remote "$remote_ip" local "$local_ip"; then
          print_color "$COLOR_RED" "Failed to create tunnel $interface."
          exit 1
        fi

        # Add IPv6 address
        print_color "$COLOR_GREEN" "Adding IPv6 address $ipv6_address to $interface"
        if ! ip -6 addr add "$ipv6_address" dev "$interface"; then
          print_color "$COLOR_RED" "Failed to add IPv6 address to $interface."
          exit 1
        fi

        # Configure MTU and bring up the interface
        print_color "$COLOR_GREEN" "Setting MTU and bringing up $interface"
        if ! ip link set "$interface" mtu 1480; then
          print_color "$COLOR_RED" "Failed to set MTU for $interface."
          exit 1
        fi

        if ! ip link set "$interface" up; then
          print_color "$COLOR_RED" "Failed to bring up $interface."
          exit 1
        fi

        print_color "$COLOR_BLUE" "Tunnel $interface has been set up for Iran with IPv6 address $ipv6_address."

      elif [ "$main_choice" -eq 2 ]; then
        # Kharej setup
        read -p "Enter the name for the interface (ensure it's unique): " interface

        if interface_exists "$interface"; then
          print_color "$COLOR_RED" "The interface name $interface is already in use. Please choose another name."
          exit 1
        fi

        # Create the tunnel
        print_color "$COLOR_GREEN" "Creating tunnel $interface with remote $remote_ip and local $local_ip"
        if ! ip tunnel add "$interface" mode sit remote "$remote_ip" local "$local_ip"; then
          print_color "$COLOR_RED" "Failed to create tunnel $interface."
          exit 1
        fi

        # Add IPv6 address
        print_color "$COLOR_GREEN" "Adding IPv6 address $ipv6_address to $interface"
        if ! ip -6 addr add "$ipv6_address" dev "$interface"; then
          print_color "$COLOR_RED" "Failed to add IPv6 address to $interface."
          exit 1
        fi

        # Configure MTU and bring up the interface
        print_color "$COLOR_GREEN" "Setting MTU and bringing up $interface"
        if ! ip link set "$interface" mtu 1480; then
          print_color "$COLOR_RED" "Failed to set MTU for $interface."
          exit 1
        fi

        if ! ip link set "$interface" up; then
          print_color "$COLOR_RED" "Failed to bring up $interface."
          exit 1
        fi

        print_color "$COLOR_BLUE" "Tunnel $interface has been set up for Kharej with IPv6 address $ipv6_address."
      fi

      # Ask if the user wants to make the configuration permanent
      read -p "Do you want to make this configuration permanent? (y/n): " make_permanent_choice
      if [[ "$make_permanent_choice" =~ ^[Yy]$ ]]; then
        make_permanent "$interface"
      fi
      ;;

    3)
      list_tunnels
      ;;

    4)
      read -p "Enter the name of the tunnel to remove: " tunnel_name
      remove_tunnel "$tunnel_name" "$distro"
      ;;

    5)
      list_tunnels
      read -p "Enter the name of the tunnel to make permanent: " tunnel_name
      make_permanent "$tunnel_name"
      ;;

    6)
      print_color "$COLOR_GREEN" "Exiting."
      exit 0
      ;;

    *)
      print_color "$COLOR_RED" "Invalid choice. Please enter a number between 1 and 6."
      ;;
  esac
done

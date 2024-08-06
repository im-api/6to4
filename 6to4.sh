#!/bin/bash

# Function to print colored messages
print_color() {
  local color="$1"
  local message="$2"
  echo -e "\e[${color}m${message}\e[0m"
}

# Directory to store tunnel scripts
TUNNEL_DIR="$HOME/root/tunnels"

# Ensure the tunnel directory exists
mkdir -p "$TUNNEL_DIR"

# Function to create the tunnel setup script
create_tunnel_script() {
  local interface="$1"
  local local_ip="$2"
  local remote_ip="$3"
  local ipv6_address="$4"
  
  local script_file="$TUNNEL_DIR/$interface.sh"

  # Create or overwrite the script file
  cat > "$script_file" <<EOF
#!/bin/bash
ip tunnel add $interface mode sit remote $remote_ip local $local_ip
ip -6 addr add $ipv6_address dev $interface
ip link set $interface mtu 1480
ip link set $interface up
EOF

  chmod +x "$script_file"
}

# Function to make configuration permanent
make_permanent() {
  local interface="$1"
  
  # Extract local and remote IPv4 addresses from tunnel configuration
  local tunnel_info=$(ip -o tunnel show dev "$interface")
  local local_ip=$(echo "$tunnel_info" | awk '{print $4}' | cut -d' ' -f2)
  local remote_ip=$(echo "$tunnel_info" | awk '{print $4}' | cut -d' ' -f1)
  
  # Extract IPv6 address
  local ipv6_address=$(ip -6 addr show dev "$interface" | awk '/inet6 / {print $2}' | cut -d'/' -f1)

  # Validate retrieved values
  if [ -z "$local_ip" ] || [ -z "$remote_ip" ]; then
    print_color "33" "No IPv4 address found for the interface $interface. Configuring for IPv6 only."
    local_ip="none"
    remote_ip="none"
  fi

  if [ -z "$ipv6_address" ]; then
    print_color "31" "Failed to retrieve IPv6 address for the tunnel $interface. Ensure the tunnel is properly configured."
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

  print_color "34" "Tunnel configuration has been made permanent."
}

# Function to list all 6to4 tunnels
list_tunnels() {
  print_color "34" "Listing all 6to4 tunnels:"
  ip -o tunnel show | awk '{print $1}'
}

# Function to remove a tunnel
remove_tunnel() {
  local tunnel_name="$1"
  
  if ip link show "$tunnel_name" > /dev/null 2>&1; then
    print_color "33" "Are you sure you want to delete the tunnel $tunnel_name? (y/n)"
    read -p "Enter your choice: " confirm_choice
    
    if [[ "$confirm_choice" =~ ^[Yy]$ ]]; then
      ip tunnel del "$tunnel_name"
      print_color "32" "Tunnel $tunnel_name has been deleted."

      # Remove the associated script
      local script_file="$TUNNEL_DIR/$tunnel_name.sh"
      if [ -f "$script_file" ]; then
        rm "$script_file"
        print_color "32" "Tunnel script $script_file has been removed."
      fi

      # Remove from systemd service if the script was present
      if [ -f /usr/local/bin/tunnel-setup.sh ]; then
        sudo sed -i "/$script_file/d" /usr/local/bin/tunnel-setup.sh
        sudo chmod +x /usr/local/bin/tunnel-setup.sh
      fi

      # Reload and restart the systemd service
      sudo systemctl daemon-reload
      sudo systemctl restart tunnel-setup.service

      print_color "32" "Tunnel $tunnel_name has been removed from the permanent configuration."
    else
      print_color "33" "Operation canceled."
    fi
  else
    print_color "31" "Tunnel $tunnel_name does not exist."
  fi
}

# Main menu loop
while true; do
  print_color "36" "Select an option:"
  print_color "36" "1. Iran"
  print_color "36" "2. Kharej"
  print_color "36" "3. List tunnels"
  print_color "36" "4. Remove tunnel"
  print_color "36" "5. Make permanent"
  print_color "36" "6. Exit"
  read -p "Enter your choice (1-6): " main_choice

  case $main_choice in
    1|2)
      # Common questions
      read -p "Enter the local IPv4 address: " local_ip
      read -p "Enter the remote IPv4 address: " remote_ip
      read -p "Enter the base IPv6 address (e.g., fdcc:c4da:bc9b::): " base_ipv6

      # Validate base IPv6 address
      if ! [[ $base_ipv6 =~ ^[0-9a-fA-F:]+::$ ]]; then
        print_color "31" "Invalid base IPv6 address format."
        exit 1
      fi

      # Generate a dynamic suffix for the IPv6 address and interface name
      suffix=$(printf '%04x' $((RANDOM % 65536)))
      ipv6_address="${base_ipv6}${suffix}/64"

      # Determine the type of setup
      if [ "$main_choice" -eq 1 ]; then
        # Iran setup
        interface="6to4_tun__$suffix"  # Unique interface name using dynamic suffix

        if ip link show "$interface" > /dev/null 2>&1; then
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
          print_color "31" "Failed to add IPv6 address to $interface."
          exit 1
        fi

        # Configure MTU and bring up the interface
        print_color "32" "Setting MTU and bringing up $interface"
        if ! ip link set "$interface" mtu 1480; then
          print_color "31" "Failed to set MTU for $interface."
          exit 1
        fi

        if ! ip link set "$interface" up; then
          print_color "31" "Failed to bring up $interface."
          exit 1
        fi

        print_color "34" "Tunnel $interface has been set up for Iran with IPv6 address $ipv6_address."

      elif [ "$main_choice" -eq 2 ]; then
        # Kharej setup
        read -p "Enter the name for the interface (ensure it's unique): " interface

        if ip link show "$interface" > /dev/null 2>&1; then
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
          print_color "31" "Failed to add IPv6 address to $interface."
          exit 1
        fi

        # Configure MTU and bring up the interface
        print_color "32" "Setting MTU and bringing up $interface"
        if ! ip link set "$interface" mtu 1480; then
          print_color "31" "Failed to set MTU for $interface."
          exit 1
        fi

        if ! ip link set "$interface" up; then
          print_color "31" "Failed to bring up $interface."
          exit 1
        fi

        print_color "34" "Tunnel $interface has been set up for Kharej with IPv6 address $ipv6_address."
      fi
      ;;

    3)
      # List tunnels
      list_tunnels
      ;;

    4)
      # Remove tunnel
      read -p "Enter the name of the tunnel to remove: " tunnel_to_remove
      remove_tunnel "$tunnel_to_remove"
      ;;

    5)
      # Make permanent
      print_color "34" "Listing all 6to4 tunnels:"
      list_tunnels

      read -p "Enter the name of the tunnel to make permanent: " tunnel_to_make_permanent
      make_permanent "$tunnel_to_make_permanent"
      ;;

    6)
      # Exit
      print_color "32" "Exiting..."
      exit 0
      ;;

    *)
      print_color "31" "Invalid option. Please enter a number between 1 and 6."
      ;;
  esac
done

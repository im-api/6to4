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

# Function to make configuration permanent using rc.local
make_permanent() {
  local interface="$1"
  local remote_ip="$2"
  local local_ip="$3"
  local ipv6_address="$4"

  # Commands to add to /etc/rc.local
  local setup_cmds="ip tunnel add $interface mode sit remote $remote_ip local $local_ip\n\
ip -6 addr add $ipv6_address dev $interface\n\
ip link set $interface mtu 1480\n\
ip link set $interface up"

  # Check if /etc/rc.local exists and is executable
  local rc_local="/etc/rc.local"

  if [ ! -f "$rc_local" ]; then
    print_color "$COLOR_RED" "$rc_local does not exist. Creating it."
    sudo tee "$rc_local" > /dev/null <<EOF
#!/bin/sh -e
EOF
    sudo chmod +x "$rc_local"
  fi

  # Append commands to /etc/rc.local
  if ! grep -q "$interface" "$rc_local"; then
    print_color "$COLOR_GREEN" "Adding configuration to $rc_local"

    sudo tee -a "$rc_local" > /dev/null <<EOF

# Tunnel setup for $interface
$setup_cmds
EOF
  else
    print_color "$COLOR_YELLOW" "$rc_local already contains configuration for $interface."
  fi
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

      # Remove from rc.local
      local rc_local="/etc/rc.local"
      sudo sed -i "/ip tunnel add $tunnel_name/d" "$rc_local"
      sudo sed -i "/ip -6 addr add .* dev $tunnel_name/d" "$rc_local"
      sudo sed -i "/ip link set $tunnel_name mtu 1480/d" "$rc_local"
      sudo sed -i "/ip link set $tunnel_name up/d" "$rc_local"

      print_color "$COLOR_GREEN" "Tunnel $tunnel_name has been removed from $rc_local."
    else
      print_color "$COLOR_YELLOW" "Operation canceled."
    fi
  else
    print_color "$COLOR_RED" "Tunnel $tunnel_name does not exist."
  fi
}

# Function to list all 6to4 tunnels
list_tunnels() {
  print_color "$COLOR_BLUE" "Listing all 6to4 tunnels:"
  ip -o link show | awk -F': ' '{print $2}' | sed 's/@NONE$//'
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
  print_color "$COLOR_CYAN" "5. Make tunnel permanent"
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
        make_permanent "$interface" "$remote_ip" "$local_ip" "$ipv6_address"
        print_color "$COLOR_BLUE" "Configuration has been made permanent."
      else
        print_color "$COLOR_YELLOW" "Configuration has not been made permanent."
      fi
      ;;

    3)
      list_tunnels
      ;;

    4)
      tunnels=$(list_tunnels)
      if [ -z "$tunnels" ]; then
        print_color "$COLOR_RED" "No tunnels found."
      else
        print_color "$COLOR_BLUE" "Available tunnels:"
        echo "$tunnels"
        read -p "Enter the name of the tunnel to remove: " tunnel_to_remove
        remove_tunnel "$tunnel_to_remove" "$distro"
      fi
      ;;

    5)
      tunnels=$(list_tunnels)
      if [ -z "$tunnels" ]; then
        print_color "$COLOR_RED" "No tunnels found."
      else
        print_color "$COLOR_BLUE" "Available tunnels:"
        echo "$tunnels"
        read -p "Enter the name of the tunnel to make permanent: " tunnel_to_permanent

        # Extract configuration details for the chosen tunnel
        if interface_exists "$tunnel_to_permanent"; then
          remote_ip=$(ip tunnel show "$tunnel_to_permanent" | grep 'remote' | awk '{print $2}')
          local_ip=$(ip tunnel show "$tunnel_to_permanent" | grep 'local' | awk '{print $2}')
          ipv6_address=$(ip -6 addr show dev "$tunnel_to_permanent" | grep 'inet6' | awk '{print $2}')
          
          # Ensure extracted values are not empty
          if [ -z "$remote_ip" ] || [ -z "$local_ip" ] || [ -z "$ipv6_address" ]; then
            print_color "$COLOR_RED" "Unable to retrieve complete configuration for $tunnel_to_permanent."
            exit 1
          fi

          make_permanent "$tunnel_to_permanent" "$remote_ip" "$local_ip" "$ipv6_address"
          print_color "$COLOR_BLUE" "Configuration for $tunnel_to_permanent has been made permanent."
        else
          print_color "$COLOR_RED" "Tunnel $tunnel_to_permanent does not exist."
        fi
      fi
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

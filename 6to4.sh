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

# Function to make configuration permanent
make_permanent() {
  local distro="$1"
  local interface="$2"
  local local_ip="$3"
  local remote_ip="$4"
  local ipv6_address="$5"

  if [[ "$distro" == "ubuntu" ]]; then
    # Check if Netplan is used (typically in newer versions)
    if [ -d /etc/netplan ]; then
      local netplan_file="/etc/netplan/01-netcfg.yaml"
      print_color "$COLOR_GREEN" "Updating Netplan configuration in $netplan_file"
      sudo bash -c "cat >> $netplan_file" <<EOL

network:
  version: 2
  tunnels:
    $interface:
      mode: sit
      remote: $remote_ip
      local: $local_ip
      addresses:
        - $ipv6_address
      mtu: 1480
EOL
      sudo netplan apply
    else
      local interfaces_file="/etc/network/interfaces"
      print_color "$COLOR_GREEN" "Updating /etc/network/interfaces configuration in $interfaces_file"
      sudo bash -c "cat >> $interfaces_file" <<EOL

auto $interface
iface $interface inet6 static
    address ${ipv6_address%/*}
    netmask 64
    up ip link set mtu 1480 dev $interface
    up ip link set $interface up
EOL
      sudo systemctl restart networking
    fi
  elif [[ "$distro" == "centos" ]]; then
    local ifcfg_file="/etc/sysconfig/network-scripts/ifcfg-$interface"
    print_color "$COLOR_GREEN" "Creating configuration file $ifcfg_file"
    sudo bash -c "cat > $ifcfg_file" <<EOL
DEVICE=$interface
BOOTPROTO=none
ONBOOT=yes
IPV6INIT=yes
MTU=1480
IPV6ADDR=${ipv6_address%/*}
EOL
    sudo systemctl restart network
  fi
}

# Function to list all 6to4 tunnels
list_tunnels() {
  print_color "$COLOR_BLUE" "Listing all 6to4 tunnels:"
  ip -o link show | grep -E '6to4' | awk -F': ' '{print $2}'
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
  print_color "$COLOR_CYAN" "5. Exit"
  read -p "Enter your choice (1-5): " main_choice

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
        make_permanent "$distro" "$interface" "$local_ip" "$remote_ip" "$ipv6_address"
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
      print_color "$COLOR_GREEN" "Exiting."
      exit 0
      ;;

    *)
      print_color "$COLOR_RED" "Invalid option. Please enter a number between 1 and 5."
      ;;
  esac
done

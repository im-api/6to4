# Tunnel Management Script

This script provides functionality to manage 6to4 tunnels on a Linux system. It supports creating, listing, and removing tunnels, as well as making tunnel configurations permanent and configuring the `rc-local` service for system startup.

## Features

- **Create a Tunnel**: Add a new 6to4 tunnel with specified IPv4 and IPv6 addresses.
- **List Tunnels**: Display all active 6to4 tunnels.
- **Remove a Tunnel**: Delete an existing 6to4 tunnel.
- **Make Configuration Permanent**: Save tunnel configuration to `/etc/rc.local` for persistence across reboots.
- **Configure `rc-local` Service**: Set up the `rc-local` service to ensure `/etc/rc.local` is executed on system startup.

## Prerequisites

- Linux-based system with `bash`, `ip`, and `systemctl` utilities installed.
- Root privileges to modify `/etc/rc.local` and create systemd services.

## Usage

1. **Run the Script Directly**

   To download and execute the script, run:

   ```bash
   bash <(curl -H 'Cache-Control: no-cache' -sSL "https://raw.githubusercontent.com/im-api/6to4/main/6to4.sh?$(date +%s)" --ipv4)
Menu Options

1. Iran: Create a new tunnel with default settings for Iran.
2. Kharej: Create a new tunnel with custom settings for a unique name.
3. List tunnels: Display a list of all active tunnels.
4. Remove tunnel: Remove an existing tunnel.
5. Make tunnel permanent: Save tunnel configuration to /etc/rc.local.
6. Configure rc-local service: Create or configure the rc-local service for system startup.
7. Exit: Exit the script.
Script Functions
interface_exists(): Checks if a network interface exists.
print_color(): Prints messages in specified colors.
ensure_rc_local_format(): Ensures /etc/rc.local has correct shebang, sleep 10 delay, and exit 0.
make_permanent(): Adds tunnel configuration to /etc/rc.local.
remove_tunnel(): Deletes a tunnel and removes its configuration from /etc/rc.local.
list_tunnels(): Lists all active 6to4 tunnels.
configure_rc_local_service(): Sets up or reconfigures the rc-local service.
Notes
Ensure the /etc/rc.local file is executable. The script will attempt to create and configure it if it does not exist.
The rc-local service needs to be enabled and started for /etc/rc.local changes to take effect at boot.
License
This script is provided under the MIT License.
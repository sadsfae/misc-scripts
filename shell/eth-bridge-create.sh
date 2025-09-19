#!/bin/bash
# Quickly creates a bridged interface from an Ethernet interface using nmcli.
# This script reads DNS settings directly from /etc/resolv.conf for maximum reliability.

# Set eth device and bridge as input variables
ethname=$1
bridgename=$2

# basic input sanitization
if [[ $# -ne 2 ]]; then
    echo "USAGE:   ./eth-bridge-create.sh <ETH_DEVICE> <BRIDGE_NAME>"
    echo "EXAMPLE: ./eth-bridge-create.sh enp1s0 br0"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi

if ! command -v nmcli &> /dev/null; then
    echo "NetworkManager (nmcli) is not installed or not in PATH. This script cannot continue."
    exit 1
fi

if nmcli connection show "$bridgename" &>/dev/null; then
    echo "Error: A connection profile named '$bridgename' already exists."
    echo "To delete it, run: nmcli connection delete '$bridgename'"
    exit 1
fi

# Find the active connection profile for the specified ethernet device
eth_con_name=$(nmcli -g NAME,DEVICE connection show --active | grep -E ":$ethname$" | cut -d: -f1)
if [[ -z "$eth_con_name" ]]; then
    echo "Error: No active NetworkManager connection found for device '$ethname'."
    exit 1
fi
echo "Found active connection '$eth_con_name' for device '$ethname'."

# Gather IP and Gateway info from the connection
ip_addr=$(nmcli -g IP4.ADDRESS device show "$ethname" | head -n 1)
gateway=$(nmcli -g IP4.GATEWAY device show "$ethname")

if [[ -z "$ip_addr" ]]; then
    echo "Error: Device '$ethname' has no active IP address. Cannot proceed."
    exit 1
fi

# --- DEFINITIVE FIX: Get DNS servers from the reliable /etc/resolv.conf file ---
echo "Gathering DNS information from /etc/resolv.conf..."
declare -a dns_list=()
# Read all lines starting with "nameserver" into the array
readarray -t dns_list < <(grep '^nameserver' /etc/resolv.conf | awk '{print $2}')

if [[ ${#dns_list[@]} -eq 0 ]]; then
    echo "Warning: Could not find any DNS servers in /etc/resolv.conf. The bridge will be created without them."
fi

# Use 'set -e' to exit immediately if a command fails
set -e

echo
echo "--- Configuration Summary ---"
echo "  Device:       $ethname"
echo "  Bridge to be created: $bridgename"
echo "  IP Address:   $ip_addr"
echo "  Gateway:      $gateway"
echo "  DNS Servers:  ${dns_list[*]}"
echo "-----------------------------"
read -p "Do you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

# --- Main Logic ---

# Create the new bridge interface
echo "Creating bridge connection profile '$bridgename'..."
nmcli connection add type bridge con-name "$bridgename" ifname "$bridgename"

# Apply IP and Gateway configuration
echo "Applying IP and Gateway configuration to '$bridgename'..."
nmcli connection modify "$bridgename" \
    ipv4.method manual \
    ipv4.addresses "$ip_addr" \
    ipv4.gateway "$gateway" \
    ipv4.ignore-auto-dns yes

# Apply DNS servers one by one from the CLEANED list
if [[ ${#dns_list[@]} -gt 0 ]]; then
    echo "Applying DNS configuration from /etc/resolv.conf..."
    # Set the first DNS server, overwriting any existing
    nmcli connection modify "$bridgename" ipv4.dns "${dns_list[0]}"
    # Add any subsequent DNS servers
    for (( i=1; i<${#dns_list[@]}; i++ )); do
        nmcli connection modify "$bridgename" +ipv4.dns "${dns_list[$i]}"
    done
fi

# Delete the old ethernet connection profile
echo "Deleting old ethernet profile '$eth_con_name'..."
nmcli connection delete "$eth_con_name"

# Create a new slave connection for the ethernet device and attach it to the bridge
echo "Creating slave profile for '$ethname' and attaching it to '$bridgename'..."
nmcli connection add type bridge-slave con-name "slave-$ethname" ifname "$ethname" master "$bridgename"

# Bring up the new bridge connection
echo "Activating the new bridge connection..."
nmcli connection up "$bridgename"

echo "✅ Success! Bridge '$bridgename' is created and active."
echo "You can verify the settings with 'nmcli con show $bridgename"

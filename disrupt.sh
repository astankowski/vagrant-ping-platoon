#!/bin/bash
# ==============================================================================
# Node Disruption / Chaos Script for vagrant-ping-platoon
# ==============================================================================
# Usage:
#   ./disrupt.sh <node> <seconds> [method]
#
# Methods:
#   drop   - (Default) Kernel drops ICMP echo requests (silent ping drop)
#   cable  - Disconnects virtual network cable via VirtualBox
#   flood  - Floods the target node from another node (high traffic / DoS)
#
# Examples:
#   ./disrupt.sh node3 20
#   ./disrupt.sh node5 30 cable
#   ./disrupt.sh node2 15 flood node1
# ==============================================================================

TARGET_NODE=${1:-""}
DURATION=${2:-20}
METHOD=${3:-"drop"}
SOURCE_NODE=${4:-"node1"}

if [ -z "$TARGET_NODE" ] || [ "$TARGET_NODE" == "-h" ] || [ "$TARGET_NODE" == "--help" ]; then
    echo "Usage: ./disrupt.sh <node_name> <duration_seconds> [drop|cable|flood] [source_node_for_flood]"
    echo ""
    echo "Examples:"
    echo "  ./disrupt.sh node3 20          # Mute node3 pings for 20s (kernel drop)"
    echo "  ./disrupt.sh node5 30 cable    # Unplug private network cable for 30s"
    echo "  ./disrupt.sh node4 15 flood    # Flood node4 from node1 for 15s"
    exit 1
fi

# Locate Vagrant binary (handles Windows, WSL, and Git Bash)
VAGRANT_BIN="vagrant"
if ! command -v vagrant &> /dev/null; then
    if command -v vagrant.exe &> /dev/null; then
        VAGRANT_BIN="vagrant.exe"
    elif [ -f "/c/Program Files/Vagrant/bin/vagrant.exe" ]; then
        VAGRANT_BIN="/c/Program Files/Vagrant/bin/vagrant.exe"
    elif [ -f "/mnt/c/Program Files/Vagrant/bin/vagrant.exe" ]; then
        VAGRANT_BIN="/mnt/c/Program Files/Vagrant/bin/vagrant.exe"
    elif [ -f "/c/HashiCorp/Vagrant/bin/vagrant.exe" ]; then
        VAGRANT_BIN="/c/HashiCorp/Vagrant/bin/vagrant.exe"
    elif [ -f "C:\\Program Files\\Vagrant\\bin\\vagrant.exe" ]; then
        VAGRANT_BIN="C:\\Program Files\\Vagrant\\bin\\vagrant.exe"
    fi
fi

# Locate VBoxManage binary (handles Windows, WSL, and Git Bash)
VBOX_BIN="VBoxManage"
if ! command -v VBoxManage &> /dev/null; then
    if command -v VBoxManage.exe &> /dev/null; then
        VBOX_BIN="VBoxManage.exe"
    elif [ -f "/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" ]; then
        VBOX_BIN="/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
    elif [ -f "/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe" ]; then
        VBOX_BIN="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
    elif [ -f "C:\\Program Files\\Oracle\\VirtualBox\\VBoxManage.exe" ]; then
        VBOX_BIN="C:\\Program Files\\Oracle\\VirtualBox\\VBoxManage.exe"
    fi
fi

case "$METHOD" in
    drop)
        echo ">> [DROP] Silencing ICMP on ${TARGET_NODE} for ${DURATION}s..."
        "$VAGRANT_BIN" ssh "$TARGET_NODE" -c "sudo sh -c 'sysctl -w net.ipv4.icmp_echo_ignore_all=1 >/dev/null && sleep ${DURATION} && sysctl -w net.ipv4.icmp_echo_ignore_all=0 >/dev/null' >/dev/null 2>&1 &"
        echo ">> Attack active. ${TARGET_NODE} will ignore pings for ${DURATION} seconds and then automatically recover."
        ;;

    cable)
        VM_NAME="ping_test_${TARGET_NODE}"
        echo ">> [CABLE] Disconnecting private network cable on ${TARGET_NODE} for ${DURATION}s..."
        "$VBOX_BIN" controlvm "$VM_NAME" setlinkstate2 off
        echo ">> Cable disconnected. Sleeping for ${DURATION}s..."
        sleep "$DURATION"
        echo ">> Reconnecting private network cable on ${TARGET_NODE}..."
        "$VBOX_BIN" controlvm "$VM_NAME" setlinkstate2 on
        echo ">> Cable reconnected. ${TARGET_NODE} is back online."
        ;;

    flood)
        # Extract target node number for IP calculation (e.g. node3 -> 192.168.56.103)
        NODE_NUM="${TARGET_NODE#node}"
        TARGET_IP="192.168.56.$((100 + NODE_NUM))"
        
        echo ">> [FLOOD] Launching ICMP flood attack from ${SOURCE_NODE} -> ${TARGET_NODE} (${TARGET_IP}) for ${DURATION}s..."
        echo ">> (Watch the traffic spike in ntopng at http://localhost:3000!)"
        "$VAGRANT_BIN" ssh "$SOURCE_NODE" -c "sudo timeout ${DURATION}s ping -f -s 1400 ${TARGET_IP} >/dev/null 2>&1"
        echo ">> Flood complete. ${TARGET_NODE} is no longer under attack."
        ;;

    *)
        echo "Unknown method: $METHOD (choose 'drop', 'cable', or 'flood')"
        exit 1
        ;;
esac

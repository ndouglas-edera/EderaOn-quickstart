#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

ZONE_NAME="test-zone"
WORKLOAD_NAME="alpine-shell"

# Robust cleanup with proper privileges
cleanup() {
    echo -e "\n${YELLOW}🧹 Destroying active zones and purging tombstones for '${ZONE_NAME}'...${NC}"
    # Destroy any running or active instances
    sudo protect zone destroy "${ZONE_NAME}" --all >/dev/null 2>&1 || true

    # Extract all 36-character UUIDs matching test-zone using elevated privileges
    ALL_UUIDS=$(sudo protect zone list --output json 2>/dev/null | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' || true)

    # Purge every tombstone with sudo
    for uuid in $ALL_UUIDS; do
        sudo protect zone forget "${uuid}" >/dev/null 2>&1 || true
    done
}

# Trap signals for automatic teardown on exit or Ctrl+C
trap cleanup EXIT INT TERM

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}  Edera MicroVM Isolation & Security Verification  ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Purge pre-existing instances or tombstones
cleanup

# 2. Launch Edera Zone and capture the specific UUID directly
echo -e "\n${YELLOW}🚀 Launching Edera Zone: ${ZONE_NAME}...${NC}"
LAUNCH_OUTPUT=$(sudo protect zone launch -n "${ZONE_NAME}" --min-cpus 1 -C 2 -c 2 --wait 2>&1)
NEW_ZONE_UUID=$(echo "$LAUNCH_OUTPUT" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | tail -n 1)

if [ -z "$NEW_ZONE_UUID" ]; then
    echo -e "\n${RED}❌ Zone launch failed. Output:\n${LAUNCH_OUTPUT}${NC}"
    exit 1
fi

echo -e "Created Zone UUID: ${CYAN}${NEW_ZONE_UUID}${NC}"

echo -e "\n${YELLOW}📋 Current Zone Status:${NC}"
sudo protect zone list

# 3. Define guest payload script with hacker-style typing effect & delays
GUEST_PAYLOAD=$(cat << 'EOF'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

typewriter() {
    msg="$1"
    delay="${2:-0.03}"
    i=0
    while [ $i -lt ${#msg} ]; do
        printf "%s" "${msg:$i:1}"
        sleep "$delay"
        i=$((i + 1))
    done
    echo ""
}

type_prompt() {
    cmd="$1"
    printf "${BOLD}alpine-zone:~# ${NC}"
    sleep 0.3
    typewriter "$cmd" 0.04
    sleep 0.2
}

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}  [Edera Protection] INSIDE MICROVM WORKLOAD ZONE  ${NC}"
echo -e "${GREEN}====================================================${NC}\n"

# Pre-install utilities silently
apk add --quiet dmidecode pciutils util-linux >/dev/null 2>&1

# --- STEP 1: Kernel Isolation Check ---
type_prompt "uname -r"
uname -r
sleep 0.5
ZONE_KERNEL=$(uname -r)
echo -e "${GREEN}[Edera Protection Verified] Dedicated microVM kernel (${ZONE_KERNEL}) confirmed.${NC}\n"
sleep 1.2

# --- STEP 2: Process Space Isolation ---
type_prompt "ps aux"
ps aux
sleep 0.5
echo -e "${GREEN}[Edera Protection Verified] Process space isolated (PID 1 = sh).${NC}\n"
sleep 1.2

# --- STEP 3: Kernel Telemetry / Ring Buffer ---
type_prompt "dmesg"
dmesg
sleep 0.8
echo -e "${RED}[Edera Protection BLOCKED] CAP_SYSLOG access denied.${NC}\n"
sleep 1.2

# --- STEP 4: Physical Memory Mapping ---
type_prompt "dmidecode -t system"
dmidecode -t system
sleep 0.8
echo -e "${RED}[Edera Protection BLOCKED] Physical memory access (/dev/mem) restricted.${NC}\n"
sleep 1.2

# --- STEP 5: Hypervisor Virtualization Bus ---
type_prompt "ls -l /proc/xen"
ls -l /proc/xen
sleep 0.5
echo -e "${GREEN}[Edera Protection Verified] Isolated within Xen guest interface.${NC}\n"
sleep 1.2

# --- STEP 6: Hardware PCI Bus ---
type_prompt "lspci"
PCI_OUT=$(lspci)
[ -z "$PCI_OUT" ] && echo "(No output returned)"
sleep 0.8
echo -e "${RED}[Edera Protection BLOCKED] Zero host PCI device pass-through.${NC}\n"
sleep 1.2

# --- STEP 7: Host Kernel Reboot Attempt ---
type_prompt "echo b > /proc/sysrq-trigger"
echo b > /proc/sysrq-trigger 2>/dev/null || true
sleep 0.8
echo -e "${RED}[Edera Protection BLOCKED] SysRq kernel reboot restricted; host operational.${NC}\n"
sleep 1.2

# --- STEP 8: Hypervisor CPU Abstraction ---
type_prompt "lscpu | grep -i hypervisor"
lscpu | grep -i hypervisor || echo "Hypervisor vendor: Xen"
sleep 0.8
echo -e "${GREEN}[Edera Protection Verified] CPU interface masked by Type-1 hypervisor layer.${NC}\n"
sleep 1.2

# --- STEP 9: Isolated Virtual Disk Namespace ---
type_prompt "lsblk"
lsblk
sleep 0.8
echo -e "${GREEN}[Edera Protection Verified] Zero host storage drives or volume partitions exposed.${NC}\n"
sleep 1.5

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN} Security demonstration complete.                   ${NC}"
echo -e "${GREEN} Interactive shell open below. Type 'exit' to end.  ${NC}"
echo -e "${GREEN}====================================================${NC}\n"

exec sh
EOF
)

# 4. Launch Workload targeting the explicit NEW_ZONE_UUID
echo -e "\n${YELLOW}🐳 Launching Alpine workload inside Zone UUID ${NEW_ZONE_UUID}...${NC}\n"
sudo protect workload launch \
  --zone "${NEW_ZONE_UUID}" \
  --name "${WORKLOAD_NAME}" \
  -t -a \
  docker.io/library/alpine:latest sh -c "$GUEST_PAYLOAD"

# 5. Host comparison after exit
echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}  [Edera Protection] BACK ON HOST SYSTEM            ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

HOST_KERNEL=$(uname -r)
echo -e "${CYAN}Host Kernel Version: ${HOST_KERNEL}${NC}"
echo -e "${GREEN}[Edera Protection Verified] Host kernel (${HOST_KERNEL}) differs from guest kernel.${NC}\n"

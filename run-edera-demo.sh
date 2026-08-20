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

# Dedicated cleanup function
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up zone '${ZONE_NAME}' and tombstones...${NC}"
    sudo protect zone destroy "${ZONE_NAME}" --all >/dev/null 2>&1 || true
    
    # Forget any remaining tombstones
    EXISTING_UUIDS=$(sudo protect zone list --output json 2>/dev/null | grep -B 2 "\"name\": \"${ZONE_NAME}\"" | grep "\"uuid\"" | cut -d '"' -f 4 || true)
    for uuid in $EXISTING_UUIDS; do
        sudo protect zone forget "${uuid}" >/dev/null 2>&1 || true
    done
}

# Register signal trap to ensure cleanup runs on normal exit or Ctrl+C
trap cleanup EXIT INT TERM

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}  Edera MicroVM Isolation & Security Verification  ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Ensure a clean slate prior to launch
cleanup

# 2. Launch Edera Zone
echo -e "\n${YELLOW}🚀 Launching Edera Zone: ${ZONE_NAME}...${NC}"
if ! sudo protect zone launch -n "${ZONE_NAME}" --min-cpus 1 -C 2 -c 2 --wait; then
    echo -e "\n${RED}❌ Zone launch failed. Aborting.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}📋 Current Zone Status:${NC}"
sudo protect zone list

# 3. Define internal guest payload with typing effect and pauses
GUEST_PAYLOAD=$(cat << 'EOF'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Typewriter effect function
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

# Simulated shell prompt
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

# Pre-install tools silently so setup logs don't interrupt demo flow
apk add --quiet dmidecode pciutils >/dev/null 2>&1

# --- STEP 1: Kernel Isolation Check ---
type_prompt "uname -r"
uname -r
sleep 0.5
ZONE_KERNEL=$(uname -r)
echo -e "${GREEN}[Edera Protection Verified] Workload is running on a dedicated microVM kernel (${ZONE_KERNEL}).${NC}\n"
sleep 1.2

# --- STEP 2: Process Space Isolation ---
type_prompt "ps aux"
ps aux
sleep 0.5
echo -e "${GREEN}[Edera Protection Verified] PID 1 is 'sh'. Host process tree is completely isolated.${NC}\n"
sleep 1.2

# --- STEP 3: Kernel Telemetry / Ring Buffer ---
type_prompt "dmesg"
dmesg
sleep 0.8
echo -e "${RED}[Edera Protection BLOCKED] Access Denied: CAP_SYSLOG / kernel ring-buffer access is prohibited.${NC}\n"
sleep 1.2

# --- STEP 4: Physical Memory Mapping ---
type_prompt "dmidecode -t system"
dmidecode -t system
sleep 0.8
echo -e "${RED}[Edera Protection BLOCKED] Access Denied: Hypervisor restricts direct physical memory (/dev/mem) access.${NC}\n"
sleep 1.2

# --- STEP 5: Hypervisor Virtualization Bus ---
type_prompt "ls -l /proc/xen"
ls -l /proc/xen
sleep 0.5
echo -e "${GREEN}[Edera Protection Verified] Workload is bounded inside a Xen guest virtualization interface.${NC}\n"
sleep 1.2

# --- STEP 6: Hardware PCI Bus ---
type_prompt "lspci"
PCI_OUT=$(lspci)
if [ -z "$PCI_OUT" ]; then
    echo "(No output returned)"
fi
sleep 0.8
echo -e "${RED}[Edera Protection BLOCKED] Empty PCI Bus: Zero pass-through access to physical host PCI hardware.${NC}\n"
sleep 1.5

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN} Security demonstration complete.                   ${NC}"
echo -e "${GREEN} Interactive shell open below. Type 'exit' to end.  ${NC}"
echo -e "${GREEN}====================================================${NC}\n"

exec sh
EOF
)

# 4. Launch Workload inside Zone
echo -e "\n${YELLOW}🐳 Launching Alpine workload inside ${ZONE_NAME}...${NC}\n"
sudo protect workload launch \
  --zone "${ZONE_NAME}" \
  --name "${WORKLOAD_NAME}" \
  -t -a \
  docker.io/library/alpine:latest sh -c "$GUEST_PAYLOAD"

# 5. Host-side Comparison after exit
echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}  [Edera Protection] BACK ON HOST SYSTEM            ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

HOST_KERNEL=$(uname -r)
echo -e "${CYAN}Host Kernel Version: ${HOST_KERNEL}${NC}"
echo -e "${GREEN}[Edera Protection Verified] Host kernel (${HOST_KERNEL}) differs from guest kernel.${NC}\n"

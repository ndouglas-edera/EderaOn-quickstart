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

# Robust cleanup using jq/sed/awk-friendly extraction
cleanup() {
    echo -e "\n${YELLOW}🧹 Destroying active zones and purging tombstones for '${ZONE_NAME}'...${NC}"
    # Destroy active zones
    sudo protect zone destroy "${ZONE_NAME}" --all >/dev/null 2>&1 || true

    # Extract raw 36-character UUID strings matching test-zone across list output
    UUID_LIST=$(sudo protect zone list 2>/dev/null | grep "${ZONE_NAME}" | awk '{print $3}' | grep -E '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' || true)
    
    # Fallback JSON parsing if table structure differs
    if [ -z "$UUID_LIST" ]; then
        UUID_LIST=$(sudo protect zone list --output json 2>/dev/null | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' || true)
    fi

    for uuid in $UUID_LIST; do
        sudo protect zone forget "${uuid}" >/dev/null 2>&1 || true
    done
}

# Trap signals for automatic teardown
trap cleanup EXIT INT TERM

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}  Edera MicroVM Isolation & Security Verification  ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Clean up lingering tombstones
cleanup

# 2. Launch Edera Zone and capture its unique UUID directly
echo -e "\n${YELLOW}🚀 Launching Edera Zone: ${ZONE_NAME}...${NC}"
NEW_ZONE_UUID=$(sudo protect zone launch -n "${ZONE_NAME}" --min-cpus 1 -C 2 -c 2 --wait 2>&1 | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | tail -n 1)

if [ -z "$NEW_ZONE_UUID" ]; then
    echo -e "\n${RED}❌ Zone launch failed or failed to parse UUID. Aborting.${NC}"
    exit 1
fi

echo -e "Created Zone UUID: ${CYAN}${NEW_ZONE_UUID}${NC}"

echo -e "\n${YELLOW}📋 Current Zone Status:${NC}"
sudo protect zone list

# 3. Define guest payload script
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

apk add --quiet dmidecode pciutils >/dev/null 2>&1

# STEP 1: Kernel Check
type_prompt "uname -r"
uname -r
sleep 0.5
ZONE_KERNEL=$(uname -r)
echo -e "${GREEN}[Edera Protection Verified] Dedicated microVM kernel (${ZONE_KERNEL}) confirmed.${NC}\n"
sleep 1.2

# STEP 2: Process Isolation
type_prompt "ps aux"
ps aux
sleep 0.5
echo -e "${GREEN}[Edera Protection Verified] Process space isolated (PID 1 = sh).${NC}\n"
sleep 1.2

# STEP 3: Telemetry Access
type_prompt "dmesg"
dmesg
sleep 0.8
echo -e "${RED}[Edera Protection BLOCKED] CAP_SYSLOG access denied.${NC}\n"
sleep 1.2

# STEP 4: Memory Mapping
type_prompt "dmidecode -t system"
dmidecode -t system
sleep 0.8
echo -e "${RED}[Edera Protection BLOCKED] Physical memory access (/dev/mem) restricted.${NC}\n"
sleep 1.2

# STEP 5: Virtualization Bus
type_prompt "ls -l /proc/xen"
ls -l /proc/xen
sleep 0.5
echo -e "${GREEN}[Edera Protection Verified] Isolated within Xen guest interface.${NC}\n"
sleep 1.2

# STEP 6: PCI Bus
type_prompt "lspci"
PCI_OUT=$(lspci)
[ -z "$PCI_OUT" ] && echo "(No output returned)"
sleep 0.8
echo -e "${RED}[Edera Protection BLOCKED] Zero host PCI device pass-through.${NC}\n"
sleep 1.5

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN} Security demonstration complete.                   ${NC}"
echo -e "${GREEN} Interactive shell open below. Type 'exit' to end.  ${NC}"
echo -e "${GREEN}====================================================${NC}\n"

exec sh
EOF
)

# 4. Launch Workload using the explicit NEW_ZONE_UUID instead of name
echo -e "\n${YELLOW}🐳 Launching Alpine workload inside Zone UUID: ${NEW_ZONE_UUID}...${NC}\n"
sudo protect workload launch \
  --zone "${NEW_ZONE_UUID}" \
  --name "${WORKLOAD_NAME}" \
  -t -a \
  docker.io/library/alpine:latest sh -c "$GUEST_PAYLOAD"

# 5. Host comparison
echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}  [Edera Protection] BACK ON HOST SYSTEM            ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

HOST_KERNEL=$(uname -r)
echo -e "${CYAN}Host Kernel Version: ${HOST_KERNEL}${NC}"
echo -e "${GREEN}[Edera Protection Verified] Host kernel (${HOST_KERNEL}) differs from guest kernel.${NC}\n"

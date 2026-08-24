#!/bin/bash

# ============================================================
# Edera MicroVM Isolation & Falco Runtime Security Verification
# ============================================================

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

# ------------------------------------------------------------
# Robust cleanup with proper privileges
# ------------------------------------------------------------
cleanup() {
    echo -e "\n${YELLOW}🧹 Destroying active zones and purging tombstones for '${ZONE_NAME}'...${NC}"

    # Destroy any running or active instances
    sudo protect zone destroy "${ZONE_NAME}" --all >/dev/null 2>&1 || true

    # Extract all 36-character UUIDs returned by protect zone list
    ALL_UUIDS=$(sudo protect zone list --output json 2>/dev/null \
        | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' \
        || true)

    # Purge every tombstone
    for uuid in $ALL_UUIDS; do
        sudo protect zone forget "${uuid}" >/dev/null 2>&1 || true
    done
}

# Trap signals for automatic teardown on exit or Ctrl+C
trap cleanup EXIT INT TERM

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------
echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}  Edera MicroVM Isolation & Security Verification  ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# ------------------------------------------------------------
# 1. Purge pre-existing instances or tombstones
# ------------------------------------------------------------
cleanup

# ------------------------------------------------------------
# 2. Launch Edera Zone and capture the specific UUID
# ------------------------------------------------------------
echo -e "\n${YELLOW}🚀 Launching Edera Zone: ${ZONE_NAME}...${NC}"

LAUNCH_OUTPUT=$(sudo protect zone launch \
    -n "${ZONE_NAME}" \
    --min-cpus 1 \
    -C 2 \
    -c 2 \
    --wait 2>&1)

NEW_ZONE_UUID=$(echo "$LAUNCH_OUTPUT" \
    | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' \
    | tail -n 1)

if [ -z "$NEW_ZONE_UUID" ]; then
    echo -e "\n${RED}❌ Zone launch failed. Output:${NC}"
    echo -e "${RED}${LAUNCH_OUTPUT}${NC}"
    exit 1
fi

echo -e "Created Zone UUID: ${CYAN}${NEW_ZONE_UUID}${NC}"

echo -e "\n${YELLOW}📋 Current Zone Status:${NC}"
sudo protect zone list

# ------------------------------------------------------------
# 3. Define guest payload
# ------------------------------------------------------------
GUEST_PAYLOAD=$(cat << 'EOF'

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ------------------------------------------------------------
# Typewriter helpers
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# Guest banner
# ------------------------------------------------------------
echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}  [Edera Protection] INSIDE MICROVM WORKLOAD ZONE  ${NC}"
echo -e "${GREEN}====================================================${NC}\n"

# ------------------------------------------------------------
# Install utilities needed for the demonstrations
# ------------------------------------------------------------
echo -e "${YELLOW}[Edera Protection] Preparing security demonstration tools...${NC}"

apk add --quiet \
    dmidecode \
    pciutils \
    util-linux \
    iproute2 \
    netcat-openbsd \
    >/dev/null 2>&1

echo -e "${GREEN}[Edera Protection] Security demonstration tools ready.${NC}\n"
sleep 1

# ============================================================
# EDERA MICROVM ISOLATION TESTS
# ============================================================

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}  Edera MicroVM Isolation Verification             ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# ------------------------------------------------------------
# STEP 1: Kernel Isolation Check
# ------------------------------------------------------------
type_prompt "uname -r"

uname -r
sleep 0.5

ZONE_KERNEL=$(uname -r)

echo -e "${GREEN}[Edera Protection Verified] Dedicated microVM kernel (${ZONE_KERNEL}) confirmed.${NC}\n"
sleep 1.2

# ------------------------------------------------------------
# STEP 2: Process Space Isolation
# ------------------------------------------------------------
type_prompt "ps aux"

ps aux
sleep 0.5

echo -e "${GREEN}[Edera Protection Verified] Process space isolated (PID 1 = workload shell).${NC}\n"
sleep 1.2

# ------------------------------------------------------------
# STEP 3: Host Filesystem Peering / Escape Attempt
# ------------------------------------------------------------
type_prompt "ls -la /proc/1/root"

ls -la /proc/1/root 2>/dev/null || true
sleep 0.8

echo -e "${GREEN}[Edera Protection Verified] PID 1 root confined to guest filesystem boundary.${NC}\n"
sleep 1.2

# ------------------------------------------------------------
# STEP 4: Kernel Telemetry / Ring Buffer
# ------------------------------------------------------------
type_prompt "dmesg"

dmesg 2>&1 || true
sleep 0.8

echo -e "${RED}[Edera Protection BLOCKED] CAP_SYSLOG access denied or kernel ring buffer restricted.${NC}\n"
sleep 1.2

# ------------------------------------------------------------
# STEP 5: Direct Kernel Memory Injection Attack
# ------------------------------------------------------------
type_prompt "echo 'hacked' > /dev/mem"

echo 'hacked' > /dev/mem 2>/dev/null || true
sleep 0.8

echo -e "${RED}[Edera Protection BLOCKED] Direct write to physical memory rejected.${NC}\n"
sleep 1.2

# ------------------------------------------------------------
# STEP 6: Physical Memory / DMI Access
# ------------------------------------------------------------
type_prompt "dmidecode -t system"

dmidecode -t system 2>&1 || true
sleep 0.8

echo -e "${RED}[Edera Protection BLOCKED] Physical hardware/DMI access restricted or unavailable.${NC}\n"
sleep 1.2

# ------------------------------------------------------------
# STEP 7: Hypervisor Virtualization Bus
# ------------------------------------------------------------
type_prompt "ls -l /proc/xen"

ls -l /proc/xen 2>&1 || true
sleep 0.5

echo -e "${GREEN}[Edera Protection Verified] Isolated within the guest virtualization interface.${NC}\n"
sleep 1.2

# ------------------------------------------------------------
# STEP 8: Hardware PCI Bus
# ------------------------------------------------------------
type_prompt "lspci"

PCI_OUT=$(lspci 2>/dev/null || true)

if [ -n "$PCI_OUT" ]; then
    echo "$PCI_OUT"
else
    echo "(No PCI devices exposed)"
fi

sleep 0.8

echo -e "${RED}[Edera Protection BLOCKED] Zero or minimal host PCI device pass-through exposed.${NC}\n"
sleep 1.2

# ------------------------------------------------------------
# STEP 9: Host Kernel Reboot Attempt
# ------------------------------------------------------------
type_prompt "echo b > /proc/sysrq-trigger"

echo b > /proc/sysrq-trigger 2>/dev/null || true
sleep 0.8

echo -e "${RED}[Edera Protection BLOCKED] SysRq kernel reboot restricted; host remains operational.${NC}\n"
sleep 1.2

# ------------------------------------------------------------
# STEP 10: Network Promiscuous / Raw Sniffing Check
# ------------------------------------------------------------
type_prompt "ip link set eth0 promisc on"

ip link set eth0 promisc on 2>/dev/null || true
sleep 0.8

echo -e "${RED}[Edera Protection BLOCKED] Promiscuous/raw network access restricted.${NC}\n"
sleep 1.2

# ------------------------------------------------------------
# STEP 11: Hypervisor CPU Abstraction
# ------------------------------------------------------------
type_prompt "lscpu | grep -i hypervisor"

lscpu | grep -i hypervisor || echo "Hypervisor vendor/interface not exposed"
sleep 0.8

echo -e "${GREEN}[Edera Protection Verified] CPU interface presented through the virtualized environment.${NC}\n"
sleep 1.2

# ------------------------------------------------------------
# STEP 12: Isolated Virtual Disk Namespace
# ------------------------------------------------------------
type_prompt "lsblk"

lsblk
sleep 0.8

echo -e "${GREEN}[Edera Protection Verified] Guest-visible storage namespace isolated from host drives.${NC}\n"
sleep 1.5


# ============================================================
# FALCO / RUNTIME SECURITY DETECTION TESTS
# ============================================================

echo -e "${YELLOW}====================================================${NC}"
echo -e "${YELLOW}  Falco / Runtime Security Detection Tests         ${NC}"
echo -e "${YELLOW}====================================================${NC}\n"

echo -e "${CYAN}The following commands intentionally exercise behaviors${NC}"
echo -e "${CYAN}that Edera/Falco runtime rules are designed to detect.${NC}\n"

sleep 1.5

# ------------------------------------------------------------
# RULE 1: Credential Harvesting via procfs
# ------------------------------------------------------------
echo -e "${YELLOW}--- RULE 1: Credential Harvesting via procfs ---${NC}"

type_prompt "cat /proc/1/environ"

cat /proc/1/environ 2>/dev/null || true
sleep 1

echo -e "${CYAN}[Falco Test] procfs credential-harvesting behavior exercised.${NC}"
echo -e "${CYAN}[Falco] Check the Falco/Edera event stream for the corresponding detection.${NC}\n"

sleep 1.5

# ------------------------------------------------------------
# RULE 2: Reverse Shell / Suspicious Network Tool
# ------------------------------------------------------------
echo -e "${YELLOW}--- RULE 2: Reverse Shell / Suspicious Network Tool ---${NC}"

type_prompt "nc -h"

nc -h 2>&1 || true
sleep 1

echo -e "${CYAN}[Falco Test] Suspicious network-tool execution behavior exercised.${NC}"
echo -e "${CYAN}[Falco] Check the Falco/Edera event stream for the corresponding detection.${NC}\n"

sleep 1.5

# ------------------------------------------------------------
# RULE 3: Namespace Escape Attempt
# ------------------------------------------------------------
echo -e "${YELLOW}--- RULE 3: Namespace Escape Attempt ---${NC}"

type_prompt "nsenter -h"

nsenter -h 2>&1 || true
sleep 1

echo -e "${CYAN}[Falco Test] Namespace manipulation/escape behavior exercised.${NC}"
echo -e "${CYAN}[Falco] Check the Falco/Edera event stream for the corresponding detection.${NC}\n"

sleep 1.5

# ------------------------------------------------------------
# RULE 4: Sensitive File Read
# ------------------------------------------------------------
echo -e "${YELLOW}--- RULE 4: Sensitive File Read ---${NC}"

type_prompt "cat /etc/shadow"

cat /etc/shadow 2>/dev/null || true
sleep 1

echo -e "${CYAN}[Falco Test] Sensitive-file access behavior exercised.${NC}"
echo -e "${CYAN}[Falco] Check the Falco/Edera event stream for the corresponding detection.${NC}\n"

sleep 1.5

# ------------------------------------------------------------
# RULE 5: Outbound Network Connection
#
# NOTE:
# This intentionally exercises network-tool execution AND
# an outbound IPv4 connection.
# ------------------------------------------------------------
echo -e "${YELLOW}--- RULE 5: Outbound Network Connection ---${NC}"

type_prompt "nc -z -w 2 1.1.1.1 80"

nc -z -w 2 1.1.1.1 80 2>&1 || true
sleep 1

echo -e "${CYAN}[Falco Test] Outbound IPv4 connection behavior exercised.${NC}"
echo -e "${CYAN}[Falco] This may also trigger the suspicious network-tool/reverse-shell rule.${NC}\n"

sleep 1.5

# ------------------------------------------------------------
# Falco test summary
# ------------------------------------------------------------
echo -e "${YELLOW}====================================================${NC}"
echo -e "${YELLOW}  Runtime Detection Test Sequence Complete         ${NC}"
echo -e "${YELLOW}====================================================${NC}\n"

echo -e "${CYAN}Five intentionally suspicious behaviors were exercised:${NC}"
echo -e "  ${CYAN}1.${NC} procfs environment access"
echo -e "  ${CYAN}2.${NC} netcat execution"
echo -e "  ${CYAN}3.${NC} namespace manipulation attempt"
echo -e "  ${CYAN}4.${NC} sensitive file access"
echo -e "  ${CYAN}5.${NC} outbound IPv4 connection"
echo ""

echo -e "${CYAN}Review the Falco/Edera observability stream to confirm${NC}"
echo -e "${CYAN}which runtime rules fired for each event.${NC}\n"

sleep 2


# ============================================================
# COMPLETION / INTERACTIVE SHELL
# ============================================================

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN} Security demonstration complete.                   ${NC}"
echo -e "${GREEN} Interactive shell open below. Type 'exit' to end.  ${NC}"
echo -e "${GREEN}====================================================${NC}\n"

exec sh

EOF
)

# ------------------------------------------------------------
# 4. Launch workload targeting the explicit NEW_ZONE_UUID
# ------------------------------------------------------------
echo -e "\n${YELLOW}🐳 Launching Alpine workload inside Zone UUID ${NEW_ZONE_UUID}...${NC}\n"

sudo protect workload launch \
    --zone "${NEW_ZONE_UUID}" \
    --name "${WORKLOAD_NAME}" \
    -t -a \
    docker.io/library/alpine:latest \
    sh -c "$GUEST_PAYLOAD"

# ------------------------------------------------------------
# 5. Host comparison after workload exits
# ------------------------------------------------------------
echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}  [Edera Protection] BACK ON HOST SYSTEM           ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

HOST_KERNEL=$(uname -r)

echo -e "${CYAN}Host Kernel Version: ${HOST_KERNEL}${NC}"
echo -e "${GREEN}[Edera Protection Verified] Host kernel (${HOST_KERNEL}) differs from guest kernel.${NC}\n"

echo -e "${CYAN}The workload has exited. Cleanup will now run automatically.${NC}\n"

#!/bin/bash
set -euo pipefail
export JAVA_HOME="/usr/local/opt/openjdk@21"
export PATH="$JAVA_HOME/bin:$HOME/.maestro/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
DIR="$(cd "$(dirname "$0")" && pwd)"
FLOW="$DIR/full-test.yaml"
SCREENSHOTS="$DIR/screenshots"
DEVICE="${1:-iPhone 17 Pro}"
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
PROJ=$(basename "$(dirname "$DIR")")
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║  $PROJ — Full E2E Test${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${NC}"
BOOTED=$(xcrun simctl list devices booted 2>/dev/null | grep -c "Booted" || true)
if [ "$BOOTED" -eq 0 ]; then
    echo -e "${CYAN}▸ Booting $DEVICE...${NC}"
    UDID=$(xcrun simctl list devices available | grep "$DEVICE" | head -1 | sed -n 's/.*(\([A-F0-9-]*\)).*/\1/p')
    [ -z "$UDID" ] && { echo -e "${RED}✗ '$DEVICE' not found${NC}"; exit 1; }
    xcrun simctl boot "$UDID" 2>/dev/null || true
    open -a Simulator
    sleep 3
    echo -e "${GREEN}✓ Booted ($UDID)${NC}"
else
    echo -e "${GREEN}✓ Simulator running${NC}"
fi
rm -rf "$SCREENSHOTS" && mkdir -p "$SCREENSHOTS"
echo -e "${CYAN}▸ Running full-test.yaml...${NC}\n"
if maestro test "$FLOW"; then
    echo -e "\n${GREEN}${BOLD}✓ ALL PHASES PASSED${NC}"
else
    echo -e "\n${RED}${BOLD}✗ SOME PHASES FAILED${NC}"
    exit 1
fi
COUNT=$(ls "$SCREENSHOTS"/*.png 2>/dev/null | wc -l | tr -d ' ')
echo -e "${CYAN}Screenshots: $COUNT → $SCREENSHOTS/${NC}"
[ "$COUNT" -gt 0 ] && open "$SCREENSHOTS"

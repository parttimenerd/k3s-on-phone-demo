#!/usr/bin/env bash
set -e

# Change to the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

LAUNCH_TERMINAL=false
OPEN_BROWSER=false
TERMINAL_PID=""

# Usage function
usage() {
  echo -e "${BLUE}Usage:${NC} $0 [OPTIONS]"
  echo ""
  echo -e "${BLUE}Options:${NC}"
  echo -e "  ${GREEN}--terminal${NC}    Enable interactive terminal server for running scripts from slides"
  echo -e "  ${GREEN}--open${NC}        Open browser automatically"
  echo -e "  ${GREEN}--help, -h${NC}    Show this help message"
  echo ""
  echo -e "${BLUE}Examples:${NC}"
  echo -e "  $0                  # Launch presentation only"
  echo -e "  $0 --open           # Launch and open browser"
  echo -e "  $0 --terminal       # Launch with terminal server (press 't' to open terminal)"
  echo -e "  $0 --terminal --open # Launch with terminal and open browser"
  echo ""
  exit 0
}

# Parse arguments
for arg in "$@"; do
  case $arg in
    --terminal)
      LAUNCH_TERMINAL=true
      shift
      ;;
    --open)
      OPEN_BROWSER=true
      shift
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo -e "${YELLOW}Unknown option: $arg${NC}"
      echo ""
      usage
      ;;
  esac
done

# Cleanup function
cleanup() {
  if [ -n "$TERMINAL_PID" ]; then
    echo -e "\n${YELLOW}Stopping terminal server...${NC}"
    kill $TERMINAL_PID 2>/dev/null || true
  fi
  exit 0
}

trap cleanup SIGINT SIGTERM EXIT

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}  K3s on Phone - Slidev Presentation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
  echo -e "${YELLOW}Installing presentation dependencies...${NC}"
  npm install
  echo ""
fi

# Launch terminal server if requested
if [ "$LAUNCH_TERMINAL" = true ]; then
  echo -e "${GREEN}🚀 Launching with terminal server${NC}"
  echo ""
  
  # Check and install terminal server dependencies
  if [ ! -d "terminal-server/node_modules" ]; then
    echo -e "${YELLOW}Installing terminal server dependencies...${NC}"
    cd terminal-server
    npm install
    cd ..
    echo ""
  fi
  
  # Start terminal server in background
  echo -e "${BLUE}Starting terminal server on http://127.0.0.1:3031${NC}"
  cd terminal-server
  node server.js &
  TERMINAL_PID=$!
  cd ..
  
  # Wait a moment for server to start
  sleep 1
  
  # Check if server started successfully
  if kill -0 $TERMINAL_PID 2>/dev/null; then
    echo -e "${GREEN}✓ Terminal server running (PID: $TERMINAL_PID)${NC}"
    echo ""
    echo -e "${GREEN}Terminal features enabled:${NC}"
    echo -e "  • Press ${YELLOW}'t'${NC} to open terminal"
    echo -e "  • Click ${YELLOW}'Run'${NC} buttons to execute scripts"
    echo ""
  else
    echo -e "${YELLOW}Warning: Terminal server failed to start${NC}"
    TERMINAL_PID=""
    echo ""
  fi
else
  echo -e "${BLUE}Launching presentation (without terminal)${NC}"
  echo -e "${YELLOW}Tip: Use ${NC}./launch.sh --terminal${YELLOW} to enable terminal features${NC}"
  echo ""
fi

# Launch Slidev
echo -e "${BLUE}Starting Slidev on http://localhost:3032${NC}"
echo ""
echo -e "${GREEN}Press Ctrl+C to stop${NC}"
echo ""

if [ "$OPEN_BROWSER" = true ]; then
  npm run dev
else
  npx slidev --port 3032
fi

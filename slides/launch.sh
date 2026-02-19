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
TERMINAL_HOSTS=""

# Usage function
usage() {
  echo -e "${BLUE}Usage:${NC} $0 [OPTIONS]"
  echo ""
  echo -e "${BLUE}Options:${NC}"
  echo -e "  ${GREEN}--terminal${NC}                    Enable interactive terminal server for running scripts from slides"
  echo -e "  ${GREEN}--terminal-host HOST[,HOST...]${NC}   Connect to remote terminal server(s) (e.g., phone-a or phone-a,phone-b)"
  echo -e "  ${GREEN}--open${NC}                        Open browser automatically"
  echo -e "  ${GREEN}--help, -h${NC}                    Show this help message"
  echo ""
  echo -e "${BLUE}Examples:${NC}"
  echo -e "  $0                              # Launch presentation only"
  echo -e "  $0 --open                       # Launch and open browser"
  echo -e "  $0 --terminal                   # Launch with local terminal server"
  echo -e "  $0 --terminal-host phone-a      # Connect to terminal server on phone-a"
  echo -e "  $0 --terminal-host phone-a,phone-b  # Connect to multiple terminal servers"
  echo -e "  $0 --terminal --open            # Launch with terminal and open browser"
  echo ""
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --terminal)
      LAUNCH_TERMINAL=true
      shift
      ;;
    --terminal-host)
      TERMINAL_HOSTS="$2"
      shift 2
      ;;
    --open)
      OPEN_BROWSER=true
      shift
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo -e "${YELLOW}Unknown option: $1${NC}"
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
  echo -e "${GREEN}🚀 Launching with local terminal server${NC}"
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
elif [ -n "$TERMINAL_HOSTS" ]; then
  echo -e "${GREEN}🌐 Connecting to remote terminal server(s)${NC}"
  
  # Convert comma-separated hosts to array
  IFS=',' read -ra HOST_ARRAY <<< "$TERMINAL_HOSTS"
  
  echo -e "${BLUE}Terminal servers:${NC}"
  for host in "${HOST_ARRAY[@]}"; do
    echo -e "  • http://${host}:3031"
  done
  echo ""
  echo -e "${GREEN}Terminal features enabled:${NC}"
  echo -e "  • Press ${YELLOW}'t'${NC} to open terminal"
  echo -e "  • Click ${YELLOW}'Run'${NC} buttons to execute scripts"
  if [ ${#HOST_ARRAY[@]} -gt 1 ]; then
    echo -e "  • ${YELLOW}Note:${NC} Multiple hosts available - use selector in terminal"
  fi
  echo -e "  • ${YELLOW}Note:${NC} Terminal servers must be running on specified hosts"
  echo ""
else
  echo -e "${BLUE}Launching presentation (without terminal)${NC}"
  echo -e "${YELLOW}Tip: Use ${NC}./launch.sh --terminal${YELLOW} or ${NC}--terminal-host HOST${YELLOW} to enable terminal features${NC}"
  echo ""
fi

# Launch Slidev
echo -e "${BLUE}Starting Slidev on http://localhost:3032${NC}"
echo ""
echo -e "${GREEN}Press Ctrl+C to stop${NC}"
echo ""
# Set terminal host for frontend
if [ -n "$TERMINAL_HOSTS" ]; then
  # Pass comma-separated hosts to frontend
  export VITE_TERMINAL_HOSTS="$TERMINAL_HOSTS"
  
  # Set default WS URL (first host)
  IFS=',' read -ra HOST_ARRAY <<< "$TERMINAL_HOSTS"
  export VITE_TERMINAL_WS_URL="ws://${HOST_ARRAY[0]}:3031"
elif [ "$LAUNCH_TERMINAL" = true ]; then
  export VITE_TERMINAL_WS_URL="ws://127.0.0.1:3031"
  export VITE_TERMINAL_HOSTS="127.0.0.1"
fi
if [ "$OPEN_BROWSER" = true ]; then
  npm run dev
else
  npx slidev --port 3032
fi

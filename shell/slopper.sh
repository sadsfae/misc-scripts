#!/bin/bash
# start or stop LLM services
# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to check status of services
status() {
  echo -e "${YELLOW}Checking status of AI services...${NC}"
  if systemctl --user is-active --quiet llama-server; then
    echo -e "llama-server: ${GREEN}Running${NC}"
  else
    echo -e "llama-server: ${RED}Stopped${NC}"
  fi
  if podman ps -a --filter "name=open-webui" | grep -q "Up"; then
    echo -e "open-webui: ${GREEN}Running${NC}"
  else
    echo -e "open-webui: ${RED}Stopped${NC}"
  fi
  if systemctl --user is-active --quiet forge-server.service; then
    echo -e "forge-server.service: ${GREEN}Running${NC}"
  else
    echo -e "forge-server.service: ${RED}Stopped${NC}"
  fi
  if systemctl --user is-active --quiet comfy; then
    echo -e "comfy: ${GREEN}Running${NC}"
  else
    echo -e "comfy: ${RED}Stopped${NC}"
  fi
  if ss -lnt '( sport = :http )' | grep -q ':80'; then
    echo -e "nginx: ${GREEN}Running${NC}"
  else
    echo -e "nginx: ${RED}Stopped${NC}"
  fi
}

# Function to stop AI services
slopstop() {
  echo -e "${RED}Stopping AI services...${NC}"
  systemctl --user stop llama-server
  podman stop open-webui >/dev/null
  systemctl --user stop forge-server.service
  systemctl --user stop comfy
  sudo systemctl stop nginx
  echo -e "${GREEN}AI services stopped.${NC}"
}

# Function to start AI services
slopstart() {
  echo -e "${RED}Starting AI services...${NC}"
  systemctl --user start llama-server
  sleep 10
  podman start open-webui >/dev/null
  systemctl --user start forge-server.service
  systemctl --user start comfy
  sudo systemctl start nginx
  echo -e "${GREEN}AI services started.${NC}"
}

# Check if the first argument is "stop", "start", or "status"
case "$1" in
stop)
  slopstop
  ;;
start)
  slopstart
  ;;
status)
  status
  ;;
*)
  echo "Usage: $0 {start|stop|status}"
  exit 1
  ;;
esac

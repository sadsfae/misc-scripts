"""Simple tool for start/stop/status of LLM"""

import subprocess
import sys
import time

# Define colors
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[0;33m"
NC = "\033[0m"  # No Color


def check_status():
    print(f"{YELLOW}Checking status of AI services...{NC}")
    services = [
        ("llama-server", "systemctl --user is-active --quiet llama-server"),
        ("open-webui", "podman ps -a --filter 'name=open-webui' | grep -q 'Up'"),
        (
            "forge-server.service",
            "systemctl --user is-active --quiet forge-server.service",
        ),
        ("comfy", "systemctl --user is-active --quiet comfy"),
        ("nginx", "ss -lnt '( sport = :http )' | grep -q ':80'"),
    ]
    for service_name, check_command in services:
        if subprocess.run(check_command, shell=True).returncode == 0:
            print(f"{service_name}: {GREEN}Running{NC}")
        else:
            print(f"{service_name}: {RED}Stopped{NC}")


def slopstop():
    print(f"{RED}Stopping AI services...{NC}")
    subprocess.run(["systemctl", "--user", "stop", "llama-server"])
    subprocess.run(
        ["podman", "stop", "open-webui"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    subprocess.run(["systemctl", "--user", "stop", "forge-server.service"])
    subprocess.run(["systemctl", "--user", "stop", "comfy"])
    subprocess.run(["sudo", "systemctl", "stop", "nginx"])
    print(f"{GREEN}AI services stopped.{NC}")


def slopstart():
    print(f"{RED}Starting AI services...{NC}")
    subprocess.run(["systemctl", "--user", "start", "llama-server"])
    time.sleep(10)
    subprocess.run(
        ["podman", "start", "open-webui"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    subprocess.run(["systemctl", "--user", "start", "forge-server.service"])
    subprocess.run(["systemctl", "--user", "start", "comfy"])
    subprocess.run(["sudo", "systemctl", "start", "nginx"])
    print(f"{GREEN}AI services started.{NC}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} {{start|stop|status}}")
        sys.exit(1)
    action = sys.argv[1]
    if action == "status":
        check_status()
    elif action == "stop":
        slopstop()
    elif action == "start":
        slopstart()
    else:
        print(f"Invalid action: {action}")
        sys.exit(1)

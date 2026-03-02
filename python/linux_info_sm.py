import os
import platform
import socket
import psutil
from datetime import datetime
from termcolor import colored


def get_color(name, color):
    return colored(f"{name}:", color)


def main():
    print("\n" + "=" * 50)
    print(get_color("🐧 System Info", "green"))
    print("=" * 50 + "\n")

    # 1. OS & Host
    print(get_color("OS", "cyan"))
    print(f"{platform.system()} {platform.version()}")
    print(f"Arch: {platform.machine()} | Host: {socket.gethostname()}")

    # 2. Kernel & Uptime
    boot_ts = psutil.boot_time()
    now = datetime.now()
    uptime = now - datetime.fromtimestamp(boot_ts)

    print(get_color("Kernel", "cyan"))
    print(f"Ver: {platform.release()}")
    print(f"Up: {uptime.days}d {uptime.seconds//3600}h {uptime.seconds%3600//60}m")

    # 3. CPU
    cpu = psutil.cpu_percent(interval=0.1)
    freq = psutil.cpu_freq()
    cores = psutil.cpu_count(logical=True)

    print(get_color("CPU", "cyan"))
    print(f"Usage: {cpu:.0f}% | Cores: {cores}")
    print(f"Freq: {freq.current:.0f}MHz" if freq else "Freq: N/A")

    # 4. Memory
    mem = psutil.virtual_memory()
    total_g = mem.total / 1024**3
    used_g = mem.used / 1024**3
    pct = mem.percent

    print(get_color("RAM", "cyan"))
    print(f"Total: {total_g:.1f}GB | Used: {used_g:.1f}GB ({pct:.0f}%)")

    # 5. Disk (Root)
    disk = psutil.disk_usage("/")
    total_g = disk.total / 1024**3
    used_g = disk.used / 1024**3
    pct = disk.percent

    print(get_color("Disk", "cyan"))
    print(f"Total: {total_g:.1f}GB | Used: {used_g:.1f}GB ({pct:.0f}%)")

    # 6. Network
    print(get_color("Net", "cyan"))
    for iface in psutil.net_if_addrs().keys():
        if not iface.startswith(("lo", "docker", "br-")):
            print(f"- {iface}")
    print("-" * 50)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(colored(f"Error: {e}", "red"))

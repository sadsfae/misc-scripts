import os
import platform
import socket
import psutil
from datetime import datetime, timedelta
from termcolor import colored


def get_color(name, color):
    """Helper to wrap text with color."""
    return colored(f" {name}:", color)


def print_header():
    print("\n" + "=" * 50)
    print(get_color("🐧 Linux System Information Report", "green"))
    print("=" * 50 + "\n")


def print_section(title, content, color="cyan"):
    print(get_color(title, color))
    print("-" * 50)
    print(f"{content}\n")


def main():
    print_header()

    # 1. OS & Hostname
    os_name = platform.system()
    os_version = platform.version()
    arch = platform.machine()
    hostname = socket.gethostname()

    print_section(
        "System Overview",
        f"OS: {os_name} {os_version}\n"
        f"Architecture: {arch}\n"
        f"Hostname: {hostname}",
    )

    # 2. Kernel & Uptime
    kernel_version = platform.release()
    boot_time = datetime.fromtimestamp(psutil.boot_time())
    uptime_seconds = psutil.boot_time()
    current_time = datetime.now()  # Calculate current time here to avoid scope issues
    uptime = current_time - boot_time
    uptime_str = f"{uptime.days} days, {uptime.seconds // 3600} hours, {uptime.seconds % 3600 // 60} minutes"

    print_section(
        "Kernel & Uptime",
        f"Kernel Version: {kernel_version}\n"
        f"System Boot Time: {boot_time.strftime('%Y-%m-%d %H:%M:%S')}\n"
        f"Uptime: {uptime_str}",
    )

    # 3. CPU Info
    cpu_count = psutil.cpu_count(logical=True)
    cpu_freq = psutil.cpu_freq()
    cpu_percent = psutil.cpu_percent(interval=0.1)
    cpu_freq_str = f"{cpu_freq.current:.2f} GHz" if cpu_freq else "N/A"

    print_section(
        "CPU Information",
        f"Cores (Logical): {cpu_count}\n"
        f"Current Usage: {cpu_percent:.1f}%\n"
        f"Frequency: {cpu_freq_str}",
    )

    # 4. Memory Usage
    mem = psutil.virtual_memory()
    mem_total_gb = mem.total / (1024**3)
    mem_used_gb = mem.used / (1024**3)
    mem_free_gb = mem.free / (1024**3)
    mem_percent = mem.percent

    print_section(
        "Memory (RAM)",
        f"Total: {mem_total_gb:.2f} GB\n"
        f"Used: {mem_used_gb:.2f} GB ({mem.percent:.1f}%)\n"
        f"Free: {mem_free_gb:.2f} GB",
    )

    # 5. Disk Usage (Root Partition)
    disk = psutil.disk_usage("/")
    disk_total_gb = disk.total / (1024**3)
    disk_used_gb = disk.used / (1024**3)
    disk_free_gb = disk.free / (1024**3)
    disk_percent = disk.percent

    print_section(
        "Disk Usage (Root /)",
        f"Total: {disk_total_gb:.2f} GB\n"
        f"Used: {disk_used_gb:.2f} GB ({disk.percent:.1f}%)\n"
        f"Free: {disk_free_gb:.2f} GB",
    )

    # 6. Network Interfaces
    print_section("Network Interfaces", "Active Interfaces:")
    for iface, addrs in psutil.net_if_addrs().items():
        if not iface.startswith(("lo", "docker", "br-")):
            print(f"  - {iface}")
    print("-" * 50)

    print(get_color("✅ Report generated successfully!", "green"))
    print("=" * 50)


if __name__ == "__main__":
    try:
        main()
    except PermissionError:
        print(
            colored(
                "Error: Requires root/sudo privileges for some system stats.", "red"
            )
        )
    except Exception as e:
        print(colored(f"An unexpected error occurred: {e}", "red"))

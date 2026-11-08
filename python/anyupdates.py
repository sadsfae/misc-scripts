#!/usr/bin/env python3
"""anyupdates: report pending Omarchy, AUR, and Arch updates. Read-only."""

import os
import re
import subprocess
import sys
from datetime import datetime

# `sudo anyupdates` resets PATH/HOME and would run yay as root; re-run as the
# invoking user so yay/checkupdates and user site-packages behave normally.
if os.geteuid() == 0 and os.environ.get("SUDO_USER"):
    os.execv(
        "/usr/bin/sudo",
        [
            "/usr/bin/sudo",
            "-u",
            os.environ["SUDO_USER"],
            "-H",
            sys.executable,
            os.path.realpath(__file__),
        ],
    )

from rich import box
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

console = Console()
UPDATES_RE = re.compile(r"^(\S+)\s+(\S+)\s+->\s+(\S+)")
OMARCHY_PKGS = ("omarchy", "omarchy-dev")


def run(cmd, ok_codes):
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        return [], f"{type(exc).__name__}: {exc}"
    if proc.returncode not in ok_codes:
        return [], proc.stderr.strip() or f"exit code {proc.returncode}"
    if "error" in proc.stderr.lower():
        return [], proc.stderr.strip()
    return proc.stdout.splitlines(), None


def fetch(cmd, ok_codes):
    lines, err = run(cmd, ok_codes)
    rows = []
    for line in lines:
        match = UPDATES_RE.match(line.strip())
        if match:
            rows.append(match.groups())
    return rows, err


def source_table(title, style, rows):
    table = Table(
        title=title,
        title_style=style,
        box=box.ROUNDED,
        header_style="bold",
        show_edge=False,
    )
    table.add_column("Package", style="bold")
    table.add_column("Current", justify="right", style="dim")
    table.add_column("New", justify="right")
    for pkg, current, new in rows:
        table.add_row(pkg, current, new)
    return table


def main():
    arch, err_arch = fetch(["checkupdates", "--nocolor"], ok_codes=(0, 2))
    aur, err_aur = fetch(["yay", "-Qua", "--color", "never"], ok_codes=(0, 1))

    omarchy = sorted(row for row in arch if row[0] in OMARCHY_PKGS)
    arch = sorted(row for row in arch if row[0] not in OMARCHY_PKGS)
    total = len(arch) + len(aur) + len(omarchy)
    errors = [e for e in (err_arch, err_aur) if e]
    now = datetime.now().strftime("%Y-%m-%d %H:%M")

    if not total and not errors:
        console.print(
            Panel(
                "\n".join(
                    [
                        "[green]\u2713[/green] Arch repos: up to date",
                        "[green]\u2713[/green] AUR: up to date",
                        "[green]\u2713[/green] Omarchy: up to date",
                    ]
                ),
                title=f"[bold]Update check[/bold] [dim]· {now}[/dim]",
                border_style="green",
            )
        )
        return

    console.print(f"[bold]Update check[/bold] [dim]· {now}[/dim]")

    if arch:
        console.print(source_table("Arch", "bold cyan", arch))
    if aur:
        console.print(source_table("AUR", "bold magenta", aur))
    if omarchy:
        console.print(source_table("Omarchy", "bold green", omarchy))

    for err in errors:
        console.print(f"[yellow]![/yellow] {err}")

    if total:
        parts = []
        for name, count, style in (
            ("Arch", len(arch), "cyan"),
            ("AUR", len(aur), "magenta"),
            ("Omarchy", len(omarchy), "green"),
        ):
            if count:
                parts.append(f"[bold {style}]{count} {name}[/bold {style}]")
        console.print(
            "\n[bold]"
            f"{total} pending update{'s' if total != 1 else ''}:[/bold] "
            + " · ".join(parts)
        )
        console.print(
            "[dim]Read-only check · run [bold]omarchy update[/bold] to install[/dim]"
        )
    else:
        console.print("[yellow]Could not determine update status.[/yellow]")


if __name__ == "__main__":
    main()

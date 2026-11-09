#!/usr/bin/env python3
"""plugin-update: update git-managed Omarchy shell plugins, preserving local changes."""

import os
import shutil
import subprocess
import sys
from pathlib import Path

from rich import box
from rich.console import Console
from rich.table import Table

console = Console()
PLUGINS_DIR = Path(os.environ.get("OMARCHY_PLUGINS_DIR", "~/.config/omarchy/plugins")).expanduser()
GIT_ENV = {
    **os.environ,
    "GIT_TERMINAL_PROMPT": "0",
    "GIT_SSH_COMMAND": os.environ.get("GIT_SSH_COMMAND", "ssh -oBatchMode=yes"),
}
STATUS_STYLE = {
    "ok": "[dim]up to date[/dim]",
    "updated": "[green]updated[/green]",
    "error": "[red]error[/red]",
    "blocked": "[yellow]blocked[/yellow]",
    "conflict": "[yellow]conflict[/yellow]",
    "skip": "[yellow]skipped[/yellow]",
}


def git(path, *args):
    try:
        proc = subprocess.run(
            ["git", "-C", str(path), *args],
            capture_output=True,
            text=True,
            timeout=600,
            env=GIT_ENV,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        return [], f"{type(exc).__name__}: {exc}"
    if proc.returncode != 0:
        return [], proc.stderr.strip() or f"exit code {proc.returncode}"
    return proc.stdout.splitlines(), None


def tool(cmd):
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        return f"{type(exc).__name__}: {exc}"
    if proc.returncode != 0:
        return proc.stderr.strip() or f"exit code {proc.returncode}"
    return None


def pop_stash(path, pid):
    _, err = git(path, "stash", "pop")
    if err:
        return (
            f"local changes kept in stash (resolve conflicts in {path}, "
            f"then: git -C {path} stash drop)"
        )
    return None


def update_plugin(path, pid):
    _, err = git(path, "fetch", "--quiet", "origin", "HEAD")
    if err:
        return "error", f"fetch failed: {err.splitlines()[0]}"

    head, err = git(path, "rev-parse", "HEAD")
    if err:
        return "error", f"rev-parse HEAD failed: {err.splitlines()[0]}"
    fetched, err = git(path, "rev-parse", "FETCH_HEAD")
    if err:
        return "error", f"rev-parse FETCH_HEAD failed: {err.splitlines()[0]}"
    if head[0] == fetched[0]:
        return "ok", "up to date"

    new_commits, _ = git(path, "rev-list", "--count", "HEAD..FETCH_HEAD")
    stat_lines, _ = git(path, "diff", "--stat", "HEAD", "FETCH_HEAD")
    stat = stat_lines[-1].strip() if stat_lines else ""
    detail = f"{new_commits[0] if new_commits else '?'} new commit(s)"
    if stat:
        detail += f" · {stat}"

    status, err = git(path, "status", "--porcelain", "--untracked-files=normal")
    if err:
        return "error", f"status failed: {err.splitlines()[0]}"

    stashed = False
    if status:
        _, err = git(path, "stash", "push", "--include-untracked", "-m", f"plugin-update: {pid}")
        if err:
            return "error", f"could not stash local changes: {err.splitlines()[0]}"
        stashed = True

    ff, _ = git(path, "merge-base", "--is-ancestor", "HEAD", "FETCH_HEAD")
    ahead_only, _ = git(path, "merge-base", "--is-ancestor", "FETCH_HEAD", "HEAD")

    if ahead_only:
        # Nothing new upstream (local commits on top or history rewound); keep local work.
        problem = pop_stash(path, pid) if stashed else None
        return "skip", "locally ahead, nothing new upstream" + (f"; {problem}" if problem else "")

    if ff:
        _, err = git(path, "merge", "--ff-only", "FETCH_HEAD")
    else:
        _, err = git(path, "rebase", "FETCH_HEAD")
    if err:
        if not ff:
            git(path, "rebase", "--abort")
        problem = pop_stash(path, pid) if stashed else None
        return (
            "blocked",
            "local changes diverge from upstream, not updated"
            + (f"; {problem}" if problem else f": {err.splitlines()[0]}"),
        )

    validator = shutil.which("omarchy-plugin-validate")
    if validator:
        verr = tool([validator, str(path)])
        if verr:
            git(path, "reset", "--hard", head[0])
            problem = pop_stash(path, pid) if stashed else None
            return "error", "update failed validation, rolled back" + (f"; {problem}" if problem else "")

    if stashed:
        problem = pop_stash(path, pid)
        if problem:
            return "conflict", f"{detail} · {problem}"
        detail += " · local changes kept"
    return "updated", detail


def main():
    if not PLUGINS_DIR.is_dir():
        console.print(f"[yellow]No plugins directory:[/yellow] {PLUGINS_DIR}")
        sys.exit(1)

    plugins = sorted(
        path for path in PLUGINS_DIR.iterdir() if path.is_dir() and (path / ".git").is_dir()
    )
    if not plugins:
        console.print("[dim]No git-managed plugins installed.[/dim]")
        return
    if not shutil.which("omarchy-plugin-validate"):
        console.print("[yellow]![/yellow] omarchy-plugin-validate not found; skipping validation")

    table = Table(box=box.ROUNDED, header_style="bold", show_edge=False)
    table.add_column("Plugin", style="bold")
    table.add_column("Result")
    table.add_column("Detail", style="dim")

    updated = failed = 0
    for plugin in plugins:
        status, detail = update_plugin(plugin, plugin.name)
        if status == "updated":
            updated += 1
        elif status in ("error", "blocked", "conflict"):
            failed += 1
        table.add_row(plugin.name, STATUS_STYLE[status], detail)

    console.print(table)
    console.print(
        f"[bold]{updated} updated[/bold], {len(plugins) - updated - failed} up to date"
    )

    if updated:
        rescan = shutil.which("omarchy-shell")
        if rescan and "OMARCHY_PLUGINS_DIR" not in os.environ:
            err = tool([rescan, "shell", "rescanPlugins"])
            if err:
                console.print(f"[yellow]![/yellow] shell rescan failed: {err}")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()

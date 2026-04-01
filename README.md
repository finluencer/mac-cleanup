# 🧹 Mac Disk Cleanup

An interactive CLI tool to safely free up disk space on macOS — no install required.

## Run instantly

```bash
curl -fsSL https://raw.githubusercontent.com/finluencer/mac-cleanup/refs/heads/main/mac_cleanup.sh | bash
```

## What it cleans

| Step | Target | Typical Size |
|------|--------|-------------|
| 1 | Time Machine local snapshots | 10–50GB |
| 2 | Trash | varies |
| 3 | User caches (`~/Library/Caches`) | 1–35GB |
| 4 | System & user logs | 0.5–2GB |
| 5 | Xcode derived data | 1–10GB |
| 6 | iOS device backups | 1–20GB |
| 7 | Downloads folder | varies |
| 8 | Homebrew cache | 0.5–5GB |

## Features

- Asks permission before every action — nothing runs without your confirmation
- Shows folder size before each step so you know what you're deleting
- Displays disk usage progress bar before and after cleanup
- Summary of total space freed at the end
- Safe to re-run anytime

## Requirements

- macOS 11 or later
- Bash (pre-installed on all Macs)
- Optional: Xcode (for step 5), Homebrew (for step 8)

## Manual install

```bash
curl -o mac_cleanup.sh https://raw.githubusercontent.com/finluencer/mac-cleanup/refs/heads/main/mac_cleanup.sh
chmod +x mac_cleanup.sh
./mac_cleanup.sh
```

## License

MIT

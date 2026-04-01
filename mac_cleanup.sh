#!/bin/bash

# mac_cleanup.sh — Interactive Mac Disk Cleanup Tool
# Repo:    https://github.com/YOUR_USERNAME/mac-cleanup
# Run:     curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/mac-cleanup/main/mac_cleanup.sh | bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

TOTAL_FREED=0

print_header() {
  clear
  echo -e "${BOLD}${BLUE}"
  echo "  ╔════════════════════════════════════╗"
  echo "  ║     Mac Disk Cleanup Assistant     ║"
  echo "  ╚════════════════════════════════════╝"
  echo -e "${RESET}"
}

disk_free() {
  df -H / | awk 'NR==2 {print $4}' | tr -d '\n'
}

disk_used_pct() {
  df / | awk 'NR==2 {print $5}' | tr -d '%\n'
}

progress_bar() {
  local pct=$1
  local filled=$(( pct / 5 ))
  local empty=$(( 20 - filled ))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  if [ "$pct" -ge 90 ]; then
    echo -e "${RED}  [${bar}] ${pct}%${RESET}"
  elif [ "$pct" -ge 75 ]; then
    echo -e "${YELLOW}  [${bar}] ${pct}%${RESET}"
  else
    echo -e "${GREEN}  [${bar}] ${pct}%${RESET}"
  fi
}

show_disk_status() {
  local free=$(disk_free)
  local pct=$(disk_used_pct)
  echo -e "${BOLD}  Disk usage:${RESET}"
  progress_bar "$pct"
  echo -e "  Free space: ${CYAN}${free}${RESET}\n"
}

ask() {
  echo -ne "${YELLOW}  → $1 [y/N]: ${RESET}"
  read -r ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

section() {
  echo -e "\n${BOLD}${CYAN}▶ $1${RESET}"
  echo -e "  ${BLUE}$2${RESET}\n"
}

success() { echo -e "  ${GREEN}✓ $1${RESET}"; }
info()    { echo -e "  ${BLUE}ℹ $1${RESET}"; }
warn()    { echo -e "  ${YELLOW}⚠ $1${RESET}"; }
err()     { echo -e "  ${RED}✗ $1${RESET}"; }

bytes_to_mb() {
  echo $(( $1 / 1024 / 1024 ))
}

folder_size_mb() {
  local path="$1"
  if [ -d "$path" ]; then
    du -sm "$path" 2>/dev/null | awk '{print $1}'
  else
    echo 0
  fi
}

step_timemachine() {
  section "Step 1: Time Machine Snapshots" "Local snapshots can silently consume 10–50GB+"
  info "Scanning for local snapshots..."
  local snaps
  snaps=$(tmutil listlocalsnapshots / 2>/dev/null)
  if [ -z "$snaps" ]; then
    info "No local snapshots found."
    return
  fi
  echo -e "  Found snapshots:\n"
  echo "$snaps" | while read -r line; do echo "    • $line"; done
  echo ""
  if ask "Delete all local Time Machine snapshots?"; then
    sudo tmutil deletelocalsnapshots / 2>/dev/null
    success "Snapshots deleted."
  else
    info "Skipped."
  fi
}

step_trash() {
  section "Step 2: Empty Trash" "Files in Trash still consume disk space until emptied."
  local trash=~/.Trash
  local size
  size=$(folder_size_mb "$trash")
  if [ "$size" -eq 0 ]; then
    info "Trash is already empty."
    return
  fi
  info "Trash contains ~${size}MB"
  if ask "Empty Trash now?"; then
    rm -rf ~/.Trash/* 2>/dev/null
    success "Trash emptied (~${size}MB freed)"
    TOTAL_FREED=$(( TOTAL_FREED + size ))
  else
    info "Skipped."
  fi
}

step_caches() {
  section "Step 3: User Caches" "App caches build up over time and are safe to delete."
  local cache_dir=~/Library/Caches
  local size
  size=$(folder_size_mb "$cache_dir")
  info "Cache folder size: ~${size}MB"
  if ask "Clear user caches? (Apps will rebuild them automatically)"; then
    find "$cache_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null
    success "User caches cleared (~${size}MB freed)"
    TOTAL_FREED=$(( TOTAL_FREED + size ))
  else
    info "Skipped."
  fi
}

step_logs() {
  section "Step 4: System & User Logs" "Old log files accumulate but are rarely needed."
  local log_dirs=(~/Library/Logs /var/log)
  local total=0
  for d in "${log_dirs[@]}"; do
    local s
    s=$(folder_size_mb "$d")
    total=$(( total + s ))
    info "$d: ~${s}MB"
  done
  if ask "Delete old log files?"; then
    rm -rf ~/Library/Logs/* 2>/dev/null
    sudo rm -rf /var/log/*.gz /var/log/*.old 2>/dev/null
    success "Logs cleared (~${total}MB freed)"
    TOTAL_FREED=$(( TOTAL_FREED + total ))
  else
    info "Skipped."
  fi
}

step_xcode() {
  section "Step 5: Xcode Derived Data" "Safe to delete — Xcode rebuilds this automatically."
  local xcode_dir=~/Library/Developer/Xcode/DerivedData
  if [ ! -d "$xcode_dir" ]; then
    info "Xcode not installed or no derived data found."
    return
  fi
  local size
  size=$(folder_size_mb "$xcode_dir")
  info "Derived data size: ~${size}MB"
  if ask "Delete Xcode derived data?"; then
    rm -rf "$xcode_dir"/* 2>/dev/null
    success "Xcode derived data cleared (~${size}MB freed)"
    TOTAL_FREED=$(( TOTAL_FREED + size ))
  else
    info "Skipped."
  fi
}

step_ios_backups() {
  section "Step 6: iOS Device Backups" "Old iPhone/iPad backups can take several GB each."
  local backup_dir=~/Library/Application\ Support/MobileSync/Backup
  if [ ! -d "$backup_dir" ]; then
    info "No iOS backups found."
    return
  fi
  local size
  size=$(folder_size_mb "$backup_dir")
  info "iOS backups total: ~${size}MB"
  warn "Review backups manually before deleting."
  info "Open: Finder → your Mac in sidebar → Manage Backups"
  if ask "Open Finder to manage backups now?"; then
    open "$backup_dir"
    info "Opened backup folder. Delete old backups manually."
  else
    info "Skipped."
  fi
}

step_downloads() {
  section "Step 7: Downloads Folder" "Old downloads are often forgotten but take up significant space."
  local size
  size=$(folder_size_mb ~/Downloads)
  info "Downloads folder size: ~${size}MB"
  if ask "Open Downloads folder to review?"; then
    open ~/Downloads
    info "Review and delete files you no longer need."
  else
    info "Skipped."
  fi
}

step_brew() {
  section "Step 8: Homebrew Cache" "Old package downloads cached by Homebrew."
  if ! command -v brew &>/dev/null; then
    info "Homebrew not installed. Skipping."
    return
  fi
  local size
  size=$(folder_size_mb "$(brew --cache)")
  info "Homebrew cache: ~${size}MB"
  if ask "Run 'brew cleanup'?"; then
    brew cleanup --prune=all 2>/dev/null
    success "Homebrew cache cleaned (~${size}MB freed)"
    TOTAL_FREED=$(( TOTAL_FREED + size ))
  else
    info "Skipped."
  fi
}

summary() {
  echo ""
  echo -e "${BOLD}${GREEN}  ══════════════════════════════════════${RESET}"
  echo -e "${BOLD}${GREEN}  Cleanup complete!${RESET}"
  echo -e "${BOLD}${GREEN}  ══════════════════════════════════════${RESET}"
  echo -e "  Estimated space freed: ${CYAN}${BOLD}~${TOTAL_FREED}MB${RESET}"
  echo ""
  show_disk_status
  echo -e "  ${YELLOW}Tip: For deeper cleanup, try OmniDiskSweeper (free)${RESET}"
  echo -e "  ${BLUE}     https://www.omnigroup.com/more${RESET}\n"
}

main() {
  print_header
  show_disk_status
  echo -e "  This tool will walk you through safe cleanup steps.\n"
  echo -ne "  ${BOLD}Press Enter to start...${RESET}"
  read -r

  step_timemachine
  step_trash
  step_caches
  step_logs
  step_xcode
  step_ios_backups
  step_downloads
  step_brew

  summary
}

main

#!/bin/bash

# Create log file
LOG_PATH="/var/log/jumpcloud_patch_log.txt"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

log_message() {
    echo "$TIMESTAMP - $1" | tee -a "$LOG_PATH"
}

log_message "=== Starting macOS Patch Management ==="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_message "ERROR: This script must be run as root"
    exit 1
fi

# Check for available updates
log_message "Checking for available updates..."

# Use softwareupdate to list all available updates
AVAILABLE_UPDATES=$(softwareupdate -l 2>&1)

# Check if there are any updates
if echo "$AVAILABLE_UPDATES" | grep -q "No new software available"; then
    log_message "No updates available"
    exit 0
fi

log_message "Updates found. Parsing update list..."

# Get list of all recommended updates
UPDATE_LIST=$(softwareupdate -l | grep -E "^\*|^   \*" | grep "recommended" | sed 's/^[[:space:]]*\*[[:space:]]*//' | sed 's/-[[:space:]].*$//')

if [ -z "$UPDATE_LIST" ]; then
    log_message "No recommended updates found"
    exit 0
fi

# Separate software updates from OS updates
SOFTWARE_UPDATES=()
OS_UPDATES=()

while IFS= read -r update; do
    # Check if it's an OS update (macOS, Security Update, or major system updates)
    if echo "$update" | grep -qiE "macOS|Security Update.*macOS|Command Line Tools"; then
        OS_UPDATES+=("$update")
    else
        SOFTWARE_UPDATES+=("$update")
    fi
done <<< "$UPDATE_LIST"

log_message "Found ${#SOFTWARE_UPDATES[@]} software update(s)"
log_message "Found ${#OS_UPDATES[@]} OS update(s)"

# Install Software Updates First
if [ ${#SOFTWARE_UPDATES[@]} -gt 0 ]; then
    log_message "=== Installing Software Updates ==="
    
    for update in "${SOFTWARE_UPDATES[@]}"; do
        log_message "Installing: $update"
        softwareupdate -i "$update" --no-scan 2>&1 | tee -a "$LOG_PATH"
        
        if [ $? -eq 0 ]; then
            log_message "Successfully installed: $update"
        else
            log_message "ERROR: Failed to install: $update"
        fi
    done
    
    log_message "Software updates installation completed"
fi

# Install OS Updates
if [ ${#OS_UPDATES[@]} -gt 0 ]; then
    log_message "=== Installing OS Updates ==="
    
    for update in "${OS_UPDATES[@]}"; do
        log_message "Installing: $update"
        softwareupdate -i "$update" --no-scan 2>&1 | tee -a "$LOG_PATH"
        
        if [ $? -eq 0 ]; then
            log_message "Successfully installed: $update"
        else
            log_message "ERROR: Failed to install: $update"
        fi
    done
    
    log_message "OS updates installation completed"
fi

# Alternative: Install all recommended updates at once (uncomment if preferred)
# log_message "Installing all recommended updates..."
# softwareupdate -i -r 2>&1 | tee -a "$LOG_PATH"

# Check if restart is required
RESTART_REQUIRED=$(softwareupdate -l | grep -i "restart")

if [ -n "$RESTART_REQUIRED" ]; then
    log_message "REBOOT REQUIRED: System needs to be restarted to complete updates"
    # Uncomment the line below to auto-reboot after 1 minute
    # shutdown -r +1 "System will reboot in 1 minute to complete updates"
else
    log_message "No reboot required"
fi

log_message "=== Patch Management Completed ==="
exit 0

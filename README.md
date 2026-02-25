
# macOS Patch Management Script for JumpCloud

Automated, root-safe macOS patching for enterprise fleets managed via JumpCloud.  
This script discovers and installs recommended updates, applying software updates first, then OS-level updates (e.g., macOS / Security Updates / Command Line Tools), and logs everything to `/var/log/jumpcloud_patch_log.txt`. It also detects if a **reboot is required.

---
## Features

- Verifies **root** execution
- Enumerates available updates via `softwareupdate`
- Separates software updates from OS/security updates
- Installs in the **right order** (software → OS)
- Detailed logging to `/var/log/jumpcloud_patch_log.txt`
- Detects **restart requirement** (with optional auto-reboot hook)
- Designed for **JumpCloud** command deployment (also works standalone)

## Requirements

- macOS with the native `softwareupdate` utility (built-in on macOS)
- Root privileges** (required to install updates and write to `/var/log`)
- (Optional) JumpCloud for remote execution / scheduling

> Tested behavior is aligned with standard `softwareupdate` output formatting across recent macOS releases.

---

## Installation

Clone or copy the script into a directory on the target Mac(s):

```bash
# Example: place under /usr/local/sbin
sudo mkdir -p /usr/local/sbin
sudo cp jumpcloud_macos_patch.sh /usr/local/sbin/jumpcloud_macos_patch.sh
sudo chmod +x /usr/local/sbin/jumpcloud_macos_patch.sh
````

> Ensure the file has **LF** line endings and execute permissions.

***

## Usage

### Run locally (manual)

```bash
sudo /usr/local/sbin/jumpcloud_macos_patch.sh
```

### Run via JumpCloud Command

*   **Type:** macOS
*   **Run As:** Root
*   **Command:**
    ```bash
    /usr/local/sbin/jumpcloud_macos_patch.sh
    ```

> You can schedule this command in JumpCloud to run during maintenance windows.

***

## What the script does (high level)

1.  Creates/uses log file: `/var/log/jumpcloud_patch_log.txt`
2.  Checks **root**: exits with error if not root
3.  Lists available updates via `softwareupdate -l`
4.  Parses **recommended** updates
5.  Categorizes into:
    *   **Software updates** (e.g., Safari, minor components)
    *   **OS updates** (macOS, Security Update, Command Line Tools)
6.  Installs software updates first, then OS updates (each individually)
7.  Writes output to the log file and STDOUT
8.  Checks if **restart is required**; logs status (optional auto-reboot line provided but commented)

***

## Logging

*   **Path:** `/var/log/jumpcloud_patch_log.txt`
*   **Format:** `YYYY-MM-DD HH:MM:SS - <message>`
*   Logs both high-level steps and `softwareupdate` output per update

### Sample Log Excerpt

```text
2026-02-25 10:12:03 - === Starting macOS Patch Management ===
2026-02-25 10:12:03 - Checking for available updates...
2026-02-25 10:12:10 - Updates found. Parsing update list...
2026-02-25 10:12:10 - Found 2 software update(s)
2026-02-25 10:12:10 - Found 1 OS update(s)
2026-02-25 10:12:10 - === Installing Software Updates ===
2026-02-25 10:12:10 - Installing: Safari16.6.1VenturaAuto-16.6.1
Software Update Tool
Installing Safari16.6.1VenturaAuto-16.6.1
Done.
2026-02-25 10:13:02 - Successfully installed: Safari16.6.1VenturaAuto-16.6.1
2026-02-25 10:13:02 - Software updates installation completed
2026-02-25 10:13:02 - === Installing OS Updates ===
2026-02-25 10:13:02 - Installing: macOS Ventura 13.6.3-23G304
Software Update Tool
Installing macOS Ventura 13.6.3-23G304
Done.
2026-02-25 10:25:54 - Successfully installed: macOS Ventura 13.6.3-23G304
2026-02-25 10:25:54 - OS updates installation completed
2026-02-25 10:25:54 - REBOOT REQUIRED: System needs to be restarted to complete updates
2026-02-25 10:25:54 - === Patch Management Completed ===
```

***

## Example Console Output

```bash
$ sudo /usr/local/sbin/jumpcloud_macos_patch.sh
2026-02-25 10:12:03 - === Starting macOS Patch Management ===
2026-02-25 10:12:03 - Checking for available updates...
2026-02-25 10:12:10 - Updates found. Parsing update list...
2026-02-25 10:12:10 - Found 2 software update(s)
2026-02-25 10:12:10 - Found 1 OS update(s)
2026-02-25 10:12:10 - === Installing Software Updates ===
...
2026-02-25 10:25:54 - REBOOT REQUIRED: System needs to be restarted to complete updates
2026-02-25 10:25:54 - === Patch Management Completed ===
```

***

## Reboot Behavior

The script **detects** if a reboot is required and logs it.  
To enable an **automatic reboot after 1 minute**, uncomment:

```bash
# shutdown -r +1 "System will reboot in 1 minute to complete updates"
```

***

## Optional: Schedule with LaunchDaemon (local scheduling)

Create a LaunchDaemon to run nightly at 02:30:

```xml
<!-- /Library/LaunchDaemons/com.companyname.patch.macos.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.companyname.patch.macos</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/local/sbin/jumpcloud_macos_patch.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>2</integer>
    <key>Minute</key><integer>30</integer>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>/var/log/jumpcloud_patch_log.txt</string>
  <key>StandardErrorPath</key><string>/var/log/jumpcloud_patch_log.txt</string>
</dict>
</plist>
```

Load it:

```bash
sudo chown root:wheel /Library/LaunchDaemons/com.compantname.patch.macos.plist
sudo chmod 644 /Library/LaunchDaemons/com.company.patch.macos.plist
sudo launchctl load -w /Library/LaunchDaemons/com.company.patch.macos.plist
```

> In managed environments, prefer **JumpCloud Scheduled Commands** to centralize control and reporting.

***

## Script Options

This script is designed to run **without arguments** for predictable fleet behavior.  
If you want optional flags (e.g., `--all-recommended`, `--auto-reboot`), you can fork and extend argument parsing.

***

## Troubleshooting

*   **“This script must be run as root”**  
    Run with `sudo` or set the command to run as root in JumpCloud.

*   **No updates detected**  
    The script exits successfully if `softwareupdate` returns “No new software available”.

*   **Stuck / slow installs**  
    macOS updates can be large and time-consuming. Allow sufficient timeouts in remote tooling.

*   **Log file not written**  
    Confirm permissions on `/var/log/` and that the script is executed as root.

*   **Update name parsing edge cases**  
    The script targets **recommended** updates and uses conservative parsing to separate software vs. OS/security updates. If Apple changes output formatting, adjust the `grep/sed` filters accordingly.

***

## Security Considerations

*   Runs only as **root**; least-privilege isn’t possible for system updates
*   Writes logs to a root-owned path (`/var/log/`)
*   Does **not** alter update catalog or install non-recommended updates by default
*   Does not force reboot unless you explicitly enable it
  
***

## Contributing

PRs are welcome for:

*   Argument flags (e.g., `--auto-reboot`, `--install-all`)
*   Additional logging / JSON log export
*   Enhanced detection for specific macOS versions

Please open an issue to discuss major changes.

***

## License

MIT License

Copyright (c) 2026 John Patrick Lita

Permission is hereby granted, free of charge, to any person obtaining a copy
of this script and associated documentation files (the "Script"), to deal in
the Script without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or share
copies of the Script, and to permit persons to whom the Script is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Script.

THE SCRIPT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SCRIPT OR THE USE OR OTHER DEALINGS IN THE
SCRIPT.

***

### Tip

If you’re using this in production, consider pairing it with:

*   **JumpCloud Scheduled Commands or other solution that you can remove a device** with maintenance MacOS
*   A **dashboard** that tails `/var/log/jumpcloud_patch_log.txt` for quick compliance checks
*   A safe **post-patch reboot policy** aligned with user schedules

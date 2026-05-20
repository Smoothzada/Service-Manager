# System Check Tool

A PowerShell utility to inspect and restore Windows services required for competitive (ranked) gameplay.

---

## Overview

**System Check Tool** is an interactive command-line script that helps you verify the health of critical Windows services and registry settings, and quickly restore them to a running state when needed — especially useful before queuing into ranked matches.

---

## Requirements

- **Windows** operating system
- **PowerShell** 5.1 or later
- **Administrator privileges** (the script will refuse to run otherwise)

---

## How to Run

1. Right-click on `Service.ps1` and select **"Run with PowerShell"**, or open a PowerShell terminal as Administrator and run:

```powershell
.\Service.ps1
```

2. Or open CMD as Administrator and run:

```powershell
powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass && powershell Invoke-Expression (Invoke-RestMethod https://raw.githubusercontent.com/Smoothzada/Service-Manager/refs/heads/main/main/Service.ps1)
```

> The script must be run as **Administrator**. If it detects insufficient privileges, it will display a warning and exit.

---

## Menu Options

```
[1] General Check
[2] Start Services
[x] Close
```

### [1] General Check

Displays a full diagnostic report containing:

**Service Status Table**

Shows the current status, startup type, and uptime for the following services:

| Service     | Description                              |
| ----------- | ---------------------------------------- |
| `AppInfo`   | Application Information                  |
| `BAM`       | Background Activity Moderator            |
| `DPS`       | Diagnostic Policy Service                |
| `DiagTrack` | Connected User Experiences and Telemetry |
| `DusmSvc`   | Data Usage Subscription Manager          |
| `EventLog`  | Windows Event Log                        |
| `PcaSvc`    | Program Compatibility Assistant          |
| `PlugPlay`  | Plug and Play                            |
| `Schedule`  | Task Scheduler                           |
| `SysMain`   | Superfetch / SysMain                     |
| `WSearch`   | Windows Search                           |

---

**Registry Check**

Validates the following registry settings:

| Setting                | What is checked                                    |
| ---------------------- | -------------------------------------------------- |
| `CMD`                  | Whether Command Prompt is disabled via policy      |
| `PowerShell Logging`   | Whether Script Block Logging is enabled            |
| `Activities Cache`     | Whether the Activity Feed is enabled               |
| `Prefetch Enabled`     | Whether the Prefetcher is active                   |
| `SysMain (Superfetch)` | Whether SysMain is disabled in the registry        |
| `PcaSvc Key`           | Whether PcaSvc startup is disabled in the registry |

---

### [2] Start Services

Allows you to re-enable and start services in two modes:

- **All services** — Starts all 11 monitored services.
- **Necessary services only** — Starts only the core subset required for Ranked games:
  `AppInfo`, `BAM`, `DPS`, `DusmSvc`, `EventLog`, `PcaSvc`, `WSearch`, `SysMain`, `Schedule`, `PlugPlay`

For each service, the script will:

1. Set the startup type to **Automatic**
2. Start the service if it is not already running
3. Report the result per service (Started / Already running / Failed)

---

## Notes

- A **system restart** is recommended after starting services to ensure all changes take full effect.
- This tool does **not modify registry values**; it only reads them for diagnostic purposes.
- The tool was mainly designed for **Prime Ranked Bedwars**, and the necessary services follow the Prime RBW rules.

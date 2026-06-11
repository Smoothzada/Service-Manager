#admin 
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Clear-Host
    write-host @"

    +==================================================+
    |        ADMINISTRATOR PRIVILEGES REQUIRED         |
    |    Please run this script as Administrator!      |
    +==================================================+

"@ -foregroundcolor darkRed
    Read-Host "  Press ENTER to exit"
    exit
}



function MainMenu {
    Clear-Host
    write-host ""
    Write-Host "   +=================================================+" -ForegroundColor darkgreen
    Write-Host "   |          SYSTEM CHECK TOOL - by Smooth          |" -ForegroundColor green
    write-host "   | Check and start necessary services for rankeds! |" -ForegroundColor green
    Write-Host "   +=================================================+" -ForegroundColor darkgreen
    Write-Host ""
    Write-Host "     [1] " -foregroundcolor green -nonewline; Write-Host "General Check" -ForegroundColor white 
    Write-Host "     [2] " -foregroundcolor green -nonewline; Write-Host "Start Services" -ForegroundColor white
    Write-Host "     [x] " -foregroundcolor green -nonewline; Write-Host "Exit" -ForegroundColor white
    Write-Host ""
    $choice = Read-Host " Option"
    return $choice
}

function Show-GeneralCheck {
    Clear-Host
    write-host ""
    Write-Host "   +================================================+" -ForegroundColor darkgreen
    Write-Host "   |              GENERAL CHECK                     |" -ForegroundColor green
    Write-Host "   +================================================+" -ForegroundColor darkgreen
    write-host ""
    #services
    Write-Host "[*] Services" -ForegroundColor Cyan
    write-host ""

    $serviceNames = @("AppInfo", "BAM", "DPS", "DiagTrack", "DusmSvc", "EventLog", "PcaSvc", "PlugPlay", "Schedule", "SysMain", "WSearch")

    $col1 = 12
    $col2 = 14

    $header = ("  " + "NAME".PadRight($col1) + "START TYPE".PadRight($col2) + "UPTIME")
    Write-Host $header -ForegroundColor DarkGray
    Write-Host ("  " + ("-" * 50)) -ForegroundColor DarkGray

    foreach ($name in $serviceNames) {
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if (-not $svc) {
            Write-Host ("  " + $name.PadRight($col1)) -NoNewline -ForegroundColor White
            Write-Host "Not found" -ForegroundColor Red
            continue
        }

        $startType = $svc.StartType.ToString()
        $status    = $svc.Status.ToString()

        $uptimeStr = "---"
        if ($status -eq "Running") {
            try {
                $wmi = Get-WmiObject Win32_Service -Filter "Name='$name'" -ErrorAction SilentlyContinue
                if ($wmi -and $wmi.ProcessId -and $wmi.ProcessId -gt 0) {
                    $proc = Get-Process -Id $wmi.ProcessId -ErrorAction SilentlyContinue
                    if ($proc -and $proc.StartTime) {
                        $uptime = (Get-Date) - $proc.StartTime
                        if ($uptime.TotalHours -ge 24) {
                            $days = [math]::Floor($uptime.TotalDays)
                            $uptimeStr = "${days}d " + $proc.StartTime.ToString("HH:mm:ss")
                        } else {
                            $uptimeStr = $proc.StartTime.ToString("HH:mm:ss")
                        }
                    }
                }
            } catch {}
        }

        $nameColor   = "White"
        $statusColor = if ($status -eq "Running") { "Green" } else { "Red" }

        Write-Host ("  " + $name.PadRight($col1)) -NoNewline -ForegroundColor $nameColor
        Write-Host ($startType.PadRight($col2))    -NoNewline -ForegroundColor $statusColor
        Write-Host $uptimeStr                                  -ForegroundColor $statusColor
    }

    #registries
    Write-Host ""
    Write-Host "[*] REGISTRY" -ForegroundColor Cyan
    Write-Host ""

    # Registros onde valor 0 = desabilitado (ruim) e qualquer outro valor = habilitado (bom)
    $settings = @(
        @{ Name = "PowerShell Logging"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging";                     Key = "EnableScriptBlockLogging"; Warning = "Disabled"; Safe = "Enabled" },
        @{ Name = "Activities Cache";   Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System";                                            Key = "EnableActivityFeed";       Warning = "Disabled"; Safe = "Enabled" },
        @{ Name = "Prefetch Enabled";   Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key = "EnablePrefetcher";         Warning = "Disabled"; Safe = "Enabled" }
    )

    foreach ($s in $settings) {
        $reg = Get-ItemProperty -Path $s.Path -Name $s.Key -ErrorAction SilentlyContinue
        Write-Host "  " -NoNewline
        if ($reg -and $reg.$($s.Key) -eq 0) {
            Write-Host "$($s.Name): " -NoNewline -ForegroundColor White
            Write-Host $s.Warning     -ForegroundColor Red
        } else {
            Write-Host "$($s.Name): " -NoNewline -ForegroundColor White
            Write-Host $s.Safe        -ForegroundColor Green
        }
    }

    # CMD - DisableCMD: 0 = disponivel (bom), 1 ou 2 = bloqueado (ruim)
    # Logica invertida em relacao aos demais registros acima
    $cmdReg = Get-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\System" -Name "DisableCMD" -ErrorAction SilentlyContinue
    Write-Host "  " -NoNewline
    Write-Host "CMD: " -NoNewline -ForegroundColor White
    if ($cmdReg -and $cmdReg.DisableCMD -ge 1) {
        Write-Host "Disabled" -ForegroundColor Red
    } else {
        Write-Host "Available" -ForegroundColor Green
    }

    # Sysmain (superfetch)
    $superfetchReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SysMain" -Name "Start" -ErrorAction SilentlyContinue
    Write-Host "  " -NoNewline
    Write-Host "SysMain (Superfetch): " -NoNewline -ForegroundColor White
    if ($superfetchReg -and $superfetchReg.Start -eq 4) {
        Write-Host "Disabled" -ForegroundColor Red
    } else {
        Write-Host "Enabled"  -ForegroundColor Green
    }

    # PcaSvc 
    $pcaSvcReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\PcaSvc" -Name "Start" -ErrorAction SilentlyContinue
    Write-Host "  " -NoNewline
    Write-Host "PcaSvc Key: " -NoNewline -ForegroundColor White
    if ($pcaSvcReg -and $pcaSvcReg.Start -eq 4) {
        Write-Host "Disabled" -ForegroundColor Red
    } else {
        Write-Host "Enabled"  -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "================================================" -ForegroundColor DarkCyan
    Read-Host "  Press ENTER to return to menu"
}


function Show-StartServices {
    Clear-Host
    Write-Host "   +================================================+" -ForegroundColor darkgreen
    Write-Host "   |              START SERVICES                   |" -ForegroundColor green
    Write-Host "   +================================================+" -ForegroundColor darkgreen
    Write-Host ""
    Write-Host "    Do you want to enable all services or only the necessary ones?" -ForegroundColor White
    Write-Host ""
    Write-Host "     [1] " -foregroundcolor green -nonewline; Write-Host "All services" -ForegroundColor white 
    Write-Host "     [2] " -foregroundcolor green -nonewline; Write-Host "Necessary services only (recommended)" -ForegroundColor white
    Write-Host "     [x] " -foregroundcolor green -nonewline; Write-Host "Back" -ForegroundColor white
    Write-Host ""
    $choice = Read-Host "  Select an option"

    if ($choice -eq "x") { return }
    if ($choice -ne "1" -and $choice -ne "2") {
        Write-Host "`n  Invalid option." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    $allServices       = @("AppInfo", "BAM", "DPS", "DiagTrack", "DusmSvc", "EventLog", "PcaSvc", "PlugPlay", "Schedule", "SysMain", "WSearch")
    $necessaryServices = @("AppInfo", "BAM", "DPS", "DusmSvc", "EventLog", "PcaSvc", "WSearch", "SysMain", "PlugPlay", "Schedule")

    $targetList = if ($choice -eq "1") { $allServices } else { $necessaryServices }

    Write-Host ""
    Write-Host "  Starting services..." -ForegroundColor Cyan
    Write-Host ""

    foreach ($name in $targetList) {
        Write-Host "  " -NoNewline
        Write-Host "$($name.PadRight(15))" -NoNewline -ForegroundColor White
        Write-Host ": " -NoNewline -ForegroundColor DarkGray

        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if (-not $svc) {
            Write-Host "Not found" -ForegroundColor Red
            continue
        }

        try {
            Set-Service -Name $name -StartupType Automatic -ErrorAction Stop
        } catch {
            Write-Host "Failed to set Automatic" -ForegroundColor Red
            continue
        }

        if ($svc.Status -ne "Running") {
            try {
                Start-Service -Name $name -ErrorAction Stop
                Write-Host "Started" -ForegroundColor Green
            } catch {
                Write-Host "Automatic set, failed to start" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Already running" -ForegroundColor Green
        }
    }

    Write-Host ""
    Write-Host "================================================" -ForegroundColor darkgreen

    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show("It is recommended to restart before playing!", "Warning", "OK", "Warning") | Out-Null

    Read-Host "  Press ENTER to return to menu"
}


do {
    $option = MainMenu
    switch ($option) {
        "1" { Show-GeneralCheck }
        "2" { Show-StartServices }
        "x" { Clear-Host; exit }
        default { Write-Host "`n  Invalid option." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($true)
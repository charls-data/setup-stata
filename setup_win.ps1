# For use in GitHub Actions workflows to automate Stata setup
$ErrorActionPreference = 'Stop'

# =============================================================================
#  0. ENV
# =============================================================================
$esc = [char]27
$DBW = "$esc[48;2;0;0;139m$esc[38;2;255;255;255m"
$DRW = "$esc[48;2;139;0;0m$esc[38;2;255;255;255m"

$StataURL = $env:STATA_URL
$StataLicense = $env:STATA_LICENSE
$StataVersion = $env:STATA_VERSION
$StataEdition = $env:STATA_EDITION.ToUpper()

Write-Host "${DBW}========== Stata Automated Installation Script Starting =========="
Write-Host " "

# =============================================================================
#  1. Download Stata installer
# =============================================================================
Write-Host "${DBW}1 of 6: Download Stata Installer"
$StataInstaller = "C:\SetupStata.exe"
curl.exe -L -o $StataInstaller $StataURL
Write-Host "Download complete, preparing for installation..."
Write-Host " "

# =============================================================================
#  2. Install Stata
# =============================================================================
Write-Host "${DBW}2 of 6: Install Stata"
$addLocalOption = "core,Stata${stataEdition}64"
Start-Process -FilePath $StataInstaller -ArgumentList "/s", "/v`"/qn ADDLOCAL=$addLocalOption`"" `
    -Wait
Write-Host "Installation command executed, verifying installation..."

$StataExe = "C:\Program Files\Stata$StataVersion\Stata$stataEdition-64.exe"
if (-not (Test-Path $StataExe)) {
    Write-Host "${DRW}Stata installation failed, executable not found: $StataExe"
    exit 1  # Installation failed
}
Write-Host "Stata installed successfully."
Write-Host " "

# =============================================================================
#  3. Stata License
# =============================================================================
# Create license file
Write-Host "${DBW}3 of 6: Setup Stata License"
$licenseFile = "C:\Program Files\Stata$StataVersion\STATA.LIC"

# Write license content to license file
$($StataLicense) | Set-Content -LiteralPath $licenseFile -Encoding utf8NoBOM -NoNewline

# Check if the license file was created successfully
if (-not (Test-Path $licenseFile)) {
    Write-Host "${DRW}Failed to create license file at: $licenseFile"
    exit 2  # License file creation failed
}

Write-Host "License file created successfully at: $licenseFile"
Write-Host " "

# =============================================================================
#  4. Disable Stata Update Dialog
# =============================================================================
Write-Host "${DBW}4 of 6: Disable Stata Update Dialog via Registry"
Start-Process -FilePath "$StataExe"
Start-Sleep -Seconds 5
Stop-Process -Name "Stata$StataEdition-64" -ErrorAction SilentlyContinue
if (!(Test-Path -Path "HKCU:\Software\Stata\Stata$StataVersion\set_w\update_query")) {
    New-Item -Path "HKCU:\Software\Stata\Stata$StataVersion\set_w\update_query" -Force
}
New-ItemProperty -Path "HKCU:\Software\Stata\Stata$StataVersion\set_w\update_query" `
    -Name '(Default)' -PropertyType String -Value "0" -Force

Write-Host "Update Registry successfully."
Write-Host " "

# =============================================================================
#  5. Test Stata Functionality
# =============================================================================
Write-Host "${DBW}5 of 6: Test Stata Functionality"

$scriptDir = Split-Path -Parent $PSCommandPath
$expectedLogFile = Join-Path $scriptDir "stata.log"

# remove any previous log file
if (Test-Path $expectedLogFile) {
    Write-Host "Removing previous test log file: $expectedLogFile"
    Remove-Item $expectedLogFile -Force
}

$stataProcess = Start-Process -FilePath "$stataExe" -ArgumentList '/e', 'di 3241' `
    -Wait -NoNewWindow -PassThru -WorkingDirectory "$scriptDir"
$stataExitCode = $stataProcess.ExitCode

# Check Stata execution result
if ($stataExitCode -ne 0) {
    Write-Host "${DRW}Stata test failed, exit code: $stataExitCode"
    exit 3  # Stata execution failed
}
Write-Host "Stata test run passed!"

# Check for log file
if (-not (Test-Path $expectedLogFile)) {
    Write-Host "${DRW}Expected log file not found: $expectedLogFile"
    exit 4  # Log file not created
}

# check end of log file - 使用更简洁的方法获取最后一行
$lastLine = Get-Content -Path $expectedLogFile -Tail 1
if ($lastLine -ne "3241") {
    Write-Host "${DRW}Stata test did not complete successfully,"
    Write-Host "${DRW}last line of the log file is: $lastLine"
    exit 5  # Log format unexpected
}
Write-Host "Log file confirms successful execution."
Write-Host " "

# =============================================================================
#  6. Export Stata Executable to ENV
# =============================================================================
Write-Host "${DBW}6 of 6: Export Stata Executable to Environment Variable"

if ($env:GITHUB_ENV) {
    "STATA_EXE=$StataExe" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
    Write-Host "Setting environment variable 'STATA_EXE' to: $StataExe"
    Write-Host " "
} else {
    Write-Host "${DRW}Warning: GITHUB_ENV not found. Cannot export Stata_EXE."
    exit 6  # Environment variable export failed
}

# Clean up
Write-Host "Cleaning up: Removing files..."
Remove-Item -Path $expectedLogFile -Force
Remove-Item -Path $StataInstaller -Force

Write-Host " "
Write-Host "${DBW}========== Stata $StataVersion $StataEdition Successfully " -NoNewline
Write-Host "${DBW}Installed and Configured ==========="
Write-Host " "

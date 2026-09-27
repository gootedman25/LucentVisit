$ErrorActionPreference = 'Stop'

$workspace = Split-Path $PSScriptRoot -Parent
$flutter = Join-Path $workspace '.tools\flutter\bin\flutter.bat'
$sdk = Join-Path $env:LOCALAPPDATA 'ClearVisitDev\android-sdk'
$avdHome = Join-Path $env:LOCALAPPDATA 'ClearVisitDev\avd'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'

if (-not (Test-Path $flutter)) { throw "Flutter SDK not found at $flutter" }
if (-not (Test-Path $emulator)) { throw "Android emulator not found at $emulator" }

$env:ANDROID_HOME = $sdk
$env:ANDROID_SDK_ROOT = $sdk
$env:ANDROID_AVD_HOME = $avdHome

$connected = & $adb devices
if ($connected -notmatch 'emulator-\d+\s+device') {
  Start-Process -FilePath $emulator -ArgumentList @(
    '-avd', 'ClearVisit_API_36',
    '-no-snapshot',
    '-gpu', 'swiftshader_indirect',
    '-no-audio'
  )
  & $adb wait-for-device
  for ($attempt = 0; $attempt -lt 90; $attempt++) {
    if ((& $adb shell getprop sys.boot_completed 2>$null).Trim() -eq '1') { break }
    Start-Sleep -Seconds 1
  }
}

Push-Location $workspace
try {
  & $flutter run -d emulator-5554
} finally {
  Pop-Location
}


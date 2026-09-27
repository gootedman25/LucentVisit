$ErrorActionPreference = 'Stop'

$workspace = Split-Path $PSScriptRoot -Parent
$localFlutter = Join-Path $workspace '.tools\flutter\bin\flutter.bat'
$flutter = if (Test-Path $localFlutter) { $localFlutter } else { (Get-Command flutter -ErrorAction Stop).Source }
$androidSdk = Join-Path $env:LOCALAPPDATA 'ClearVisitDev\android-sdk'
$env:ANDROID_HOME = $androidSdk
$env:ANDROID_SDK_ROOT = $androidSdk

Push-Location (Split-Path $PSScriptRoot -Parent)
try {
  & $flutter create --platforms=android,ios --project-name=lucentvisit --org=org.clearvisit .
  & $flutter config --android-sdk $androidSdk
  & $flutter pub get
  & $flutter analyze
  & $flutter test
} finally {
  Pop-Location
}

Write-Output 'Native wrappers generated. Apply the platform hardening steps in docs/PLATFORM_SECURITY.md before running a release build.'

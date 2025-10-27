Write-Output "Checking for ninja..."
$cmd = Get-Command ninja -ErrorAction SilentlyContinue
if ($null -eq $cmd) {
  Write-Output "ninja not found - installing ninja 1.12.0 via Chocolatey"
  choco install ninja --version=1.12.0 -y --no-progress
} else {
  $ninja = (& ninja --version) -replace '\s+',''
  # Try parsing the version safely
  $parsed = $null
  if ([version]::TryParse($ninja, [ref]$parsed)) {
    if ($parsed -lt [version]'1.12.0') {
      Write-Output "Ninja $ninja is older than 1.12.0 - installing 1.12.0"
      choco install ninja --version=1.12.0 -y --no-progress
    } else {
      Write-Output "Ninja $ninja meets requirement"
    }
  } else {
    Write-Output "Could not parse ninja version '$ninja' - installing 1.12.0"
    choco install ninja --version=1.12.0 -y --no-progress
  }
}
Write-Output "Final ninja version:"
ninja --version

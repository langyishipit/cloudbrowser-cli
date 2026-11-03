# CloudBrowser CLI installer for Windows. No administrator privileges required.
$ErrorActionPreference = 'Stop'
$version = if ($env:CLOUDBROWSER_VERSION) { $env:CLOUDBROWSER_VERSION -replace '^v', '' } else { '0.2.0' }
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid CLOUDBROWSER_VERSION (expected e.g. 0.2.0)' }
$cpu = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
$arch = switch ($cpu) { 'AMD64' { 'amd64' } 'ARM64' { 'arm64' } default { throw "Unsupported CPU architecture: $cpu" } }
$installDir = if ($env:CLOUDBROWSER_INSTALL_DIR) { $env:CLOUDBROWSER_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'CloudBrowser\bin' }
$tempDir = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
$staging = $null
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $asset = "cloudbrowser_${version}_windows_${arch}.zip"
    $base = "https://github.com/langyishipit/cloudbrowser-cli/releases/download/v$version"
    Write-Host "Downloading CloudBrowser CLI v$version (windows/$arch)..."
    Invoke-WebRequest -UseBasicParsing -Uri "$base/$asset" -OutFile (Join-Path $tempDir $asset)
    Invoke-WebRequest -UseBasicParsing -Uri "$base/checksums.txt" -OutFile (Join-Path $tempDir 'checksums.txt')
    $lines = @(Get-Content (Join-Path $tempDir 'checksums.txt') | Where-Object { $_ -match ('^[a-fA-F0-9]{64}\s+' + [regex]::Escape($asset) + '$') })
    if ($lines.Count -ne 1) { throw 'Missing or invalid release checksum' }
    $expected = ($lines[0] -split '\s+')[0]
    $actual = (Get-FileHash -Algorithm SHA256 (Join-Path $tempDir $asset)).Hash
    if ($actual -ne $expected) { throw 'Checksum mismatch; installation aborted' }
    Expand-Archive -LiteralPath (Join-Path $tempDir $asset) -DestinationPath (Join-Path $tempDir 'extracted')
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    $staging = Join-Path $installDir ('.cloudbrowser-' + [Guid]::NewGuid().ToString() + '.exe')
    Copy-Item (Join-Path $tempDir 'extracted\cloudbrowser.exe') $staging
    Move-Item -Force -LiteralPath $staging -Destination (Join-Path $installDir 'cloudbrowser.exe')
    $staging = $null
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (($userPath -split ';') -notcontains $installDir) { [Environment]::SetEnvironmentVariable('Path', "$installDir;$userPath", 'User') }
    if (($env:Path -split ';') -notcontains $installDir) { $env:Path = "$installDir;$env:Path" }
    Write-Host "Installed CloudBrowser CLI v$version at $installDir"
    Write-Host 'Next: cloudbrowser auth login'
} finally {
    if ($staging -and (Test-Path -LiteralPath $staging)) { Remove-Item -Force -LiteralPath $staging }
    if (Test-Path -LiteralPath $tempDir) { Remove-Item -Recurse -Force -LiteralPath $tempDir }
}

# Use GH_PROXY environment variable if set, otherwise default to empty
if (-not $env:GH_PROXY) {
    $GH_PROXY = ""
} else {
    $GH_PROXY = $env:GH_PROXY
}

function Test-Url {
    param([string]$Url)
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 5
        return $true
    } catch {
        return $false
    }
}

try {
    Write-Host "Fetching latest Nilesoft Shell release..."

    $repo = "jianghuaangte/nilesoft-shell-releases"
    $apiUrl = "https://api.github.com/repos/$repo/releases/latest"
    $headers = @{ "User-Agent" = "PowerShellScript" }

    # Fetch release JSON
    $json = Invoke-RestMethod -Uri $apiUrl -Headers $headers

    # Detect system architecture
    if ([Environment]::Is64BitOperatingSystem) {
        if ([Environment]::Is64BitProcess) {
            $fileNamePattern = "setup-x64.msi"
        } else {
            $fileNamePattern = "setup-x86.msi"
        }
    } else {
        $fileNamePattern = "setup-arm64.msi"
    }

    $asset = $json.assets |
             Where-Object { $_.name -eq $fileNamePattern } |
             Select-Object -First 1

    if (-not $asset) { 
        Write-Host "MSI file not found: $fileNamePattern, trying alternative files..."
        # 如果没找到特定架构的文件，尝试其他文件
        $alternativeAssets = $json.assets | Where-Object { $_.name -like "setup-*.msi" }
        if ($alternativeAssets.Count -eq 0) {
            throw "No setup MSI files found in the release"
        }
        $asset = $alternativeAssets | Select-Object -First 1
        Write-Host "Using alternative file: $($asset.name)"
    }

    $downloadUrl = $asset.browser_download_url

    # Apply GH_PROXY if set and reachable
    if ($GH_PROXY -ne "") {
        $proxiedUrl = "$GH_PROXY$downloadUrl"
        if (Test-Url $proxiedUrl) {
            $downloadUrl = $proxiedUrl
            Write-Host "Using GH_PROXY for download: $GH_PROXY"
        } else {
            Write-Host "GH_PROXY is set but unreachable, using original URL"
        }
    }

    Write-Host "Found MSI: $($asset.name)"
    Write-Host "Download URL: $downloadUrl"

    $tmpDir = [System.IO.Path]::GetTempPath()
    $localFile = Join-Path -Path $tmpDir -ChildPath $asset.name

    Write-Host "Downloading to $localFile..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $localFile

    if (-not (Test-Path $localFile)) { throw "Download failed: $localFile does not exist" }

    Write-Host "Installing Nilesoft Shell silently..."
    $installArgs = "/i `"$localFile`" /quiet /norestart"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -NoNewWindow

    # Wait for installation to complete
    Start-Sleep -Seconds 3

    Write-Host "Configuring Nilesoft Shell..."

    $nilesoftInstallPath = "C:\Program Files\Nilesoft Shell"
    $configFile = Join-Path $nilesoftInstallPath "shell.nss"
    $importsDir = Join-Path $nilesoftInstallPath "imports"
    $neovimConfigFile = Join-Path $importsDir "neovim.nss"

    # Check if installation was successful
    if (-not (Test-Path $nilesoftInstallPath)) {
        throw "Nilesoft Shell installation failed: $nilesoftInstallPath not found"
    }

    # Backup existing shell.nss if it exists
    if (Test-Path $configFile) {
        $backupFile = "$configFile.bak"
        Copy-Item -Path $configFile -Destination $backupFile -Force
        Write-Host "Backed up existing configuration to: $backupFile"
    }

    # Create imports directory if it doesn't exist
    if (-not (Test-Path $importsDir)) {
        New-Item -Path $importsDir -ItemType Directory -Force | Out-Null
        Write-Host "Created imports directory: $importsDir"
    }

    # Write main shell.nss configuration
    $shellNssContent = @"
settings
{
    priority=1
    exclude.where = !process.is_explorer
    showdelay = 200
    // Options to allow modification of system items
    modify.remove.duplicate=1
    tip.enabled=true
}

// import 'imports/theme.nss'
// import 'imports/images.nss'

import 'imports/modify.nss'

menu(mode=`"multiple`" title=`"Pin/Unpin`" image=icon.pin)
{
}

menu(mode=`"multiple`" title=title.more_options image=icon.more_options)
{
}

import 'imports/terminal.nss'
// import 'imports/file-manage.nss'
import 'imports/develop.nss'
// import 'imports/goto.nss'
import 'imports/taskbar.nss'
import 'imports/neovim.nss'
"@

    Write-Host "Writing main configuration to: $configFile"
    $shellNssContent | Set-Content -Path $configFile -Encoding UTF8

    # Write neovim.nss configuration
    $neovimNssContent = @"
item(
    title='Edit with Neovim'
    // icon
    image=image.res(`"C:\\Program Files\\Neovim\\bin\\nvim.exe`")
    cmd='wt.exe'
    args='nvim `"@sel.path`"'
    admin='true' // 管理员权限
    sep='top'
)
"@

    Write-Host "Writing Neovim configuration to: $neovimConfigFile"
    $neovimNssContent | Set-Content -Path $neovimConfigFile -Encoding UTF8

    # Restart Nilesoft Shell to apply configuration
    $shellExe = Join-Path $nilesoftInstallPath "shell.exe"
    if (Test-Path $shellExe) {
        Write-Host "Restarting Nilesoft Shell to apply configuration..."
        Start-Process -FilePath $shellExe -ArgumentList "-restart" -Wait
        Write-Host "Nilesoft Shell restarted successfully."
    } else {
        Write-Warning "shell.exe not found at: $shellExe"
        Write-Warning "Please manually restart Nilesoft Shell to apply configuration."
    }

    Write-Host "Cleaning up downloaded MSI..."
    Remove-Item -Path $localFile -Force

    Write-Host "Nilesoft Shell installed and configured successfully!"
    Write-Host "Main configuration: $configFile"
    Write-Host "Neovim menu configuration: $neovimConfigFile"
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}

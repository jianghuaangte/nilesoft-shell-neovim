# nilesoft-shell-neovim
Windows 添加右键 Edit with Neovim

- 配合neovim安装脚本使用
- 以管理员权限运行 powershell

### cmd
- 无法使用 OSC52 复制

```powershell
$env:GH_PROXY = "https://ghproxy.cn/"
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jianghuaangte/nilesoft-shell-cmd-neovim/refs/heads/main/nilesoft-shell-neovim.ps1'))
```

### windows terminal
```powershell
$env:GH_PROXY = "https://ghproxy.cn/"
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jianghuaangte/nilesoft-shell-terminal-neovim/refs/heads/main/nilesoft-shell-neovim.ps1'))
```

### wezterm
```powershell
$env:GH_PROXY = "https://ghproxy.cn/"
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/jianghuaangte/nilesoft-shell-wezterm-neovim/refs/heads/main/nilesoft-shell-neovim.ps1'))
```

关联
- https://github.com/jianghuaangte/Neovim

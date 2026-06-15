# Multi-Browser Clean Optimizer

Windows 11 多浏览器清洁、隐私、安全、稳定性优化脚本。

这个项目只优化浏览器本身：关闭新闻、广告、促销、默认浏览器提示、后台运行、遥测和不必要的厂商功能；默认打开书签栏；主页和启动页尽量设为空白页；保留登录、密码、自动填充、翻译、安全浏览和硬件加速等正常功能。

脚本不会安装浏览器，不配置代理、VPN、Clash，不做流量伪装，不做虚假指纹或反检测伪装。

## 先看这三句话

1. 你不需要安装满 9 个浏览器。脚本默认只优化本机已经检测到的浏览器，没安装的会自动跳过。
2. 正式优化需要用管理员身份打开 PowerShell。
3. 正式运行时脚本会自动关闭正在运行的浏览器。运行前请先保存网页、表单、聊天内容和未提交内容。

## 一键安装并运行

推荐新手直接用这一段。它会把仓库下载到：

```text
C:\Users\你的用户名\Documents\Browser-main
```

如果这个目录已经存在，旧目录会先改名成带时间戳的备份目录，不会直接删除。

操作方法：

1. 关闭或保存所有浏览器里的重要内容。
2. 右键开始菜单。
3. 打开“终端(管理员)”或“Windows PowerShell(管理员)”。
4. 复制下面整段命令，粘贴进去，按回车。

```powershell
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Repo = Join-Path $env:USERPROFILE "Documents\Browser-main"
$Backup = Join-Path $env:USERPROFILE ("Documents\Browser-main-backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
$Zip = Join-Path $env:TEMP "Browser-main.zip"
$Extract = Join-Path $env:TEMP "Browser-main-extract"

if (Test-Path -LiteralPath $Extract) { Remove-Item -LiteralPath $Extract -Recurse -Force }
Invoke-WebRequest -Uri "https://github.com/vpn3288/Browser/archive/refs/heads/main.zip" -OutFile $Zip
Expand-Archive -LiteralPath $Zip -DestinationPath $Extract -Force

if (Test-Path -LiteralPath $Repo) { Move-Item -LiteralPath $Repo -Destination $Backup }
Move-Item -LiteralPath (Join-Path $Extract "Browser-main") -Destination $Repo

& (Join-Path $Repo "scripts\deployment\Invoke-BrowserOptimization.ps1")
```

## 运行成功怎么看

最后重点看这一行：

```text
FAIL=0
```

`FAIL=0` 表示没有硬失败。

`WARN` 是提醒，不一定是错误。常见原因包括：

- 有浏览器还没完全关闭。
- 某个浏览器还没有第一次启动过，所以还没有 Profile 目录。
- Chrome/Chromium 系没有官方策略能强制“书签左键点击在新的前台标签页打开”，脚本会如实提示。
- Opera 没有公开完整的 Chrome/Edge 风格 Windows 企业策略，所以脚本用可验证的 Profile 偏好处理 Opera，不伪造策略。

## 已经下载过仓库

如果你已经有这个仓库，进入仓库根目录后运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\Invoke-BrowserOptimization.ps1
```

默认只处理本机检测到的浏览器。

## 只预览不修改

想先看看脚本会做什么，但不写注册表、不改浏览器配置文件、不关闭浏览器，运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\Invoke-BrowserOptimization.ps1 -DryRun
```

这是最适合排错和测试的命令。

## 只重新验证

已经优化过，只想重新检查结果，运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\Invoke-BrowserOptimization.ps1 -VerifyOnly
```

验证前也需要关闭浏览器，否则可能出现浏览器进程残留的 WARN 或 FAIL。

## 支持哪些浏览器

脚本按 9 个浏览器维护：

- Google Chrome
- Chromium
- Microsoft Edge
- Brave
- Opera
- Vivaldi
- Mozilla Firefox
- LibreWolf
- Zen Browser

没有安装的浏览器会跳过。只有你明确想强制检查全部 9 个目标浏览器时，才使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\Invoke-BrowserOptimization.ps1 -AllBrowsers
```

新手一般不需要 `-AllBrowsers`。

## 第一次优化后的推荐流程

有些浏览器只有启动过一次以后才会创建 Profile。为了让 Profile 偏好也补齐，推荐这样做：

1. 用“一键安装并运行”优化一次。
2. 分别打开你已经安装的浏览器一次。
3. 关闭所有浏览器。
4. 再运行一次优化命令。
5. 最后确认验证结果是 `FAIL=0`。

## 优化了什么

通用优化：

- 默认显示书签栏。
- 显示主页按钮。
- 主页和启动页尽量设置为 `about:blank`。
- 关闭默认浏览器提示。
- 关闭浏览器退出后的后台运行。
- 关闭新闻、广告、促销、推荐、赞助内容、遥测和不必要的厂商功能。
- 保留正常登录、Cookie、密码管理、自动填充、翻译、安全浏览和硬件加速。
- 避免过度优化导致网页、游戏、AI 网站、支付、登录或扩展系统不稳定。

Chromium 系浏览器：

- Chrome、Chromium、Edge、Brave、Vivaldi 使用官方 Windows 企业策略作为主配置。
- 设置书签栏、主页按钮、空白启动页、空白主页、关闭后台模式。
- 关闭 Privacy Sandbox 广告相关功能、促销页、搜索建议、遥测、反馈、QUIC、DoH。
- 阻止默认地理位置和通知请求。
- 阻止第三方 Cookie，同时保留正常 Cookie，减少登录异常。

Firefox 系浏览器：

- Firefox、LibreWolf、Zen 写入 `distribution\policies.json`。
- 显示书签栏和主页按钮。
- 主页和新标签页设为空白。
- 关闭 Telemetry、Studies、Pocket、默认浏览器 Agent、Firefox Suggest、赞助建议和用户消息推荐。
- 开启增强跟踪保护、指纹跟踪防护和加密挖矿防护。
- 书签点击通过官方偏好设置为在新的前台标签页打开。

Opera：

- Opera 没有公开完整的 Chrome/Edge 风格 Windows 企业策略。
- 脚本不伪造 Opera 注册表策略。
- Opera 通过可观察的 Profile 偏好设置书签栏、空白主页、空白启动页、关闭个性化广告和个性化内容。

## 常见问题

### 提示不是管理员

正式优化需要管理员权限。请右键开始菜单，选择“终端(管理员)”或“Windows PowerShell(管理员)”后重新运行。

### 浏览器被自动关闭

这是正常设计。浏览器运行时会占用 Profile 文件，脚本直接改配置容易失败或损坏配置，所以优化和验证前会先关闭浏览器。

### 我没有 9 个浏览器

没关系。v14.26 起默认只处理检测到的浏览器，没有安装的浏览器会跳过。

### Chromium 是 zip 解压版

脚本会检测常见的 `chrome-win\chrome.exe` 解压目录，也会检测 `%LOCALAPPDATA%\Chromium\Application\chrome.exe`。如果你把 Chromium 解压到很特殊的位置，建议放到 `Downloads\chrome-win`、`Documents\chrome-win` 或 `%LOCALAPPDATA%\Chromium\Application` 这类常见路径。

### 有 WARN 但没有 FAIL

通常可以接受。重点看 `FAIL=0`。如果 WARN 提到浏览器 Profile 不存在，启动一次对应浏览器，关闭后再运行一次优化即可。

## 参数说明

常用入口脚本：

```text
scripts\deployment\Invoke-BrowserOptimization.ps1
```

常用参数：

- `-DryRun`：只预览，不写入，不关闭浏览器。
- `-VerifyOnly`：只重新验证，不重新优化。
- `-AllBrowsers`：强制处理/验证全部 9 个目标浏览器；新手一般不用。
- `-SkipVerify`：优化后跳过验证。
- `-NoCloseBrowsers`：不自动关闭浏览器，不推荐正式优化时使用。

底层脚本：

- `scripts\deployment\OPTIMIZE_ALL_v14.26.ps1`
- `scripts\deployment\Verify-BrowserOptimization.ps1`

一般用户只需要使用入口脚本，不需要直接调用底层脚本。

## 备份

脚本修改 Profile 文件前会备份到：

```text
backups\<时间戳>
```

`backups/` 已经被 `.gitignore` 忽略，不会上传到 GitHub。

## 项目边界

本项目不会做：

- 不安装浏览器。
- 不增加启动器。
- 不伪装成其他人或其他地区。
- 不绕过网站、游戏、AI 平台的风控或审查。
- 不配置 Clash、代理、VPN 或 GFW 绕过。
- 不做虚假指纹、反检测、异常流量规避。

本项目会做：

- 使用官方策略和可验证的 Profile 偏好。
- 优先稳定、兼容、安全。
- 关闭厂商噪音和推广功能。
- 保留正常浏览、登录、翻译、密码管理、扩展系统和安全浏览。
- 明确报告官方做不到的项目，不假装成功。

## 更多资料

- 官方资料整理：`docs/official-sources.md`
- 排错文档：`docs/troubleshooting.md`
- 历史说明和旧脚本背景：`zhubi.md`、`v14.1_修复说明.md`

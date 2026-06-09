# Multi-Browser Clean Optimizer

Windows 11 多浏览器清洁、隐私、安全、稳定性优化脚本。

这个仓库只优化浏览器本身：关闭新闻、广告、促销、默认浏览器提示、后台运行、遥测和不必要的厂商功能；默认打开书签栏；主页和启动页尽量设为空白页；修正扩展强制安装策略。脚本不增加启动器，不配置代理，不做流量伪装，不做虚假指纹或反检测伪装。

## 小白直接复制

先关闭所有浏览器。

然后用管理员身份打开 PowerShell 7 或 Windows PowerShell。看到类似下面这样就可以粘贴命令：

```text
PS C:\Users\Newby>
```

复制下面整段，不要只复制其中一行：

```powershell
$Repo = "C:\Users\Newby\Documents\浏览器优化\Browser-main"
$OptimizeScript = Join-Path $Repo "scripts\deployment\OPTIMIZE_ALL_v14.25.ps1"
$VerifyScript = Join-Path $Repo "scripts\deployment\Verify-BrowserOptimization.ps1"
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) { throw "当前 PowerShell 不是管理员。请右键 PowerShell，选择“以管理员身份运行”，然后重新粘贴这整段命令。" }
if (-not (Test-Path -LiteralPath $Repo)) { throw "找不到仓库目录：$Repo" }
if (-not (Test-Path -LiteralPath $OptimizeScript)) { throw "找不到优化脚本：$OptimizeScript" }
if (-not (Test-Path -LiteralPath $VerifyScript)) { throw "找不到验证脚本：$VerifyScript" }
$RunningBrowsers = @(Get-Process -Name chrome,msedge,brave,vivaldi,opera,firefox,librewolf,zen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName -Unique)
if ($RunningBrowsers.Count -gt 0) { throw "请先关闭这些浏览器进程，然后重新粘贴这整段命令：$($RunningBrowsers -join ', ')" }
$PowerShellExe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $PowerShellExe) { $PowerShellExe = (Get-Command powershell -ErrorAction Stop).Source }
Set-Location -LiteralPath $Repo
& $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $OptimizeScript -OnlyInstalled
if ($LASTEXITCODE -ne 0) { throw "优化脚本运行失败，退出码：$LASTEXITCODE" }
& $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $VerifyScript -RequireMachinePolicy -OnlyInstalled -Detailed
if ($LASTEXITCODE -ne 0) { throw "验证没有通过，退出码：$LASTEXITCODE" }
```

这段命令会做三件事：

- 自动进入正确仓库目录。
- 优化本机已经安装的浏览器。
- 运行详细验证，确认优化是否真的生效。

重点看最后的结果：

```text
FAIL=0
```

只要 `FAIL=0`，就是没有硬失败。`WARN` 是提醒，不一定是错误，下面有解释。

## 只预览不修改

如果你想先看看脚本准备做什么，复制这段：

```powershell
$Repo = "C:\Users\Newby\Documents\浏览器优化\Browser-main"
$OptimizeScript = Join-Path $Repo "scripts\deployment\OPTIMIZE_ALL_v14.25.ps1"
$PowerShellExe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $PowerShellExe) { $PowerShellExe = (Get-Command powershell -ErrorAction Stop).Source }
if (-not (Test-Path -LiteralPath $OptimizeScript)) { throw "找不到优化脚本：$OptimizeScript" }
Set-Location -LiteralPath $Repo
& $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $OptimizeScript -OnlyInstalled -DryRun
```

`-DryRun` 只预览，不写注册表，不改浏览器配置文件。

## 只重新验证

如果你已经优化过，只想重新检查，复制这段：

```powershell
$Repo = "C:\Users\Newby\Documents\浏览器优化\Browser-main"
$VerifyScript = Join-Path $Repo "scripts\deployment\Verify-BrowserOptimization.ps1"
$PowerShellExe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $PowerShellExe) { $PowerShellExe = (Get-Command powershell -ErrorAction Stop).Source }
if (-not (Test-Path -LiteralPath $VerifyScript)) { throw "找不到验证脚本：$VerifyScript" }
$RunningBrowsers = @(Get-Process -Name chrome,msedge,brave,vivaldi,opera,firefox,librewolf,zen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName -Unique)
if ($RunningBrowsers.Count -gt 0) { throw "请先关闭这些浏览器进程，然后重新粘贴这整段命令：$($RunningBrowsers -join ', ')" }
Set-Location -LiteralPath $Repo
& $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $VerifyScript -RequireMachinePolicy -OnlyInstalled -Detailed
```

## 为什么旧命令不能用

如果你在这里：

```text
PS C:\Users\Newby>
```

直接运行下面这种命令会失败：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\OPTIMIZE_ALL_v14.25.ps1
```

原因是 `.\scripts\deployment\...` 是相对路径。它会从当前目录 `C:\Users\Newby` 下面找脚本，但脚本实际在：

```text
C:\Users\Newby\Documents\浏览器优化\Browser-main\scripts\deployment
```

所以 README 现在给的是完整复制块，会自动进入正确目录，并且直接使用脚本的绝对路径。

## 支持浏览器

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

默认命令使用 `-OnlyInstalled`，意思是只优化本机已经安装的浏览器。没安装的浏览器会跳过，不会因为不存在就失败。

## 优化内容

通用优化：

- 默认显示书签栏。
- 显示主页按钮。
- 主页和启动页尽量设置为 `about:blank`。
- 关闭默认浏览器提示。
- 关闭浏览器退出后的后台运行。
- 关闭新闻、广告、促销、推荐、赞助内容、遥测和不必要的厂商功能。
- 保留安全浏览、硬件加速、密码管理、自动填充、登录能力和翻译能力。
- 避免过度优化导致网页、游戏、AI 网站、支付、登录或扩展系统不稳定。

Chromium 系浏览器：

- Chrome、Chromium、Edge、Brave、Vivaldi 使用官方 Windows 企业策略作为主配置。
- 设置书签栏、主页按钮、空白启动页、空白主页、关闭后台模式。
- 关闭 Privacy Sandbox 广告相关功能、促销页、搜索建议、遥测、反馈、QUIC、DoH。
- 阻止默认地理位置和通知请求。
- 阻止第三方 Cookie，同时保留正常 Cookie，减少登录异常。
- 保留 Safe Browsing、硬件加速、密码管理、自动填充、登录和翻译。

Edge 额外优化：

- 关闭首启体验、默认浏览器营销提示、推荐、侧边栏、购物助手、钱包结账、Rewards、Collections、Workspaces、Visual Search。
- 保留 SmartScreen。
- Tracking Prevention 使用 Balanced，兼顾隐私和网页兼容性。

Brave 额外优化：

- 关闭 Brave News、Rewards、Wallet、VPN、Talk、AI Chat、P3A、Stats Ping、Web Discovery、Tor、IPFS。
- 不关闭 Brave 的基础安全能力。

Vivaldi 额外优化：

- 关闭默认浏览器检查和 Workspaces。
- 保留 Vivaldi Translate。
- 对 Vivaldi 自有偏好使用 Profile 配置补充。

Opera 处理方式：

- Opera 没有公开与 Chrome/Edge 完全一致的 Windows 企业策略面。
- 脚本不伪造 Opera 注册表策略。
- Opera 通过可观察的 Profile 偏好设置书签栏、空白主页、空白启动页、关闭个性化广告和个性化内容。

Firefox 系浏览器：

- Firefox、LibreWolf、Zen 写入 `distribution\policies.json`。
- 显示书签栏和主页按钮。
- 主页和新标签页设为空白。
- 关闭 Telemetry、Studies、Pocket、默认浏览器 Agent、Firefox Suggest、赞助建议、用户消息推荐。
- 开启增强跟踪保护、指纹跟踪防护、加密挖矿防护。
- 保留密码管理、表单历史、硬件加速和翻译。
- 书签点击通过官方偏好设置为在新的前台标签页打开。

LibreWolf 单独说明：

- LibreWolf 有优化，不是漏掉了。
- 脚本会检测 `C:\Program Files\LibreWolf\librewolf.exe` 和 `C:\Program Files (x86)\LibreWolf\librewolf.exe`。
- 脚本会写入 `C:\Program Files\LibreWolf\distribution\policies.json`。
- 脚本会处理 `%APPDATA%\LibreWolf\Profiles` 下的 `user.js`。
- LibreWolf 复用 Mozilla 企业策略格式，因为 LibreWolf 本身就是 Firefox 系浏览器。
- 如果 LibreWolf 还没有首次启动过，可能没有 Profile 目录。先启动一次 LibreWolf，再关闭，然后重新运行优化脚本即可补齐用户 Profile 优化。

## 验证结果怎么看

验证脚本会输出：

- `PASS`：项目已按预期配置。
- `WARN`：不是失败，但需要人工知道原因。
- `FAIL`：优化未生效或浏览器/配置缺失。

正常情况下，重点是：

```text
FAIL=0
```

常见 WARN：

- `Chromium bookmark click foreground tab`：Chromium 系没有官方策略能强制书签栏左键点击在新的前台标签页打开。Firefox、LibreWolf、Zen 可以做到。
- `Opera registry policy`：Opera 没有公开对应 Windows 企业策略，所以脚本用 Profile 偏好验证，不伪造策略。
- `Chrome NewTabPageLocation`：Chrome 在部分非托管设备上可能忽略 `NewTabPageLocation=about:blank`，需要在 `chrome://policy` 里确认。
- `profile root` 或 `user.js missing`：浏览器还没有首次启动创建 Profile。启动一次浏览器，关闭后再运行优化脚本。
- `process count expected=0`：还有浏览器没关干净。关闭对应浏览器，任务管理器里确认没有残留进程，再重新验证。

## 重装浏览器后的推荐流程

1. 关闭所有浏览器。
2. 用管理员身份打开 PowerShell。
3. 复制“ 小白直接复制 ”里的整段命令并运行。
4. 分别启动一次每个浏览器，让浏览器创建 Profile。
5. 关闭所有浏览器。
6. 再复制“ 小白直接复制 ”里的整段命令运行一次。
7. 最后确认验证结果是 `FAIL=0`。

## 扩展配置

扩展强制安装只读取：

```text
config/extensions.json
```

默认示例全部是 `enabled: false`，不会强制安装任何扩展。这样做是为了先解决“扩展安装失败”和“错误扩展策略残留”的问题。

需要启用扩展时，必须同时满足：

- `enabled` 改为 `true`。
- Chromium 扩展 ID 是 32 位 `a-p` 小写字符。
- update URL 正确。
- Firefox 系扩展使用可下载的 XPI URL。
- `browsers` 里包含目标浏览器名。

常用 update URL：

```text
Chrome/Chromium/Brave/Vivaldi:
https://clients2.google.com/service/update2/crx

Microsoft Edge:
https://edge.microsoft.com/extensionwebstorebase/v1/crx

Firefox/LibreWolf/Zen:
https://addons.mozilla.org/firefox/downloads/latest/<addon>/latest.xpi
```

## 参数说明

优化脚本常用参数：

- `-OnlyInstalled`：只处理本机已经安装的浏览器。
- `-DryRun`：只预览，不写入。
- `-UserOnly`：只写当前用户策略和用户配置，不写 HKLM。
- `-ApplyProfilePreferences:$false`：只写官方策略，跳过直接编辑 Profile 偏好文件。
- `-ExtensionConfigPath <path>`：使用自定义扩展配置文件。

验证脚本常用参数：

- `-OnlyInstalled`：只验证本机已经安装的浏览器。
- `-RequireMachinePolicy`：严格验证 HKLM 机器级策略。
- `-Detailed`：输出每个浏览器和每类优化项目的完整明细。
- `-Quiet`：静默验证，只看退出码。
- `-StrictProfilePreferences`：把 Profile 偏好警告提升为失败，适合排错时使用。

## 备份

脚本修改 Profile 文件前会备份到：

```text
backups\<时间戳>
```

`backups/` 已经被 `.gitignore` 忽略，不会上传到 GitHub。

## 项目边界

本项目不会做：

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

## 官方依据和排错

官方资料整理：

```text
docs/official-sources.md
```

排错文档：

```text
docs/troubleshooting.md
```

历史说明和旧脚本背景：

```text
zhubi.md
v14.1_修复说明.md
```

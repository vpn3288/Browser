# Multi-Browser Clean Optimizer

Windows 11 多浏览器清洁、隐私、安全、稳定性优化脚本。

这个仓库只做一件事：把常用浏览器尽量调成干净、安静、少打扰、少遥测、少后台常驻的浏览器。脚本不增加启动器，不做代理配置，不做流量伪装，不做账号风控绕过，不做虚假指纹或反检测伪装。

## 支持浏览器

当前按 9 个浏览器维护：

- Google Chrome
- Chromium
- Microsoft Edge
- Brave
- Opera
- Vivaldi
- Mozilla Firefox
- LibreWolf
- Zen Browser

## 快速开始

请先进入仓库根目录。很多运行失败都是因为当前目录不对。

正确目录示例：

```powershell
cd "C:\Users\Newby\Documents\浏览器优化\Browser-main"
```

如果你现在在 `C:\Users\Newby`，直接运行 `.\scripts\deployment\OPTIMIZE_ALL_v14.25.ps1` 会报“文件不存在”，因为脚本不在那个目录下。

推荐使用 PowerShell 7：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\OPTIMIZE_ALL_v14.25.ps1
```

先预览，不写注册表、不改浏览器 Profile：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\OPTIMIZE_ALL_v14.25.ps1 -DryRun
```

严格验证机器级策略和浏览器配置：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\Verify-BrowserOptimization.ps1 -RequireMachinePolicy -Detailed
```

如果你坚持使用 Windows 自带 PowerShell 5.1，把 `pwsh` 换成 `powershell` 即可。脚本已经处理了 PowerShell 5.1 读取 UTF-8 浏览器 JSON 的问题。

## 管理员权限

建议用管理员权限打开 PowerShell，然后进入仓库目录运行脚本。

管理员模式会写入 HKLM 机器级浏览器策略，这是最稳定、最接近官方企业策略的方式。非管理员模式会跳过 HKLM，只尽量写 HKCU 和用户 Profile；如果你的系统限制了 `HKCU\SOFTWARE\Policies`，非管理员模式会出现权限警告。

确认是否管理员：

```powershell
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

返回 `True` 才是管理员。

## 常用命令

只处理已安装浏览器：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\OPTIMIZE_ALL_v14.25.ps1 -OnlyInstalled
```

只写当前用户，不写 HKLM：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\OPTIMIZE_ALL_v14.25.ps1 -UserOnly
```

只写官方策略，跳过直接编辑浏览器 Profile：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\OPTIMIZE_ALL_v14.25.ps1 -ApplyProfilePreferences:$false
```

静默验证，只看退出码：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\Verify-BrowserOptimization.ps1 -RequireMachinePolicy -Quiet
```

## 优化内容

通用目标：

- 默认显示书签栏。
- 显示主页按钮。
- 主页、启动页尽量设为 `about:blank`。
- 关闭默认浏览器提示。
- 关闭浏览器关闭后的后台运行。
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

- 关闭首启体验、默认浏览器营销提示、推荐、侧边栏、购物助手、钱包结账、Rewards、Collections、Workspaces、Visual Search 等项目。
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
- LibreWolf 复用 Mozilla 企业策略格式，因为 LibreWolf 本身就是 Firefox 系浏览器；这不是 Chrome/Chromium 策略，也不是假策略。
- 如果 LibreWolf 还没有首次启动过，可能没有 Profile 目录。先启动一次 LibreWolf，再关闭，然后重新运行优化脚本即可补齐用户 Profile 优化。

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

## 验证结果怎么看

验证脚本会输出：

- `PASS`：项目已按预期配置。
- `WARN`：不是失败，但需要人工知道原因。
- `FAIL`：优化未生效或浏览器/配置缺失。

推荐看这条命令：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\Verify-BrowserOptimization.ps1 -RequireMachinePolicy -Detailed
```

正常情况下，重点是 `FAIL=0`。

常见 WARN：

- `Chromium bookmark click foreground tab`：Chromium 系没有官方策略能强制书签栏左键点击在新的前台标签页打开。Firefox、LibreWolf、Zen 可以做到。
- `Opera registry policy`：Opera 没有公开对应 Windows 企业策略，所以脚本用 Profile 偏好验证，不伪造策略。
- `Chrome NewTabPageLocation`：Chrome 在部分非托管设备上可能忽略 `NewTabPageLocation=about:blank`，需要在 `chrome://policy` 里确认。
- `LibreWolf profile root`：LibreWolf 尚未首次启动创建 Profile；策略文件仍然生效，首次启动后再运行一次优化脚本即可补 user.js。

## 推荐重装后流程

1. 关闭所有浏览器。
2. 以管理员身份打开 PowerShell 7。
3. 进入仓库根目录。
4. 运行优化脚本。
5. 分别启动一次每个浏览器，让它们创建 Profile。
6. 关闭所有浏览器。
7. 再运行一次优化脚本。
8. 运行详细验证，确认 `FAIL=0`。

命令：

```powershell
cd "C:\Users\Newby\Documents\浏览器优化\Browser-main"
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\OPTIMIZE_ALL_v14.25.ps1 -OnlyInstalled
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\Verify-BrowserOptimization.ps1 -RequireMachinePolicy -Detailed
```

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

官方资料整理见：

```text
docs/official-sources.md
```

排错文档见：

```text
docs/troubleshooting.md
```

历史说明和旧脚本背景见：

```text
zhubi.md
v14.1_修复说明.md
```

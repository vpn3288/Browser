# Multi-Browser Clean Optimizer

Windows 11 多浏览器清洁、隐私、安全和稳定性优化脚本。

支持 9 个浏览器：

- Google Chrome
- Chromium
- Microsoft Edge
- Brave
- Opera
- Vivaldi
- Mozilla Firefox
- LibreWolf
- Zen Browser

本项目只优化浏览器本身：关闭新闻、广告、促销、遥测、默认浏览器提示、后台运行和不必要的厂商功能；默认打开书签栏；主页和启动页设为 `about:blank`；修正扩展强制安装策略。脚本不增加启动器，也不处理代理、账号风控、流量伪装或绕过平台检测。

## 快速开始

以管理员身份打开 PowerShell，在仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\OPTIMIZE_ALL_v14.25.ps1
```

先看将要做什么，不写注册表、不改配置文件：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\OPTIMIZE_ALL_v14.25.ps1 -DryRun
```

只读取当前优化状态：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\Verify-BrowserOptimization.ps1
```

管理员级严格验证 HKLM 机器策略：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\Verify-BrowserOptimization.ps1 -RequireMachinePolicy
```

输出每个浏览器和每类优化项目的完整明细：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\deployment\Verify-BrowserOptimization.ps1 -RequireMachinePolicy -Detailed
```

## 参数

- `-DryRun`：只预览，不写入。
- `-UserOnly`：只写当前用户策略和用户配置，不写 HKLM。
- `-OnlyInstalled`：只处理检测到已安装的浏览器。
- `-ApplyProfilePreferences:$false`：只写官方策略，跳过直接编辑 Profile 偏好文件。
- `-ExtensionConfigPath <path>`：使用自定义扩展配置文件。

验证脚本支持 `-RequireMachinePolicy`、`-StrictProfilePreferences`、`-Detailed` 和 `-Quiet`。其中 `-Detailed` 会把所有验证项按浏览器和优化类别完整列出，适合重装或大版本升级后复查。

脚本在管理员 PowerShell 中会自动写 HKLM 机器策略；非管理员 PowerShell 中会跳过 HKLM，并尽量写 HKCU 和用户配置。
如果 Windows 权限拒绝写入 `HKCU\SOFTWARE\Policies`，请在管理员 PowerShell 里重新运行优化脚本。

## 优化内容

Chromium 系浏览器：

- 显示书签栏和主页按钮。
- 主页、新标签页和启动页设置为 `about:blank`。
- 关闭后台运行、默认浏览器提示、促销页、搜索建议、Privacy Sandbox 广告功能、遥测和反馈。
- 关闭 DoH 和 QUIC，避免绕过系统/本机网络栈造成不稳定。
- 保留安全浏览、硬件加速、登录、同步、密码管理、自动填充和翻译能力。
- Edge、Brave、Vivaldi 按品牌追加关闭首启体验、侧边栏、购物、奖励、新闻、钱包、VPN、Talk、P3A、Web Discovery 等功能。

Firefox 系浏览器：

- 写入 `distribution\policies.json`。
- 显示书签栏，主页和新标签页为空白。
- 关闭 Telemetry、Studies、Pocket、默认浏览器 Agent、赞助内容、Firefox Suggest 和用户消息推荐。
- 开启增强跟踪保护、加密挖矿/指纹跟踪防护。
- 保留登录、密码管理、表单历史、硬件加速和翻译能力。
- 书签点击通过官方偏好配置为在新的前台标签页打开。

Opera：

- Opera 没有公开与 Chrome/Edge 完全一致的 Windows 企业策略面，所以脚本不伪造 Opera 注册表策略。
- 通过可观察的 Profile 偏好关闭个性化广告/内容、后台模式，并设置书签栏、主页和启动页。

## 扩展配置

扩展强制安装只读取 [config/extensions.json](./config/extensions.json)。

默认示例扩展全部是 `enabled: false`，不会强制安装任何扩展。需要安装时，先填入真实扩展 ID、正确 update URL 或 XPI 安装 URL，再把对应条目改为 `enabled: true`。

Chromium Web Store：

```text
https://clients2.google.com/service/update2/crx
```

Microsoft Edge Add-ons：

```text
https://edge.microsoft.com/extensionwebstorebase/v1/crx
```

Firefox 系：

```text
https://addons.mozilla.org/firefox/downloads/latest/<addon>/latest.xpi
```

## 已知限制

- Chromium 系浏览器没有官方策略可以强制原生书签栏左键点击在新的前台标签页打开。脚本会明确报告这个限制，不会假装已实现。
- Chrome 的 `NewTabPageLocation=about:blank` 在某些非托管 Windows 环境可能被忽略，需要在 `chrome://policy` 里确认。
- 正在运行的浏览器 Profile 文件不会被直接编辑，请关闭浏览器后重新运行。
- 如果现有 `Preferences` 或 `Local State` JSON 已损坏，脚本会跳过该文件，避免覆盖原有状态。
- Codex 当前进程如果不是管理员，就不能自动控制已经打开的管理员 PowerShell 窗口；需要在管理员窗口里直接运行上面的命令。

## 官方依据

见 [docs/official-sources.md](./docs/official-sources.md)。

排错见 [docs/troubleshooting.md](./docs/troubleshooting.md)。

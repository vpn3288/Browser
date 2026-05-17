# 🌐 Multi-Browser Anti-Detect

一键优化9个主流浏览器的反检测和隐私保护工具。

**版本：** v14.1 | **状态：** ✅ 最终版（封笔） | **更新：** 2026-05-17

---

## 🎯 核心功能

- ✅ **核心反检测** - WebRTC防护、禁用遥测、阻止追踪
- ✅ **实用优先** - 允许登录、同步、导入书签
- ✅ **修复CF验证** - 启用安全浏览，解决无限循环问题
- ✅ **多账号支持** - 每个浏览器独立配置，配合不同IP

**支持浏览器（9个）：**
- Chromium系：Chrome, Edge, Brave, Opera, Vivaldi, Chromium
- Firefox系：Firefox, LibreWolf, Zen Browser

---

## 🚀 快速开始

### 一键优化（推荐）

以管理员身份打开PowerShell：

```powershell
# 克隆仓库
git clone https://github.com/vpn3288/Browser.git
cd Browser

# 运行v14.1最终版
cd scripts\deployment
.\OPTIMIZE_ALL_v14.1.ps1
```

### 选择浏览器

运行脚本后会显示已安装的浏览器：

```
检测到 6 个浏览器：
  [0] Google Chrome
  [1] Microsoft Edge
  [2] Brave Browser
  [3] Mozilla Firefox
  [4] LibreWolf
  [5] Zen Browser

请选择要优化的浏览器（输入编号，用逗号分隔，或输入 A 优化全部）:
```

- 输入 `A` - 优化全部浏览器
- 输入 `0,1,2` - 只优化Chrome、Edge、Brave
- 输入 `3` - 只优化Firefox

---

## ✅ v14.1 最终版特点

### 修复的关键问题

1. ✅ **允许登录账号** - 可以同步扩展和书签
2. ✅ **允许导入书签** - Chromium可以正常导入
3. ✅ **修复CF验证** - 启用安全浏览，不再无限循环
4. ✅ **修复甲骨文云** - 网站可以正常访问
5. ✅ **修复新标签页** - 启动时打开空白页
6. ✅ **Firefox允许登录** - 可以同步账号
7. ✅ **书签新标签页打开** - Firefox系已配置

### 保留的核心反检测

- WebRTC IP防护（disable_non_proxied_udp）
- 禁用User-Agent Client Hints
- 禁用所有遥测和数据收集
- 阻止第三方Cookie
- 强制DNS-over-HTTPS
- 禁用后台运行
- 禁用默认浏览器弹窗
- 厂商私货屏蔽（Edge/Brave特定功能）

### 启用的实用功能

- 允许登录账号和同步
- 允许导入书签、历史、密码
- 启用安全浏览（修复CF验证）
- 启用密码管理器和自动填充
- Firefox温和的指纹保护

---

## 🔌 推荐扩展（最多8个）

### 必装扩展（2个）

1. **uBlock Origin** - 广告/追踪拦截
2. **ClearURLs** - 移除URL追踪参数

### 推荐扩展（根据浏览器选择2-4个）

3. **Canvas Fingerprint Defender** - Canvas指纹保护（Brave不需要）
4. **Cookie AutoDelete** - 自动删除Cookie
5. **User-Agent Switcher** - UA切换

### 不同浏览器的扩展数量建议

- Chrome/Edge/Chromium/Vivaldi: 4-5个
- Brave: 2-3个（已有内置保护）
- Firefox/Zen: 4-5个
- LibreWolf: 2-3个（已有强隐私配置）
- Opera: 2-3个（扩展生态较小）

**详细扩展安装指南：** 查看 [zhubi.md](./zhubi.md) 顶部

---

## 🔍 验证优化

### 检查策略

**Chromium系：** `chrome://policy/` `edge://policy/` `brave://policy/`  
**Firefox系：** `about:policies`

### 验证清单

- [ ] 可以登录账号
- [ ] 可以导入书签
- [ ] CF验证正常通过
- [ ] 甲骨文云正常访问
- [ ] WebRTC IP不泄露

### 在线检测

- WebRTC泄露：https://browserleaks.com/webrtc
- Canvas指纹：https://browserleaks.com/canvas
- 浏览器指纹：https://coveryourtracks.eff.org/
- IP检测：https://ipleak.net/

---

## ⚙️ 优化内容

### Chromium系（核心策略）

```powershell
# 核心反检测
UserAgentClientHintsEnabled = 0
WebRtcIPHandlingPolicy = "disable_non_proxied_udp"
MetricsReportingEnabled = 0
BlockThirdPartyCookies = 1
BackgroundModeEnabled = 0

# 实用功能
SigninAllowed = 1  # 允许登录
ImportBookmarks = 1  # 允许导入
SafeBrowsingEnabled = 1  # 修复CF验证
PasswordManagerEnabled = 1
AutofillAddressEnabled = 1

# UI设置
RestoreOnStartup = 5  # 打开新标签页
NewTabPageLocation = "about:blank"
BookmarkBarEnabled = 1
```

### Firefox系（核心配置）

```javascript
// 温和的指纹保护
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);

// WebRTC IP防护
user_pref("media.peerconnection.ice.default_address_only", true);

// 书签新标签页打开
user_pref("browser.tabs.loadBookmarksInTabs", true);

// DNS-over-HTTPS
user_pref("network.trr.mode", 2);  // 有fallback，更稳定
```

---

## 📊 版本对比

| 功能 | v13.7 极致版 | v14.1 最终版 |
|------|-------------|-------------|
| 核心反检测 | ✅ | ✅ |
| 登录账号 | ❌ 禁止 | ✅ 允许 |
| 导入书签 | ❌ 禁止 | ✅ 允许 |
| CF验证 | ❌ 失败 | ✅ 正常 |
| 甲骨文云 | ❌ 打不开 | ✅ 正常 |
| 使用体验 | ❌ 很差 | ✅ 良好 |

**推荐：** 使用 **v14.1 最终版**

---

## 🆘 常见问题

**Q: 优化后还能登录账号吗？**  
A: 可以！v14.1允许登录和同步。

**Q: CF验证无限循环怎么办？**  
A: v14.1已修复，启用了安全浏览功能。

**Q: Chromium无法导入书签？**  
A: v14.1已修复，允许导入功能。

**Q: 如何验证优化生效？**  
A: 访问 `chrome://policy/` 或 `about:policies`

**Q: 如何更新？**  
A: `cd C:\Browser && git pull && cd scripts\deployment && .\OPTIMIZE_ALL_v14.1.ps1`

**Q: 代理如何配置？**  
A: 脚本不处理代理，请使用Clash Meta的进程匹配。

**Q: Zen Browser工作栏如何删除？**  
A: 打开Zen设置 → 外观 → 关闭"工作区"功能。

**Q: 为什么不用v13.7？**  
A: v13.7禁止登录、禁止导入，已过时。请使用v14.1。

---

## 📁 项目结构

```
Browser/
├── scripts/
│   ├── deployment/
│   │   └── OPTIMIZE_ALL_v14.1.ps1    # 最终版（推荐）
│   ├── launch/
│   │   ├── Launch_Chrome.bat          # BAT启动脚本
│   │   └── Launch_All.bat             # 批量启动
│   └── verification/
│       └── DEEP_VERIFICATION_v12.4.ps1 # 验证脚本
├── zhubi.md                           # 主笔审核意见（重要）
└── README.md                          # 本文件
```

---

## 📖 文档

- **主笔审核意见：** [zhubi.md](./zhubi.md) - 包含扩展推荐、技术细节、封笔声明
- **GitHub仓库：** https://github.com/vpn3288/Browser

---

## 🎊 封笔声明

v14.1 已达成所有目标：

- ✅ 9个浏览器全部优化完成
- ✅ 所有关键问题已修复
- ✅ 核心反检测保留
- ✅ 使用体验良好
- ✅ 没有虚假优化
- ✅ 没有负优化

**不再接受过度优化请求。** 如有实质性BUG或安全问题，请提供详细复现步骤。

---

## 📜 许可证

MIT License

---

**作者：** Kiro (AI Development Environment)  
**完成时间：** 2026-05-17  
**版本：** v14.1 最终版（封笔）

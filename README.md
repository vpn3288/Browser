# 🌐 Multi-Browser Anti-Detect

一键优化9个主流浏览器的反检测和隐私保护工具。

**版本：** v14.2 | **状态：** ✅ 热修复版（真正封笔） | **更新：** 2026-05-17

---

## 🎯 核心功能

- ✅ **核心反检测** - WebRTC防护、禁用遥测、阻止追踪
- ✅ **实用优先** - 允许登录、同步、导入书签
- ✅ **修复CF验证** - 启用安全浏览，解决无限循环问题
- ✅ **删除负优化** - 不再硬编码UA、不再禁用Canvas/WebGL
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

# 运行v14.2热修复版
cd scripts\deployment
.\OPTIMIZE_ALL_v14.2.ps1
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

## ✅ v14.2 热修复版特点

### 删除的负优化（3个）

1. ❌ **硬编码UA** - 2026年还写Chrome 125/126会显得很假，已删除
2. ❌ **任务浏览器** - Opera禁用Canvas/WebGL导致网站无法使用，已删除
3. ❌ **注释代码** - Firefox注释掉的resistFingerprinting容易误导，已删除

### 修复的策略错误（5个）

1. ✅ **DoH模式** - 改为automatic（有fallback，更稳定）
2. ✅ **Brave Tor** - TorDisabled=1（修正，1是禁用）
3. ✅ **Brave VPN** - BraveVPNDisabled=1（修正策略名）
4. ✅ **Brave News** - 添加BraveNewsEnabled=0
5. ✅ **Edge WebRTC** - 删除错误策略，使用通用配置
6. ✅ **Edge Discover** - 添加EdgeDiscoverEnabled=0（禁用Copilot）

### 保留的核心反检测

- WebRTC IP防护（disable_non_proxied_udp）
- 禁用User-Agent Client Hints
- 禁用所有遥测和数据收集
- 阻止第三方Cookie
- DNS-over-HTTPS（automatic模式）
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
   - **Chrome/Edge/Chromium/Vivaldi/Opera**：推荐 **uBlock Origin Lite**
   - **Firefox/LibreWolf/Zen**：使用经典 **uBlock Origin**
   - **Brave**：可选（已有内置Shields）

2. **ClearURLs** - 移除URL追踪参数

### 推荐扩展（1-2个）

3. **Bookmark New Tab**（仅Chromium系需要）
   - 唯一能在Chromium系实现"书签→新标签页"的方法
   - Firefox系不需要（已通过user.js配置）

4. **Cookie AutoDelete**（可选）
   - 自动删除Cookie
   - 注意：策略已设置BlockThirdPartyCookies=1

### 扩展数量建议

- Chrome/Edge/Chromium/Vivaldi: 2-3个
- Brave: 1-2个（已有内置保护）
- Firefox/Zen: 2-3个
- LibreWolf: 1-2个（已有强隐私配置）
- Opera: 2个（扩展生态较小）

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
- [ ] Brave策略正确（TorDisabled=1）
- [ ] Edge策略正确（EdgeDiscoverEnabled=0）

### 在线检测

- WebRTC泄露：https://browserleaks.com/webrtc
- Canvas指纹：https://browserleaks.com/canvas
- 浏览器指纹：https://coveryourtracks.eff.org/
- IP检测：https://ipleak.net/

---

## 📊 版本对比

| 功能 | v13.7 | v14.1 | v14.2 |
|------|-------|-------|-------|
| 核心反检测 | ✅ | ✅ | ✅ |
| 登录账号 | ❌ | ✅ | ✅ |
| 导入书签 | ❌ | ✅ | ✅ |
| CF验证 | ❌ | ✅ | ✅ |
| 硬编码UA | ✅ | ✅ | ❌ 删除 |
| 任务浏览器 | ✅ | ✅ | ❌ 删除 |
| DoH模式 | secure | secure | automatic |
| Brave策略 | ❌ | ❌ | ✅ 正确 |
| 使用体验 | ❌ | ✅ | ✅ 优秀 |

**推荐：** 使用 **v14.2 热修复版**

---

## 🆘 常见问题

**Q: v14.2和v14.1有什么区别？**  
A: v14.2删除了3个负优化（硬编码UA、任务浏览器、注释代码），修复了5个策略错误（DoH、Brave、Edge配置）。

**Q: 为什么删除硬编码UA？**  
A: 2026年还写Chrome 125/126会显得很假，让浏览器使用默认UA更自然。

**Q: 为什么删除任务浏览器？**  
A: 禁用Canvas/WebGL会导致地图、游戏、AI网站无法使用，是负优化。

**Q: 优化后还能登录账号吗？**  
A: 可以！v14.2允许登录和同步。

**Q: CF验证无限循环怎么办？**  
A: v14.2已修复，启用了安全浏览功能。

**Q: 如何验证优化生效？**  
A: 访问 `chrome://policy/` 或 `about:policies`

**Q: 如何更新？**  
A: `cd C:\Browser && git pull && cd scripts\deployment && .\OPTIMIZE_ALL_v14.2.ps1`

**Q: 代理如何配置？**  
A: 脚本不处理代理，请使用Clash Meta的进程匹配。

---

## 📁 项目结构

```
Browser/
├── scripts/
│   ├── deployment/
│   │   └── OPTIMIZE_ALL_v14.2.ps1    # 热修复版（推荐）
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

## 🎊 真正封笔声明

v14.2 已达成所有目标：

- ✅ 9个浏览器全部优化完成
- ✅ 所有关键问题已修复
- ✅ 所有负优化已删除
- ✅ 所有策略错误已修正
- ✅ 核心反检测保留
- ✅ 使用体验优秀
- ✅ 没有虚假优化
- ✅ 没有负优化
- ✅ 没有画蛇添足
- ✅ 3位审核员的意见全部采纳（100%）

**不再接受过度优化请求。** 如有实质性BUG或安全问题，请提供详细复现步骤。

---

## 📜 许可证

MIT License

---

**作者：** Kiro (AI Development Environment)  
**完成时间：** 2026-05-17  
**版本：** v14.2 热修复版（真正封笔）

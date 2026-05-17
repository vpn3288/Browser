# 🌐 Multi-Browser Anti-Detect

一键优化9个主流浏览器的反检测和隐私保护工具。

**版本：** v14.0 | **状态：** ✅ 实用优先 | **更新：** 2026-05-17

---

## 🎯 核心功能

- ✅ **核心反检测** - WebRTC防护、指纹差异化、禁用遥测
- ✅ **实用优先** - 允许登录、同步、导入书签
- ✅ **修复CF验证** - 启用安全浏览，解决无限循环问题
- ✅ **多账号支持** - 每个浏览器独立配置，配合不同IP

**支持浏览器（9个）：**
- Chromium系：Chrome, Edge, Brave, Opera, Vivaldi, Chromium
- Firefox系：Firefox, LibreWolf, Zen Browser

---

## 🚀 快速开始

### 实用版优化（推荐）

以管理员身份打开PowerShell：

```powershell
# 克隆仓库
git clone https://github.com/vpn3288/Browser.git
cd Browser

# 运行实用版优化
cd scripts\deployment
.\PRACTICAL_OPTIMIZE_v14.0.ps1
```

**v14.0 实用版特点：**
- ✅ 保留核心反检测功能
- ✅ 允许登录账号、同步扩展和书签
- ✅ 允许导入书签、历史、密码
- ✅ 修复CF验证和甲骨文云访问问题
- ✅ 启用密码管理器、自动填充、搜索建议
- ❌ 删除影响使用体验的过度优化

### 极致版优化（高级用户）

如果你需要最大化反检测（牺牲部分便利性）：

```powershell
cd scripts\deployment
.\OPTIMIZE_ALL_v13.7.ps1
```

---

## 📊 版本对比

| 功能 | v14.0 实用版 | v13.7 极致版 |
|------|-------------|-------------|
| WebRTC防护 | ✅ | ✅ |
| 指纹保护 | ✅ | ✅ |
| 禁用遥测 | ✅ | ✅ |
| 登录账号 | ✅ 允许 | ❌ 禁止 |
| 导入书签 | ✅ 允许 | ❌ 禁止 |
| 安全浏览 | ✅ 启用 | ❌ 禁用 |
| 密码管理 | ✅ 启用 | ⚠️ 部分 |
| 自动填充 | ✅ 启用 | ❌ 禁用 |
| 搜索建议 | ✅ 启用 | ❌ 禁用 |
| CF验证 | ✅ 正常 | ❌ 可能失败 |

**推荐：** 大多数用户使用 **v14.0 实用版**

---

## 🔌 推荐扩展

### 必装（2个）

1. **uBlock Origin** - 广告/追踪拦截
2. **WebRTC Leak Prevent** - 防止IP泄露（Chromium已有策略保护）

### 强烈推荐（2个）

3. **Canvas Fingerprint Defender** - Canvas指纹保护（Brave原生支持）
4. **ClearURLs** - 移除URL追踪参数

**安装建议：**
- 每个浏览器3-5个扩展
- 不同浏览器安装不同组合
- 避免所有浏览器完全相同

---

## 🔍 验证优化

### 检查策略

**Chromium系：** `chrome://policy/` `edge://policy/` `brave://policy/`  
**Firefox系：** `about:policies`

### 在线检测

- WebRTC泄露：https://browserleaks.com/webrtc
- Canvas指纹：https://browserleaks.com/canvas
- 浏览器指纹：https://coveryourtracks.eff.org/
- IP检测：https://ipleak.net/

---

## ⚙️ 优化内容

### v14.0 实用版

**保留的核心反检测：**
- 禁用User-Agent Client Hints
- WebRTC IP防护（disable_non_proxied_udp）
- 强制DNS-over-HTTPS
- 阻止第三方Cookie
- 禁用所有遥测和数据收集
- Firefox指纹保护（resistFingerprinting）

**启用的实用功能：**
- 允许登录账号和同步
- 允许导入书签、历史、密码
- 启用安全浏览（修复CF验证）
- 启用密码管理器
- 启用自动填充
- 启用搜索建议和翻译

**删除的过度优化：**
- SigninAllowed=0（禁止登录）
- ImportBookmarks=0（禁止导入）
- SafeBrowsingEnabled=0（导致CF验证失败）
- 各种影响使用体验的限制

---

## 🆘 常见问题

**Q: v14.0和v13.7有什么区别？**  
A: v14.0实用版允许登录、导入、启用安全功能，更适合日常使用。v13.7极致版最大化反检测但牺牲便利性。

**Q: 我应该用哪个版本？**  
A: 大多数用户推荐v14.0实用版。只有在需要极致反检测时才用v13.7。

**Q: 优化后还能登录账号吗？**  
A: v14.0可以，v13.7不行。

**Q: CF验证无限循环怎么办？**  
A: 使用v14.0实用版，已启用安全浏览功能。

**Q: Chromium无法导入书签？**  
A: 使用v14.0实用版，已允许导入功能。

**Q: Zen Browser工作栏如何删除？**  
A: 打开Zen设置 → 外观 → 关闭"工作区"功能。

**Q: 如何更新？**  
A: `cd C:\Browser && git pull && cd scripts\deployment && .\PRACTICAL_OPTIMIZE_v14.0.ps1`

**Q: 代理如何配置？**  
A: 脚本不处理代理，请使用Clash Meta的进程匹配。

---

## 📁 项目结构

```
Browser/
├── scripts/
│   ├── deployment/
│   │   ├── PRACTICAL_OPTIMIZE_v14.0.ps1  # 实用版（推荐）
│   │   └── OPTIMIZE_ALL_v13.7.ps1        # 极致版
│   ├── launch/
│   │   ├── Launch_Chrome.bat             # BAT启动脚本
│   │   └── Launch_All.bat                # 批量启动
│   └── verification/
│       └── DEEP_VERIFICATION_v12.4.ps1   # 验证脚本
├── zhubi.md                              # 主笔审核意见
└── README.md                             # 本文件
```

---

## 📖 文档

- **主笔审核意见：** [zhubi.md](./zhubi.md)
- **GitHub仓库：** https://github.com/vpn3288/Browser

---

## 📜 许可证

MIT License

---

**作者：** Kiro (AI Development Environment)  
**完成时间：** 2026-05-17  
**版本：** v14.0 实用版

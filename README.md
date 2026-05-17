# 🌐 Multi-Browser Anti-Detect

一键优化9个主流浏览器的反检测和隐私保护工具。

**版本：** v14.4 | **状态：** ✅ 彻底删除启动器（真正封笔） | **更新：** 2026-05-17

---

## 🎯 核心功能

- ✅ **核心反检测** - WebRTC防护、禁用遥测、阻止追踪
- ✅ **实用优先** - 允许登录、同步、导入书签
- ✅ **修复CF验证** - 启用安全浏览，解决无限循环问题
- ✅ **不依赖启动器** - 完全基于注册表策略和配置文件
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

# 运行v14.4彻底删除启动器版
cd scripts\deployment
.\OPTIMIZE_ALL_v14.4.ps1
```

### 选择浏览器

运行脚本后会显示已安装的浏览器，选择要优化的浏览器即可。

**优化完成后，直接使用浏览器原生快捷方式启动，不需要任何启动器。**

---

## ✅ v14.4 彻底删除启动器版特点

### 用户反馈
> "不要启动器了。不然后面的优化还围着启动器来。我不喜欢使用启动器"

v14.4 **彻底删除所有启动器相关功能**。

### 删除的启动器功能（2个）

1. ❌ **BAT启动脚本** - 已在v14.3删除
2. ❌ **桌面启动器** - v14.4删除（70行）
3. ❌ **启动器提示** - v14.4删除

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

---

## 🔌 推荐扩展（最多8个）

### 必装扩展（2个）

1. **uBlock Origin** (Lite for Chromium) - 广告/追踪拦截
2. **ClearURLs** - 移除URL追踪参数

### 推荐扩展（1-2个）

3. **Bookmark New Tab**（仅Chromium系）- 书签新标签页打开
4. **Cookie AutoDelete**（可选）- 自动删除Cookie

**详细扩展安装指南：** 查看 [zhubi.md](./zhubi.md)

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

## 📊 版本对比

| 功能 | v14.3 | v14.4 |
|------|-------|-------|
| 核心反检测 | ✅ | ✅ |
| 登录账号 | ✅ | ✅ |
| BAT启动脚本 | ❌ | ❌ |
| 桌面启动器 | ✅ | ❌ 删除 |
| 文件大小 | 826行 | 727行 |

**推荐：** 使用 **v14.4 彻底删除启动器版**

---

## 🆘 常见问题

**Q: v14.4和v14.3有什么区别？**  
A: v14.4彻底删除了桌面启动器创建功能，完全不依赖启动器。

**Q: 优化后如何启动浏览器？**  
A: 直接使用浏览器原生快捷方式，不需要任何启动器。

**Q: 优化后还能登录账号吗？**  
A: 可以！v14.4允许登录和同步。

**Q: CF验证无限循环怎么办？**  
A: v14.4已修复，启用了安全浏览功能。

**Q: 如何验证优化生效？**  
A: 访问 `chrome://policy/` 或 `about:policies`

**Q: 如何更新？**  
A: `cd C:\Browser && git pull && cd scripts\deployment && .\OPTIMIZE_ALL_v14.4.ps1`

**Q: 代理如何配置？**  
A: 脚本不处理代理，请使用Clash Meta的进程匹配。

---

## 📁 项目结构

```
Browser/
├── scripts/
│   └── deployment/
│       └── OPTIMIZE_ALL_v14.4.ps1    # 彻底删除启动器版（推荐）
├── zhubi.md                           # 主笔审核意见（重要）
└── README.md                          # 本文件
```

---

## 📖 文档

- **主笔审核意见：** [zhubi.md](./zhubi.md) - 包含扩展推荐、技术细节、封笔声明
- **GitHub仓库：** https://github.com/vpn3288/Browser

---

## 🎊 真正封笔声明

v14.4 已达成所有目标：

- ✅ 9个浏览器全部优化完成
- ✅ 所有关键问题已修复
- ✅ 所有负优化已删除
- ✅ 所有启动器功能已删除
- ✅ 核心反检测保留
- ✅ 使用体验优秀
- ✅ 100%采纳用户反馈

**不再接受任何优化请求。** 如有实质性BUG或安全问题，请提供详细复现步骤。

---

## 📜 许可证

MIT License

---

**作者：** Kiro (AI Development Environment)  
**完成时间：** 2026-05-17  
**版本：** v14.4 彻底删除启动器版（真正封笔）

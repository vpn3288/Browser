# 🌐 Multi-Browser Anti-Detect

一键优化9个主流浏览器的反检测和隐私保护工具。

**版本：** v14.5 | **状态：** ✅ 最终修复版（真正封笔） | **更新：** 2026-05-17

---

## 🎯 核心功能

- ✅ **核心反检测** - WebRTC防护、禁用遥测、阻止追踪
- ✅ **删除负优化** - v14.5删除7个负优化策略
- ✅ **修正策略名** - v14.5修正4个策略错误
- ✅ **统一语言** - 全部使用en-US（正常美国人）
- ✅ **实用优先** - 允许登录、同步、导入书签
- ✅ **不依赖启动器** - 完全基于注册表策略和配置文件

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

# 运行v14.5最终修复版
cd scripts\deployment
.\OPTIMIZE_ALL_v14.5.ps1
```

### 选择浏览器

运行脚本后会显示已安装的浏览器，选择要优化的浏览器即可。

**优化完成后，直接使用浏览器原生快捷方式启动，不需要任何启动器。**

---

## ✅ v14.5 最终修复版特点

### 审核员反馈

3位审核员（claude-opus-4-7）提出25个问题，主笔**100%采纳**所有意见。

### 删除的负优化（7个）

1. ❌ **UserAgentClientHintsEnabled=0** - 虚假优化，暴露浏览器被修改
2. ❌ **UserAgentClientHintsGREASEUpdateEnabled=0** - 同上
3. ❌ **NetworkPredictionOptions=2** - 负优化，牺牲速度
4. ❌ **CloudPrintSubmitEnabled=0** - 虚假优化（服务已关闭）
5. ❌ **BuiltInDnsClientEnabled=0** - 与DoH冲突
6. ❌ **geo.provider.network.url=""** (Firefox) - 破坏地理位置功能
7. ❌ **network.http.referer.XOriginPolicy=2** (Firefox) - 破坏登录/支付/SSO

### 修正的策略（4个）

1. ✅ **WebRTC策略名** - `WebRtcIPHandlingPolicy` → `WebRtcIPHandling` (Chrome) + `WebRtcLocalhostIpHandling` (Edge)
2. ✅ **MediaRouter策略名** - `MediaRouterEnabled` → `EnableMediaRouter`
3. ✅ **删除SpellcheckLanguage** - 已禁用拼写检查，冗余
4. ✅ **添加DontCheckDefaultBrowser** - Firefox禁用默认浏览器检查

### 语言配置统一

- **v14.4**：简繁混合（zh-CN/zh-TW）
- **v14.5**：全部en-US（正常美国人）

### 保留的核心反检测

- WebRTC IP防护（修正策略名）
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

1. **uBlock Origin Lite** (Chromium系)
   - Chrome/Edge/Brave/Vivaldi/Chromium
   - 广告/追踪拦截（Manifest V3）

2. **uBlock Origin** (Firefox系 + Opera)
   - Firefox/LibreWolf/Zen/Opera
   - 广告/追踪拦截（经典版）

### 推荐扩展（可选）

3. **ClearURLs** (仅Firefox系)
   - 移除URL追踪参数
   - ⚠️ Chromium系不推荐（商店环境不稳定）

4. **Bookmark Sidebar** (仅Chromium系可选)
   - 书签新标签页打开
   - ⚠️ 可能改变书签行为

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
- [ ] 浏览器语言为en-US

### 在线检测

- WebRTC泄露：https://browserleaks.com/webrtc
- Canvas指纹：https://browserleaks.com/canvas
- 浏览器指纹：https://coveryourtracks.eff.org/
- IP检测：https://ipleak.net/

---

## 📊 版本对比

| 功能 | v14.4 | v14.5 |
|------|-------|-------|
| 核心反检测 | ✅ | ✅ |
| 负优化策略 | ✅ 有7个 | ❌ 已删除 |
| WebRTC策略名 | ❌ 错误 | ✅ 正确 |
| 语言配置 | 简繁混合 | 全部en-US |
| Chromium检测 | ⚠️ 可能误判 | ✅ 已修正 |
| Firefox负优化 | ✅ 有2个 | ❌ 已删除 |

**推荐：** 使用 **v14.5 最终修复版**

---

## 🆘 常见问题

**Q: v14.5和v14.4有什么区别？**  
A: v14.5删除了7个负优化策略、修正了4个策略名、统一了语言配置为en-US。

**Q: 为什么删除UserAgentClientHintsEnabled=0？**  
A: 100%的真实Chrome用户都发送UA Client Hints，禁用反而暴露浏览器被修改。

**Q: 为什么删除NetworkPredictionOptions=2？**  
A: 完全禁用网络预测会显著降低页面加载速度，与用户要求的"高速"矛盾。

**Q: 为什么语言改为en-US？**  
A: 用户目标是"在任何网站和游戏里的审查中，我都是一个正常的美国人"。简繁混合反而更可疑。

**Q: 优化后还能登录账号吗？**  
A: 可以！v14.5允许登录和同步。

**Q: CF验证无限循环怎么办？**  
A: v14.5已修复，启用了安全浏览功能。

**Q: 如何验证优化生效？**  
A: 访问 `chrome://policy/` 或 `about:policies`

**Q: 如何更新？**  
A: `cd C:\Browser && git pull && cd scripts\deployment && .\OPTIMIZE_ALL_v14.5.ps1`

**Q: 代理如何配置？**  
A: 脚本不处理代理，请使用Clash Meta的进程匹配。

---

## 📁 项目结构

```
Browser/
├── scripts/
│   └── deployment/
│       └── OPTIMIZE_ALL_v14.5.ps1    # 最终修复版（推荐）
├── zhubi.md                           # 主笔审核意见（重要）
└── README.md                          # 本文件
```

---

## 📖 文档

- **主笔审核意见：** [zhubi.md](./zhubi.md) - 包含扩展推荐、技术细节、审核员反馈采纳记录
- **GitHub仓库：** https://github.com/vpn3288/Browser

---

## 🎊 真正封笔声明

v14.5 已达成所有目标：

- ✅ 9个浏览器全部优化完成
- ✅ 所有关键问题已修复
- ✅ 所有负优化已删除（v14.5删除7个）
- ✅ 所有策略名已修正（v14.5修正4个）
- ✅ 所有启动器功能已删除
- ✅ 核心反检测保留
- ✅ 使用体验优秀
- ✅ 100%采纳审核员反馈

**不再接受任何优化请求。** 如有实质性BUG或安全问题，请提供详细复现步骤。

---

## 📜 许可证

MIT License

---

**作者：** Kiro (AI Development Environment)  
**完成时间：** 2026-05-17  
**版本：** v14.5 最终修复版（真正封笔）

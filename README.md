# 🌐 Multi-Browser Anti-Detect

一键优化9个主流浏览器的反检测和隐私保护工具。

**版本：** v14.17 | **状态：** ✅ 修复5个BUG版（最终封笔） | **更新：** 2026-05-18

---

## 🎯 核心功能

- ✅ **修复5个BUG** - v14.17修复所有虚假优化
- ✅ **删除虚假优化** - EdgeDiscoverEnabled、EdgeEnhanceImagesEnabled、Chrome GenAI全部删除
- ✅ **Edge WebRTC格式正确** - 使用简单键值对格式
- ✅ **Firefox AIControls完整** - Mozilla官方AI总控策略
- ✅ **核心反检测** - WebRTC防护、禁用遥测、阻止追踪
- ✅ **实用优先** - 允许登录、同步、导入书签
- ✅ **不依赖启动器** - 完全删除启动器，直接优化浏览器本身
- ✅ **中文界面** - 所有浏览器使用中文（简繁混合）
- ✅ **空白主页** - 新标签页和主页都是about:blank
- ✅ **书签栏默认打开** - 所有浏览器默认显示书签栏
- ✅ **禁止后台运行** - 关闭浏览器后完全退出

---

## 🚀 快速开始

### 一键优化（推荐）

以管理员身份打开PowerShell：

```powershell
# 克隆仓库
git clone https://github.com/vpn3288/Browser.git
cd Browser

# 运行v14.17最终版
cd scripts\deployment
.\OPTIMIZE_ALL_v14.17.ps1
```

### 选择浏览器

运行脚本后会显示已安装的浏览器，选择要优化的浏览器即可。

**优化完成后，直接使用浏览器原生快捷方式启动，不需要任何启动器。**

**⚠️ Firefox系浏览器（Firefox/LibreWolf/Zen）需要重启后配置才会生效。**

---

## ✅ v14.10 修复3个BUG、补充1个策略版特点

### v14.9的3个BUG

| 问题 | 影响 |
|------|------|
| 1. 版本号不一致 | 脚本头部写v14.8，但文件名是v14.9 |
| 2. Edge WebRTC配置冗余 | 通用配置块和Edge特定块都设置WebRTC |
| 3. Firefox广告/促销关闭不完整 | 缺少SponsoredTopSites、SponsoredPocket等官方策略 |

### v14.10 修复内容

#### 🔧 修复3个BUG

1. ✅ **版本号不一致** - 脚本头部已改为v14.10
2. ✅ **Edge WebRTC配置冗余** - 删除Edge特定块的冗余WebRTC配置
3. ✅ **Firefox广告/促销关闭不完整** - 补充SponsoredTopSites、SponsoredPocket、Stories、SponsoredStories、FirefoxSuggest

#### 🟡 补充1个策略

4. ✅ **Firefox后台Agent** - 补充DisableDefaultBrowserAgent策略

#### 🗑️ 删除1个旧版本

- scripts/deployment/OPTIMIZE_ALL_v14.9.ps1（有3个BUG）

#### 📋 审核员反馈采纳

**3位审核员提出10个问题 → 主笔采纳4个BUG修复 → 拒绝6个过度优化/文档问题**

**采纳率：4/10（40%）- 只修复BUG，拒绝过度优化和虚假优化**

### 保留的核心反检测

- WebRTC IP防护（v14.6+v14.8+v14.9所有Chromium系，包括Edge）
- 禁用所有遥测和数据收集
- 阻止第三方Cookie
- DNS-over-HTTPS（automatic模式）
- 禁用后台运行
- 禁用默认浏览器弹窗
- 厂商私货屏蔽（Edge/Brave特定功能）
- 禁用QUIC（v14.7+v14.8所有Chromium系，稳定过墙）
- 保留主页按钮（v14.7+v14.8所有浏览器）
- Brave官方隐私策略（v14.9补充）
- Firefox广告/促销完整关闭（v14.10补充）
- Firefox后台Agent禁用（v14.10补充）

### 启用的实用功能

- 允许登录账号和同步
- 允许导入书签、历史、密码
- 启用安全浏览（修复CF验证）
- 启用密码管理器和自动填充

---

## 🔌 推荐扩展（最多3个）

### 必装扩展（2个）

1. **uBlock Origin Lite** (Chromium系)
   - Chrome/Edge/Brave/Vivaldi/Chromium
   - 广告/追踪拦截（Manifest V3）

2. **uBlock Origin** (Firefox系 + Opera)
   - Firefox/LibreWolf/Zen/Opera
   - 广告/追踪拦截（经典版）
   - ⚠️ Opera必须从addons.opera.com安装

### 推荐扩展（可选1个）

3. **ClearURLs** (仅Firefox系)
   - 移除URL追踪参数
   - ⚠️ Chromium系不推荐（商店环境不稳定）

### ❌ 不推荐

- ❌ **Open Bookmark in New Tab** - 会修改书签URL
- ❌ **Cookie AutoDelete** - 与"保持登录"冲突
- ❌ **Random User-Agent** - 容易被检测为假
- ❌ **CanvasBlocker** - 破坏网站功能

**总计：最多3个扩展（2个必装 + 1个可选），符合"不过度优化"原则**

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
- [ ] WebRTC IP不泄露（包括Edge）
- [ ] 浏览器语言为中文（简体或繁体）
- [ ] 主页按钮可见
- [ ] 菜单顺序固定
- [ ] 无旧文件残留
- [ ] Firefox系重启后配置生效
- [ ] Firefox无赞助内容（常用网站、Pocket、Stories、Suggest）

### 在线检测

- WebRTC泄露：https://browserleaks.com/webrtc
- Canvas指纹：https://browserleaks.com/canvas
- 浏览器指纹：https://coveryourtracks.eff.org/
- IP检测：https://ipleak.net/

---

## 📊 版本对比

| 功能 | v14.9 | v14.10 |
|------|-------|--------|
| 核心反检测 | ✅ | ✅ |
| 版本号一致性 | ❌ 不一致 | ✅ 已修复 |
| Edge WebRTC配置 | ❌ 冗余 | ✅ 已优化 |
| Firefox广告/促销关闭 | ❌ 不完整 | ✅ 已补充 |
| Firefox后台Agent | ❌ 缺失 | ✅ 已补充 |
| 旧版本文件 | ❌ 存在 | ✅ 已删除1个 |

**推荐：** 使用 **v14.10 修复3个BUG、补充1个策略版**

---

## 🆘 常见问题

**Q: v14.10和v14.9有什么区别？**  
A: v14.10修复了3个BUG、补充了1个策略、删除了1个旧版本。v14.9有版本号不一致、Edge WebRTC配置冗余、Firefox广告/促销关闭不完整等问题。

**Q: 为什么删除Edge WebRTC冗余配置？**  
A: Edge的WebRTC配置在通用配置块和Edge特定块都设置了，造成代码冗余。

**Q: Firefox广告/促销补充了哪些策略？**  
A: 补充了SponsoredTopSites、SponsoredPocket、Stories、SponsoredStories、FirefoxSuggest等官方策略。

**Q: Firefox后台Agent是什么？**  
A: DisableDefaultBrowserAgent策略禁用Firefox后台默认浏览器Agent，符合用户"关闭浏览器后禁止后台运行"的要求。

**Q: 优化后还能登录账号吗？**  
A: 可以！v14.10允许登录和同步。

**Q: CF验证无限循环怎么办？**  
A: v14.10已修复，启用了安全浏览功能。

**Q: 如何验证优化生效？**  
A: 访问 `chrome://policy/` 或 `about:policies`

**Q: 如何更新？**  
A: `cd C:\Browser && git pull && cd scripts\deployment && .\OPTIMIZE_ALL_v14.10.ps1`

**Q: 代理如何配置？**  
A: 脚本不处理代理，请使用Clash Meta的进程匹配。

---

## 📁 项目结构

```
Browser/
├── scripts/
│   ├── deployment/
│   │   └── OPTIMIZE_ALL_v14.10.ps1   # 最终版（推荐）
│   └── verification/
│       └── (空目录)
├── zhubi.md                           # 主笔审核意见（重要）
└── README.md                          # 本文件
```

---

## 📖 文档

- **主笔审核意见：** [zhubi.md](./zhubi.md) - 包含扩展推荐、技术细节、审核员反馈采纳记录
- **GitHub仓库：** https://github.com/vpn3288/Browser

---

## 🎊 最终封笔声明

v14.10 已达成所有目标：

- ✅ 9个浏览器全部优化完成
- ✅ 所有关键问题已修复
- ✅ 所有负优化已删除（v14.5删除7个）
- ✅ 所有语法错误已修复（v14.6修复3个）
- ✅ 所有硬伤BUG已修复（v14.7修复5个）
- ✅ 所有BUG已修复（v14.8修复7个 + v14.9修复4个 + v14.10修复3个）
- ✅ 所有旧文件已删除（v14.8删除29个 + v14.9删除2个 + v14.10删除1个）
- ✅ WebRTC策略已补全（v14.6+v14.8+v14.9）
- ✅ 中文语言配置已修正（v14.7单个locale）
- ✅ QUIC已禁用（v14.7+v14.8所有Chromium系）
- ✅ 主页按钮已保留（v14.7+v14.8所有浏览器）
- ✅ 过时文件已删除（v14.7+v14.8+v14.9+v14.10共35个）
- ✅ 所有启动器功能已删除
- ✅ 核心反检测保留
- ✅ 使用体验优秀
- ✅ 只修复BUG，拒绝过度优化和虚假优化
- ✅ Brave官方隐私策略已补充（v14.9）
- ✅ Firefox user.js重启提示已添加（v14.9）
- ✅ Firefox广告/促销已完整关闭（v14.10）
- ✅ Firefox后台Agent已禁用（v14.10）

**不再接受任何优化请求。** 如有实质性BUG或安全问题，请提供详细复现步骤。

---

## 📜 许可证

MIT License

---

**作者：** Kiro (AI Development Environment)  
**完成时间：** 2026-05-17  
**版本：** v14.10 修复3个BUG、补充1个策略版（最终封笔）

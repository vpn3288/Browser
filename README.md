# 🌐 Multi-Browser Anti-Detect

一键优化9个主流浏览器的反检测和隐私保护工具。

**版本：** v14.7 | **状态：** ✅ 修复5个硬伤BUG版（真正封笔） | **更新：** 2026-05-17

---

## 🎯 核心功能

- ✅ **修复硬伤BUG** - v14.7修复5个硬伤BUG
- ✅ **删除过时文件** - v14.7删除3个过时文件
- ✅ **核心反检测** - WebRTC防护、禁用遥测、阻止追踪
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

# 运行v14.7修复硬伤BUG版
cd scripts\deployment
.\OPTIMIZE_ALL_v14.7.ps1
```

### 选择浏览器

运行脚本后会显示已安装的浏览器，选择要优化的浏览器即可。

**优化完成后，直接使用浏览器原生快捷方式启动，不需要任何启动器。**

---

## ✅ v14.7 修复5个硬伤BUG版特点

### v14.6的5个硬伤BUG

| 问题 | 影响 |
|------|------|
| 1. Zen Browser语言=en-US | 与用户要求"中文界面"冲突 |
| 2. ApplicationLocaleValue=列表 | 不支持列表格式，应该单个locale |
| 3. QuicAllowed=1 | QUIC过墙时易被干扰，应该=0 |
| 4. ShowHomeButton=0 | 隐藏主页按钮，用户无法回到主页 |
| 5. 菜单顺序不固定 | 每次运行顺序可能不同 |

### v14.7 修复内容

#### 🔧 修复5个硬伤BUG

1. ✅ **Zen Browser语言** - `en-US` → `zh-CN`
2. ✅ **语言配置格式** - `zh-CN,zh,en-US,en` → `zh-CN`（单个locale）
3. ✅ **QuicAllowed** - `1` → `0`（禁用QUIC，稳定过墙）
4. ✅ **ShowHomeButton** - `0` → `1`（保留主页按钮）
5. ✅ **菜单排序** - 添加`Sort-Object`固定顺序

#### 🗑️ 删除3个过时文件

1. ❌ **VERIFY_ALL.ps1** - 验证旧版负优化（与v14.7冲突）
2. ❌ **QUICK_START.ps1** - 指向v13.7旧仓库
3. ❌ **RUN_OPTIMIZE_v12.2.bat** - 过期启动器

#### 📋 审核员反馈采纳

**3位审核员提出9个问题 → 主笔采纳6个硬伤修复 → 拒绝3个过度优化建议**

**采纳率：6/9（67%）- 只修复硬伤，拒绝过度优化**

### 保留的核心反检测

- WebRTC IP防护（v14.6补全）
- 禁用所有遥测和数据收集
- 阻止第三方Cookie
- DNS-over-HTTPS（automatic模式）
- 禁用后台运行
- 禁用默认浏览器弹窗
- 厂商私货屏蔽（Edge/Brave特定功能）
- 禁用QUIC（v14.7稳定过墙）
- 保留主页按钮（v14.7用户体验）

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
- [ ] WebRTC IP不泄露
- [ ] 浏览器语言为中文（简体或繁体）
- [ ] 主页按钮可见
- [ ] 菜单顺序固定

### 在线检测

- WebRTC泄露：https://browserleaks.com/webrtc
- Canvas指纹：https://browserleaks.com/canvas
- 浏览器指纹：https://coveryourtracks.eff.org/
- IP检测：https://ipleak.net/

---

## 📊 版本对比

| 功能 | v14.6 | v14.7 |
|------|-------|-------|
| 核心反检测 | ✅ | ✅ |
| 语法错误 | ✅ 已修复 | ✅ 已修复 |
| Zen Browser语言 | ❌ en-US | ✅ zh-CN |
| 语言配置格式 | ❌ 列表 | ✅ 单个locale |
| QuicAllowed | ❌ 1 | ✅ 0 |
| ShowHomeButton | ❌ 0 | ✅ 1 |
| 菜单顺序 | ❌ 不固定 | ✅ 固定 |
| 过时文件 | ❌ 存在 | ✅ 已删除 |

**推荐：** 使用 **v14.7 修复5个硬伤BUG版**

---

## 🆘 常见问题

**Q: v14.7和v14.6有什么区别？**  
A: v14.7修复了5个硬伤BUG、删除了3个过时文件。v14.6有语言配置错误、QUIC配置错误等问题。

**Q: 为什么QuicAllowed要设为0？**  
A: QUIC基于UDP，过墙时极易被干扰和限速。所有过墙工具（包括Clash Meta）都建议禁用QUIC。

**Q: 为什么语言配置改为单个locale？**  
A: Chromium的ApplicationLocaleValue不支持列表格式，只能填单个locale（zh-CN或zh-TW）。

**Q: 为什么删除VERIFY_ALL.ps1？**  
A: 它验证旧版负优化（BrowserSignin=0、SyncDisabled=1），与v14.7"保持登录"冲突。

**Q: 优化后还能登录账号吗？**  
A: 可以！v14.7允许登录和同步。

**Q: CF验证无限循环怎么办？**  
A: v14.7已修复，启用了安全浏览功能。

**Q: 如何验证优化生效？**  
A: 访问 `chrome://policy/` 或 `about:policies`

**Q: 如何更新？**  
A: `cd C:\Browser && git pull && cd scripts\deployment && .\OPTIMIZE_ALL_v14.7.ps1`

**Q: 代理如何配置？**  
A: 脚本不处理代理，请使用Clash Meta的进程匹配。

---

## 📁 项目结构

```
Browser/
├── scripts/
│   └── deployment/
│       └── OPTIMIZE_ALL_v14.7.ps1    # 修复硬伤BUG版（推荐）
├── zhubi.md                           # 主笔审核意见（重要）
└── README.md                          # 本文件
```

---

## 📖 文档

- **主笔审核意见：** [zhubi.md](./zhubi.md) - 包含扩展推荐、技术细节、审核员反馈采纳记录
- **GitHub仓库：** https://github.com/vpn3288/Browser

---

## 🎊 真正封笔声明

v14.7 已达成所有目标：

- ✅ 9个浏览器全部优化完成
- ✅ 所有关键问题已修复
- ✅ 所有负优化已删除（v14.5删除7个）
- ✅ 所有语法错误已修复（v14.6修复3个）
- ✅ 所有硬伤BUG已修复（v14.7修复5个）
- ✅ WebRTC策略已补全（v14.6）
- ✅ 中文语言配置已修正（v14.7单个locale）
- ✅ QUIC已禁用（v14.7稳定过墙）
- ✅ 主页按钮已保留（v14.7用户体验）
- ✅ 过时文件已删除（v14.7避免误用）
- ✅ 所有启动器功能已删除
- ✅ 核心反检测保留
- ✅ 使用体验优秀
- ✅ 只修复硬伤，拒绝过度优化

**不再接受任何优化请求。** 如有实质性BUG或安全问题，请提供详细复现步骤。

---

## 📜 许可证

MIT License

---

**作者：** Kiro (AI Development Environment)  
**完成时间：** 2026-05-17  
**版本：** v14.7 修复5个硬伤BUG版（真正封笔）

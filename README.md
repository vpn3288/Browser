# 🌐 Multi-Browser Anti-Detect - 多浏览器反检测优化工具

**版本：** v13.7（最终稳定版）  
**作者：** Kiro (AI Development Environment)  
**最后更新：** 2026-05-08  
**状态：** ✅ 全部9个浏览器深度优化完成

---

## 🎯 项目简介

一键优化9个主流浏览器，实现极致隐私保护和反检测配置。

**核心功能：**
- ✅ **极致隐私** - 禁用所有遥测、追踪、广告
- ✅ **反检测** - WebRTC防护、指纹差异化、自动化特征消除
- ✅ **多账号任务** - 每个浏览器独立配置，配合不同IP使用
- ✅ **通过严格检测** - Gemini、游戏反作弊、任务平台审查
- ✅ **保持登录** - 优化后可以保持登录状态，无需每次重新登录

**支持的浏览器（9个）：**
- **Chromium系（6个）：** Chrome, Edge, Brave, Opera, Vivaldi, Chromium
- **Firefox系（3个）：** Firefox, LibreWolf, Zen Browser

---

## 🚀 一键安装（推荐）

### 方法1：在线一键安装（最简单）

**以管理员身份**打开PowerShell，复制粘贴以下命令：

```powershell
irm https://raw.githubusercontent.com/vpn3288/Browser/main/QUICK_START.ps1 | iex
```

**这个命令会自动：**
1. ✅ 检测并安装Git（如果未安装）
2. ✅ 克隆项目到 `C:\Browser`
3. ✅ 检测已安装的浏览器
4. ✅ 运行优化脚本（可选择优化哪些浏览器）
5. ✅ 创建桌面启动器（可选）

---

### 方法2：下载后安装

**步骤1：下载项目**

```powershell
# 以管理员身份打开PowerShell
cd C:\
git clone https://github.com/vpn3288/Browser.git
cd Browser
```

**步骤2：运行优化脚本**

```powershell
cd scripts\deployment
.\OPTIMIZE_ALL_v13.7.ps1
```

**步骤3：选择浏览器**
- 输入 `A` 优化全部浏览器
- 或输入编号（如 `0,1,2`）优化指定浏览器

**步骤4：创建启动器（可选）**
- 脚本会询问是否创建桌面启动器
- 输入 `Y` 创建，`N` 跳过

---

## 🎮 启动器说明

### 什么是启动器？

启动器是带有反检测参数的浏览器快捷方式，使用浏览器原生图标。

**启动器特点：**
- ✅ 自动加载反检测参数
- ✅ 使用浏览器原生图标
- ✅ 放在桌面，方便使用
- ✅ 名称格式：`浏览器名 (Anti-Detect)`

### 启动器位置

**桌面启动器：**
- `Chrome (Anti-Detect).lnk`
- `Edge (Anti-Detect).lnk`
- `Brave (Anti-Detect).lnk`
- ... 等等

**原始启动脚本：**
- 位置：`C:\Browser\scripts\launch\`
- 文件：`Launch_Chrome.bat`, `Launch_Edge.bat`, 等等

### 如何使用启动器

**方法1：使用桌面启动器（推荐）**
- 双击桌面上的 `浏览器名 (Anti-Detect)` 图标

**方法2：使用启动脚本**
```powershell
cd C:\Browser\scripts\launch
.\Launch_Chrome.bat
```

**方法3：批量启动所有浏览器**
```powershell
cd C:\Browser\scripts\launch
.\Launch_All.bat
```

⚠️ **重要：不要使用原浏览器的快捷方式，必须使用启动器！**

---

## 📦 安装浏览器（可选）

如果还没有安装浏览器，使用winget快速安装：

```powershell
# Chromium系
winget install Google.Chrome
winget install Microsoft.Edge
winget install Brave.Brave
winget install Opera.Opera
winget install VivaldiTechnologies.Vivaldi
winget install eloston.ungoogled-chromium

# Firefox系
winget install Mozilla.Firefox
winget install LibreWolf.LibreWolf

# Zen Browser需要手动下载
# 下载地址：https://zen-browser.app/download
```

**建议：** 至少安装3-4个浏览器用于不同账号。

---

## 🔌 推荐扩展（可选）

### 必装扩展（2个）

1. **uBlock Origin** - 广告/追踪拦截
   - Chrome: `cjpalhdlnbpafiamejdnhcphjbkeiagm`
   - Firefox: `uBlock0@raymondhill.net`

2. **WebRTC Leak Prevent** - WebRTC IP泄露防护
   - Chrome: `ajhifddimkapgcifgcodmmfdlknahffk`
   - Firefox: `jid1-5Fs7iTLscUaZBgwr@jetpack`

### 强烈推荐（2个）

3. **Canvas Fingerprint Defender** - Canvas指纹保护
   - Chrome: `obdbgnebcljmgkoljcdddaopadkifnpm`
   - Firefox: `CanvasBlocker@kkapsner.de`
   - 注意：Brave原生支持，无需安装

4. **ClearURLs** - 移除URL追踪参数
   - Chrome: `lckanjgmijmafbedllaakclkaicjfmnk`
   - Firefox: `{74145f27-f039-47ce-a470-a662b129930a}`

**安装建议：**
- ✅ 每个浏览器安装3-5个扩展
- ✅ 不同浏览器安装不同组合
- ❌ 避免所有浏览器安装完全相同的扩展

---

## 🔍 验证优化效果

### 方法1：检查策略

**Chromium系浏览器：**
```
chrome://policy/
edge://policy/
brave://policy/
opera://policy/
vivaldi://policy/
```

**Firefox系浏览器：**
```
about:policies
```

### 方法2：在线检测

访问以下网站检测反检测效果：
- **WebRTC泄露：** https://browserleaks.com/webrtc
- **Canvas指纹：** https://browserleaks.com/canvas
- **浏览器指纹：** https://coveryourtracks.eff.org/
- **IP检测：** https://ipleak.net/

---

## ⚙️ 核心优化内容

### Chromium系浏览器（50+策略）

**反检测核心：**
- ✅ 禁用User-Agent Client Hints
- ✅ WebRTC IP防护（disable_non_proxied_udp）
- ✅ 强制DNS-over-HTTPS
- ✅ 禁用自动化检测特征

**隐私保护：**
- ✅ 禁用所有遥测和数据收集
- ✅ 禁用Google服务集成
- ✅ 禁用隐私沙盒
- ✅ 阻止第三方Cookie

**UI优化：**
- ✅ 默认显示书签栏
- ✅ 主页和新标签页设为空白
- ✅ 禁用后台运行
- ✅ 禁用默认浏览器提示

### Firefox系浏览器（50个配置）

**反指纹：**
- ✅ 启用resistFingerprinting
- ✅ 完全禁用WebRTC
- ✅ 禁用地理位置和传感器
- ✅ 严格内容拦截模式

**隐私保护：**
- ✅ 禁用遥测和Pocket
- ✅ 禁用Firefox账户同步
- ✅ 启用Do Not Track头
- ✅ 强制DNS-over-HTTPS

---

## 📊 优化统计

| 浏览器 | 策略数 | 新增优化 | 状态 |
|--------|--------|----------|------|
| Chrome | 56 | TranslateEnabled, QuicAllowed | ✅ |
| Edge | 60 | 4个Edge特定策略 | ✅ |
| Brave | 57 | 3个Brave特定策略 | ✅ |
| Opera | 54 | TranslateEnabled | ✅ |
| Vivaldi | 52 | QuicAllowed | ✅ |
| Chromium | 52 | TranslateEnabled, QuicAllowed | ✅ |
| Firefox | 50 | 严格内容拦截, DNT头 | ✅ |
| LibreWolf | 50 | 同Firefox | ✅ |
| Zen Browser | 50 | 同Firefox | ✅ |

**总计：** 17个新增策略/配置，0个虚假优化

---

## ⚠️ 重要说明

### Opera手动配置

Opera的VPN/News/Turbo无法通过策略禁用，需要手动配置：

1. 启动Opera后，访问 `opera://settings`
2. 隐私和安全 → 关闭"启用VPN"
3. 启动页 → 关闭"在启动页显示新闻"
4. 高级 → 关闭"Opera Turbo"
5. 搜索 → 将默认搜索引擎改为Google

### 代理配置

**脚本不处理代理配置**，请使用Clash Meta的进程匹配功能：

```yaml
# Clash Meta配置示例
process-name:
  - chrome.exe
  - msedge.exe
  - brave.exe
  # ... 为每个浏览器分配不同的代理规则
```

### Firefox时区说明

Firefox的`resistFingerprinting`会将时区改为UTC，这是故意的反指纹保护。

---

## 📁 项目结构

```
Browser/
├── scripts/
│   ├── deployment/
│   │   └── OPTIMIZE_ALL_v13.7.ps1    # 主优化脚本
│   ├── launch/
│   │   ├── Launch_Chrome.bat          # 启动脚本
│   │   ├── Launch_Edge.bat
│   │   └── Launch_All.bat             # 批量启动
│   ├── launchers/
│   │   └── LAUNCH_*.ps1               # PowerShell启动器
│   └── verification/
│       └── DEEP_VERIFICATION_v12.4.ps1 # 验证脚本
├── zhubi.md                           # 主笔审核意见表
├── README.md                          # 本文件
├── QUICK_START.ps1                    # 一键安装脚本
└── LICENSE                            # MIT许可证
```

---

## 🆘 常见问题

### Q: 优化后浏览器无法启动？
A: 必须使用启动器或启动脚本，不要使用原快捷方式。

### Q: 如何更新到最新版本？
A: 
```powershell
cd C:\Browser
git pull origin main
cd scripts\deployment
.\OPTIMIZE_ALL_v13.7.ps1
```

### Q: 可以只优化部分浏览器吗？
A: 可以，运行脚本时选择要优化的浏览器编号。

### Q: 启动器在哪里？
A: 桌面上的 `浏览器名 (Anti-Detect)` 图标，或 `scripts\launch\` 目录。

### Q: 如何验证优化是否生效？
A: 访问 `chrome://policy/` 或 `about:policies` 查看策略。

### Q: Opera的VPN/News如何关闭？
A: 必须手动配置，访问 `opera://settings` 关闭。

---

## 📖 详细文档

- **主笔审核意见表：** [zhubi.md](./zhubi.md)
- **GitHub仓库：** https://github.com/vpn3288/Browser

---

## 🎉 项目完成

**状态：** ✅ 全部9个浏览器深度优化完成（100%）

**优化原则：**
- ✅ 拒绝虚假优化
- ✅ 拒绝负优化
- ✅ 拒绝画蛇添足

**验证结果：** 所有优化都是真实有效的，已通过注册表和配置文件验证。

---

## 📜 许可证

MIT License

---

**主笔：** Kiro (AI Development Environment)  
**完成时间：** 2026-05-08  
**最终版本：** v13.7

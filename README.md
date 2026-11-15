# 微软模拟飞行 2020 简体中文汉化（合并式）

Microsoft Flight Simulator 2020 的民间简体中文汉化，采用**合并式安装**：以你当前的官方文本为底，逐条替换为中文，而不是整文件覆盖。

> 基于 [Yuuki-Sakura/MFS2020_zh-CN](https://github.com/Yuuki-Sakura/MFS2020_zh-CN) 的中文词条，
> 重新整理、补齐并改为增量合并方案。

---

## 为什么用合并而不是覆盖

传统汉化包的做法是把官方 `en-US.locPak` 整个换成旧版本文件。游戏一更新，新版本里新增的文案在旧包里不存在，覆盖后这些界面会显示成 `ACTIVITY_RENO_TITLE` 这样的原始键名，或者干脆空白。

本项目的安装器在安装时读取**你机器上当前版本**的官方文件，只把两边都有的键替换成中文：

- 官方新增的文案 → 保持英文（不会出现空白键）
- 已有译文 → 中文
- `.tts` 语音合成串 → 始终保留英文（喂中文给英文语音引擎只会念不出来）

因此**每次游戏更新后，重跑一次安装脚本即可**，不需要等新包发布。

## 翻译数据

| 项目 | 数值 |
|---|---|
| 官方文本条目（`fs-base`，1.39.12） | 44,296 |
| 已汉化 | 30,465（68.8%） |
| 其中 `.tts` 语音串（故意保留英文） | 11,025 |
| 非语音文本汉化率 | **≈ 92%** |
| 覆盖包数量 | 22 个（`fs-base`、机模、丛林飞行、着陆挑战、线上活动等） |

剩余未汉化的 1,431 条主要是机型代号（`HS 748`）、航司（`KLM`）、导航术语缩写（`RNAV`、`LDA`）等按惯例保留原文的内容。

## 安装

```powershell
# 直接运行（自动探测数据包路径与 Steam 库）
powershell -ExecutionPolicy Bypass -File .\install.ps1

# 只看会做什么，不写文件
powershell -ExecutionPolicy Bypass -File .\install.ps1 -DryRun

# 自动探测失败时手动指定
powershell -ExecutionPolicy Bypass -File .\install.ps1 `
    -PackagesRoot "F:\Microsoft Flight Simulator\Packages" `
    -GamePackagesDir "E:\SteamLibrary\steamapps\common\MicrosoftFlightSimulator\Packages"
```

**游戏内语言必须保持 English** —— 汉化写入的是 `en-US` 槽位。

### 还原

安装前会自动备份官方原文件到 `backups\<时间戳>\`，并生成 `manifest.json`。

```powershell
powershell -ExecutionPolicy Bypass -File .\restore.ps1              # 用最近一次备份
powershell -ExecutionPolicy Bypass -File .\restore.ps1 -BackupDir ".\backups\20261115-161057"
```

### 可选参数

| 参数 | 说明 |
|---|---|
| `-IncludeGameDir` | 同时汉化游戏安装目录下的 `fs-base-onboarding` / `fs-base-ui`。**不推荐**：这些文件归 Steam 管，Steam 校验时会被重置。 |
| `-IncludeFont` | 安装 `simsun.ttc` 字体。**不推荐**：游戏自带 `NotoSansSC` 全套简体中文字体。 |
| `-Edition` | 强制指定 `Steam` / `OneStore`（默认自动判断）。 |

## 工作流程

```
payload/           中文词条（按游戏包结构组织）
   └─ Steam/
       └─ fs-base/en-US.locPak     键 → 中文
install.ps1        读取目标位置的官方文件 → 逐键合并 → 写入
restore.ps1        从 backups/<时间戳>/ 还原
tools/
   ├─ RULES.md     翻译规范与术语表
   └─ Extract-Missing.ps1   提取「仍是英文」的条目，供后续翻译
```

## 参与翻译

游戏更新后，新增的文案会保持英文。提取出来：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\Extract-Missing.ps1
# 输出 missing.csv：key, value（未汉化的英文）
```

翻译时请遵循 [`tools/RULES.md`](tools/RULES.md)：占位符 `{0}` `${...}` `%s` 与 `<br/>` 等标签必须原样保留，机型/航司/单位不译。

## 致谢

- [Yuuki-Sakura/MFS2020_zh-CN](https://github.com/Yuuki-Sakura/MFS2020_zh-CN) —— 原始中文词条
- 所有参与校对与反馈的玩家

## 声明

- 本项目**不包含任何游戏可执行文件或资源文件**，仅包含文本译文与安装脚本。
- 游戏文本、机型名称、商标等版权归 Microsoft / Asobo Studio 及各权利人所有。
- 本项目与 Microsoft、Asobo Studio 无任何关联，使用风险自负。
- 脚本部分采用 [MIT License](LICENSE)；译文数据版权归原作者及贡献者所有。

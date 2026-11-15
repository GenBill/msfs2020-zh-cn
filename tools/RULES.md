# MSFS 汉化翻译规则（所有分块通用）

你在翻译《微软模拟飞行 2020》的界面/教程文本（英文 → 简体中文）。

## 硬性规则

1. **占位符必须原样保留**：`{0}` `{1}` `${...}` `%s` `%d` `\n` 一个字符都不能改。
2. **HTML 标签原样保留**：`<br/>` `<b>` `</b>` `<i>` `<span ...>` 等。标签内的文字才翻译。
3. **不要翻译的东西**：
   - 机型/型号：`A320neo` `747-8` `TBM 930` `Cessna 172` `F/A-18` `A310-300`
   - 航空公司/品牌：`KLM` `Lufthansa` `Boeing` `Airbus` `Asobo` `Honeywell`
   - 按键名：`ENTER` `ESC` `SPACE` `TAB` `SHIFT`
   - 单位：`ft` `kt` `nm` `ft/min` `lbs` `kg` `gal` `MHz`
   - 文件路径、URL、代码、代号（如 `LIVE_WEATHER` `KEY_A`）
   - 版本号、纯数字
4. **空字符串返回空字符串**，不要编造。
5. **地名用通行中文译名**：Seattle→西雅图，Grand Canyon→大峡谷，Sedona→塞多纳。
6. 语气：简洁的界面用语，不要加句号后缀（除非原文有）。按钮/标签尽量 2-6 个字。
7. 长描述（教程、任务简报）正常翻译，保持原意，可适当断句，但不要增删信息。

## 术语表（必须遵守）

| 英文 | 中文 |
|---|---|
| ATC | 空管 |
| VFR / IFR | 目视飞行规则 / 仪表飞行规则 |
| Approach | 进近 |
| Departure | 离场 |
| Takeoff / Landing | 起飞 / 着陆 |
| Taxi / Taxiway | 滑行 / 滑行道 |
| Cruise | 巡航 |
| Runway | 跑道 |
| Apron / Gate | 停机坪 / 登机口 |
| Altitude | 高度 |
| Heading | 航向 |
| Bearing | 方位角 |
| Airspeed | 空速 |
| Knots | 节 |
| Flaps | 襟翼 |
| Trim | 配平 |
| Throttle | 油门 |
| Rudder | 方向舵 |
| Aileron | 副翼 |
| Elevator | 升降舵 |
| Landing Gear | 起落架 |
| Cockpit | 驾驶舱 |
| Autopilot | 自动驾驶 |
| ILS | 仪表着陆系统 |
| Waypoint | 航点 |
| Flight Plan | 飞行计划 |
| Squawk | 应答机编码 |
| Livery | 涂装 |
| Cold and Dark | 冷舱状态 |
| Bush Trip | 丛林飞行 |
| Landing Challenge | 着陆挑战 |
| Achievement | 成就 |
| Tutorial | 教程 |
| Live Event | 线上活动 |
| Rolling Cache | 滚动缓存 |
| Photogrammetry | 摄影测量 |
| Live Weather | 实时天气 |
| Multiplayer | 多人游戏 |
| Settings / Options | 设置 / 选项 |
| Assistance | 辅助 |
| Sensitivity | 灵敏度 |
| Binding | 按键绑定 |
| Axis | 轴 |
| Checklist | 检查单 |
| Pause | 暂停 |
| HUD | 平视显示器 |
| Sim Rate | 模拟速率 |
| Time of Day | 时刻 |
| Weather Preset | 天气预设 |
| Scenery | 地景 |
| Add-on | 附加组件 |
| Content Manager | 内容管理器 |

## 输出格式

输入文件是一个 JSON 对象：`{"s00001": "English text", ...}`
输出必须是同样的键、值为中文的 JSON 对象，**UTF-8 无 BOM**，不要加任何解释文字。

# owoDE Monet 色彩系统

owoDE 的 Material Expressive 感不能只靠圆角和动效。颜色也需要围绕当前壁纸
形成连续的层级：顶栏、Temporal Capsule、Dock、面板和强调按钮应像同一个
环境中的材质，而不是各自带一套蓝色或紫色。

## 当前实现

`qml/MonetPalette.qml` 为每张内置壁纸提供一组离线、可审阅的种子色板。它把
壁纸的主要气质映射为 Material 风格的语义角色：

- `primary` / `onPrimary`
- `primaryContainer`
- `secondary` / `secondaryContainer`
- `tertiary` / `tertiaryContainer`
- `background`
- `surface` / `surfaceContainer` / `surfaceElevated`
- `outline`
- `textPrimary` / `textSecondary`
- `warning` / `success`

`Tokens.qml` 只消费这些角色。切换 `snow`、`abstract`、`quiet` 或 `kemono`
壁纸时，普通胶囊、顶栏分组、System Island、面板表面和强调色会同步改变。
用户手动选择 teal、lilac 或 apricot 时，仍然保留显式强调色控制。

## 为什么先使用种子色

第一版必须离线、稳定且不会在静态桌面上启动持续取样或重绘循环。当前色板是
根据随项目发布的原创 SVG 壁纸预先审阅的 Monet 风格种子，不会假装自己已经
完成了任意用户壁纸的实时像素分析。这样可以先把视觉层级固定下来，同时保留
未来接入缓存式图像取色后端的接口。

后续真实取色后端应满足：

1. 只在壁纸更换或用户明确请求时运行一次；
2. 在后台生成受限数量的主色、辅助色和明暗色阶；
3. 通过同一组语义角色进入 `Tokens`，不让 QML 组件直接消费原始 RGB；
4. 取色失败时回退到当前壁纸的内置种子色板；
5. 保证文字、焦点环和错误状态的对比度，不为了追求鲜艳而牺牲可读性。

这套方案借鉴 Material Expressive 的角色化色彩和动态层级，但不复制 Google
组件或其默认配色。owoDE 的识别仍来自雪山、柔和蓝绿、少量紫粉和清晰的
胶囊秩序。

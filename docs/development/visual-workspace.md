# owoDE 可视化工作区

正式名称：**owo Desktop Environment（owoDE）**。首个计划版本为
**v0.0.1 Alpha · YunShuang（云霜）**，不是可日用版本承诺。

## Fedora 44 打开工程

使用 Qt Design Studio 的 **File → Open File or Project**，选择仓库内
`design/owoDE.qmlproject`。不要打开 `qml/Main.qml` 作为设计入口：它负责真实后端和原生表面。
Qt Design Studio 需要带 Qt Quick Controls 的 Qt 6.8 或更新的运行环境；本工程不依赖
`QtQuick.Studio.*` 商业扩展、KWin、LayerShellQt 或自己编译的 C++ 插件来显示设计场景。

Qt Design Studio 需从 Qt 官方安装渠道另行安装。Fedora 上的 Qt Creator 和 Qt Design Studio
是不同产品；只有 Qt Creator 不能据此宣称装好了 Qt Design Studio。

只看完整交互预览，可安装发行版 Qt 6 QML runtime、Qt Quick Controls 和 SVG 支持后运行：

```sh
bash tools/design-preview.sh
```

这条命令直接读取源文件，不编译项目，不启动 KWin，不更改登录会话。
若系统将 `qml` 放在其他位置，设置 `QML_RUNTIME=/实际路径/qml`。

## 选择与编辑页面

在工程树中打开 `design/scenes/*.ui.qml`，进入 **Design / 2D**：

| 场景 | 内容与主要共享文件 |
| --- | --- |
| Desktop | 完整桌面布局，`DesktopForm.ui.qml` |
| Background | 原有壁纸，`BackgroundForm.ui.qml` |
| TopRibbon | 顶栏与时间文字，`RibbonForm.ui.qml`、`TemporalTextForm.ui.qml` |
| Dock | 应用栏，`DockForm.ui.qml`、`DockItemForm.ui.qml` |
| Launcher | 与 Dock 连成一体的启动器，`LauncherForm.ui.qml`、`AppTileForm.ui.qml` |
| QuickSettings | 紧凑按钮与滑条，`QuickSettingsForm.ui.qml`、`CompactSliderForm.ui.qml` |
| NotificationCenter | 通知布局与卡片，`PanelHeaderForm.ui.qml`、`NotificationCardForm.ui.qml` |
| LockScreen | 锁屏视觉，`LockCompositionForm.ui.qml`；不是安全认证实现 |
| Language | 克制的第一屏，`LanguageForm.ui.qml` |
| Welcome | 语言确认后的品牌欢迎，`WelcomeBrandForm.ui.qml` |
| Settings | 通用设置控件，`SettingsForm.ui.qml` |
| WindowOsd | 窗口视觉与屏幕提示，`WindowChromeForm.ui.qml`、`OsdForm.ui.qml` |

先选场景看整体；要改一个组件所有实例，继续打开表中对应的共享 `.ui.qml`。
只改 `scenes` 里的实例属性只会改变设计场景；**要让 Native Runtime 也改变，应编辑共享表单或令牌**。

在 Navigator 中选中 Rectangle、Text、Image 或布局项，使用 Properties 修改位置、尺寸、
锚点、布局边距、圆角、颜色、透明度、字体和文字。选中 Image 可以更换原有资产路径。
被布局管理的项目应改 Layout 属性，不能一边保留 anchors/Layout 一边强行拖 x/y。
画布内组件是复用实例时，进入其组件文件编辑子对象，而不是在外层寻找不存在的子对象。

## 统一颜色、尺寸与主题

打开 `design/Owo/Visuals/ThemeValues.ui.qml`，选中根项目，在自定义属性区域调整
`radius*`、`space*`、`panelWidth`、`dockHeight`、`launcherWidth/Height`、字体尺寸、透明度、层级和动画时长。
这些是 `Tokens` 真正读取的默认值，不是另一份设计样例。

默认继续使用原有 Monet 壁纸取色。需要手动配置颜色时，将 `manualColors` 设为 true，
再修改 `primaryLight/Dark`、`surface*Light/Dark`、文字、轮廓等角色；应同时检查浅色和深色的文字对比度。
语义令牌、字体角色、材质层级和弹簧曲线统一保留在 `Tokens.qml`、`MonetPalette.qml`；
推导算法仍由开发者维护，不要求设计者手写算法。

画布支持的状态与过渡可以在根组件的 States / Transitions 中编辑。
正式运行时的事件触发和有限弹簧行为留在普通 `.qml` 适配器里，避免 `.ui.qml` 出现不支持的 Behavior 或信号处理器。

## 保存、预览、进入真实运行时

1. `Ctrl+S` 保存共享表单，2D 画布更新；使用 Preview 查看实际 Qt Quick 渲染。
2. `design/Preview.qml` 的顶部控件切换场景、逻辑分辨率、文字缩放和浅/深色。
   设计场景使用明确标注的模拟数据，没有系统服务写操作。
   画布缩放和文字缩放可分别调整；系统 DPI 可用 `QT_SCALE_FACTOR=1.25 bash tools/design-preview.sh` 检查。
   每个场景根对象的 States 含 `light` / `dark`，可在 2D 画布直接切换。
3. 启动器预览支持网格/列表与搜索；快捷设置预览的切换只改设计状态。
4. 独立命令行预览重新运行可读取保存后的文件；Qt Design Studio 自身的实时预览由设计器管理。
5. 提交共享文件并推送功能分支，让 CircleCI / CNB 云端构建、测试、截图和打包。
6. 安装同一提交的云端包，按既有 Fedora 嵌套 KWin 路径启动 Native Runtime。
   安装包使用编译嵌入的 QML，保存源文件不会热修改已经安装的二进制；必须重新云端打包。

原生壁纸、Ribbon、Dock 和弹出层的角色、锚点、独占区、焦点与输入区域仍归
`NativeSurfaceController` / `Main.qml` 管理。设计器不创建 Wayland shell role。

## 设计师与开发者边界

可直接编辑的是共享表单里的对象、样式和支持的布局/状态。不是所有现有 QML 都可由画布编辑：

- 系统模型、应用发现和启动、D-Bus、KWin、LayerShellQt、焦点与输入区：C++ / 普通 QML。
- 动态 Ribbon 模块与退化策略、实时 Temporal 景观/天气逻辑：普通 QML。
- OOBE 全部 11 步的导航、持久化、配置操作与恢复：`WelcomeFlow.qml`；语言始终先于品牌欢迎。
- 锁屏认证、安全会话锁定、真正的 KWin 窗口装饰插件：尚不能用视觉预览代替。
- ShaderEffect、Canvas、材质采样、弹簧计算、信号处理器：开发者维护。
- 通知和设置里的高级动态内容仍通过共享框架组合；设计场景中的模拟通知不代表真实后端已接通。

不要开启 QDS 的 CMake Generator 覆写仓库现有构建。现有 CMake 已显式登记共享模块，
新增文件时同时登记 `design/Owo/Visuals/{qmldir,CMakeLists.txt}`，云端检查会比对。

## 兼容性验收

- `check-design-workspace.py`：检查共享文件登记、禁止在表单中出现不支持的逻辑构造。
- `design-workspace`：独立于 KLDE C++ 后端，从源文件目录加载每个场景；云端输出 PNG。
- `designer-compat`：Fedora 云端安装 Qt Creator 的 QML Designer runtime，使用其
  `qmlpuppet --qml-renderer` 渲染每个场景，核验实际 import、资源与组件加载。
- 正式 Qt Test / QML / 原生 KWin 测试继续检查运行时，没有用设计预览替换它们。

Qt Creator 的 QML Designer renderer 验收与“在某个 Qt Design Studio 版本中手工拖拽并保存”
是两项不同证据。后者在取得相应版本实测记录之前仍不能宣称完成。

参考：[Qt 官方 UI Form 支持范围](https://doc.qt.io/qtdesignstudio/creator-quick-ui-forms.html)、
[Designer/developer workflow](https://doc.qt.io/qtdesignstudio/qtquick-design-development.html)、
[官方 QML Puppet 诊断方法](https://wiki.qt.io/QtDesignStudio/Troubleshooting)。

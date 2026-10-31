# 云端真实登录验收

`fedora-login-vm` 是独立于现有容器构建、Visual Lab 和嵌套 KWin 的登录验收。
当前在功能分支 `feat/fedora-gdm-vm` 和 `feat/session-activation-env` 启用；
新增任务通过之前，不声称登录验收完成。
Ubuntu 26.04 仍是首要支持平台。该 Fedora 44 虚拟机任务不会在维护者设备上运行。

CircleCI 的 Linux machine executor 启动一次性的 Fedora Cloud 44 客体，安装同一
源码提交生成、校验和匹配的两个 RPM。先使用 Fedora 官方 44 公钥指纹验证镜像的
签名校验文件，再校验实际镜像。客体不共享宿主磁盘、用户会话、显示 socket 或设备。
SSH 仅绑定云端 runner 的回环地址，临时密钥、磁盘和 NoCloud seed 不作为产物上传。

这个任务实际检查：

- GDM 读取已安装的 `owode.desktop`，启动独立 owoDE 会话。
- logind 报告活动的 `gdm-autologin`、Wayland、`Desktop=owode` 用户会话。`owode`
  对应入口文件名；`XDG_CURRENT_DESKTOP=owoDE` 是单独的桌面品牌/兼容标识。
- KWin 使用虚拟 DRM；用户下有真实 KWin 和 shell，没有 Plasma Shell 或 GNOME Shell。
- 独立 KWin 脚本报告桌面背景、两个 panel/Dock 和真实 GNOME Calculator/KCalc 窗口。
- Wayland 日志记录背景、Ribbon、Dock 的真实首帧、图层和输出归属。
- QEMU 直接抓取客体显示帧，独立于 QML 截图功能。
- 通过 owoDE 自己的会话接口退出，原 KWin/shell 与 logind 会话结束，返回活动 GDM 登录页。

自动登录只针对临时客体账号，用于先验收入口、PAM 自动登录链路和生命周期。退出前
关闭客体自动登录，避免登录循环。这不是密码认证或安全锁屏测试。GNOME Shell 仅作为
GDM 的独立 greeter 运行，不属于 owoDE 用户会话。SELinux 保持发行版默认策略。

任务探测 `/dev/kvm` 的可访问性；没有加速时使用 TCG，并记录实际选择。无论哪种
加速，虚拟显卡与软件渲染都不能代表 Intel 实机性能、物理显卡兼容性或生产级可靠性。
不要为了这个任务在维护者主机加载内核模块、改权限或修改 GDM/niri 配置。

产物 `artifacts/login-vm` 保存来源、镜像签名结果、包校验、加速方式、客体日志、
logind/KWin 状态、实际显示截图以及明确的验收边界。只有所有断言成功才会生成
`acceptance.json`；失败时保留已有证据。既有双平台构建、静态分析和原生角色验收不变。

本任务仍不能替代密码登录、锁屏与解锁、门户授权、物理硬件、多屏、崩溃恢复、
重复登录和长时间使用验收。请继续按 [production-readiness.md](production-readiness.md) 追踪。

实现依据：

- [CircleCI Linux VM executor](https://circleci.com/docs/guides/execute/using-linuxvm/)
- [Fedora Cloud](https://fedoraproject.org/cloud/download/) 与 [Fedora 公钥指纹](https://fedoraproject.org/en/security/)
- [GDM 自动登录配置](https://help.gnome.org/system-admin-guide/login-automatic.html)
- [QEMU QMP screendump](https://www.qemu.org/docs/master/interop/qemu-qmp-ref.html#command-screendump)

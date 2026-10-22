# ScreenOff

双击一下就**关闭显示器**，主机照常运转，后台任务一秒不停；动一下鼠标或按任意键，屏幕立刻亮回来。

单文件 exe，**无 .NET 安装、无依赖、不写注册表、不联网、不装任何东西**。

> English: *Turn the monitors off while the PC keeps working. One unsigned `.exe`, no installer, no dependencies. Any mouse move or key press wakes the display.*

## 为什么需要它

Windows 自带的「几分钟后关闭显示器」经常被别的程序顶住（视频播放器、会议软件、远程控制的向日葵都会登记一条 *display required* 请求），结果就是：人走了，屏幕一直亮着。而直接在电源计划里把电脑设成睡眠，后台任务又会被打断。

**关屏和睡眠是两回事。** ScreenOff 只改显示器的供电状态（DPMS 关闭），CPU、磁盘、网络、GPU 全部照常工作。

## 用法

到 [Releases](../../releases) 下载 `ScreenOff.exe`，双击。

1. 听到「叮」一声 —— 倒计时开始，**这时候把手从鼠标上拿开**；
2. 2 秒后屏幕熄灭（会一直黑到你下次动鼠标或按键）；
3. 主机不睡眠，后台继续跑。

想在桌面上留个图标：右键 `ScreenOff.exe` → 发送到 → 桌面快捷方式。

### 参数

| 参数 | 作用 | 默认 |
| --- | --- | --- |
| `<N>` | 延时 N 秒的简写，等价于 `-delay N` | 2 |
| `-delay N` | 双击后等 N 秒再关屏（0-60）。给「我刚点完还想动两下鼠标」留时间 | 2 |
| `-method M` | `both` / `broadcast` / `post`，两种投递关屏请求的方式，个别驱动只认其中一种时用来试 | both |
| `-quiet` | 倒计时开始时不响提示音 | 响 |
| `-version` / `-help` | 弹窗显示版本 / 用法 | |

例：`ScreenOff.exe -delay 5 -quiet`

命令行返回值：0 正常，1 关屏调用抛异常，2 参数不对。

## 原理

向 `HWND_BROADCAST` 广播 `WM_SYSCOMMAND / SC_MONITORPOWER, lParam = 2`（2 = 关闭），这是 Windows 官方的显示器节能通道，和系统闲置计时器到期后走的是同一条路。发送前先 `SetThreadExecutionState(ES_CONTINUOUS)` 清掉自己的显示保持请求；`SendMessageTimeout` 与 `PostMessage` 各发一次，兼容只处理其中一种的驱动。细节与实测记录见 [docs/LESSONS.md](docs/LESSONS.md)。

## 已知限制

- **所有显示器一起关**，不能只关其中一台（per-monitor 要走 `ChangeDisplaySettingsEx`，本机没这个需求所以没做）。
- **不碰电源计划**。插电时睡眠设成「从不」才适合挂机跑长任务；ScreenOff 不会替你改，`scripts/diagnose.ps1` 会告诉你现在是多少。
- **用向日葵/远程桌面观看这台机器时**，物理屏熄灭后远程画面可能跟着黑掉——远程软件是靠「显示保持唤醒」撑住渲染管线的。
- **exe 未做代码签名**（个人项目没有证书）。第一次运行 Windows SmartScreen 可能拦一下，点「仍要运行」即可；个别杀软对「广播关屏消息」的小 exe 也可能报误杀。源码全在本仓库，可以自己 `build.ps1` 编译。
- 文件属性里的「版本」页是空的：`csc` 不写 `VS_VERSION_INFO` 资源。`-version` 弹窗里的版本来自程序集版本，是准的。

## 自己构建

需要 Windows 10/11 自带的 C# 编译器（`.NET Framework 4.x` 的 `csc.exe`），不需要 Visual Studio。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Version 1.0.0
```

产物与 sha256 落在 `bin/`：`ScreenOff.exe`、`ScreenOff-v<版本>-win-x64.zip`。源码按 C# 5 编写并钉死 `/langversion:5`，所以老编译机也能过。

注意：Windows 自带的 `csc 4.8.9221.0` 不支持 `/deterministic`（会报 `CS2007`），所以每次重编的 exe 字节不同（MVID 和 PE 时间戳会变）。要核对「你编的和 Release 上的是不是同一份」，只能比源码，不能比哈希。

## 不想用 exe？

`scripts/` 里是同逻辑的纯脚本路线，效果一样：

- `monitor-off.ps1` —— PowerShell + `Add-Type` 版，`-Diagnose` 可自查
- `monitor-off.vbs` —— 双击入口，隐藏控制台窗口（无黑框闪现）
- `diagnose.ps1` —— 只读体检：睡眠状态、谁在保持显示器唤醒、关屏/睡眠超时、屏幕列表

## 排查「黑一下又自己亮回来」

跑 `scripts/diagnose.ps1`，看第 `[2]` 节 `powercfg /requests` 的 `DISPLAY:` 下面列了谁。临时退出那个程序再试，就能确认是它顶回来的。

## 许可

MIT，见 [LICENSE](LICENSE)。改动历史见 [CHANGELOG.md](CHANGELOG.md)。

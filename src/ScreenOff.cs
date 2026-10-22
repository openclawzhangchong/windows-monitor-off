// ScreenOff - turn the monitors off (DPMS) while the PC keeps running.
// Build with the in-box C# compiler, no external dependency, no installer.
//   csc /target:winexe /nologo /version:1.0.0 /out:ScreenOff.exe src\ScreenOff.cs
// Written against C# 5 so the Windows 10/11 in-box csc (4.8, "for C# 5") compiles it as-is.

using System;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Media;
using System.Windows.Forms;

namespace ScreenOff
{
    internal static class Program
    {
        private const uint WM_SYSCOMMAND = 0x0112;
        private const int SC_MONITORPOWER = 0xF170;
        private const int MONITOR_STATE_OFF = 2;
        private const uint SMTO_ABORTIFHUNG = 0x0002;
        private const uint ES_CONTINUOUS = 0x80000000;
        private const int DEFAULT_DELAY_SEC = 2;
        private const int MAX_DELAY_SEC = 60;
        private static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam,
            uint flags, uint timeoutMs, out IntPtr result);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern IntPtr PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern uint SetThreadExecutionState(uint esFlags);

        [STAThread]
        private static int Main(string[] args)
        {
            string method = "both";
            int delaySec = DEFAULT_DELAY_SEC;
            bool quiet = false;

            for (int i = 0; i < args.Length; i++)
            {
                string raw = args[i];
                if (raw == null || raw.Length == 0)
                {
                    continue;
                }

                string token = raw.Trim();
                string key = token.TrimStart('-', '/').ToLowerInvariant();
                string value = null;

                int colon = key.IndexOf(':');
                if (colon >= 0)
                {
                    value = key.Substring(colon + 1);
                    key = key.Substring(0, colon);
                    if (value.Length == 0)
                    {
                        value = null;
                    }
                }

                if (key == "h" || key == "help" || key == "?")
                {
                    Show(Usage());
                    return 0;
                }
                if (key == "version")
                {
                    Show("ScreenOff " + ProductVersion());
                    return 0;
                }
                if (key == "quiet" || key == "q")
                {
                    quiet = true;
                    continue;
                }
                if (key == "delay")
                {
                    if (value == null && i + 1 < args.Length)
                    {
                        i++;
                        value = args[i].Trim();
                    }
                    int parsed;
                    if (!int.TryParse(value, out parsed) || parsed < 0 || parsed > MAX_DELAY_SEC)
                    {
                        Show("Bad -delay value: \"" + value + "\" (need 0-" + MAX_DELAY_SEC + ")");
                        return 2;
                    }
                    delaySec = parsed;
                    continue;
                }
                if (key == "method")
                {
                    if (value == null && i + 1 < args.Length)
                    {
                        i++;
                        value = args[i].Trim();
                    }
                    if (value != null)
                    {
                        value = value.ToLowerInvariant();
                    }
                    if (value != "both" && value != "broadcast" && value != "post")
                    {
                        Show("Bad -method value: \"" + value + "\" (need both, broadcast or post)");
                        return 2;
                    }
                    method = value;
                    continue;
                }

                int bare;
                if (int.TryParse(key, out bare))
                {
                    if (bare < 0 || bare > MAX_DELAY_SEC)
                    {
                        Show("Bad delay: " + bare + " (need 0-" + MAX_DELAY_SEC + ")");
                        return 2;
                    }
                    delaySec = bare;
                    continue;
                }

                Show(Usage());
                return 2;
            }

            if (!quiet)
            {
                // The countdown is invisible, so mark its start: put the mouse down now.
                SystemSounds.Exclamation.Play();
            }

            if (delaySec > 0)
            {
                Thread.Sleep(delaySec * 1000);
            }

            try
            {
                // Drop our own display-required request before asking the panel to sleep.
                SetThreadExecutionState(ES_CONTINUOUS);

                if (method != "post")
                {
                    IntPtr ignored;
                    SendMessageTimeout(HWND_BROADCAST, WM_SYSCOMMAND, (IntPtr)SC_MONITORPOWER,
                        (IntPtr)MONITOR_STATE_OFF, SMTO_ABORTIFHUNG, 2000, out ignored);
                }
                if (method != "broadcast")
                {
                    if (method == "both")
                    {
                        Thread.Sleep(250);
                    }
                    PostMessage(HWND_BROADCAST, WM_SYSCOMMAND, (IntPtr)SC_MONITORPOWER,
                        (IntPtr)MONITOR_STATE_OFF);
                }
            }
            catch (Exception ex)
            {
                Show("Could not turn the display off: " + ex.Message);
                return 1;
            }

            return 0;
        }

        private static string ProductVersion()
        {
            Version v = Assembly.GetExecutingAssembly().GetName().Version;
            return string.Format("{0}.{1}.{2}", v.Major, v.Minor, v.Build);
        }

        private static string Usage()
        {
            return string.Join(Environment.NewLine, new string[]
            {
                "ScreenOff " + ProductVersion() + " - monitors off, PC keeps working.",
                "",
                "Double-click with no arguments: beeps, waits 2 s (put the mouse down),",
                "then blanks every monitor. Any mouse move or key press wakes it.",
                "",
                "Usage: ScreenOff.exe [options]",
                "  <N>              shorthand for -delay N (seconds, 0-60, default 2)",
                "  -delay N         wait N seconds before turning the display off",
                "  -method M        both (default) | broadcast | post",
                "  -quiet           do not beep when the countdown starts",
                "  -version         show version",
                "  -help            show this text",
                "",
                "The PC does not sleep: only the display power state changes.",
                "If the panel lights straight back up, another program is holding a",
                "display-required request - see docs/LESSONS.md."
            });
        }

        private static void Show(string text)
        {
            MessageBox.Show(text, "ScreenOff", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
    }
}

<p align="center">
  <img src="docs/icon.png" width="128" alt="Mac mini Mode icon">
</p>

<h1 align="center">Mac mini Mode</h1>

<p align="center">Keep a plugged-in MacBook running with the lid closed. Unplug it and it sleeps like a normal laptop again.</p>

This personal edition adds an adjustable battery threshold to **Always On**. The buttons below download the latest installer from this fork.

<p align="center">
  <a href="https://github.com/fx-39/MacMiniMode/releases/latest/download/MacMiniMode.pkg"><img src="docs/download-en.svg" height="48" alt="Download for macOS"></a>
  &nbsp;
  <a href="https://github.com/fx-39/MacMiniMode/releases/latest/download/MacMiniMode.pkg"><img src="docs/download-zh.svg" height="48" alt="下载安装包"></a>
</p>

<p align="center"><b>English</b> · <a href="README.zh-CN.md">简体中文（安装说明）</a></p>

## Install the personal edition

Requires macOS 12 or later on Apple silicon or Intel. The v1.00 installer ships without a Developer ID signature or Apple notarization, so Gatekeeper may block it.

1. Click **Download for macOS** above to get `MacMiniMode.pkg`.
2. Double-click it and follow the installer. You will be asked for your Mac password once.
3. A new icon appears in the menu bar. It is already working, no restart needed.

To build locally, download the source code for v1.00, run `bash scripts/build.sh` from the project directory, then open `build/MacMiniMode.pkg`. [v1.00 release and source code](https://github.com/fx-39/MacMiniMode/releases/tag/v1.00)

<p align="center">
  <img src="docs/installer-en.png" width="620" alt="Mac mini Mode installer">
</p>

## What it does

Mac mini Mode turns a MacBook into an always-on home server or headless Mac. It gives you clamshell mode without an external display or a dummy HDMI plug, and there is no `caffeinate` or `sudo pmset disablesleep` to remember. In Automatic mode, it follows the power adapter.

- **On when plugged in**: sleep is disabled on AC power, so your Mac keeps running with the lid closed and no display attached.
- **Off when unplugged**: normal sleep returns on battery. If the lid is already closed, the Mac sleeps right away.
- **Menu bar control**: switch between Automatic, Always On and Always Off, and see the current state at a glance.
- **Quit and Allow Sleep**: choosing Quit switches to Always Off and waits until sleep is allowed. The setting stays off after reconnecting power or restarting; choose Automatic or Always On to enable it again. Logging out, restarting or shutting down macOS preserves the selected mode. Other power settings are unchanged.
- **Screen off with the lid closed**: the built-in display's backlight turns off when you close the lid and returns to its previous brightness when you open it. Only the backlight changes, so the Mac does not lock and remote desktop or running apps are not interrupted. It never touches an external display. Can be switched off in the menu.
- **Health Check**: one click checks whether Remote Login, Screen Sharing, the battery and power settings are ready, and copies diagnostics for bug reports.
- **Low-battery protection for Always On.** The Always On menu item shows the current threshold. Choose **Adjust Low-Battery Threshold…** below the three modes and enter a whole percentage from 1 to 100 (default 10%). You can set it in any mode. The setting takes effect immediately in Always On and survives restarts.
  - On battery, your Mac can sleep when its charge reaches or falls below the threshold. The menu keeps Always On selected and shows that low-battery protection is allowing sleep. With the lid open, normal macOS sleep rules apply.
  - Plugging in restores keep-awake immediately. On battery, it resumes five percentage points above the threshold, capped at 100%. For example, a 30% threshold allows sleep at 30% and resumes keep-awake at 35%. At a threshold of 100%, sleep is always allowed on battery.
- **Command line**: `macminimode status` and `macminimode on|off|auto`, also usable from Shortcuts with Run Shell Script.

## Update this fork

Updates are manual. Download `MacMiniMode.pkg` from the latest release of this fork and follow the installer to update the app and its background service. [Personal edition releases](https://github.com/fx-39/MacMiniMode/releases)

## Troubleshooting

If your Mac sleeps unexpectedly with the lid closed, choose **Health Check…** from the menu bar icon, click **Copy Diagnostics**, and paste it in [Issues](../../issues). A common cause is remote desktop or cleaner software that rewrites power settings on a timer; the app now restores the setting right away and notes it in the log.

If the screen is still dark after you open the lid (rare, for example if the app was force-quit while the lid was closed), press the brightness-up key (F2). Over a remote connection you can also run `macminimode screen-on`.

## Uninstall

```bash
sudo /Applications/MacMiniMode.app/Contents/Resources/uninstall.sh
```

## License

[MIT](LICENSE)

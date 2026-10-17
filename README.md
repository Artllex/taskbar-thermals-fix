# Taskbar Thermals Fix

[Polski](README.pl.md) · [Download installer](https://github.com/Artllex/taskbar-thermals-fix/releases/latest) · [Report an issue](https://github.com/Artllex/taskbar-thermals-fix/issues)

Keep the **Taskbar Thermals temperature panel visible when the Windows 11 Start menu is open**, including the sequence **Start → click an empty part of the taskbar**.

This is an independent compatibility fix for [Quenchh/Taskbar Thermals](https://github.com/Quenchh/taskbar-thermals), implemented as a local [Windhawk](https://windhawk.net/) mod. It also offers an optional application patch for screen capture compatibility.

## Download and install

1. Install and run **Taskbar Thermals** and the standard, non-portable **x64 Windhawk** installation.
2. Download `TaskbarThermalsFix-1.0.0-Setup.exe` from [Releases](https://github.com/Artllex/taskbar-thermals-fix/releases/latest).
3. Run the installer and choose English or Polish. The standard installation adds only the Start menu compatibility mod.
4. Optionally select the **screen capture compatibility** component and point it at your existing `TaskbarThermals.exe`.

Administrator approval is needed to install a Windhawk mod. The installer restarts Taskbar Thermals so the fix can attach cleanly. It preserves temperature settings, history, logs, startup configuration, and unrelated Windhawk mods.

The optional application component supports the **official framework-dependent Taskbar Thermals 1.1.0 executable** and the documented local `1.1.0-local.7` build. Other versions, including the standalone executable, can use the Start menu mod without selecting that component. Unknown application files are rejected rather than overwritten. The optional component retains the original application's .NET 8 Desktop Runtime requirement.

## What it fixes

| Situation | Component |
| --- | --- |
| The panel disappears behind Start | Windhawk compatibility mod |
| The panel stays obscured after Start → taskbar click | Windhawk compatibility mod |
| Opening screen capture causes the application to hide the panel | Optional Taskbar Thermals application patch |
| A taskbar click briefly covers the panel | Optional application patch adds a reorder event and reduces the fallback refresh interval |

Windows moves its taskbar to a separate window band while Start is active. An ordinary always-on-top window cannot follow that transition. The mod synchronizes only the verified Taskbar Thermals window during Explorer's own taskbar band changes; it leaves other applications and the Start menu untouched. It uses private Windows interfaces, so compatibility with future Windows builds needs to be checked. Background: [ADeltaX's original window-band research](https://blog.adeltax.com/window-z-order-in-windows-10/).

## Startup and removal

The enabled mod is saved in Windhawk's configuration and loads with Windhawk. Keep Windhawk's startup enabled and Taskbar Thermals' existing startup enabled if you want both after logon. This installer does not create a second autostart entry or change the existing one.

Use **Windows Settings → Apps → Installed apps → Taskbar Thermals Fix → Uninstall** to remove it. The uninstaller restores a previous copy/configuration of the same mod if one existed, or removes its registration if it was newly installed. If the optional application patch was used, it restores the saved executable only when the current file is still the one installed by this package. If you updated it yourself afterward, that newer file is preserved and the original backup is retained in `%ProgramData%\TaskbarThermalsFix`.

## Validation

Initial validation environment: **Windows 11 25H2 x64, build 26200.9711; Windhawk 1.7.3; Taskbar Thermals 1.1.0 / local.7**.

- The working implementation was checked visually with Start open, after clicking the taskbar, and during screen capture, including three repeated Start-button click sequences.
- The installer backend is tested in isolated files and registry keys for installation, upgrade, rollback, restoring an existing mod, rejecting unsupported executables, and preserving a newer user-installed executable.
- A real Windows reboot has not been part of the initial validation. Startup registration and early Explorer initialization are handled, but a reboot test is reported separately from runtime tests.

## Build from source

Prerequisites: Windows x64, **.NET SDK 8.0.426** (pinned in `global.json`), the **Windhawk 1.7.3 offline distribution** including its compiler/SDK, and **Inno Setup 6**.

```powershell
.\scripts\build.ps1
.\tests\installer.tests.ps1
```

Use `-Dotnet`, `-WindhawkPath`, or `-InnoCompiler` to select tool locations. Outputs are written to `build/` and `dist/`. Application dependency versions and hashes are pinned in `vendor/TaskbarThermals/packages.lock.json`. The automated workflow builds and tests the same package; publishing a release is a separate, explicit operation.

## License and attribution

The compatibility mod, installer, and new code are **MIT licensed**; see [LICENSE](LICENSE). The vendored Taskbar Thermals source retains **Quenchh's MIT copyright notice**. The modified application is based on upstream commit `23207757799d2df6d22f2a42825cea81404ccbde`; changes concern foreground/shell detection, taskbar reorder handling, and the placement fallback interval.

Bundled application dependencies retain their own licenses, including MPL-2.0 components. See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md), the exact source/dependency versions, and the license texts installed with the package. Windhawk itself is a separately installed prerequisite and is not redistributed inside this installer. This project is not an official Quenchh or Windhawk release.

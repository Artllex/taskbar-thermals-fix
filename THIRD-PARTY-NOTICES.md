# Third-party notices / Informacje o zależnościach

## Taskbar Thermals

Copyright (c) 2026 Quenchh. MIT License, preserved in `vendor/TaskbarThermals/LICENSE` and installed as `payload/TaskbarThermals-LICENSE.txt`.

Upstream: https://github.com/Quenchh/taskbar-thermals/tree/23207757799d2df6d22f2a42825cea81404ccbde

The optional patched application uses the upstream 1.1.0 code with shell/fullscreen classification, taskbar reorder handling and placement fallback changes. These source changes are included in this repository. No bundled dependency source has been modified by this project.

## Application dependencies

Exact package versions, content hashes, and dependency relationships are in `vendor/TaskbarThermals/packages.lock.json`. The build generates `payload/DEPENDENCY-NOTICES.md` with package metadata and upstream source links, and includes license texts in `payload/licenses/`.

MPL-2.0 components include LibreHardwareMonitorLib, BlackSharp.Core, DiskInfoToolkit and RAMSPDToolkit-NDD. Their respective source repositories are linked in the generated notices. Source for these unmodified components remains available from their upstream repositories; the package repository commit identifiers from NuGet metadata are used when available.

HidSharp includes its own license file. Mono.Posix.NETStandard and Microsoft .NET libraries retain their upstream notices. License files present in the original NuGet packages are copied into the binary distribution, alongside canonical license texts.

## Windhawk

Windhawk is a separately installed prerequisite: https://github.com/ramensoftware/windhawk . Its application, engine and compiler are not included in this installer. This repository's mod is compiled against Windhawk 1.7.3's SDK and runs under that independently installed engine. The compatibility mod's own source is MIT licensed.

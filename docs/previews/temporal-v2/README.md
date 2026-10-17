# Temporal v2 preview evidence

These are actual Qt renders from CircleCI integration job 368 in pipeline 50
(source `775d72896001437a5c4be0c5fa0ee1f23586ac05`). The runtime state is mock
data; these images are visual evidence, not screenshots of a complete desktop
session or a hardware performance benchmark.

The matrix manifest reported 95 records with `exitCode: 0`. The Wayland and XCB
interaction logs each report 26 QML tests passed and 0 failed.

| File | Review target | Size / SHA-256 |
| --- | --- | --- |
| `temporal-study.png` | Six temporal scenes and three sizes | 138632 bytes | `0150209140c5115cc9284cabeb388ac62a2ba15b2ca1985d88cad65acba45a9c` |
| `night-desktop.png` | Dark night desktop | 202316 bytes | `1cfa226dac207e751e8130a8164c252ce862eed0c7be7b7d714fcb5b2bd09e47` |
| `axis-narrow.png` | 1366x768 narrow desktop | 134633 bytes | `601f6ac3e160cc218dac3c44a24dea16c74599bd4a2a5bcb52ee3ea81bef66e5` |
| `ribbon-detail.png` | 1920px ribbon crop | 30160 bytes | `f112ffbc2a82a01ae39c24bd58a682279b26407f6d2fb7d4cdd5fe6a2a7ccedd` |
| `temporal-expanded.png` | Expanded sunset capsule | 234603 bytes | `f7c8db85668dfcb213434e23f01bd2e46289a6eddb173178ac901ea5ba8ca982` |
| `focus-desktop.png` | Focus clock mode | 131716 bytes | `f599250115bfd14061a192b7174259c39aef3ebdb7da96291bf7dc10b092d994` |

The original supplied desktop images are design references only. These previews
use original KLDE artwork and the bundled OFL Rubik face.

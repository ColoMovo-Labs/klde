# Selected Visual Lab baselines

Actual Qt window captures from `752af8c8f36b`, CircleCI pipeline 38,
[capture job 272](https://app.circleci.com/pipelines/circleci/3oxaeukVqAvAfF4HxntS1j/9f38edc2-e2b3-4a5a-b510-656e0f838973/38/details?workflowId=6f262d05-ad85-42b2-b335-4c19c5d39b24).
These are mock-service previews, not concept illustrations or a desktop session.

The cloud job generated 72 locale/voice/theme, error, wallpaper and display
cases, plus individual panels and Wayland/XCB interaction checks. Full captures,
logs and the complete matrix manifest remain CI artifacts. These seven images are
intentional design references; [manifest.json](manifest.json) records exact input
state, physical dimensions, rendering revision and PNG hashes. The hashes identify
files, not visual acceptance or runtime performance.

| Baseline | Scope | Physical size |
| --- | --- | --- |
| [baseline-light-zh-standard](baseline-light-zh-standard.png) | Light / Chinese / Standard | 1920×1080 |
| [baseline-light-zh-cute](baseline-light-zh-cute.png) | Light / Chinese / Cute | 1920×1080 |
| [baseline-dark-zh-cute](baseline-dark-zh-cute.png) | Dark / Chinese / Cute | 1920×1080 |
| [baseline-dense-ribbon](baseline-dense-ribbon.png) | Dense ribbon / ambient workspace | 1920×1080 |
| [baseline-quick-settings](baseline-quick-settings.png) | Compact Quick Settings | 1440×900 |
| [baseline-notification-center](baseline-notification-center.png) | Notification center / original abstract wallpaper / ambient | 1920×1080 |
| [baseline-language-input](baseline-language-input.png) | Language & Input / Chinese Cute | 1440×900 |

![Notification and ambient composition](baseline-notification-center.png)

## Review and regeneration

Use the matching cloud-built binary and parameters in the manifest. For example:

```sh
klde-shell --scenario laptop-balanced --locale zh_CN --voice standard \
  --density dense --wallpaper abstract --ambient --view notifications --size 1920x1080
```

CI runs `tools/smoke-test.sh` and `tools/visual-matrix.py`. A future visual change
should compare the matching state against these images, review changed geometry,
contrast, focus, text, shapes and clipping, and deliberately select a new baseline
with its source revision. There is no automated perceptual-difference acceptance
gate yet. Images with different state, size or scale are not equivalent comparisons.

The inspected display matrix includes 1366×768, 1920×1080, 2560×1440,
2880×1800 physical HiDPI (1440×900 logical, scale 2), 3440×1440 and
1080×1920 portrait. Dense sections wrap; tall control pages scroll inside bounded
popups, and notification activity stays in a fixed footer. The candidate sample
is an owned, keyboard-selectable row, not a native cross-application IME surface.

Software-rendered idle-frame audits verify that these static views settle. They
do not measure Intel GPU utilization, power consumption, native compositor blur,
secure session behavior or real input latency. Owner design acceptance, assistive
technology and representative hardware profiling remain open in the
[mock-phase exit checklist](../development/visual-lab.md).

All screenshot artwork is original KLDE geometry. Demo identity and notifications
are synthetic; supplied references' wallpaper, logos and personal messages are
not redistributed. Font provenance is in [the asset notice](../../assets/fonts/README.md).

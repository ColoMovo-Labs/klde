# Visual System Lab

This phase is deliberately mock first. Product behavior, information density and
composition are the acceptance target before real Linux control is added. The
previous eight-job green prototype remains the engineering baseline.

SystemStateModel is the Qt-facing snapshot/control contract: nested battery,
CPU/memory/GPU, capabilities, audio/network, input, weather, time, application,
workspace, notification/media and policy state. Values are validated centrally;
QML presents this state and issues requests. MockScenarioManager loads a complete
baseline plus named overrides and applies an atomic snapshot. Selecting a scenario
resets its fixtures, revokes experimental weather consent and never changes host
settings. Manual edits remain in memory. There is no simulation repaint timer.

Existing SystemBackend, WeatherProvider, WindowManagerBackend and InputMethodBackend
remain the integration boundaries. ShellServices projects scenario state onto the
existing mock adapters and reconciles their events. This phase does not introduce
unused one-property service hierarchies; real audio/network/power connections will
split where connection lifetimes and confirmation semantics require it.

StatusModuleRegistry owns in-tree module IDs, order, section, priority and visibility.
StatusRibbon/Section/Capsule are independent presentation components. There is no
third-party ABI. Comfortable/Balanced/Dense changes shared metrics. Narrow layouts
wrap/reduce optional information and retain an expanded module view, rather than
scaling essential text to unreadable sizes.

NotificationModel owns synthetic records and dismiss/clear state. CandidatePreview
is an owned mock surface, never a cross-application IME popup. Ambient mode is an
optional desktop layout, not authentication or locking. Device capabilities describe
the simulated hardware; every policy control is labelled preview and remains in RAM.

The developer Mock Lab is opt-in through --dev-tools or Ctrl+Alt+M. Product panels
consume the same state without scenario branches. Keyboard workspace/window actions
change mock state only and do not register global shortcuts.

Cloud acceptance includes model invariants, cross-panel propagation, tone locks,
keyboard flows, all eight language/voice/theme combinations, panel/error scenes and
six display configurations including HiDPI and portrait. Screenshots are CI artifacts;
only a few intentionally selected, revision-labelled baselines enter docs/previews.
Software rendering remains correctness evidence, not GPU/power/IME acceptance.

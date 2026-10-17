# Wallpaper depth and cached backgrounds

Depth is optional enhancement. It must never become a continuous inference or
blur job. The shell runtime is a consumer of completed assets. This pass provides
an interface, settings, failure scenarios and pre-authored resource studies;
**no segmentation model, disk-cache generator or real lock service is implemented**.

## Production pipeline contract

```text
explicit wallpaper/effect change
    -> decode / identify source
    -> optional isolated foreground worker
    -> matte refinement + background preparation
    -> precompute desktop and lock blur tiers
    -> validate complete generation
    -> atomically publish manifest
    -> shell loads cached images
```

Run once for a new wallpaper, explicit Depth enable, or Regenerate request. An
opt-in Auto Cache preference may queue that same job after wallpaper changes.
Do not run inference at startup, each lock, each frame or every pointer movement.
The preview stores the Auto Cache preference only; it schedules no worker.

A future optional worker may evaluate a lightweight segmentation model, but no
model/runtime is selected or downloaded by this change. Selection requires a
pinned model revision, redistribution license, CPU latency and memory evidence.
Keep that dependency out of the core Qt shell. A plain background path always
works without it. Background reconstruction quality must be evaluated separately;
a foreground cutout alone cannot recover pixels hidden behind the subject.

Suggested private cache layout under the stable technical namespace:

```text
$XDG_CACHE_HOME/<namespace>/wallpaper/generations/<content-key>/
    original.jpg
    foreground.png
    background.jpg
    blur_desktop_low.jpg
    blur_desktop_medium.jpg
    blur_lock.jpg
    thumbnail.jpg
    meta.json
```

`meta.json` should version the schema, source digest/orientation/dimensions, worker
and model revisions, matte parameters, quality tier, color space, alpha convention,
asset sizes/digests and completion status. A cache key combines source content and
all processing inputs; changing blur quality or model revision invalidates it.
A small current-generation pointer is published only after every selected asset
is complete. Ignore stale completion from a cancelled source. Retain the previous
valid generation until the new one can be read atomically.

Use a user-owned private cache directory, bounded decoded dimensions and worker
memory, checked relative asset paths, regular files and atomic replacement.
Do not trust arbitrary paths or execute commands from a manifest. Wallpaper content
stays local; model acquisition, if later supported, must be explicit and visible.
Clear Cache affects the shell-owned generation directory, not source pictures.
Eviction and independent lock-service lifetime need a defined generation lease.

## Rendering and failure behavior

Normal mode loads the original cached image. Depth places a refined transparent
foreground on a separate static plane with slight scale/separation; no live
parallax is implemented. Avoid hard halos and sticker edges. The clock remains
readable; scene depth is subordinate to the central axis.

Soft Blur uses completed cached tiers. Lock composition uses a stronger cached
blur and a small readability tint, never a blur recomputation on each lock. These
are distinct from compositor blur behind shell panels. No shader is needed for
these cached image layers. Power Saver can suppress depth while retaining the
requested preference; returning to Balanced restores it without regeneration.

Missing, failed, stale, unsupported or incomplete cache -> plain wallpaper.
Clearing cache immediately drops foreground/soft layers. Disabling linked lock
wallpaper keeps the visual preview on its plain fallback. Future live generation
should expose queued/running/cancelled/failed separately rather than pretending
an asynchronous operation completed immediately.

## What the prototype demonstrates

`WallpaperEffectsBackend` separates requested mode from effective mode and exposes
cache validity and layer URLs. Settings cover Normal/Depth/Soft Blur, linked lock,
auto-cache preference, foreground, blur tiers and quality. Resource studies exist
only for the original Snow wallpaper. Regenerate Sample simulates readiness for
that fixture; other wallpapers simulate failure. It does not generate files.

The soft/lock studies are original smooth SVG gradients, not calculated Gaussian
blur or extracted layers. Tier controls blend those sample assets; they are not
performance or image-quality benchmarks. The foreground is pre-authored original
vector geometry. The lock page clearly states that it cannot lock/authenticate a
session. Real secure locking belongs to an audited Wayland/session implementation.

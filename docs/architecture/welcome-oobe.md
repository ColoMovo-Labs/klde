# KLDE Welcome / OOBE boundary

`WelcomeFlow` is a first-run experience that starts after the host distribution
has installed KLDE. It is not an installer and never owns disks, partitions,
accounts or package transactions.

The flow keeps core KLDE steps independent from distribution services:

```text
WelcomeFlow
  ├─ language, input, appearance, window preference
  ├─ privacy, weather and optional accounts
  ├─ non-blocking update check
  └─ local preparation and desktop handoff
        └─ DistributionWelcomeProvider (future)
```

The supplied mint fox reference is used as a replaceable guide asset in the
welcome screen, currently with a small welcoming wave. It is deliberately treated as project artwork, not as a
security identity or a mandatory mascot on every page. The source asset lives
at `assets/welcome/klde-guide-placeholder.png` until a final licensed character
asset is selected.

Optional network failures are ordinary status outcomes. The user can always
skip setup or enter the desktop once local preparation is complete. Reduced
motion and keyboard navigation are part of the surface contract.

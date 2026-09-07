# Changelog

## 0.134 (unreleased — pending review)

### Fixed
- `Write-ProgressBar` on a closed bar no longer calls `exit` (which terminated the
  entire host session). It now writes a warning and returns. ([#16](https://github.com/Tiberriver256/PoshProgressBar/issues/16) context; reported via triage)
- Timer-failure branch referenced undefined `$clock` (`$clock.Close()`); now stops the
  `$timer` (`DispatcherTimer`) and writes an error.
- Window icon assignment used undefined `$Icon`; now assigns the constructed `$icon`.
- `Write-ProgressBar -PercentComplete 0` was silently dropped (`if ($PercentComplete)`);
  now uses `$PSBoundParameters.ContainsKey('PercentComplete')` with `[ValidateRange(0,100)]`.

### Added (issue #17 triage — contributed by VDL / Paul Vergouwe)
- `New-ProgressBar` window options: `-Topmost`, `-ResizeMode`
  (`NoResize|CanMinimize|CanResize|CanResizeWithGrip`), `-ShowInTaskbar`,
  `-PicturePath` (optional logo beside the bar), `-ShowOnPrimaryMonitor`
  (multi-monitor workaround: opens on the primary monitor).
- Early `Test-Path` validation for `-IconPath` / `-PicturePath` with warnings instead
  of broken XAML.
- Friendly error on non-Windows hosts (module requires WPF).

### Changed
- Assembly loading: `Add-Type -AssemblyName` first, legacy `LoadWithPartialName`
  fallback (was `LoadWithPartialName` only).
- UI refresh timer: 10 ms → 250 ms, matching the documented "4 times every second"
  (major CPU-spin reduction).
- Manifest: version `0.133` → `0.134`, `PowerShellVersion 5.1`,
  `CompatiblePSEditions = @('Desktop')`, Gallery metadata filled
  (Tags, LicenseUri, ProjectUri, ReleaseNotes).
- Known issue (from contributor): with `-PicturePath` + `-Size Large`, the bar can
  start too far left and overlap the picture; percent-fill calibration is approximate.

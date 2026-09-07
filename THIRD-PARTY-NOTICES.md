# Third-party notices — vendored Material Design binaries

`PoshProgressBar/` ships two prebuilt .NET Framework assemblies from the
**MaterialDesignInXAML toolkit** (originally "Material Design in XAML Toolkit"
by ButchersBoy / James Willock and contributors):

- `MaterialDesignThemes.Wpf.dll` (~3.1 MB)
- `MaterialDesignColors.dll` (~223 KB)

## Provenance (best-effort, legacy vendoring)

- Both assemblies target **.NET Framework 4.0** (verified via assembly metadata strings).
- They were committed to this repository circa **2015–2016** alongside the original
  blog-series code; the exact upstream release tag was never recorded.
- Upstream project: <https://github.com/MaterialDesignInXAML/MaterialDesignInXamlToolkit>
- Upstream license: **MIT** (same as this module).

## Why this is recorded as tech debt

- The binaries are **unsigned, version-unpinned, and ~10 years stale**. They cannot be
  verified against a published hash and predate PowerShell 7 / .NET Core entirely.
- The module loads them via `NestedModules` in `PoshProgressBar.psd1`.

## How to verify locally (Windows)

```powershell
# Show file / product versions embedded in the DLLs:
Get-Item ./PoshProgressBar/*.dll | Select-Object Name, Length,
    @{n='FileVersion';e={$_.VersionInfo.FileVersion}},
    @{n='ProductVersion';e={$_.VersionInfo.ProductVersion}}

# Or run the provenance helper (prints metadata + guidance):
./tools/Get-DllProvenance.ps1
```

## Recommended path forward

1. Identify the closest upstream release (likely a 2015-era `MaterialDesignThemes`
   build for .NET 4.0) and record its tag + commit hash here.
2. Upgrade to a current signed `MaterialDesignThemes` release and reference it as a
   **NuGet package at build/publish time** instead of committing binaries.
3. Long term: make `-MaterialDesign` an optional dependency so the `Standard`
   (dependency-free WPF) progress bar works with zero binaries.

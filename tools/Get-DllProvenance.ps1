#Requires -Version 5.1
<#
.SYNOPSIS
    Prints embedded version / target-framework metadata for the vendored DLLs.
.DESCRIPTION
    Best-effort provenance helper for THIRD-PARTY-NOTICES.md. Run on Windows for
    full VersionInfo; elsewhere it falls back to size + target-framework strings.
#>
[CmdletBinding()]
param(
    [string]$LibDir = (Join-Path $PSScriptRoot '..' 'PoshProgressBar')
)

foreach ($dll in Get-ChildItem -Path $LibDir -Filter *.dll) {
    Write-Host "== $($dll.Name) ($([math]::Round($dll.Length / 1KB)) KB) =="
    $vi = $dll.VersionInfo
    if ($vi.FileVersion -or $vi.ProductVersion) {
        Write-Host "  FileVersion:    $($vi.FileVersion)"
        Write-Host "  ProductVersion: $($vi.ProductVersion)"
    }
    else {
        Write-Host '  (no VS_VERSION_INFO resource - legacy unsigned build)'
    }
    $bytes = [IO.File]::ReadAllBytes($dll.FullName)
    $text = [Text.Encoding]::ASCII.GetString($bytes)
    foreach ($m in [regex]::Matches($text, '\.NETFramework,Version=v[0-9.]+')) {
        Write-Host "  Target: $($m.Value)"
        break
    }
}
Write-Host ''
Write-Host 'See THIRD-PARTY-NOTICES.md for upgrade guidance.'

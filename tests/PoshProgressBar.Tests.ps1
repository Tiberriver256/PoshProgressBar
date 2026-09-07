BeforeAll {
    $ModuleRoot = Join-Path $PSScriptRoot '..' 'PoshProgressBar'
    $ManifestPath = Join-Path $ModuleRoot 'PoshProgressBar.psd1'
    $ScriptPath = Join-Path $ModuleRoot 'PoshProgressBar.psm1'
    $ScriptText = Get-Content -Path $ScriptPath -Raw
    $Ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $ScriptPath, [ref]$null, [ref]$null
    )
}

Describe 'PoshProgressBar module health' {

    Context 'Manifest' {
        It 'has a valid manifest' {
            { Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } | Should -Not -Throw
        }

        It 'exports the three public functions' {
            $manifest = Test-ModuleManifest -Path $ManifestPath
            $manifest.ExportedFunctions.Keys | Sort-Object | Should -Be @('Close-ProgressBar', 'New-ProgressBar', 'Write-ProgressBar')
        }

        It 'declares Gallery metadata (Tags, LicenseUri, ProjectUri, ReleaseNotes)' {
            $data = Import-PowerShellDataFile -Path $ManifestPath
            $data.PrivateData.PSData.Tags.Count | Should -BeGreaterThan 0
            $data.PrivateData.PSData.LicenseUri | Should -Not -BeNullOrEmpty
            $data.PrivateData.PSData.ProjectUri | Should -Not -BeNullOrEmpty
            $data.PrivateData.PSData.ReleaseNotes | Should -Not -BeNullOrEmpty
        }

        It 'targets Desktop edition / PS 5.1+ (WPF requirement)' {
            $data = Import-PowerShellDataFile -Path $ManifestPath
            $data.CompatiblePSEditions | Should -Contain 'Desktop'
            ([version]$data.PowerShellVersion) | Should -BeGreaterOrEqual ([version]'5.1')
        }
    }

    Context 'Static code checks (run anywhere)' {
        It 'parses without syntax errors' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$errors)
            $errors.Count | Should -Be 0
        }

        It 'never calls exit (must not kill the host session)' {
            $exits = $Ast.FindAll(
                { param($n) $n -is [System.Management.Automation.Language.ExitStatementAst] }, $true
            )
            $exits.Count | Should -Be 0
        }

        It 'has no references to the undefined $clock variable' {
            # AST-based (comments mentioning the old bug do not count).
            $clocks = $Ast.FindAll(
                { param($n) $n -is [System.Management.Automation.Language.VariableExpressionAst] -and $n.VariablePath.UserPath -eq 'clock' }, $true
            )
            $clocks.Count | Should -Be 0
        }

        It 'uses modern assembly loading (Add-Type), not only LoadWithPartialName' {
            $ScriptText | Should -Match 'Add-Type\s+-AssemblyName'
        }

        It 'handles 0% updates (no truthiness check on PercentComplete)' {
            $ScriptText | Should -Match "ContainsKey\('PercentComplete'\)"
        }

        It 'exposes issue #17 window options' {
            foreach ($param in 'Topmost', 'ResizeMode', 'ShowInTaskbar', 'PicturePath', 'ShowOnPrimaryMonitor') {
                $ScriptText | Should -Match ('\$' + $param)
            }
        }
    }

    Context 'Smoke (Windows only)' {
        BeforeAll {
            $IsWin = ($PSVersionTable.PSEdition -eq 'Desktop') -or $IsWindows
        }

        It 'imports and exposes commands' -Skip:(-not $IsWin) {
            Import-Module $ModuleRoot -Force
            (Get-Command -Module PoshProgressBar).Name | Sort-Object |
                Should -Be @('Close-ProgressBar', 'New-ProgressBar', 'Write-ProgressBar')
        }

        It 'Write-ProgressBar on a closed bar warns instead of exiting' -Skip:(-not $IsWin) {
            Import-Module $ModuleRoot -Force
            $bar = [pscustomobject]@{ Closing = $true }
            { Write-ProgressBar -ProgressBar $bar -Activity 'x' -WarningAction Stop } |
                Should -Throw
        }
    }
}

@{
    # CI quality gate: surface errors and warnings. Exclusions are deliberate:
    # - PSAvoidUsingWMICmdlet / PSAvoidUsingEmptyCatchBlock: not applicable to this module.
    # - PSReviewUnusedParameter: runspace-bound synchash pattern trips false positives; tests cover params.
    # - PSUseShouldProcessForStateChangingFunctions: New-/Write-/Close-ProgressBar manage a live
    #   STA UI runspace; -WhatIf semantics don't apply meaningfully. Destructive-action safety is
    #   covered by the explicit Close-ProgressBar step instead.
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        'PSAvoidUsingWMICmdlet',
        'PSReviewUnusedParameter',
        'PSUseShouldProcessForStateChangingFunctions'
    )
}

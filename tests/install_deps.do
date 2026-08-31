foreach pkg in ivreg2 ranktest ivreghdfe distinct ftools require {
    capture which `pkg'
    if _rc {
        di "installing `pkg'..."
        ssc install `pkg', replace
    }
    else di "`pkg' already installed"
}

* reghdfe must be >= 6.12.5; -require- installs/updates it when missing or too old
require reghdfe>=6.12.5, install

* final sanity check: every dependency resolvable
foreach pkg in ivreg2 ranktest ivreghdfe distinct ftools require reghdfe {
    which `pkg'
}

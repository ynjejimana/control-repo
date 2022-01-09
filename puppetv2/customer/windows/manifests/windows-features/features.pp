define windows::windows-features::features ($ensure) {

$source=hiera('windows::windows-features::features::source',undef)

        dism { $title :
            ensure    => $ensure,
            all       => true,
            norestart => true,
            source    => $source,
            }
}


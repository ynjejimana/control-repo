define windows::windows-basicsoftware::packages ($ensure,$source,$installoptions = []) {

        package { $title :
            ensure          => $ensure,
            source          => $source,
            provider        => windows,
            install_options => $installoptions,
            }
}


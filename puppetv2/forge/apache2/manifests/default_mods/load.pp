# private define
define apache2::default_mods::load ($module = $title) {
  if defined("apache2::mod::${module}") {
    include "::apache2::mod::${module}"
  } else {
    ::apache2::mod { $module: }
  }
}

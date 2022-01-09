# Note: this sets the global DirectoryIndex directive, it may be necessary to consider being able to modify the apache2::vhost to declare DirectoryIndex statements in a vhost configuration
# Parameters:
# - $indexes provides a string for the DirectoryIndex directive http://httpd.apache.org/docs/current/mod/mod_dir.html#directoryindex
class apache2::mod::dir (
  $dir     = 'public_html',
  $indexes = ['index.html','index.html.var','index.cgi','index.pl','index.php','index.xhtml'],
) {
  validate_array($indexes)
  include ::apache2
  ::apache2::mod { 'dir': }

  # Template uses
  # - $indexes
  file { 'dir.conf':
    ensure  => file,
    path    => "${::apache2::mod_dir}/dir.conf",
    mode    => $::apache2::file_mode,
    content => template('apache2/mod/dir.conf.erb'),
    require => Exec["mkdir ${::apache2::mod_dir}"],
    before  => File[$::apache2::mod_dir],
    notify  => Class['apache2::service'],
  }
}

class scm_manager::params {
	$docroot = "/var/www/html"
	$ajp_port = 8000
	$application_user = "tomcat"
	$application_group = "tomcat"
	$version = "1.35"
	$installdir = "/var/lib"
	$instancedir = "${installdir}/scm-manager"
	$warfile_dest = "${instancedir}/webapps/ROOT.war"
	$warfile_source = "http://maven.scm-manager.org/nexus/content/repositories/releases/sonia/scm//scm-webapp/${version}/scm-webapp-${version}.war"
}
class common::spacewalk::params {
  $sw_version = '2.2'
  $sw_satellite_server = ''
  $sw_db_server = ''
  $sw_pg_user   = 'postgres'
  $sw_pg_group  = 'postgres'
  $sw_pg_pass   = 'sp@$ewa1k'
  $sw_db_name   = 'spacewalk'
  $sw_db_user   = 'spacewalk'
  $sw_db_pass   = 'sp@$ewa1k'
  $sw_sat_user = 'admin'
  $sw_sat_pass = '5acred1y'
  $uln_user = 'user@lab.com.au'
  $uln_pass = 'very_strong_password'
  $sw_admin_email = 'unix@lab.com.au'
  $sw_ca_org = 'NTT ICT'
  $sw_ca_org_unit = 'ESBU'
  $sw_ca_city = 'Sydney'
  $sw_ca_state = 'NSW'
  $sw_ca_country_code = 'AU'
  $sw_ca_cert_password = 'spacewalk'
  $sw_ca_cert_email = 'unix@lab.com.au'
  $sw_configure_apache_ssl = true
  $sw_enable_cobbler = false
  $sw_env_phases = 'dev, test, prod'
  $sw_enable_pam_auth = true
}

# SpaceWalk agent registration to Satellite server
#
# 1) The server/proxy address is delivered via Hiera - depending on the client location
# 
# 2) activation key might be provided via Puppet or, if missing, it is defined based on:
#	- OS vendor
#	- OS version
#	- Environment
#	

class common::spacewalk::client (
  $sw_sat_proxy = hiera(common::spacewalk::client::proxy),
  $client_env = pick(hiera(common::spacewalk::client::env),'prod'),
  $client_org = pick(hiera(common::spacewalk::client::org),'1'),
  $cu_act_key = hiera(common::spacewalk::client::customer_activation_key),
  $act_key = hiera_array(common::spacewalk::client::activation_key, []),
  $centos_6_supported_minor_version,
  $centos_7_supported_minor_version,
  $oel_6_supported_minor_version,
  $oel_7_supported_minor_version,
  $client_ver = $::operatingsystemmajrelease,
  $client_arch = pick(downcase($::architecture),'x86_64'),
  $force_register = false,
  $osad = true,
  $activate = true,
  $create_local_repos = true,
) {

    if $::operatingsystem == 'OracleLinux' {
      $client_os =  'oel'
    }
    else {
      $client_os = downcase($::operatingsystem)
    }
    
    case $client_os {
      'centos': {
        if $osad {
          $packageList = ['rhn-client-tools',
                          'rhn-check',
                          'rhn-setup',
                          'm2crypto',
                          'yum-rhn-plugin',
                          'osad']
        }
        else {
          $packageList = ['rhn-client-tools',
                          'rhn-check',
                          'rhn-setup',
                          'm2crypto',
                          'yum-rhn-plugin']
        }
        case $::operatingsystemmajrelease {
          '6': {
            $key_os_ver = $centos_6_supported_minor_version
          }
          '7': {
            $key_os_ver = $centos_7_supported_minor_version
          }
          default: {}
        }
        $rhnreg_cmd = '/usr/sbin/rhnreg_ks'
      }
      'oel': {
        if $osad {
          $packageList = ['rhn-client-tools',
                          'rhn-check',
                          'rhn-setup',
                          'm2crypto',
                          'yum-rhn-plugin',
                          'osad']
        }
        else {
          $packageList = ['rhn-client-tools',
                          'rhn-check',
                          'rhn-setup',
                          'm2crypto',
                          'yum-rhn-plugin']
        }
        case $::operatingsystemmajrelease {
          '6': {
            $key_os_ver = $oel_6_supported_minor_version
        }
          '7': {
            $key_os_ver = $oel_7_supported_minor_version
        }
        default: {}
      }
      $rhnreg_cmd = '/usr/sbin/rhnreg_ks'
    }
    default: {
      fail('OS is not supported')
    }
  }

    if $cu_act_key == 'undef' {
      $cu_act_key_temp = "${client_org}-${client_env}-${client_os}-${key_os_ver}-${client_arch}"
    }
    else {
      $cu_act_key_temp = $cu_act_key
    }

    $act_key_temp = prefix($act_key, "${client_org}-")
    $act_keys = join($act_key_temp, ',')
    $activation_key_option = " --activationkey=${cu_act_key_temp},${act_keys}"
    $serverURL_option = "  --serverUrl=https://${sw_sat_proxy}/XMLRPC"
    $sslcert_option = '  --sslCACert=/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT'
    $rhnreg_options = "${serverURL_option}${activation_key_option}${sslcert_option}"
    
    if $common::spacewalk::client::activate == true {
      require common::spacewalk::gpg_keys
      if $::is_spacewalk_client_registered == '1' or $force_register {  # if client is not with spacewalk
        if $create_local_repos == true {
          require common::spacewalk::repo_client
        }

        # Going to need to remove this in favour of an EXEC in order to avoid 
        # a dependency cycle between rpm/yum and the spacewalk class itself
        #package {$packageList:
        # ensure  => latest,
        # require => Yumrepo['lab-spacewalk-client'],
        #}
        $requiredPackages = join($packageList, ' ')
        if $create_local_repos == true {
          exec {'install_prereqs':
            command => "/usr/bin/yum -y install ${requiredPackages}",
            require => Yumrepo['lab-spacewalk-client'],
          }
        } else {
          exec {'install_prereqs':
            command => "/usr/bin/yum -y install ${requiredPackages}",
          }
        }

        if $osad {
          service {'osad':
            ensure  => running,
            require => Exec['install_prereqs'],
          }
        }

        # setup the prereq directory
        exec {'setup_prereq_dir':
          path    =>  ['/bin', '/usr/bin'],
          command =>  'mkdir -p /usr/share/rhn && chown root:root /usr/share/rhn',
          creates =>  '/usr/share/rhn',
        }
        
        wget::fetch {'satellite_ssl_cert':
          source      => "http://${sw_sat_proxy}/pub/RHN-ORG-TRUSTED-SSL-CERT",
          destination => '/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT',
          require     => Exec['setup_prereq_dir'],
          before      => Exec['install_prereqs'],
        }



        if $force_register {
          exec {'registerClient':
            command => "${rhnreg_cmd}${rhnreg_options} --force",
            require => [ Wget::Fetch['satellite_ssl_cert'], Exec['install_prereqs'] ],
            notify  => Exec['disable_local_repo'],
          }
        }
        else {
          exec {'registerClient':
            command => "${rhnreg_cmd}${rhnreg_options}",
            creates => '/etc/sysconfig/rhn/systemid',
            require => [ Wget::Fetch['satellite_ssl_cert'], Exec['install_prereqs'] ],
            notify  => Exec['disable_local_repo'],
          }
        }

        exec {'disable_local_repo':
          command     => 'sed -i s/enabled=1/enabled=0/g /etc/yum.repos.d/*.repo',
          path        => ['/bin'],
          returns     => [0,2],
          refreshonly => true,
          #unless => '/usr/bin/yum repolist | grep "^lab-" 1>/dev/null 2>/dev/null',
        }


      }
    }
    else {
      #removing spacewalk client
    }
}


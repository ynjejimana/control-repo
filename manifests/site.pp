#class nodes {

#include common::motd::default
#include common::users::dev_group::group_name
#include common::users::net_group::group_name
#include common::users::uni_group::group_name
#include common::users::recovery_account::password
#include common::users::root_account::password
#include common::users::admin_group::group_name
#include common::users::unix_accounts::current_users
#include common::users::unix_accounts::former_users
#include common::users::developers_accounts::former_users
#include common::users::developers_accounts::current_users
#include common::users::networking_accounts::current_users
#include common::users::networking_accounts::former_users
# include common::resolv::resolvconf::search_domains

#}

#node 'agent01.lab.com' {
#        include apache
#	include motd
#        include issue
#        include git
#        include curl
#        include wget
#        include vim

#}

#node 'agent02.lab.com' {
#        include apache
#	include motd
#        include issue
#        include git
#        include curl
#        include wget
#        include vim
#}

#node 'agent03.lab.com' {
#        include apache
#	include motd
#        include issue
#        include git
3        include curl
#        include wget
#        include vim
#}


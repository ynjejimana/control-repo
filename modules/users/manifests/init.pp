class users {
  
  include users::developers_accounts::current_users
  include users::dev_group::group_name
}

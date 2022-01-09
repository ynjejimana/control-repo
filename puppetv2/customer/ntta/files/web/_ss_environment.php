<?php

#define('SS_ENVIRONMENT_TYPE', 'live');
define('SS_ENVIRONMENT_TYPE', 'dev');

define('SS_DATABASE_SERVER', 'localhost');
define('SS_DATABASE_USERNAME', 'lab');
define('SS_DATABASE_PASSWORD', 'Fo5BfByTcJX6xoOj');

define('NTT_PROXY_HOST', '172.22.6.132');
define('NTT_PROXY_PORT', '8080');

//define('SS_DEFAULT_ADMIN_USERNAME', 'nttdefaultadmin');
//define('SS_DEFAULT_ADMIN_PASSWORD', 'nttdefaultpassword');

define('SS_ERROR_LOG', 'errors.log');

global $_FILE_TO_URL_MAPPING;
$_FILE_TO_URL_MAPPING['/var/www/html/lab'] = 'https://www-qat.lab.com/';

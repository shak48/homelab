<?php
$CONFIG = array (
  'htaccess.RewriteBase' => '/',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'apps_paths' => 
  array (
    0 => 
    array (
      'path' => '/var/www/html/apps',
      'url' => '/apps',
      'writable' => false,
    ),
    1 => 
    array (
      'path' => '/var/www/html/custom_apps',
      'url' => '/custom_apps',
      'writable' => true,
    ),
  ),
  'upgrade.disable-web' => true,
  'instanceid' => 'ocsief47ywlp',
  'passwordsalt' => 'fVvALEUYbYhoDxjf5Xx9aZMujSptTR',
  'secret' => '7Lj1Ucg5t4TTXVufgSzAOqA0K0o0OM9By/rEmMCRYOuBElY7',
  'trusted_domains' => 
  array (
    0 => '192.168.10.124',
    1 => 'nc.shak48.ddns.net',       //My Domains
    2 => 'shak48.mooo.com',
    3 => 'npm.local',
  ),
  'trusted_proxies' => ['192.168.10.122/24'],   // your LAN / proxy IP
  'overwriteprotocol' => 'https',
  'datadirectory' => '/var/www/html/data',
  'dbtype' => 'mysql',
  'version' => '31.0.8.1',
  'dbname' => 'nextcloud',
  'dbhost' => 'db',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'nextcloud',
  'dbpassword' => '"{{mysql_root_password}}"',
  'installed' => true,
  'forwarded_for_headers' => ['HTTP_X_FORWARDED_FOR','HTTP_X_FORWARDED','HTTP_FORWARDED_FOR','HTTP_FORWARDED'],

);
#!/usr/bin/env sh
set -e

: "${MOODLE_DATAROOT:=/var/moodledata}"
: "${DB_TYPE:=pgsql}"
: "${DB_PORT:=5432}"
: "${DB_PREFIX:=mdl_}"

mkdir -p "$MOODLE_DATAROOT"
chown -R www-data:www-data "$MOODLE_DATAROOT"

# Gera config.php se ainda não existir e as vars do DB estiverem definidas
if [ ! -f /var/www/html/config.php ] && [ -n "$DB_HOST" ] && [ -n "$DB_NAME" ] && [ -n "$DB_USER" ] && [ -n "$DB_PASS" ]; then
  : "${MOODLE_WWWROOT:=http://localhost}"
  cat > /var/www/html/config.php <<'PHP'
<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = getenv('DB_TYPE') ?: 'pgsql';
$CFG->dblibrary = 'native';
$CFG->dbhost    = getenv('DB_HOST');
$CFG->dbname    = getenv('DB_NAME');
$CFG->dbuser    = getenv('DB_USER');
$CFG->dbpass    = getenv('DB_PASS');
$CFG->prefix    = getenv('DB_PREFIX') ?: 'mdl_';
$CFG->dboptions = array(
  'dbpersist' => 0,
  'dbport'    => intval(getenv('DB_PORT') ?: 5432),
  'dbsocket'  => '',
  'dbcollation' => 'utf8mb4_unicode_ci',
);

$CFG->wwwroot   = getenv('MOODLE_WWWROOT') ?: 'http://localhost';
$CFG->dataroot  = getenv('MOODLE_DATAROOT') ?: '/var/moodledata';
$CFG->admin     = 'admin';
$CFG->directorypermissions = 02777;

require_once(__DIR__ . '/lib/setup.php');
PHP
  chown www-data:www-data /var/www/html/config.php
fi

# Executa o comando padrão do container (Apache) ou o que for passado
if [ "$#" -gt 0 ]; then
  exec "$@"
else
  exec apache2-foreground
fi
#!/usr/bin/env sh
set -ex

# Diretórios (Free = efêmero)
: "${MOODLE_DATAROOT:=/tmp/moodledata}"
: "${MOODLE_TEMPDIR:=/tmp/moodletemp}"
: "${MOODLE_CACHEDIR:=/tmp/moodlecache}"
: "${MOODLE_LOCALCACHEDIR:=/tmp/moodlelocalcache}"

: "${DB_TYPE:=pgsql}"
: "${DB_PORT:=5432}"
: "${DB_PREFIX:=mdl_}"

echo "[entrypoint] Preparando diretórios"
mkdir -p "$MOODLE_DATAROOT" "$MOODLE_TEMPDIR" "$MOODLE_CACHEDIR" "$MOODLE_LOCALCACHEDIR"
chown -R www-data:www-data "$MOODLE_DATAROOT" "$MOODLE_TEMPDIR" "$MOODLE_CACHEDIR" "$MOODLE_LOCALCACHEDIR"

# (Re)gera config.php a partir das variáveis
if [ "${FORCE_CONFIG:-1}" = "1" ]; then
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

$CFG->wwwroot        = getenv('MOODLE_WWWROOT') ?: 'http://localhost';
$CFG->dataroot       = getenv('MOODLE_DATAROOT') ?: '/tmp/moodledata';
$CFG->tempdir        = getenv('MOODLE_TEMPDIR') ?: '/tmp/moodletemp';
$CFG->cachedir       = getenv('MOODLE_CACHEDIR') ?: '/tmp/moodlecache';
$CFG->localcachedir  = getenv('MOODLE_LOCALCACHEDIR') ?: '/tmp/moodlelocalcache';

$CFG->dbsessions = 1;
$CFG->session_handler_class = '\core\session\database';
$CFG->reverseproxy = true;
$CFG->sslproxy     = true;

$CFG->admin = 'admin';
$CFG->directorypermissions = 02777;

require_once(__DIR__ . '/lib/setup.php');
PHP
  chown www-data:www-data /var/www/html/config.php
fi

echo "[entrypoint] Entregando para docker-php-entrypoint"
if [ "$#" -gt 0 ]; then
  exec /usr/local/bin/docker-php-entrypoint "$@"
else
  exec /usr/local/bin/docker-php-entrypoint apache2-foreground
fi
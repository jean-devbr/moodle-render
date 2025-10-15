#!/usr/bin/env sh
set -ex

# Corrige ${APACHE_DOCUMENT_ROOT} não definido no Apache
: "${APACHE_DOCUMENT_ROOT:=/var/www/html}"
export APACHE_DOCUMENT_ROOT
echo "Define APACHE_DOCUMENT_ROOT ${APACHE_DOCUMENT_ROOT}" > /etc/apache2/conf-available/zzz-define-docroot.conf
a2enconf zzz-define-docroot >/dev/null 2>&1 || true

# Diretórios (no plano Free são efêmeros)
: "${MOODLE_DATAROOT:=/tmp/moodledata}"
: "${MOODLE_TEMPDIR:=/tmp/moodletemp}"
: "${MOODLE_CACHEDIR:=/tmp/moodlecache}"
: "${MOODLE_LOCALCACHEDIR:=/tmp/moodlelocalcache}"

mkdir -p "$MOODLE_DATAROOT" "$MOODLE_TEMPDIR" "$MOODLE_CACHEDIR" "$MOODLE_LOCALCACHEDIR"
chown -R www-data:www-data "$MOODLE_DATAROOT" "$MOODLE_TEMPDIR" "$MOODLE_CACHEDIR" "$MOODLE_LOCALCACHEDIR"

# DB (Postgres)
: "${DB_TYPE:=pgsql}"
: "${DB_PORT:=5432}"
: "${DB_PREFIX:=mdl_}"
export PGSSLMODE="${PGSSLMODE:-require}"

echo "[entrypoint] DB_HOST=${DB_HOST:-<empty>} DB_PORT=${DB_PORT:-<empty>} DB_NAME=${DB_NAME:-<empty>} DB_USER=${DB_USER:-<empty>} SSL=${PGSSLMODE}"
php -d display_errors=0 -r '
$h=getenv("DB_HOST"); $p=getenv("DB_PORT")?:5432; $d=getenv("DB_NAME"); $u=getenv("DB_USER"); $pw=getenv("DB_PASS");
$conn=@pg_connect("host={$h} port={$p} dbname={$d} user={$u} password={$pw} sslmode=". (getenv("PGSSLMODE") ?: "require"));
if(!$conn){fwrite(STDERR,"[dbcheck] ".pg_last_error()."\n");} else {echo "[dbcheck] OK\n"; pg_close($conn);}
' || true

# (Re)gera config.php
if [ "${FORCE_CONFIG:-1}" = "1" ]; then
  : "${MOODLE_WWWROOT:=http://localhost}"
  cat > /var/www/html/config.php <<'PHP'
<?php
unset($CFG); global $CFG; $CFG = new stdClass();

/* Banco */
$sslmode = getenv('PGSSLMODE') ?: 'require';
putenv('PGSSLMODE='.$sslmode);

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
  'dbschema'  => 'public',
);

/* URLs e diretórios */
$CFG->wwwroot        = getenv('MOODLE_WWWROOT') ?: 'http://localhost';
$CFG->dataroot       = getenv('MOODLE_DATAROOT') ?: '/tmp/moodledata';
$CFG->tempdir        = getenv('MOODLE_TEMPDIR') ?: '/tmp/moodletemp';
$CFG->cachedir       = getenv('MOODLE_CACHEDIR') ?: '/tmp/moodlecache';
$CFG->localcachedir  = getenv('MOODLE_LOCALCACHEDIR') ?: '/tmp/moodlelocalcache';

/* Sessões no banco */
$CFG->dbsessions = 1;
$CFG->session_handler_class = '\core\session\database';

/* Render: manter apenas SSL proxy */
$CFG->reverseproxy = false;
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
#!/bin/sh
set -e

if ! php -m | grep -q Phar; then
    echo "Installing php8-phar..."
    apk add --no-cache php8-phar
fi

until php -r "
    \$host = 'mariadb';
    \$user = getenv('DB_USER');
    \$pass = getenv('DB_PASS');
    \$db = getenv('DB_NAME');
    \$conn = new mysqli(\$host, \$user, \$pass, \$db);
    if (\$conn->connect_error) {
        die(1);
    } else {
        \$conn->close();
    }
" > /dev/null 2>&1; do
    echo "Waiting for MariaDB..."
    sleep 2
done

if [ ! -f /var/www/wp-config.php ]; then
    cat << EOF > /var/www/wp-config.php
<?php
define( 'DB_NAME', '$DB_NAME' );
define( 'DB_USER', '$DB_USER' );
define( 'DB_PASSWORD', '$DB_PASS' );
define( 'DB_HOST', 'mariadb' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );
define('FS_METHOD','direct');
\$table_prefix = 'wp_';
define( 'WP_DEBUG', false );
if ( ! defined( 'ABSPATH' ) ) {
define( 'ABSPATH', __DIR__ . '/' );}
define( 'WP_REDIS_HOST', 'redis' );
define( 'WP_REDIS_PORT', 6379 );
define( 'WP_REDIS_TIMEOUT', 1 );
define( 'WP_REDIS_READ_TIMEOUT', 1 );
define( 'WP_REDIS_DATABASE', 0 );
require_once ABSPATH . 'wp-settings.php';
EOF
fi

wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

if ! wp core is-installed --allow-root --path=/var/www; then
    echo "Installing WordPress..."
    wp core install \
        --path=/var/www \
        --url=$DOMAIN_NAME \
        --title="My WordPress Site" \
        --admin_user=$WP_ADMIN_USER \
        --admin_password=$WP_ADMIN_PASS \
        --admin_email=$WP_ADMIN_EMAIL \
        --skip-email \
        --allow-root
fi

if ! wp user get $WP_REGULAR_USER --allow-root --path=/var/www > /dev/null 2>&1; then
    echo "Creating regular user..."
    wp user create $WP_REGULAR_USER $WP_REGULAR_EMAIL --role=subscriber --user_pass=$WP_REGULAR_PASS --path=/var/www --allow-root
fi

exec /usr/sbin/php-fpm8 -F

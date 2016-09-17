FROM armv7/armhf-ubuntu:16.04
RUN apt update && \
    apt install -y mysql-client sudo bzip2 php-apcu php-fpm php-mysql php-dompdf php-zip php-xml php-xml-parser php-xml-serializer php-mbstring php-gd php-curl && \
	apt-get clean && \
	apt-get autoclean
ADD nextcloud-10.0.0.tar.bz2 /var/www/html
RUN chown -R www-data.www-data /var/www/html/
RUN mkdir /data && chown -R www-data.www-data /data
ENV databaseHost="192.168.0.120" \
databaseName="nextcloud" \
databaseUser="nextcloud" \
databasePass="nextcloud" \
nextcloudAdminUser="admin" \
nextcloudAdminPass="admin" \
nextcloudDataDir="/data" \
nextcloudTrustedDomain="localhost"

RUN cp /etc/php/7.0/fpm/php.ini /etc/php/7.0/fpm/php.ini.bak && \
    cat /etc/php/7.0/fpm/php.ini.bak | sed -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' > tee /etc/php/7.0/fpm/php.ini && \
    sed -ie "s/;env/env/" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.0/fpm/php.ini && \
    sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/7.0/fpm/php.ini && \
    sed -i '/^listen = /clisten = 0.0.0.0:9000' /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i '/^listen.allowed_clients/c;listen.allowed_clients =' /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i '/^;catch_workers_output/ccatch_workers_output = yes' /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e 's/;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/' /etc/php/7.0/fpm/php.ini && \
    sed -i -e 's/^allow_url_fopen/;allow_url_fopen/' /etc/php/7.0/fpm/php.ini && \
    sed -i -e 's/;open_basedir =/open_basedir = \/var\/www\/html:\/data:\/tmp/' /etc/php/7.0/fpm/php.ini
COPY start.sh /start.sh

RUN echo "Creating Database" && \
    mysql -h $databaseHost -u $databaseUser -p$databasePass -e "DROP DATABASE IF EXISTS $databaseName" && \
    mysql -h $databaseHost -u $databaseUser -p$databasePass -e "CREATE DATABASE IF NOT EXISTS $databaseName" && \
    echo "Installing Nextcloud" && \
    sudo -u www-data php /var/www/html/nextcloud/occ maintenance:install --database "mysql" --database-host "$databaseHost" --database-name "$databaseName" --database-user "$databaseUser" --database-pass "$databasePass" --admin-user "$nextcloudAdminUser" --admin-pass "$nextcloudAdminPass" --data-dir "$nextcloudDataDir" && \
	echo "Changing trusted domain in config" && \
	cp /var/www/html/nextcloud/config/config.php /var/www/html/nextcloud/config/config.php.org && \
	sed -e "s/0 => 'localhost',/0 => '$nextcloudTrustedDomain',/" /var/www/html/nextcloud/config/config.php > /var/www/html/nextcloud/config/config.php.new && \
	sed -e "s/'installed' => true,/'installed' => true,\n  'memcache.local' => '\\\\OC\\\\Memcache\\\\APCu',/" /var/www/html/nextcloud/config/config.php.new > /var/www/html/nextcloud/config/config.php && \
	chown www-data.www-data /var/www/html/nextcloud/config/config.php && \
	chown www-data.www-data /var/www/html/nextcloud/config/config.php.org

VOLUME /etc/php/7.0 /var/www/html/nextcloud
EXPOSE 9000
ENTRYPOINT /start.sh

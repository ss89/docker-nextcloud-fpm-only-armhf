#!/bin/bash
service php7.0-fpm start
tail -f /var/www/html/nextcloud/data/nextcloud.log

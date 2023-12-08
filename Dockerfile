FROM alpine

# add special repository for getting php7.4 sources
RUN apk update
RUN mkdir -p /run/php /run/mysqld /scripts /var/www/html
# install php-packages, nginx, composer and mariadb with env-variables specified for tzdata (required for mariadb) 
RUN apk add php php-fpm php-opcache php-xml php-curl php81-pdo php-zip nginx mariadb mariadb-client bash vim curl composer
# Make sure that php-fpm does not run as background processes (daemon)
RUN sed -i -e "s/;\?daemonize\s*=\s*yes/daemonize = no/g" /etc/php81/php-fpm.conf
RUN printf 'PS1="\[\033[01;32m\]\u:\w\[\033[0m\]$ "\ncd /var/www/html' >> ~/.bashrc

# Create group and user
RUN adduser -S www-data -G www-data

# Setup mysql
RUN mysql_install_db
# Create ENV vars for mysql
ENV MYSQL_ROOT_PASSWORD=root
ENV MYSQL_DATABASE=default

# Adjust permissions for the PHP-FPM socket (since otherwise nginx doesn't have access to it)
RUN touch /var/run/php/php8.1-fpm.sock && \
    chmod 777 /var/run/php/php8.1-fpm.sock

# Copy config files
COPY ./config/nginx.conf /etc/nginx/http.d/default.conf
COPY ./config/php-fpm.conf /etc/php81/php-fpm.d/www.conf

# Default startup
ENTRYPOINT php-fpm81 -D ; nginx ; mysqld -u root --data=./data &> /dev/null & /bin/bash

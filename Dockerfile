
FROM ubuntu:impish-20211015

LABEL Maintainer="Roman Dulman - RWT" \
      Description="Nginx + PHP7.4-FPM+Image Magik Based on Ubuntu 20.04" \
      Version = "1.3.0"

# Setup document root
RUN mkdir -p /var/www/app


# Base install
RUN apt update --fix-missing
RUN  DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y

RUN apt install php-pear php-dev

RUN apt update && apt upgrade -y

RUN ln -snf /usr/share/zoneinfo/Asia/Jerusalem /etc/localtime && echo Asia/Jerusalem > /etc/timezone
RUN apt install git zip unzip curl gnupg2 ca-certificates lsb-release libicu-dev supervisor nginx -y

RUN apt-get update && apt-get install -y libmagickwand-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN printf "\n" | pecl install imagick
RUN docker-php-ext-enable imagick


# Install php7.4-fpm
# Since the repo is supported on ubuntu 20 +
RUN apt install php-fpm php-json php-pdo php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath php-intl -y

RUN apt install php-redis -y

#RUN rm -rf /var/lib/apt/lists/*

RUN apt update && apt upgrade -y

RUN phpenmod -v 7.4 -s ALL redis

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN php -r "unlink('composer-setup.php');"
# Check if composer installation successfull
RUN composer --help

COPY ./entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

RUN rm /etc/nginx/sites-enabled/default

COPY ./php/php.ini /etc/php/7.4/fpm/php.ini
COPY ./php/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY ./nginx/server.conf /etc/nginx/sites-enabled/default.conf
COPY ./supervisor/config.conf /etc/supervisor/conf.d/supervisord.conf

RUN rm -rf /var/lib/apt/lists/*


WORKDIR /var/www/app

#RUN composer require predis/predis
#RUN composer require firebase/php-jwt
#RUN composer require nesbot/carbon
#RUN composer require guzzlehttp/guzzle
#RUN composer update
# Test PHP ver
#COPY ./php/index.php /var/www/app/index.php


EXPOSE 80

# Let supervisord start nginx & php-fpm
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# # Prevent exit
# ENTRYPOINT ["./entrypoint.sh"]
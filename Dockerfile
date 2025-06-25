FROM php:8.2-fpm

# Install system deps
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    nginx \
    npm \
    nano   \
    default-mysql-client \
    openssh-server

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Setup working directory
WORKDIR /var/www/html

# Copy Laravel source
COPY . /var/www/html

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Laravel dependencies
RUN composer install

# Setup NGINX config
COPY default.conf /etc/nginx/conf.d/default.conf

# SSH
RUN mkdir /var/run/sshd

EXPOSE 8080 22

CMD service nginx start && php-fpm
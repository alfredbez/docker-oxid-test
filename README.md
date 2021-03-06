# docker-oxid-test
[![Next Release Test Status](https://github.com/OXIDprojects/docker-oxid-test/workflows/Docker%20Image%20CI/badge.svg?branch=master)](https://github.com/OXIDprojects/docker-oxid-test/actions?query=branch%3Amaster)

A docker container for testing modules

# How to use locally v3
Warning: Version 3 is in in development!  
Please see next section (v2) for the old version

To start the Docker Container with oxid and get a terminal run:
```
docker run --rm -d -p 3306:3306 --name=gim -e  MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=oxid  mysql:5.7
docker run -p 80:80 -d --link gim:mysql --rm --name=oxid --mount type=bind,source=$(pwd),target=/var/www/module oxidprojects/oxid-test:v3_6.2-rc_php7.2

docker exec -ti oxid bash
```

## Test a module
If you want to test a module run the following commands inside the docker container:
```
cd /var/www/module
bash ../oxideshop/scripts/setup.sh

find . -not -path "./vendor/*" -name "*.php" -print0 | xargs -0 -n1 -P8 php -l
cd /var/www/oxideshop
vendor/bin/phpstan analyse --configuration phpstan.neon /var/www/module
vendor/bin/phpcs --standard=PSR12 --extensions=php /var/www/module
vendor/bin/psalm.phar --show-info=false /var/www/module
vendor/bin/runtests 
```

## Setup shop only
If you only want to see the shop then run inside the docker container:
```
cd /var/www/oxideshop
bash scripts/setupOxid.sh
```

You can also use your browser and open http://127.0.0.1 to see the oxid shop installed.

# How to use in ci

## gitlab

```
image: oxidprojects/oxid-test:v3_6.2-rc_php7.1

test:static:
  script:
    - /var/www/oxideshop/vendor/bin/phpcs --standard=PSR12 --extensions=php --ignore="vendor/|Scripts|tests" .
    - find . -not -path "./vendor/*" -name "*.php" -print0 | xargs -0 -n1 -P8 php -l

.test_template: &test_definition
  script:
    - bash /var/www/oxideshop/scripts/setup.sh
    - cd /var/www/oxideshop
    - vendor/bin/phpstan analyse --configuration phpstan.neon $MD
    - vendor/bin/runtests
  services:
    - mariadb:10.2.24
  after_script:
    - composer config cache-dir

test:OXID6.1:
  <<: *test_definition
  image: oxidprojects/oxid-test:v3_6.1_php7.1

test:OXID6.2:
  <<: *test_definition
  allow_failure: true

variables:
  MODULE_NAME: 'mymoduleid'
  DB_HOST: 'mariadb'
  MYSQL_DATABASE: 'oxid'
  MYSQL_ROOT_PASSWORD: 'root'
```

## github

```
name: oxid module tests

on: [push]

jobs:

  build:
    runs-on: ubuntu-latest
    container: oxidprojects/oxid-test:v3_6.1_php7.1
    options: -v /var/run/mysqld/mysqld.sock:/var/run/mysqld/mysqld.sock    
    env:
      MODULE_NAME: moduleinternals
      DB_HOST: "127.0.0.1"
    steps:
    - uses: actions/checkout@v1
        
    - name: Validate composer.json and composer.lock
      run: composer validate

    - name: route db from socket to port
      run: bash /var/www/oxideshop/scripts/routeDbfromSocketToPort.sh        
   
    - name: setup oxid
      run: bash /var/www/oxideshop/scripts/setup.sh

    - name: runt tests
      run: |
        cd /var/www/oxideshop/
        vendor/bin/runtests
```

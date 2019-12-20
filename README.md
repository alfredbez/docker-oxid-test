# docker-oxid-test
[![Next Release Test Status](https://github.com/OXIDprojects/docker-oxid-test/workflows/Docker Image CI/badge.svg?branch=master)](https://github.com/OXIDprojects/docker-oxid-test/actions?query=branch%3Amaster)

A docker conteainer for testing modules


# How to use locally
navigate to the module root directory and execute
```
docker run --rm -d -p 3306:3306 --name=gim -e  MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=oxid  mysql:5.7
docker run -d --link gim:mysql --rm --name=oxid --mount type=bind,source=$(pwd),target=/var/www/module oxidprojects/oxid-test:6.2-rc_php7.1
docker exec -ti oxid bash
cd /var/www/module
bash ../OXID/setup.sh

find . -not -path "./vendor/*" -name "*.php" -print0 | xargs -0 -n1 -P8 php -l
cd /var/www/OXID
vendor/bin/phpstan analyse --configuration phpstan.neon /var/www/module
vendor/bin/phpcs --standard=PSR12 --extensions=php /var/www/module
vendor/bin/psalm.phar --show-info=false /var/www/module
vendor/bin/runtests 
```

# How to use in ci

## gitlab

```
image: oxidprojects/oxid-test:6.2-rc_php7.1

test:static:
  script:
    - /var/www/OXID/vendor/bin/phpcs --standard=PSR12 --extensions=php --ignore="vendor/|Scripts|tests" .
    - find . -not -path "./vendor/*" -name "*.php" -print0 | xargs -0 -n1 -P8 php -l

.test_template: &test_definition
  script:
    - bash /var/www/OXID/setup.sh
    - cd /var/www/OXID
    - vendor/bin/phpstan analyse --configuration phpstan.neon $MD
    - vendor/bin/runtests
  services:
    - mariadb:10.2.24
  after_script:
    - composer config cache-dir

test:OXID6.1:
  <<: *test_definition
  image: oxidprojects/oxid-test:6.1_php7.1

test:OXID6.2:
  <<: *test_definition
  allow_failure: true

variables:
  MODULE_NAME: 'mymoduleid'
  DB_HOST: 'mariadb'
  MYSQL_DATABASE: 'oxid'
  MYSQL_ROOT_PASSWORD: 'root'
```

github
```
name: oxid module tests

on: [push]

jobs:

  build:
    services:
      mysql:
        image: mysql:5.7
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: oxid
        ports: 
          - 3306
        options: --health-cmd "mysqladmin ping" --health-interval 10s --health-timeout 5s --health-retries 10

    runs-on: ubuntu-latest
    container: oxidprojects/oxid-test:6.1_php7.1
    env:
      MODULE_NAME: moduleinternals
    steps:
    - uses: actions/checkout@v1
        
    - name: Validate composer.json and composer.lock
      run: composer validate

    - name: setup oxid
      run: bash /var/www/OXID/setup.sh

    - name: runt tests
      run: |
        cd /var/www/OXID/
        vendor/bin/runtests

```

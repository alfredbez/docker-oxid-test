#! bin/bash

DB_HOST=${DB_HOST:-db}
DB_NAME=${DB_NAME:-oxid}
DB_USER=${DB_USER:-root}
DB_PWD=${DB_PWD:-root}
SHOP_URL=${SHOP_URL:-http://127.0.0.1}
SHOP_LOG_LEVEL=${SHOP_LOG_LEVEL:-info}


BUILD_DIR=$(pwd)
VERSION="0.0.0-alpha$(( ( RANDOM % 100000 )  + 1 ))"
TARGET_PATH=$(grep '"target-directory":' composer.json | awk -F'"' '{print $4}')
PACKAGE_NAME=$(grep '"name":' composer.json | awk -F'"' '{print $4}')

composer config version $VERSION

cd /var/www/OXID
OXID_PATH=$(pwd)
sed -i -e "s@<dbHost>@${DB_HOST}@g; s@<dbName>@${DB_NAME}@g; s@<dbUser>@${DB_USER}@g; s@<dbPwd>@${DB_PWD}@g" source/config.inc.php
sed -i -e "s@<sShopURL>@${SHOP_URL}@g; s@sLogLevel = 'error'@sLogLevel = '${SHOP_LOG_LEVEL}'@g" source/config.inc.php
sed -i -e "s@<sShopDir>@${OXID_PATH}/source@g; s@<sCompileDir>@${OXID_PATH}/source/tmp@g" source/config.inc.php
sed -i -e "s@partial_module_paths: null@partial_module_paths: ${TARGET_PATH}@g" test_config.yml
sed -i -e "s@run_tests_for_shop: true@run_tests_for_shop: false@g" test_config.yml
#cat test_config.yml

composer config repositories.build path "${BUILD_DIR}"

#just in case the module has private repository dependencies clone that config
#into the oxid project
php -r "
\$orgComposerJson=json_decode(file_get_contents('$BUILD_DIR/composer.json'),true);
\$reUse['repositories'] = \$orgComposerJson['repositories'] ? \$orgComposerJson['repositories'] : [];
\$reUse['config'] = \$orgComposerJson['config'] ? \$orgComposerJson['config'] : [];
\$reUse['require-dev'] = \$orgComposerJson['require-dev'] ? \$orgComposerJson['require-dev'] : [];
\$c=json_decode(file_get_contents('composer.json'), true);
\$c=array_replace_recursive(\$c, \$reUse);
file_put_contents('composer.json', json_encode(\$c, JSON_PRETTY_PRINT));
//print json_encode(\$c, JSON_PRETTY_PRINT);
"

composer config minimum-stability dev
#Module Registrieren
#composer config repo.packagist false
echo "installing ${PACKAGE_NAME} in ${TARGET_PATH}"
composer require "${PACKAGE_NAME}:$VERSION"

echo loading DB
mysql -u $DB_USER -p$DB_PWD -h $DB_HOST $DB_NAME < vendor/oxid-esales/oxideshop-ce/source/Setup/Sql/database_schema.sql
mysql -u $DB_USER -p$DB_PWD -h $DB_HOST $DB_NAME < vendor/oxid-esales/oxideshop-ce/source/Setup/Sql/initial_data.sql
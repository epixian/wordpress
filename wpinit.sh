#!/bin/bash
source config.sh

echo "Initializing SSL for domain $DOMAIN ($IP)..."
echo "Using hosted zone $HOSTEDZONE"
echo "Found zone ID: $HOSTEDZONEID"

JSON=$(cat <<EOF
{
  "Comment": "$DOMAIN: upsert A record to $IP",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$DOMAIN",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$IP"
          }
        ]
      }
    }
  ]
}
EOF
)

# write to aws
echo "Updating Route 53..."
aws route53 change-resource-record-sets --hosted-zone-id $HOSTEDZONEID --change-batch "$JSON"
echo "Writing EC2 tags..."
aws ec2 create-tags --resources $INSTANCEID --tag Key="Name",Value="$DOMAIN" --region $REGION

# configure ssl
echo "Adding certbot-required apt repository..."
sudo add-apt-repository ppa:certbot/certbot -y && apt-get -qq update
echo "Installing certbot..."
sudo apt-get -qq install python-certbot-apache -y
echo "Generating SSL certificates..."
sudo certbot --apache -n --redirect --agree-tos -m epixianllc@gmail.com -d $DOMAIN
sudo certbot renew --dry-run
echo "Verify SSL at https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN&latest"

# configure apache2
echo <<EOF >> /etc/apache2/apache2.conf
ServerName $DOMAIN

<Directory /var/www/html
    AllowOverride All
</Directory>
EOF

# give index.php higher precedence
sed -i -E 's/(DirectoryIndex\s)(.+)(index.php\s)(.+)/\1\3\2\4/' /etc/apache2/mods-enabled/dir.conf

# install wordpress
echo "Downloading wordpress..."
curl -Os https://wordpress.org/latest.tar.gz
echo "Unpacking wordpress..."
tar zxf latest.tar.gz
cd wordpress
touch .htaccess
echo <<EOF >> .htaccess
<files wp-config.php>
  order allow,deny
  deny from all
</files>
EOF
chmod 660 .htaccess
cp wp-config-sample.php wp-config.php
sudo mv * /var/www/html
cd /var/www/html
sudo chown -R ubuntu:www-data /var/www/html
find . -type d -exec chmod 754 {} \;
find . -type f -exec chmod 640 {} \;
mkdir wp-content/upgrade
chown -R www-data:www-data wp-content

# begin wp configuration
echo "Configuring Wordpress..."

# get salts
curl -s https://api.wordpress.org/secret-key/1.1/salt/ > new-salts.key
sed -i '1s|^|\n*/\n|' new-salts.key
sed -i "/#@+/,/#@-/{ /#@+/{p; r new-salts.key
}; /#@-/p; d }" wp-config.php
rm -f new-salts.key

# configure db
sed -i "s/database_name_here/$DB_NAME/g" wp-config.php
sed -i "s/username_here/$DB_USER/g" wp-config.php
sed -i "s/password_here/$DB_PASS/g" wp-config.php
sed -i "s/localhost/$DB_HOST/g" wp-config.php

# misc config
echo "define('FS_METHOD', 'direct');" >> wp-config.php

# configure RDS
echo "Setting up RDS..."
mysql -u $RDS_USER -p -h $DB_HOST -e "create database if not exists $DB_NAME; create user if not exists '$DB_USER'@'%' identified by '$DB_PASS'; grant SELECT,ALTER,UPDATE,INSERT,CREATE,DELETE,DROP,INDEX,REFERENCES on $DB_NAME.* to '$DB_USER'@'%'; flush privileges;"

echo "Restarting Apache2 web server..."
sudo systemctl restart apache2

echo "Cleaning up temporary files..."
rm -rf ~/wordpress
rm -f latest.tar.gz

echo "Wordpress configuration complete."
echo "Visit https://$DOMAIN/wp-admin to complete the installation."
cd $PWD



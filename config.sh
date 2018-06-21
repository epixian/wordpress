#!/bin/bash
PWD=pwd

# domain settings
echo -n "Domain name: "
read DOMAIN

IP=$(curl -s http://icanhazip.com)

# aws metadata
HOSTEDZONE=$(echo "$DOMAIN" | grep -oE "(\w+).(\w+)$")
HOSTEDZONEID=$(aws route53 list-hosted-zones-by-name --dns-name $HOSTEDZONE --max-items 1 --output text | grep -oP "(?<=\/hostedzone\/)(\w*)")
INSTANCEID=$(ec2metadata | grep -oP "(?<=instance-id:\s).*$")
REGION=$(ec2metadata | grep -oP "(?<=availability-zone:\s)([a-z0-9-]*)(?=\w)")

# database settings
RDS_USER=epixian
DB_HOST=epixian-wordpress-mariadb.cdzz9aj3vfhz.us-east-1.rds.amazonaws.com

echo -n "Database name: "
read DB_NAME
echo -n "Database username: "
read DB_USER
echo -n "Database password: "
read DB_PASS


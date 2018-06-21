#!/bin/bash
cd /home/ubuntu
curl -OOO https://epixian.com/init/wordpress/{init,wpinit,config}.sh
chown ubuntu:ubuntu {init,wpinit,config}.sh
chmod a+x {init,wpinit,config}.sh
./init.sh &>/var/log/epixian

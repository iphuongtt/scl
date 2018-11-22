#!bin/bash

if [ $(id -u) != "0" ]; then
    printf "Ban can chay cau lenh nay bang tai khoan root"
    exit
fi
printf "Nhap dia chi ip muon tao"

read ipaddr

sed -i ~/ifcfg-enp0s3.bak "s/IPADDR=.*/IPADDR=${ipaddr}/g" /etc/sysconfig/network-scripts/ifcfg-enp0s3
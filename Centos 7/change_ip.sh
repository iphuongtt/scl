#!bin/bash

if [ $(id -u) != "0" ]; then
    printf "Ban can chay cau lenh nay bang tai khoan root"
    exit
fi

# Backup file
cp /etc/sysconfig/network-scripts/ifcfg-enp0s3 /etc/sysconfig/network-scripts/ifcfg-enp0s3.bakup
# Xoa cac dong cau hinh cu
sed -i -e "/BOOTPROTO*/d" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "/GATEWAY*/d" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "/NETMASK*/d" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "/NM_CONTROLLED*/d" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "/DNS1*/d" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "/DNS2*/d" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "/DNS3*/d" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "/ONBOOT*/d" /etc/sysconfig/network-scripts/ifcfg-enp0s3

# Them cac dong cau hinh moi
sed -i -e "$ a BOOTPROTO=\"static\"" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "$ a GATEWAY=192.168.1.1" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "$ a NETMASK=255.255.255.0" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "$ a NM_CONTROLLED=no" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "$ a DNS1=1.0.0.1" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "$ a DNS2=1.1.1.1" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "$ a DNS3=8.8.4.4" /etc/sysconfig/network-scripts/ifcfg-enp0s3
sed -i -e "$ a ONBOOT=yes" /etc/sysconfig/network-scripts/ifcfg-enp0s3
# Khoi dong lai network.service
startNo=255
prefixIp="192.168.1."
changeip()
{
	#startNo=`expr $startNo - 1`
	let startNo-=1
	ipaddr="$prefixIp$startNo"
	sed -i -e "/IPADDR*/d" /etc/sysconfig/network-scripts/ifcfg-enp0s3
	sed -i -e "$ a IPADDR=${ipaddr}" /etc/sysconfig/network-scripts/ifcfg-enp0s3
	systemctl restart network.service
	if [[ $? -ne 0 ]]; then
		echo "Ip ${ipaddr} da ton tai \n"
		changeip
	else
		clear
		echo "\e[0;34m Yeah! We found Ip address \e[0m: \e[0;32m${ipaddr}\e[0m"
	fi
}

changeip
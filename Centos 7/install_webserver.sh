#!bin/bash
# Update system

yum -y install gawk bc wget lsof

clear
printf "=========================================================================\n"
printf "Chung ta se kiem tra cac thong so VPS cua ban de dua ra cai dat hop ly \n"
printf "=========================================================================\n"

cpu_name=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
cpu_cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
cpu_freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
server_ram_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
server_ram_mb=`echo "scale=0;$server_ram_total/1024" | bc`
server_hdd=$( df -h | awk 'NR==2 {print $2}' )
server_swap_total=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
server_swap_mb=`echo "scale=0;$server_swap_total/1024" | bc`

printf "=========================================================================\n"
printf "Thong so server cua ban nhu sau \n"
printf "=========================================================================\n"
echo "Loai CPU : $cpu_name"
echo "Tong so CPU core : $cpu_cores"
echo "Toc do moi core : $cpu_freq MHz"
echo "Tong dung luong RAM : $server_ram_mb MB"
echo "Tong dung luong swap : $server_swap_mb MB"
echo "Tong dung luong o dia : $server_hdd GB"
echo "IP cua server la : $server_ip"
printf "=========================================================================\n"
printf "=========================================================================\n"

if [ $server_ram_total -lt $low_ram ]; then
	echo -e "Canh bao: dung luong RAM qua thap de cai HocVPS Script \n (it nhat 256MB) \n"
	echo "huy cai dat..."
	exit
fi
sleep 3

clear
printf "=========================================================================\n"
printf "Chuan bi qua trinh cai dat... \n"
printf "=========================================================================\n"

printf "Ban hay lua chon phien ban PHP muon su dung:\n"
prompt="Nhap vao lua chon cua ban [1-3]: "
php_version="7.1"; # Default PHP 7.1
php_install="71"
options=("PHP 7.1" "PHP 7.2" "PHP 7.3" "PHP 7.4" "PHP 7.5")
PS3="$prompt"
select opt in "${options[@]}"; do 
    case "$REPLY" in
    1) php_version="7.1"; php_install="71"; break;;
    2) php_version="7.2"; php_install="72"; break;;
    3) php_version="7.3"; php_install="73"; break;;
	4) php_version="7.4"; php_install="74"; break;;
	5) php_version="7.5"; php_install="75"; break;;
    $(( ${#options[@]}+1 )) ) printf "\nHe thong se cai dat PHP 7.1\n"; break;;
    *) printf "Ban nhap sai, he thong cai dat PHP 7.1\n"; break;;
    esac
done
yum update -y
# Install epel
yum install epel-release -y
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
# Install nginx
yum install nginx -y
# Auto start nginx when server stared
systemctl enable nginx
systemctl start nginx

firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

yum install yum-utils -y
$( yum-config-manager --enable remi-php$php_install )
$( yum --enablerepo=remi,remi-php$php_install install php-fpm php-common -y )
$( yum --enablerepo=remi,remi-php$php_install install php-opcache php-pecl-apcu php-cli php-pear php-pdo php-mysqlnd php-pgsql php-pecl-mongodb php-pecl-redis php-pecl-memcache php-pecl-memcached php-gd php-mbstring php-mcrypt php-xml php-pecl-zip -y )
systemctl enable php-fpm
systemctl start php-fpm
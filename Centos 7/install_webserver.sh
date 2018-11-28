#!bin/bash
# Update system

if [ $(id -u) != "0" ]; then
    printf "You need to be root to perform this command. Run \"sudo su\" to become root!\n"
    exit
fi

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
current_time=`date '+%Y-%m-%d_%H_%M_%S'`
server_ip=`hostname -I`
low_ram='262144' # 256MB

printf "=========================================================================\n"
printf "Your server infomation \n"
printf "=========================================================================\n"
echo "CPU Name : $cpu_name"
echo "Number CPU core : $cpu_cores"
echo "Speed of core : $cpu_freq MHz"
echo "Total RAM : $server_ram_mb MB"
echo "Total swap : $server_swap_mb MB"
echo "HDD : $server_hdd GB"
echo "IP server : $server_ip"
printf "=========================================================================\n"
printf "=========================================================================\n"

if [ $server_ram_total -lt $low_ram ]; then
	echo -e "Canh bao: dung luong RAM qua thap de cai HocVPS Script \n (it nhat 256MB) \n"
	echo "huy cai dat..."
	exit
fi

read -n 1 -s -r -p "Press any key to continue"

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
yum-config-manager --enable remi-php$php_install
yum --enablerepo=remi,remi-php$php_install install php-fpm php-common -y
yum --enablerepo=remi,remi-php$php_install install php-opcache php-pecl-apcu php-cli php-pear php-pdo php-mysqlnd php-pgsql php-pecl-mongodb php-pecl-redis php-pecl-memcache php-pecl-memcached php-gd php-mbstring php-mcrypt php-xml php-pecl-zip -y

systemctl enable php-fpm
systemctl start php-fpm

# Config Php
cp /etc/php.ini /etc/php.ini.backup$current_time
sed -i 's/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php.ini

# Config php-fpm
cp /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf.backup$current_time
sed -i 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf
sed -i 's/listen.owner = nobody/listen.owner = nginx/' /etc/php-fpm.d/www.conf
sed -i 's/listen.group = nobody/listen.group = nginx/' /etc/php-fpm.d/www.conf
sed -i 's/listen = /var/run/php-fpm/php-fpm.sock/listen = /var/run/php-fpm/php-fpm.sock/' /etc/php-fpm.d/www.conf

systemctl restart php-fpm

# Config Nginx
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup$current_time

cat > "/etc/nginx/conf.d/default.conf" <<END
server {
    listen   80;
    server_name  ${server_ip};    # note that these lines are originally from the "location /" block
    root   /var/www/html;
    index index.php index.html index.htm;    
    location / {
        try_files $uri $uri/ =404;
    }
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/html;
    }    
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
END

systemctl restart nginx

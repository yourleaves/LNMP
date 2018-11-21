#!/bin/bash
#by ming

check_user () {
login_user=`who am i|awk '{print $1}'`
if [ $login_user != "root" ];then
  echo "必须用root用户运行"
  exit 1
fi
}

yum_nginx (){
echo -------------------------开始安装nginx-------------------------------
rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm >/dev/null 2>&1
echo "nginx yum源安装成功"
echo "开始安装nginx"
yum install -y nginx  >/dev/null 2>&1
systemctl start nginx &&echo "nginx启动成功"
systemctl enable nginx  >/dev/null 2>&1
}

yum_php(){
echo "-------------------------开始安装php5.6 -----------------------------"
echo "安装php yum源"
yum install -y epel-release >/dev/null 2>&1 
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm >/dev/null 2>&1
echo "开始安装php56"
yum install php56w-fpm php56w-opcache php56w-mysql php56w-devel -y  >/dev/null 2>&1
systemctl enable php-fpm  >/dev/null 2>&1
systemctl start php-fpm 
echo "开始集成nginx"
for i in {30..36};do
	if [ $i -eq 34 ];then
		sed -i 34d /etc/nginx/conf.d/default.conf 
		sed -i 'N;34a\fastcgi_param   SCRIPT_FILENAME    $document_root$fastcgi_script_name;'  /etc/nginx/conf.d/default.conf 
	else
		sed -i ${i}s/"#"//g /etc/nginx/conf.d/default.conf 
	fi
done
sed -i 10d /etc/nginx/conf.d/default.conf 
sed -i 'N;9a\index index.php index.html index.htm'  /etc/nginx/conf.d/default.conf 
echo "<?php <p></p>hpinfo(); ?>" > /usr/share/nginx/html/index.php

}

yum_mysql (){
echo -------------------------开始安装mysql-------------------------------
rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm >/dev/null 2>&1
echo "mysql yum 源安装成功"
echo "设置yum源版本:mysql 5.7"
sed -i 28s/"enabled=1"/"enabled=0"/g /etc/yum.repos.d/mysql-community.repo
sed -i 21s/"enabled=0"/"enabled=1"/g /etc/yum.repos.d/mysql-community.repo
echo "开始安装mysql"
yum install -y mysql mysql-server mysql-devel >/dev/null 2>&1
echo "启动mysql"
systemctl start mysqld 
systemctl enable mysqld >/dev/null 2>&1
echo "修改mysql root密码"
old_passwd=`grep "temporary password" /var/log/mysqld.log |awk '{print $NF}'`
mysql -uroot -p$old_passwd -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$new_password';" >/dev/null 2>&1
} 

firewall(){
echo '----------------------开始配置防火墙------------------------------' 
ports='80 3306'   
for port in $ports;do
echo "开始添加$port"
firewall-cmd --add-port=$port/tcp --permanent
done
echo '重新加载防火墙配置'
firewall-cmd --reload
}

main () {
clear
new_password="Mysql_test1"
check_user
yum_nginx
yum_php
yum_mysql
firewall
sleep 2
clear
echo -------------------------安装完毕-------------------------------
ipaddr=`ip a |grep inet|grep -v inet6|grep -v 127.0.0.1|awk '{print $2}'|awk -F / '{print "http://"$1}'` 
echo "安装完毕,nginx访问地址:\\n $ipaddr "
echo "mysql root 密码：$new_password"	
}

main

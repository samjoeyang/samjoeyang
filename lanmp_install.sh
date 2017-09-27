#install lanmp environment;
#Write by @SamjoeYang


function init()
{
	#import RPM-GPG-KEY and install initscripts,wget,git
	yum clean all
#	cp -rf ./repo/aliyun.repo /etc/yum.repos.d/
#	cp -rf ./repo/epel.repo /etc/yum.repos.d/
	rpm --import /etc/pki/rpm-gpg/RPM* && rpm --import http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-6
	yum -y install epel-release gcc gcc-c++ bison autoconf automake initscripts wget git svn unzip
	echo "Initialization complete" >> readme.txt
	echo "Initialization complete"
}

function install_httpd()
{
	yum -y install httpd httpd-devel
	sed -i 's/#ServerName www.example.com:80/ServerName localhost:80/g' /etc/httpd/conf/httpd.conf
}

function install_httpd_compile()
{
	#default install path is '/usr/local/',and boot script also.
	yum install -y expat-devel openssl openssl-devel

	#download packages
	if [ ! -f "httpd-2.4.27.tar.gz" ]; then
		wget -c http://mirrors.shuosc.org/apache//httpd/httpd-2.4.27.tar.gz
	fi
	if [ ! -f "apr-1.6.2.tar.gz" ]; then
		wget -c http://mirror.bit.edu.cn/apache//apr/apr-1.6.2.tar.gz
	fi
	if [ ! -f "apr-util-1.6.0.tar.gz" ]; then
		wget -c http://mirror.bit.edu.cn/apache//apr/apr-util-1.6.0.tar.gz
	fi
	if [ ! -f "pcre-8.41.zip" ]; then
		wget -c https://ftp.pcre.org/pub/pcre/pcre-8.41.zip
	fi

	tar zxvf apr-1.6.2.tar.gz && cd apr-1.6.2 && ./configure --prefix=/usr/local/apr && make && make install && cd ..

	tar zxvf apr-util-1.6.0.tar.gz && cd apr-util-1.6.0 && ./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr && make && make install && cd ..

	unzip pcre-8.41.zip && cd pcre-8.41 && ./configure && make && make install && cd ..

	tar zxvf httpd-2.4.27.tar.gz && cd httpd-2.4.27 && ./configure --prefix=/usr/local/httpd --sysconfdir=/etc/httpd/conf --enable-so --enable-rewirte --enable-ssl --enable-cgi --enable-cgid --enable-modules=all --enable-modules-shared=most --enable-mpms-shared=all --with-apr=/usr/local/apr --with-apr-util=/usr/local/apr-util --with-pcre --with-libxml2 --with-mpm=prefork && make && make install && cd ..
	#self boot script
	/usr/local/httpd/bin/apachectl start 
	#check listen port
	ss -tnl 
	#add env_value
	echo "export PATH=/usr/local/httpd/bin:$PATH">>/etc/profile.d/httpd.sh && source /etc/profile.d/httpd.sh
	#import libs
	ln -s /usr/local/httpd/include /usr/include/httpd
	#import man file
	echo "MANPATH /usr/local/httpd/man" > /etc/man.config
	#get boot script
	wget -c https://raw.githubusercontent.com/samjoeyang/samjoeyang/master/httpd_boot_sh_6 && mv httpd_boot_sh_6 /etc/rc.d/init.d/httpd && cd /etc/rc.d/init.d/ && chown root:root httpd && chmod 755 httpd
	#start on boot
	chkconfig --add httpd && chkconfig --level 345 httpd on

}

function install_nginx()
{
	echo -e "[nginx]\nname=nginx repo\nbaseurl=http://nginx.org/packages/centos/6/x86_64\ngpgcheck=0\nenabled=1" >> /etc/yum.repos.d/nginx.repo
	yum -y install nginx

}

function install_php()
{
  #install support libs
  yum -y install libxml2 libxml2-devel curl curl-devel libjpeg libjpeg-devel libpng libpng-devel libmcrypt libmcrypt-devel mhash mcrypt  libtool-ltdl libtool-ltdl-devel bzip2 bzip2-devel freetype freetype-devel openldap openldap-devel openssl openssl-devel re2c gmp gmp-devel libmcrypt libmcrypt-devel readline readline-devel libxslt libxslt-devel
  
  cp -frp /usr/lib64/libldap* /usr/lib/

#  php_version="5.6.31"
  php_version="7.1.7"

  #download php
  if [ ! -f "php-$php_version.tar.bz2" ]; then
    wget -c http://cn2.php.net/distributions/php-$php_version.tar.bz2
  fi
  if [ $php_version == "7.1.7" ]; then
    with_mysql="--enable-mysqlnd --with-mysqli=mysqlnd --with-mysql-sock=/tmp/mysql.sock --with-pdo-mysql=mysqlnd"
    with_gd="--with-gd --with-jpeg-dir=/usr/local/lib --with-png-dir --with-freetype-dir" #--with-webp-dir --with-xpm-dir 
  elif [ $php_version == "5.6.31" ]; then
    with_mysql="--enable-mysqlnd --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-mysql-sock=/tmp/mysql.sock --with-pdo-mysql=mysqlnd"
    with_gd="--with-gd --with-jpeg-dir=/usr/local/lib --with-png-dir --with-freetype-dir" #--with-vpx-dir --with-xpm-dir 
  else
    with_mysql="--enable-mysqlnd --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-mysql-sock=/tmp/mysql.sock --with-pdo-mysql=mysqlnd"
    with_gd="--with-gd --with-jpeg-dir=/usr/local/lib --with-png-dir --with-freetype-dir" #--with-xpm-dir 
  fi

  #install php
  php_path=`pwd`/php
  tar -jxvf php-$php_version.tar.bz2 && mv php-$php_version $php_path/ && cd $php_path
  #--with-apxs2=/usr/sbin/apxs --with-config-file-path=/etc --with-fpm-user=nginx --with-fpm-group=nginx--with-gmp \
  ./configure --prefix=`pwd` \
  --enable-fpm \
  --enable-inline-optimization \
  --enable-debug \
  --disable-rpath \
  --enable-shared  \
  --enable-soap \
  ${with_mysql} \
  ${with_gd} \
  --with-openssl  \
  --with-openssl-dir \
  --with-iconv \
  --with-zlib \
  --with-bz2 \
  --with-libxml-dir  \
  --with-gettext \
  --with-curl \
  --with-mhash \
  --with-mcrypt \
  --enable-mbstring \
  --enable-mbregex \
  --with-ldap \
  --with-ldap-sasl \
  --with-xmlrpc  \
  --enable-gd-native-ttf  \
  --enable-pdo  \
  --enable-pcntl \
  --enable-sockets \
  --enable-bcmath \
  --enable-xml \
  --enable-zip \
  --enable-soap \
  --enable-bcmath \
  --enable-shmop \
  --enable-sysvsem \
  --enable-inline-optimization \
  --enable-maintainer-zts \
  --enable-opcache \
  --enable-cgi \
  --without-pear \
  --disable-phar \
  --with-xmlrpc \
  --with-pcre-regex \
  --with-sqlite3 \
  --enable-bcmath \
  --with-iconv \
  --enable-calendar \
  --with-cdb \
  --enable-dom \
  --enable-exif \
  --enable-fileinfo \
  --enable-filter \
  --with-pcre-dir \
  --enable-ftp \
  --with-zlib-dir  \
  --enable-gd-native-ttf \
  --enable-gd-jis-conv \
  --with-gettext \
  --enable-json \
  --enable-mbstring \
  --enable-mbregex \
  --enable-mbregex-backtrack \
  --with-libmbfl \
  --with-onig \
  --enable-pdo \
  --with-zlib-dir \
  --with-pdo-sqlite \
  --with-readline \
  --enable-session \
  --enable-shmop \
  --enable-simplexml \
  --enable-sockets  \
  --enable-sysvmsg \
  --enable-sysvsem \
  --enable-sysvshm \
  --enable-wddx \
  --with-xsl \
  --enable-zip \
  --enable-mysqlnd-compression-support \
  --with-pear \
  --enable-opcache >> ../install_php_log 
  make >> ../install_php_log 
  make install >> ../install_php_log 
  cd ../
  
  if [ ! -f "/usr/local/bin/php-config" ]; then
    ln -s $php_path/bin/php-config  /usr/local/bin/php-config
  fi
  if [ ! -f "/usr/local/bin/phpize" ]; then
    ln -s $php_path/bin/phpize  /usr/local/bin/phpize
  fi
  if [ ! -f "/usr/local/bin/php" ]; then
    ln -s $php_path/bin/php /usr/local/bin/php
  fi
  if [ ! -f "/usr/local/bin/php-cgi" ]; then
    ln -s $php_path/bin/php-cgi /usr/local/bin/php-cgi
  fi
  echo "PATH=\$PATH:/usr/sbin:/usr/bin:/usr/local/bin" >> /etc/profile && source /etc/profile
	
  #config PHP
  cp $php_path/php.ini-development  $(php-config --prefix)/lib/php.ini && sed -i 's/\;date\.timezone \=/date\.timezone \=PRC/g' $(php-config --prefix)/lib/php.ini && sed -i "s/\;include_path \= \"\.\:\/php\/includes\"/include_path \= \"\$\(php-config --prefix\)\/lib\/php\"/g" $(php-config --prefix)/lib/php.ini && ln -s $(php-config --prefix)/bin/php /usr/bin/php
  sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 300M/g" $(php-config --prefix)/lib/php.ini
  sed -i "s/post_max_size = 8M/post_max_size = 300M/g" $(php-config --prefix)/lib/php.ini
  sed -i "s/max_execution_time = 30/max_execution_time = 600/g" $(php-config --prefix)/lib/php.ini
  sed -i "s/max_input_time = 60/max_input_time = 600/g" $(php-config --prefix)/lib/php.ini
  sed -i "s/memory_limit = 128M/memory_limit = 1024M/g" $(php-config --prefix)/lib/php.ini
	
  #config php-fpm.  use -t test fpm's configs
  kill `ps aux |grep php-fpm|cut -b 10-14`
  cp $php_path/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm && \
  chmod a+x /etc/init.d/php-fpm && \
  chkconfig --add php-fpm && \
  chkconfig php-fpm on && \
  cp $php_path/etc/php-fpm.conf.default $php_path/etc/php-fpm.conf && \
  cp $php_path/etc/php-fpm.d/www.conf.default $php_path/etc/php-fpm.d/www.conf && \
  $php_path/sbin/php-fpm -c $(php-config --prefix)/lib/php.ini -y $php_path/etc/php-fpm.conf -t && \
  $php_path/sbin/php-fpm -c $(php-config --prefix)/lib/php.ini -y $php_path/etc/php-fpm.conf

  #write something into readme.txt
  echo -e "start php-fpm:\n$php_path/sbin/php-fpm -c $(php-config --prefix)/lib/php.ini -y $php_path/etc/php-fpm.conf\nstop php-fpm:\nkill -INT 'cat /usr/local/php/var/run/php-fpm.pid'\nOR\nservice php-fpm stop\nreboot php-fpm:\nkill -USR2 'cat /usr/local/php/var/run/php-fpm.pid'\nOR\nservice php-fpm reboot" >> readme.txt

  #write phpinfo into /var/www/html
  mkdir -p /var/www/html && \
  echo "<?php phpinfo();?>" > /var/www/html/i.php && \
  cat > /var/www/html/i.php<<-EOF
<?php
$con = mysqli_connect("127.0.0.1","root","$mysqlpasswd");
if (!$con){
  die('Could not connect: ' . mysql_error());
}
echo 'Connected successfully';
mysql_close($con);
?>
EOF
#  echo -e "<?php\n\$con = mysqli_connect(\"127.0.0.1\",\"root\",\"$mysqlpasswd\");\nif (!\$con){die('Could not connect: ' . mysql_error());}\necho 'Connected successfully';\nmysql_close($con);\n?>" >>/var/www/html/i.php

  #config apache
  if [ -f "/etc/httpd/conf/httpd.conf" ]; then
    echo "AddHandler application/x-httpd-php .php" >> /etc/httpd/conf/httpd.conf
    sed -i 's/DirectoryIndex index.html index.html.var/DirectoryIndex index.php index.html index.html.var/g' /etc/httpd/conf/httpd.conf
    service httpd stop
#   service httpd restart
  fi

  #config nginx
  if [ -f "/etc/nginx/conf.d/default.conf" ]; then
    mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak
    wget -c https://raw.githubusercontent.com/samjoeyang/samjoeyang/master/nginx_vhost.conf
    mv nginx_vhost.conf /etc/nginx/conf.d/vhost.conf
#    echo -e "server\n{\n listen 80;\n server_name localhost;\n root /var/www/html;\n access_log /var/log/nginx/access_com.log;\n error_log /var/log/nginx/error_com.log;\n index index.html index.php;\n location ~ \.php$ {\n  fastcgi_pass 127.0.0.1:9000;\n  fastcgi_index index.php;\n  fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;\n  include fastcgi_params; \n  }\n}" >> /etc/nginx/conf.d/vhost.conf
#   service nginx stop
    service nginx restart
  fi
}

function uninstall_php()
{
  rm -rf php/
  rm -rf /usr/local/bin/php*
  rm -rf /usr/bin/php
  /etc/init.d/php-fpm stop
  kill `ps aux |grep php-fpm|cut -b 10-14`
  rm -rf /etc/init.d/php-fpm
}

function enable_phar()
{
	cd $(php-config --prefix)/ext/phar && `whereis phpize|cut -d' ' -f2` && ./configure --with-php-config=$(whereis php-config|cut -d' ' -f2) --enable-phar && make && make install && echo "extension=$(php-config --extension-dir)/phar.so" >> $(php-config --prefix)/lib/php.ini && service httpd restart
}

function install_php_by_yum()
{
	yum install libxml2 libxml2-devel curl curl-devel libjpeg libjpeg-devel libpng libpng-devel libmcrypt libmcrypt-devel mhash mcrypt  libtool-ltdl libtool-ltdl-devel bzip2 bzip2-devel freetype freetype-devel openldap openldap-devel openssl openssl-devel	
	yum -y install php php-mysql php-common php-gd php-mbstring php-mcrypt php-devel php-xml 
	yum -y install perl 
	yum -y install mod_python
}

function install_mysql()
{
	#install mysql
	yum -y install libaio net-tools numactl perl initscripts
	yum -y remove mysql*

	echo -e "HOSTNAME=internal.hostname.DOMAIN.com" >> /etc/sysconfig/network

  #mysql version
  #https://cdn.mysql.com//Downloads/MySQL-5.6/MySQL-server-5.6.37-1.el6.x86_64.rpm
  mysql_version="5.7"
  mysql_release="5.7.19"
  os_version="el6.x86_64"
	
	#download rpm
	if [ ! -f "mysql-community-client-$mysql_release-1.el6.x86_64.rpm" ]; then
		wget -c http://dev.mysql.com/get/Downloads/MySQL-$mysql_version/mysql-community-client-$mysql_release-1.el6.x86_64.rpm
	fi
	if [ ! -f "mysql-community-server-$mysql_release-1.el6.x86_64.rpm" ]; then
		wget -c http://dev.mysql.com/get/Downloads/MySQL-$mysql_version/mysql-community-server-$mysql_release-1.el6.x86_64.rpm
	fi
	if [ ! -f "mysql-community-devel-$mysql_release-1.el6.x86_64.rpm" ]; then
		wget -c http://dev.mysql.com/get/Downloads/MySQL-$mysql_version/mysql-community-devel-$mysql_release-1.el6.x86_64.rpm
	fi
	if [ ! -f "mysql-community-libs-$mysql_version-1.el6.x86_64.rpm" ]; then
		wget -c http://dev.mysql.com/get/Downloads/MySQL-$mysql_version/mysql-community-libs-$mysql_release-1.el6.x86_64.rpm
	fi
	if [ ! -f "mysql-community-common-$mysql_release-1.el6.x86_64.rpm" ]; then
		wget -c http://dev.mysql.com/get/Downloads/MySQL-$mysql_version/mysql-community-common-$mysql_release-1.el6.x86_64.rpm
	fi

	rpm -ivh mysql-community-common-$mysql_release-1.el6.x86_64.rpm && \
  rpm -ivh mysql-community-libs-$mysql_release-1.el6.x86_64.rpm && \
  rpm -ivh mysql-community-devel-$mysql_release-1.el6.x86_64.rpm && \
  rpm -ivh mysql-community-client-$mysql_release-1.el6.x86_64.rpm && \
  rpm -ivh mysql-community-server-$mysql_release-1.el6.x86_64.rpm && \
  echo "max_allowed_packet=200M" >> /etc/my.cnf && service mysqld start 
	
	#find the default password and save it into readme.txt
	echo -e "\nmysql install information:" >> readme.txt
	mysqlpasswd=`sed -n '/A temporary password is generated for root@localhost:/p' /var/log/mysqld.log|cut -d: -f4`
	echo -e "MySQL's Password is :\033[41;37m"$mysqlpasswd"\033[0m"
	sed -n '/A temporary password is generated for root@localhost:/p' /var/log/mysqld.log >> readme.txt
	echo -e "After login mysql,you need to do:\nstep 1: SET PASSWORD = PASSWORD(\"your new password\");\nstep 2: ALTER USER 'root'@'localhost' PASSWORD EXPIRE NEVER;\nstep 3: flush privileges;" >> readme.txt
	echo "All MySQL's information in readme.txt"
#	echo -e "export MYSQL_HOME=/usr/local/mysql\nexport PATH=\$MYSQL_HOME/bin:\$PATH" >>/etc/profile && source /etc/profile
}

function install_ssh2()
{
	if [ ! -f "libssh2-1.8.0.tar.gz" ]; then
		wget -c https://www.libssh2.org/download/libssh2-1.8.0.tar.gz
	fi
	if [ ! -f "ssh2-0.13.tgz" ]; then
		wget -c http://pecl.php.net/get/ssh2-0.13.tgz
	fi
	tar -zxvf libssh2-1.8.0.tar.gz && cd libssh2-1.8.0 && ./configure --prefix=/usr/local/libssh2 && make && make install && cd ../
	tar -zxvf ssh2-0.13.tgz && cd ssh2-0.13 && phpize && ./configure --prefix=/usr/local/ssh2 --with-ssh2=/usr/local/libssh2 && make && make install && echo "extension=ssh2.so" >> $(php-config --prefix)/lib/php.ini && cd ../
}

function install_oci()
{
	if [ ! -f "oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm" ]; then
		echo "please goto http://download.oracle.com/otn/linux/instantclient/11204/oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm to download the rpm"
	fi
	if [ ! -f "PDO_OCI-1.0.tgz" ]; then
		wget -c http://pecl.php.net/get/PDO_OCI-1.0.tgz
	fi
	if [ ! -f "oci8-2.0.12.tgz" ]; then
		wget -c http://pecl.php.net/get/oci8-2.0.12.tgz
	fi
	#install oci8 support oracle11grc2 
	rpm -ivh oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm && rpm -ivh oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm && echo '/usr/lib/oracle/11.2/client64/lib/' > /etc/ld.so.conf.d/oracle-x86_64.conf 
	if [ ! -f "/usr/lib/oracle/11.2/client" ]; then
		ln -s /usr/lib/oracle/11.2/client64 /usr/lib/oracle/11.2/client
	fi
	if [ ! -f "/usr/include/oracle/11.2/client" ]; then
		ln -s /usr/include/oracle/11.2/client64 /usr/include/oracle/11.2/client
	fi
	echo -e "export ORACLE_HOME=/usr/lib/oracle/11.2/client64/\nexport LD_LIBRARY_PATH=/usr/lib/oracle/11.2/client64:\$LD_LIBRARY_PATH\nexport NLS_LANG=\"AMERICAN_AMERICA.AL32UTF8\"" >> /etc/profile && source /etc/profile

	tar -zxvf oci8-2.0.12.tgz && cd oci8-2.0.12 && phpize && ./configure --with-oci8=shared,instantclient,/usr/lib/oracle/11.2/client64/lib && make && make install && echo "extension=oci8.so" >> $(php-config --prefix)/lib/php.ini && cd ../

	tar -zxvf PDO_OCI-1.0.tgz && cd PDO_OCI-1.0 && ln -s /usr/include/oracle/11.2 /usr/include/oracle/10.2.0.1 && ln -s /usr/lib/oracle/11.2 /usr/lib/oracle/10.2.0.1 && sed -i '101i 11.2)\n  PHP_ADD_LIBRARY(clntsh, 1, PDO_OCI_SHARED_LIBADD)\n  \;\;' config.m4 && sed -i '10i elif test -f \$PDO_OCI_DIR/lib/libclntsh\.\$SHLIB_SUFFIX_NAME.11.2\; then\n  PDO_OCI_VERSION=11\.2' config.m4 && sed -i 's/function_entry/zend_function_entry/g' pdo_oci.c && phpize && ./configure --with-pdo-oci=instantclient,/usr,11.2 && make && make install && echo "extension=pdo_oci.so" >> $(php-config --prefix)/lib/php.ini && cd ../

}

function install_phalcon()
{
	if [ ! -d "cphalcon/build" ]; then
		git clone --depth=1 git://github.com/phalcon/cphalcon.git
	fi
	#install phalcon frameworks
	cd cphalcon/build && ./install && echo "extension=phalcon.so" >> $(php-config --prefix)/lib/php.ini && cd ../../
}


function install_jdk()
{
	if [ ! -f "jdk-8u111-linux-x64.tar.gz" ]; then
		echo "please goto http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html to download tar"
	else
	install_path=$(pwd) && mkdir -p /usr/java && cp -rf jdk-8u111-linux-x64.tar.gz /usr/java/ && cd /usr/java && tar -zxvf jdk-8u111-linux-x64.tar.gz && echo -e "JAVA_HOME=/usr/java/jdk1.8.0_111\nCLASSPATH=\$JAVA_HOME/lib/\nPATH=\$PATH:\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin\nexport PATH JAVA_HOME CLASSPATH" >> /etc/profile && source /etc/profile && java -version && cd $install_path
	fi
}

function install_openssl()
{
	yum -y install openssl mod_ssl
	cd /etc/pki/tls/private/ && openssl genrsa 1024 >localhost.key && openssl req -new -key localhost.key > localhost.csr && openssl req -x509 -days 3650 -key localhost.key -in localhost.csr > localhost.crt && cp localhost.crt /etc/pki/tls/certs/localhost.crt
	echo "openssl has installed!" >> readme.txt
}

function recovery_mysql()
{
	read -p "Please enter mysql username : " un
	read -p "Please enter mysql password : " paswd
	read -p "Please enter dataname : " dbname
	read -p "Please enter source path & filename : " pf
	echo "mysql -u$un -p'$pased' $dbname < $pf"
}

function change_mysql_password()
{
	echo "login mysql by 'mysql -uroot -p'"
	echo "SET PASSWORD = PASSWORD(\"Docker20!7\");"
	echo "ALTER USER 'root'@'localhost' PASSWORD EXPIRE NEVER;"
	echo "set global max_allowed_packet = 200M;"
	echo "flush privileges;"
	echo ""
	echo "create database db_name"
	echo "use db_name"
	echo "set names utf8;"
	echo ""
	#import db.sql
	echo "source /opt/install-php/db_dfzq.sql"
}

function update_openssh()
{
	yum -y install gcc zlib zlib-devel openssl-devel pam-devel rpm-build

	#step1: update zlib
	read -p "If update zlib? Y or N : " if_zlib
	if [ $if_zlib == "y" ]; then
		zlib_path="/usr/local/zlib"
		echo "update zlib..."
	  if [ ! -f "zlib-1.2.11.tar.gz" ]; then
	  	wget -c http://www.zlib.net/zlib-1.2.11.tar.gz
	  fi
	  tar xzvf zlib-1.2.11.tar.gz
	  cd zlib-1.2.11
	  ./configure --prefix=$zlib_path
	  make
	  make install
	else
		zlib_path="/usr/include"
	fi

	#step2:update openssl
	read -p "If update openssl? Y or N : " if_ssl
    if [ $if_ssl == "y" ]; then
      echo "update ssl..."
		  openssl_path="/usr/local/openssl"

	    if [ ! -f "openssl-1.0.2l.tar.gz" ]; then
		    wget -c https://www.openssl.org/source/openssl-1.0.2l.tar.gz
	    fi
	    tar xzvf openssl-1.0.2l.tar.gz
	    cd openssl-1.0.2l
	    ./Configure --prefix=$openssl_path
	    make
	    make test	#must to run this
	    make install

	  else
	  	openssl_path="/usr/include"
	  fi

	#step3:update ssh
	#backup old-version ssh's files
	mv /etc/ssh/* /etc/sshbak/

	echo "Download URL:http://www.openssh.com/portable.html"
	echo "./configure --prefix=/usr --sysconfdir=/etc/ssh --with-pam --with-zlib=$zlib_path --with-ssl-dir=$openssl_path --with-md5-passwords"
	read -p "Press any Key to Continue..."
	if [ ! -f "openssh-7.5p1.tar.gz" ]; then
		wget -c https://openbsd.hk/pub/OpenBSD/OpenSSH/portable/openssh-7.5p1.tar.gz
	fi

	tar xzvf openssh-7.5p1.tar.gz
	cd openssh-7.5p1
	./configure --prefix=/usr --sysconfdir=/etc/ssh --with-pam --with-zlib=/usr/include --with-ssl-dir=/usr/include --with-md5-passwords
	make
	make install

#	sed -i "s/\#Protocol 2,1/\#Protocol 2/g" /etc/ssh/sshd_config
#	sed -i "s/X11Forwarding yes/X11Forwarding no/g" /etc/ssh/sshd_config
#	sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/g" /etc/ssh/sshd_config
	sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
	cp contrib/redhat/sshd.init /etc/init.d/sshd
	chmod +x /etc/init.d/sshd
	chkconfig --add sshd
	chkconfig sshd on
	/etc/init.d/sshd restart	
}

function update_openssh_2()
{
	cp /root/openssh-7.5p1/contrib/redhat/openssh.spec /usr/src/redhat/SPECS/
	cp openssh-7.5p1.tar.gz /usr/src/redhat/SOURCES/
 	cp x11-ssh-askpass-1.2.4.1.tar.gz /usr/src/redhat/SOURCES/
 	perl -i.bak -pe 's/^（%define no_（gnome|x11）_askpass）\s+0$/$1 1/' openssh.spec
	rpmbuild -bb openssh.spec

	cd /usr/src/redhat/RPMS/`uname -i`
	rpm -Uvh openssh*rpm
}

function install_gitlab-ce_omnibus()
{
	curl https://packages.gitlab.com/gpg.key 2> /dev/null | sudo apt-key add - &>/dev/null
	echo -e "[gitlab-ce]\nname=Gitlab CE Repository\nbaseurl=https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el$releasever/\ngpgcheck=0\nenabled=1" >> /etc/yum.repos.d/gitlab-ce.repo
	echo -e "[gitlab-ci-multi-runner]\nname=gitlab-ci-multi-runner\nbaseurl=https://mirrors.tuna.tsinghua.edu.cn/gitlab-ci-multi-runner/yum/el6\nrepo_gpgcheck=0\ngpgcheck=0\nenabled=1\ngpgkey=https://packages.gitlab.com/gpg.key" >> /etc/yum.repos.d/gitlab-ci-multi-runner.repo
	yum makecache
	yum install -y gitlab-ce gitlab-ci-multi-runner git patch
	cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
	gitlab-ctl stop
	patch -d /opt/gitlab/embedded/service/gitlab-rails -p1 < 9.2.5-zh.diff
	gem sources -r https://rubygems.org/
	gem sources -a http://ruby.taobao.org/
	echo -e "external_url \"http://gitlab.zhenzhidaole.com\"" >>/etc/gitlab/gitlab.rb
	echo -e "gitlab_rails['smtp_enable'] = true\ngitlab_rails['smtp_address'] = \"smtp.qq.com\"\ngitlab_rails['smtp_port'] = 465\ngitlab_rails['smtp_user_name'] = \"noreply@zhenzhidaole.com\"\ngitlab_rails['smtp_password'] = "xpdyqbdldbtrddib"\ngitlab_rails['smtp_domain'] = \"smtp.qq.com\"\ngitlab_rails['smtp_authentication'] = \"login\"\ngitlab_rails['smtp_enable_starttls_auto'] = true\ngitlab_rails['smtp_openssl_verify_mode'] = 'peer'\ngitlab_rails['smtp_tls'] = true\ngitlab_rails['gitlab_email_from'] = 'noreply@zhenzhidaole.com'\ngitlab_rails['gitlab_email_reply_to'] = 'noreply@zhenzhidaole.com'\n" >> /etc/gitlab/gitlab.rb


	gitlab-ctl reconfigure
}

function test_http()
{
	echo -e "Alias /webalias \"/var/www/alias\"\n<Directory \"/var/www/alias\">\n    Options Indexes MultiViews FollowSymLinks\n    AllowOverride None\n    Order allow,deny\n    Allow from all\n</Directory>" >> /etc/httpd/conf/httpd.conf
	echo -e "<VirtualHost *:80>\n        ServerAdmin admin@zhenzhidaole.com\n        DocumentRoot /var/www/html\n        ServerName www.zhenzhidaole.com\n        ErrorLog /var/www/logs/error_log\n        CustomLog /var/www/logs/access_log common\n</VirtualHost>" >> /etc/httpd/conf/httpd.conf
	mkdir -p /var/www/web && mkdir -p /var/www/alias
	echo "<?php phpinfo();?>" > /var/www/alias/s.php
	echo -e "127.0.0.1	www.zhenzhidaole.com" >> /etc/hosts
	service httpd restart
}

function test_phpinfo()
{
	php -v
	php -i |grep mcrypt
	php -i |grep ssh
	php -i |grep oci
	php -i |grep phalcon
	curl https://localhost/ -k
	curl http://www.zhenzhidaole.com/i.php |grep php.ini
	echo -e "<?php\n\$con = mysqli_connect(\"127.0.0.1\",\"root\",\"!qaz@wsx\");\nif (!\$con){die('Could not connect: ' . mysql_error());}\necho 'Connected successfully';\nmysql_close($con);\n?>" >> /var/www/html/i.php
}

clear;
#LANG=zh_CN.GB18030
#LANGUAGE=zh_CN.GB18030:zh_CN.GB2312:zh_CN
#export LANG LANGUAGE
#LANG=zh_CN.UTF-8
#export LANG
#sed -i "s/LANG=\"en_US\.UTF-8\"/LANG=\"zh_CN\.GB18030\"/g" /etc/sysconfig/i18n
echo "OS information: " `cat /etc/redhat-release`
echo "OS information: " `uname -a`
#echo "OS information: " `lsb_release -a`
echo "Enter ctrl+c to interrupt this program"
echo ""
echo "Choose option E to exit this program"
echo ""
echo "choose option 0 to skip current step"
echo ""
read -p "Please Press Enter Key to continue...";

if [ ! -f "readme.txt" ]; then
	echo "" > readme.txt
else
	chk_env=`sed -n '/Initialization complete/p' readme.txt`
fi
if [ ${#chk_env} -gt 0 ]; then
        echo "Initialization complete" 
else
	while true; do
	read -p "Do you wish initialization environment? Please Enter Y/N: " yn
    case $yn in
      [Yy]* ) init; break;;
      [Nn]* ) echo "";break;;
      [Ee]* ) exit;;
      * ) echo "Please answer Y or N.";;
    esac
  done
fi

while true; do
	echo -e "Do you wish to install lanmp environment? Please choose the option :\n	0.skip this step;\n	1. install_httpd;\n	2. install_nginx;\n	3. install_php;\n	4. install_mysql;\n	5. install_ssh2;\n	6. install_oci;\n	7. install_phalcon;\n	8. install_jdk;\n	9. install_openssl";
	read -p "Please Enter a number: " number
	case $number in
		[1] ) install_httpd;;
		[2] ) install_nginx;;
		[3] ) install_php;;
		[4] ) install_mysql;;
		[5] ) install_ssh2;;
		[6] ) install_oci;;
		[7] ) install_phalcon;;
		[8] ) install_jdk;;
		[9] ) install_openssl;;
		[0] ) echo "";break;;
                [Ee] ) exit;;
		[Rr] ) recovery_mysql;;
		* ) echo "Please choose a number.";;
	esac
done
read -p "Please Press Enter Key to exit......";

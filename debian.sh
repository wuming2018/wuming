#!/bin/bash

input () {
  read -p "请输入$2,默认($3):" $1
  eval ${1}=${!1:-$3}
}

caddy_boot_conf () {
cat > caddy.service <<EOF
[Unit]
Description=Caddy HTTP/2 web server
Documentation=https://caddyserver.com/docs
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Restart=on-abnormal

ExecStart=/usr/local/bin/caddy -conf=/etc/caddy/Caddyfile
ExecReload=/bin/kill -USR1 $MAINPID

KillMode=mixed
KillSignal=SIGQUIT
TimeoutStopSec=5s

LimitNOFILE=1048576
LimitNPROC=512

PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ProtectSystem=full

[Install]
WantedBy=multi-user.target
EOF
}

caddy_conf () {
cat > /etc/caddy/Caddyfile <<EOF
:80 {
	gzip
    root /var/www/html/
    index index.html
    timeouts none
}
EOF
}

echo "只在debian7+系统上面工作,不支持centos系统"
echo "1.安装v2ray"
echo "2.安装caddy"
echo "3.ssR"
echo "4.安装证书tls"
echo "5.退出"
input num "1-5" "5"
case ${num} in
	1)
	  bash <(curl -L -s https://install.direct/go.sh)
	  [ -f /usr/bin/v2ray/v2ray ] && echo "v2ray安装出错" && exit 1
	  ;;
	2)
	  curl https://getcaddy.com | bash -s personal
	  [ -f /usr/local/bin/caddy ] && echo "caddy安装出错" && exit 1
	  caddy_boot_conf
	  [ ! -d /etc/caddy ] && mkdir -p /etc/caddy
	  [ ! -d /var/www/html ] && mkdir -p /var/www/html
	  caddy_conf
	  [ ! -f /var/www/html/index.html ] && echo "Hello world" >/var/www/html/index.html
	  mv caddy.service /etc/systemd/system/
	  chmod 644 /etc/systemd/system/caddy.service
	  systemctl daemon-reload
	  systemctl start caddy.service
	  ;;
	3)
	  apt-get upgrade
	  apt-get -y install python-pip git
	  git clone -b master https://github.com/wuming2018/test.git
	  mv test/ /usr/local/shadowsocksr
	  cd /usr/local/shadowsocksr
	  bash initcfg.sh
	  input ssrport "端口" "8080"
	  input ssrpw "密码" "233666.org"
	  python mujson_mgr.py -a -u "${ssrport}" -p ${ssrport} -k ${ssrpw} -m aes-256-cfb -O auth_sha1_v4 -o http_simple
	  ./run.sh
	  cp /usr/local/shadowsocksr/shadowsocksr.service /etc/systemd/system/shadowsocksr.service
	  systemctl enable shadowsocksr.service && systemctl start shadowsocksr.service
	  ;;
	4)
	  apt-get -y install netcat
	  curl  https://get.acme.sh | sh
	  source ~/.bashrc
	  apt-get install socat
	  read -p "输入你的域名,示例(123.com):" mydomain
	  [ -z "${mydomain}" ] && exit 1
	  [ ! -d "/etc/v2ray" ] && mkdir -p /etc/v2ray
	  ~/.acme.sh/acme.sh --issue -d ${mydomain} --standalone -k ec-256
	  ~/.acme.sh/acme.sh --installcert -d ${mydomain} --fullchainpath /etc/v2ray/v2ray.crt --keypath /etc/v2ray/v2ray.key --ecc
	  ;;
	5)
	  exit 0
	 ;;
	*)
	  exit 0
	  ;;
esac

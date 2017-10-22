#!/bin/bash

cat > ./v2ray.json<<-EOF
{
  "log" : {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbound": {
    "port": 10086,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "23ad6b10-8d1a-40f7-8ad0-e3e35cd38297",
          "level": 1,
          "alterId": 64
        }
      ]
    }
  },
  "outbound": {
    "protocol": "freedom",
    "settings": {}
  },
  "outboundDetour": [
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "strategy": "rules",
    "settings": {
      "rules": [
        {
          "type": "field",
          "ip": [
            "0.0.0.0/8",
            "10.0.0.0/8",
            "100.64.0.0/10",
            "127.0.0.0/8",
            "169.254.0.0/16",
            "172.16.0.0/12",
            "192.0.0.0/24",
            "192.0.2.0/24",
            "192.168.0.0/16",
            "198.18.0.0/15",
            "198.51.100.0/24",
            "203.0.113.0/24",
            "::1/128",
            "fc00::/7",
            "fe80::/10"
          ],
          "outboundTag": "blocked"
        }
      ]
    }
  }
}
EOF

input () {
  read -p "请输入$2,默认($3):" $1
}

input vport "端口" 1110
[ -z "${vport}" ] && vport="1110"
sed -i "s/10086/${vport}/g" "./v2ray.json"

[ -f "/proc/sys/kernel/random/uuid" ] && UUID=$(cat /proc/sys/kernel/random/uuid)
[ -f "/f/temp/uuid" ] && UUID=$(cat /f/temp/uuid)
[ -z "${UUID}" ] && UUID="173fa4bb-b916-4943-b8d4-e8e37529a9f6"
input vuuid "UUID" ${UUID}
[ -z "${vuuid}" ] && vuuid=${UUID}
sed -i "s/23ad6b10-8d1a-40f7-8ad0-e3e35cd38297/${UUID}/g" "./v2ray.json"

input v_ws "websocket路径" ws
[ -z "${v_ws}" ] && v_ws="ws"
sed -i "18s/\}/\}\,/g" ./v2ray.json
sed -i "18a\    \"streamSettings\"\: \{\n      \"network\"\: \"ws\"\,\n      \"wsSettings\"\: \{\n        \"connectionReuse\"\: false\,\n        \"path\"\: \"\/${v_ws}\"\n      \}\n    \}" ./v2ray.json

input vurl "域名,示例(abc.com)" "-" 
[ -z "${vurl}" ] && echo "错误,没有域名" && exit 1

input vemail "邮箱,示例(abc@163.com)" "-" 
[ -z "${vemail}" ] && echo "错误,没有邮箱" && exit 1

cat > ./Caddy.file<<-EOF
https://${vurl} {
  root /var/www/index
  gzip
  index index.html
  tls ${vemail}
  proxy ${v_ws} localhost:${vport} {
    websocket
  }
}
EOF

echo "--------------------------------------------"
echo -e "\33[31m\33[1m配置\33[0m:"
echo -e "    端口:\033[36m          ${vport}\033[0m"
echo -e "    UUID:\033[36m          ${vuuid}\033[0m"
echo -e "    alterId:\033[36m       64\033[0m"
echo -e "    websocket路径:\033[36m /${v_ws}\033[0m"
echo -e "    域名:\033[36m          ${vurl}\033[0m"
echo -e "    邮箱:\033[36m          ${vemail}\033[0m"
echo "---------------------------------------------"
echo " "
echo -e "当前目录下已生成配置文件:"
echo -e "   \033[36m v2ray-kehu.json \033[0m是客户端配置文件,复制到电脑上的客户端使用"
echo -e "   \033[36m v2ray.json \033[0m是v2ray服务端配置文件"
echo -e "   \033[36m Caddy.file \033[0m是Caddy的配置文件"
echo " "
echo -e "\33[31m\33[1m执行\33[0m下面的命令替换服务端配置文件:"
echo -e "    替换v2ray配置文件:\033[36m mv ./v2ray.json /etc/v2ray/config.json \033[0m"
echo -e "    替换caddy配置文件:\033[36m mv ./Caddy.file /usr/local/caddy/Caddyfile \033[0m"
echo -e "    \33[31m\33[1m注意\033[0m,替换配置文件后需要重启软件使配置生效"

cat > ./v2ray-kehu.json<<-EOF
{
  "inbound": {
    "port": 1080,
    "listen": "0.0.0.0",
    "protocol": "socks",
    "settings": {
      "auth": "noauth",
      "udp": true,
      "ip": "127.0.0.1",
      "clients": null
    },
    "streamSettings": null
  },
  "outbound": {
    "tag": "wsout",
    "protocol": "vmess",
    "settings": {
      "vnext": [
        {
          "address": "${vurl}",
          "port": 443,
          "users": [
            {
              "id": "${vuuid}",
              "alterId": 64,
              "security": "aes-128-gcm"
            }
          ]
        }
      ]
    },
    "streamSettings": {
      "network": "ws",
      "security": "tls",
      "tlsSettings": {
        "serverName": "${vurl}",
        "allowInsecure": true
    },
      "wsSettings": {
        "connectionReuse": true,
        "path": "/${v_ws}"
      }
    },
    "mux": {
      "enabled": true
    }
  },
  "outboundDetour": [
    {
      "protocol": "freedom",
      "settings": {
        "response": null
      },
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {
        "response": {
          "type": "http"
        }
      },
      "tag": "blockout"
    }
  ],
  "dns": {
    "servers": [
      "8.8.8.8",
      "8.8.4.4",
      "localhost"
    ]
  },
  "routing": {
    "strategy": "rules",
    "settings": {
      "domainStrategy": "IPIfNonMatch",
      "rules": [
        {
          "type": "field",
          "port": null,
          "outboundTag": "direct",
          "ip": [
            "0.0.0.0/8",
            "10.0.0.0/8",
            "100.64.0.0/10",
            "127.0.0.0/8",
            "169.254.0.0/16",
            "172.16.0.0/12",
            "192.0.0.0/24",
            "192.0.2.0/24",
            "192.168.0.0/16",
            "198.18.0.0/15",
            "198.51.100.0/24",
            "203.0.113.0/24",
            "::1/128",
            "fc00::/7",
            "fe80::/10"
          ],
          "domain": null
        }
      ]
    }
  }
}
EOF

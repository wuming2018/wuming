#!/bin/bash

# ------------------------
# CENTOS6 only 
# install v2ray to centos 6
# github:https://github.com/wuming2018
# -------------------------

uninstall() {
  killall v2ray
  [ -d /usr/bin/v2ray ] && rm -r /usr/bin/v2ray
  [ -f /etc/v2ray/config.json ] && rm -r /etc/v2ray/config.json
  grep -q "nohup /usr/bin/v2ray/v2ray -config /etc/v2ray/config.json" /etc/rc.d/rc.local && sed -i "/nohup \/usr\/bin\/v2ray\/v2ray -config \/etc\/v2ray\/config.json/d" /etc/rc.d/rc.local
}

[[ $1 == "uninstall" ]] && uninstall && exit 0 

echo "安装依赖 curl 和 unzip"
yum install -y curl unzip

VER="$(curl -s https://api.github.com/repos/v2ray/v2ray-core/releases/latest | grep 'tag_name' | cut -d\" -f4)"
ARCH=$(uname -m)
VDIS="64"

if [[ "$ARCH" == "i686" ]] || [[ "$ARCH" == "i386" ]]; then
  VDIS="32"
elif [[ "$ARCH" == *"armv7"* ]] || [[ "$ARCH" == "armv6l" ]]; then
  VDIS="arm"
elif [[ "$ARCH" == *"armv8"* ]]; then
  VDIS="arm64"
fi

DOWNLOAD_LINK="https://github.com/v2ray/v2ray-core/releases/download/${VER}/v2ray-linux-${VDIS}.zip"

rm -rf /tmp/v2ray
mkdir -p /tmp/v2ray

echo "下载和解压官方安装包"
echo "Downloading ${DOWNLOAD_LINK} directly."
curl -L -H "Cache-Control: no-cache" -o "/tmp/v2ray/v2ray.zip" ${DOWNLOAD_LINK}

echo "Extracting V2Ray package to /tmp/v2ray."
unzip "/tmp/v2ray/v2ray.zip" -d "/tmp/v2ray/"

mkdir -p /var/log/v2ray
mkdir -p /usr/bin/v2ray
cp "/tmp/v2ray/v2ray-${VER}-linux-${VDIS}/v2ray" "/usr/bin/v2ray/v2ray"
cp "/tmp/v2ray/v2ray-${VER}-linux-${VDIS}/geoip.dat" "/usr/bin/v2ray/geoip.dat"
cp "/tmp/v2ray/v2ray-${VER}-linux-${VDIS}/geosite.dat" "/usr/bin/v2ray/geosite.dat"
chmod +x "/usr/bin/v2ray/v2ray"

mkdir -p /etc/v2ray
if [ ! -f "/etc/v2ray/config.json" ]; then
  cp "/tmp/v2ray/v2ray-${VER}-linux-${VDIS}/vpoint_vmess_freedom.json" "/etc/v2ray/config.json"

  let PORT=$RANDOM+10000
  sed -i "s/10086/${PORT}/g" "/etc/v2ray/config.json"

  UUID=$(cat /proc/sys/kernel/random/uuid)
  sed -i "s/23ad6b10-8d1a-40f7-8ad0-e3e35cd38297/${UUID}/g" "/etc/v2ray/config.json"
  echo "配置文件:"
  echo "     端口: ${PORT}"
  echo "     UUID: ${UUID}"
  echo "  AlterID: 64"
fi

[ ! -f "/usr/bin/v2ray/v2ray" ] && echo "出错了,没有成功安装v2ray到/usr/bin/v2ray/" && exit 1
# 加入到开机启动
grep -q "nohup /usr/bin/v2ray/v2ray -config /etc/v2ray/config.json" /etc/rc.d/rc.local || echo -e "nohup /usr/bin/v2ray/v2ray -config /etc/v2ray/config.json >/dev/null 2>/dev/null &" >>/etc/rc.d/rc.local
# 清除 v2ray 进程
killall v2ray
# 后台运行程序
#nohup /usr/bin/v2ray/v2ray -config /etc/v2ray/config.json >/dev/null 2>/dev/null &

echo "V2Ray ${VER} is installed."
echo "---------------------------------------------------------------------------------------------"
echo -e "配置文件在/etc/v2ray/config.json"
echo -e "更新:   bash v2-centos6.sh"
echo -e "卸载:   bash v2-centos6.sh uninstall"
echo -e "停止:   killall v2ray"
echo -e "运行:   nohup /usr/bin/v2ray/v2ray -config /etc/v2ray/config.json >/dev/null 2>/dev/null &"
echo -e "注意:先 停止 然后再 运行,不然可能会在后台多次运行v2ray进程"
# 用netstat命令查看端口占用情况
echo "执行 netstat -lntp 如果看到v2ray已占用${PORT}端口说明已经运行了"
#netstat -lntp
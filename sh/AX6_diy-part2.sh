#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
function git_sparse_clone() {
  branch="$1" rurl="$2" localdir="$3" && shift 3
  #git clone -b $branch --depth 1 --filter=blob:none --sparse $rurl $localdir
  git clone -b $branch --single-branch --no-tags --depth 1 --filter=blob:none --no-checkout $rurl $localdir
  cd $localdir
  #git sparse-checkout init --cone
  #git sparse-checkout set $@
  git checkout $branch -- $@
  mv -n $@ ../
  cd ..
  rm -rf $localdir
  }

#1. 修改默认IP
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 修改连接数
#sed -i 's/customize sysctl settings/a net.netfilter.nf_conntrack_max=65535/g' package/base-files/files/etc/sysctl.d/10-default.conf
# 修正连接数（by ベ七秒鱼ベ）
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf
# 设置密码为password
sed -i 's/root:::0:99999:7:::/root:$1$iT2B9mTF$d5CTSuJLXZZzSPQYHqwqG.:19867:0:99999:7:::/' package/base-files/files/etc/shadow
# 修改默认wifi名称ssid为🐥🐥
#sed -i 's/ssid=ImmortalWrt/ssid=🐥🐥/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# 修改默认wifi密码key为abc@abcD
#sed -i 's/encryption=none/encryption=psk2/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
#sed -i '/set wireless.default_radio${devidx}.encryption=psk2/a\set wireless.default_radio${devidx}.key=abc@abcD' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# hijack dns queries to router(firewall)
sed -i '/REDIRECT --to-ports 53/d' package/network/config/firewall/files/firewall.user
# 把局域网内所有客户端对外ipv4的53端口查询请求，都劫持指向路由器(iptables -n -t nat -L PREROUTING -v --line-number)(iptables -t nat -D PREROUTING 2)
echo 'iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> package/network/config/firewall/files/firewall.user
echo 'iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> package/network/config/firewall/files/firewall.user
# 把局域网内所有客户端对外ipv6的53端口查询请求，都劫持指向路由器(ip6tables -n -t nat -L PREROUTING -v --line-number)(ip6tables -t nat -D PREROUTING 1)
echo '[ -n "$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> package/network/config/firewall/files/firewall.user
echo '[ -n "$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> package/network/config/firewall/files/firewall.user

#3.固件版本号添加个人标识和日期
[ -e package/lean/default-settings/files/zzz-default-settings ] && sed -i "s/DISTRIB_DESCRIPTION='.*OpenWrt '/DISTRIB_DESCRIPTION='W($(TZ=UTC-8 date +%Y.%m.%d))@OpenWrt '/g" package/lean/default-settings/files/zzz-default-settings
[ ! -e package/lean/default-settings/files/zzz-default-settings ] && sed -i "/DISTRIB_DESCRIPTION='*'/d" package/base-files/files/etc/openwrt_release
[ ! -e package/lean/default-settings/files/zzz-default-settings ] && echo "DISTRIB_DESCRIPTION='W($(TZ=UTC-8 date +%Y.%m.%d))@immortalwrt '" >> package/base-files/files/etc/openwrt_release

#4.编译的固件文件名添加日期
#sed -i 's/IMG_PREFIX:=$(VERSION_DIST_SANITIZED)/IMG_PREFIX:=$(shell TZ=UTC-8 date "+%Y%m%d")-$(VERSION_DIST_SANITIZED)/g' include/image.mk

#5.更换lede源码中自带argon主题
[ -e package/lean/default-settings/files/zzz-default-settings ] && rm -rf feeds/luci/themes/luci-theme-argon && git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git feeds/luci/themes/luci-theme-argon
[ -e package/lean/default-settings/files/zzz-default-settings ] && rm -rf feeds/luci/themes/luci-theme-design && git clone --depth 1 https://github.com/gngpp/luci-theme-design feeds/luci/themes/luci-theme-design
[ -e package/lean/default-settings/files/zzz-default-settings ] && rm -rf feeds/luci/applications/luci-app-design-config && git clone --depth 1 https://github.com/gngpp/luci-app-design-config feeds/luci/applications/luci-app-design-config

#6.添加自动挂载磁盘脚本
#mkdir -p files/etc/hotplug.d/block && wget -O files/etc/hotplug.d/block/30-usbmount https://raw.githubusercontent.com/ficheny/P3TERX_Actions-OpenWrt/main/files/etc/hotplug.d/block/30-usbmount && chmod 755 files/etc/hotplug.d/block/30-usbmount

#7.修改主机名
sed -i "s/hostname='OpenWrt'/hostname='Redmi-AX6'/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='ImmortalWrt'/hostname='Redmi-AX6'/g" package/base-files/files/bin/config_generate

#8.修改插件位置
#sed -i '/sed -i "s\/services\/system\/g" \/usr\/lib\/lua\/luci\/controller\/cpufreq.lua/d'  package/lean/default-settings/files/zzz-default-settings
#sed -i '/exit 0/i sed -i "s/services/system/g" /usr/lib/lua/luci/controller/cpufreq.lua'  package/lean/default-settings/files/zzz-default-settings

#9.禁止Turbo ACC 网络加速修改net.bridge.bridge-nf-call-iptables的值为1(修改为1后旁路由需开启ip动态伪装，影响下行带宽)。
#sed -i '/exit 0/i sed -i "s/\\[ -d \\/sys\\/kernel\\/debug\\/ecm\\/ecm_nss_ipv4 \\] \\&\\& return 0/\\[ -d \\/sys\\/kernel\\/debug\\/ecm\\/ecm_nss_ipv4 \\] \\&\\& return 1/g" /etc/init.d/qca-nss-ecm'  package/lean/default-settings/files/zzz-default-settings
#sed -i '/exit 0/i sed -i "s/\\[ -d \\/sys\\/kernel\\/debug\\/ecm\\/ecm_nss_ipv4 \\] \\&\\& sysctl -w dev.nss.general.redirect=1/\\#[ -d \\/sys\\/kernel\\/debug\\/ecm\\/ecm_nss_ipv4 \\] \\&\\& sysctl -w dev.nss.general.redirect=1/g" /etc/init.d/qca-nss-ecm'  package/lean/default-settings/files/zzz-default-settings
#sed -i '/exit 0/i /etc/init.d/qca-nss-ecm disable' package/lean/default-settings/files/zzz-default-settings

#10.为bypass添加redsocks2依赖。
#svn co https://github.com/fw876/helloworld/trunk/redsocks2 package/redsocks2

#修复 shadowsocksr-libev libopenssl-legacy 依赖问题
#sed -i 's/ +libopenssl-legacy//g' feeds/fichenx/shadowsocksr-libev/Makefile

#####design主题导航栏设置######
#sed -i 's/shadowsocksr/bypass/g' feeds/fichenx/luci-theme-design/luasrc/view/themes/design/header.htm
#sed -i 's|services/openclash|services/bypass|g' feeds/fichenx/luci-theme-design/luasrc/view/themes/design/header.htm
#sed -i 's/system\/admin/docker\/containers/g' feeds/fichenx/luci-theme-design/luasrc/view/themes/design/header.htm
#sed -i 's|openclash.png|ssr.png|g' feeds/fichenx/luci-theme-design/luasrc/view/themes/design/header.htm

#nps（修改nps源为yisier）
rm -rf feeds/packages/net/nps
cp -rf $GITHUB_WORKSPACE/backup/nps feeds/packages/net
#sed -i 's/PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=https:\/\/codeload.github.com\/yisier\/nps\/tar.gz\/v$(PKG_VERSION)?/g' feeds/packages/net/nps/Makefile
#sed -i 's/PKG_VERSION:=.*/PKG_VERSION:=0.26.18/g' feeds/packages/net/nps/Makefile
#sed -i 's/PKG_HASH:=.*/PKG_HASH:=29da044262071a1fa53ce7169c6427ee4f12fc0ada60ef7fb52fabfd165afe91/g' feeds/packages/net/nps/Makefile
#luci-app-nps（修改nps显示位置）
#sed -i 's/"services"/"vpn"/g'  feeds/luci/applications/luci-app-nps/luasrc/controller/nps.lua
#sed -i 's/\[services\]/\[vpn\]/g'  feeds/luci/applications/luci-app-nps/luasrc/view/nps/nps_status.htm
#luci-app-nps（修改nps服务器允许域名）
sed -i 's|^server.datatype = "ipaddr"|--server.datatype = "ipaddr"|g' feeds/luci/applications/luci-app-nps/luasrc/model/cbi/nps.lua
sed -i 's|^server.datatype="ipaddr"|--server.datatype="ipaddr"|g' feeds/luci/applications/luci-app-nps/luasrc/model/cbi/nps.lua
sed -i 's|Must an IPv4 address|IPv4 address or domain name|g' feeds/luci/applications/luci-app-nps/luasrc/model/cbi/nps.lua
sed -i 's|Must an IPv4 address|IPv4 address or domain name|g' feeds/luci/applications/luci-app-nps/po/zh-cn/nps.po
sed -i 's|必须是 IPv4 地址|IPv4 地址或域名|g' feeds/luci/applications/luci-app-nps/po/zh-cn/nps.po

#添加design主题js版
[ ! -e package/lean/default-settings/files/zzz-default-settings ] && git clone --depth 1 -b js https://github.com/gngpp/luci-theme-design.git  package/luci-theme-design

#修改默认主题
#修改默认主题
#sed -i 's|set luci.main.mediaurlbase|#set luci.main.mediaurlbase|g' feeds/luci/themes/luci-theme-argon/root/etc/uci-defaults/30_luci-theme-argon
#sed -i 's|set luci.main.mediaurlbase|#set luci.main.mediaurlbase|g' feeds/luci/themes/luci-theme-argon-mod/root/etc/uci-defaults/90_luci-theme-argon
#sed -i 's|set luci.main.mediaurlbase|#set luci.main.mediaurlbase|g' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap
#sed -i 's|set luci.main.mediaurlbase|#set luci.main.mediaurlbase|g' feeds/luci/themes/luci-theme-material/root/etc/uci-defaults/30_luci-theme-material
#sed -i 's|set luci.main.mediaurlbase|#set luci.main.mediaurlbase|g' feeds/luci/themes/luci-theme-netgear/root/etc/uci-defaults/30_luci-theme-netgear
#sed -i 's|luci-theme-argon|luci-theme-design|g' feeds/luci/collections/luci/Makefile

#为lede源恢复mac80211v5.15.33驱动依赖kmod-qcom-qmi-helpers
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo '' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo 'define KernelPackage/qcom-qmi-helpers' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo '  SUBMENU:=$(OTHER_MENU)' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo '  TITLE:=Qualcomm QMI Helpers' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo '  KCONFIG:=CONFIG_QCOM_QMI_HELPERS' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo '  FILES:=$(LINUX_DIR)/drivers/soc/qcom/qmi_helpers.ko' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo '  AUTOLOAD:=$(call AutoProbe,qmi_helpers)' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo 'endef' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo '' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo 'define KernelPackage/qcom-qmi-helpers/description' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo '  Qualcomm QMI Helpers' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo 'endef' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo '' >> package/kernel/linux/modules/other.mk
# [ -e package/lean/default-settings/files/zzz-default-settings ] && echo '$(eval $(call KernelPackage,qcom-qmi-helpers))' >> package/kernel/linux/modules/other.mk

#golang
rm -rf feeds/packages/lang/golang
cp -rf $GITHUB_WORKSPACE/general/golang feeds/packages/lang/golang

#为immortalwrt添加turboacc
[ ! -e package/lean/default-settings/files/zzz-default-settings ] && curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh

./scripts/feeds update -a
./scripts/feeds install -a

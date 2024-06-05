#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default
#echo 'src-git fichenx https://github.com/fichenx/openwrt-package' >>feeds.conf.default
#git clone https://github.com/bootli/luci-app-v2ray-server.git package/v2ray
#git clone  https://github.com/gdy666/luci-app-lucky.git package/lucky
#echo 'src-git small https://github.com/kenzok8/small' >>feeds.conf.default
#echo 'src-git kiddin9 https://github.com/kiddin9/openwrt-packages' >>feeds.conf.default
# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

echo 'src-git kenzo https://github.com/kenzok8/openwrt-packages' >> feeds.conf.default
#echo 'src-git small https://github.com/kenzok8/small' >> feeds.conf.default
######################################################################################
git_sparse_clone master https://github.com/kiddin9/openwrt-packages luci-app-ssr-plus
git_sparse_clone master https://github.com/kiddin9/openwrt-packages shadow-tls
git_sparse_clone master https://github.com/kiddin9/openwrt-packages shadowsocks-rust
git_sparse_clone master https://github.com/kiddin9/openwrt-packages luci-app-filetransfer

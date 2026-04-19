#!/bin/bash

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	#修改WIFI名称
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	#修改WIFI密码
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	#修改WIFI名称
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
	#修改WIFI地区
	sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
	#修改WIFI加密
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#取消nss相关feed
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	#开启sqm-nss插件
	echo "CONFIG_PACKAGE_luci-app-sqm=y" >> ./.config
	echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> ./.config
	#设置NSS版本
	echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
	#无WIFI配置调整Q6大小
	if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
		echo "WRT_WIFI=wifi-no" >> $GITHUB_ENV
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi

#修复ath11k-firmware
#curl -L https://raw.githubusercontent.com/qosmio/openwrt-ipq/refs/heads/main-nss/package/firmware/ath11k-firmware/Makefile -o package/firmware/ath11k-firmware/Makefile

# 1. 禁用核心硬件支持
sed -i 's/CONFIG_USB_SUPPORT=y/# CONFIG_USB_SUPPORT is not set/' .config
sed -i 's/CONFIG_EMMC_SUPPORT=y/# CONFIG_EMMC_SUPPORT is not set/' .config

# 2. 禁用默认包含的 USB 相关驱动模块 (DWC3/USB3)
sed -i 's/CONFIG_DEFAULT_automount=y/# CONFIG_DEFAULT_automount is not set/' .config
sed -i 's/CONFIG_DEFAULT_kmod-usb3=y/# CONFIG_DEFAULT_kmod-usb3 is not set/' .config
sed -i 's/CONFIG_DEFAULT_kmod-usb-dwc3=y/# CONFIG_DEFAULT_kmod-usb-dwc3 is not set/' .config
sed -i 's/CONFIG_DEFAULT_kmod-usb-dwc3-qcom=y/# CONFIG_DEFAULT_kmod-usb-dwc3-qcom is not set/' .config

# 3. 禁用分区与磁盘管理工具 (fdisk/gdisk/blkid等)
sed -i 's/CONFIG_PACKAGE_blkid=y/# CONFIG_PACKAGE_blkid is not set/' .config
sed -i 's/CONFIG_PACKAGE_fdisk=y/# CONFIG_PACKAGE_fdisk is not set/' .config
sed -i 's/CONFIG_PACKAGE_parted=y/# CONFIG_PACKAGE_parted is not set/' .config
sed -i 's/CONFIG_PACKAGE_sfdisk=y/# CONFIG_PACKAGE_sfdisk is not set/' .config
sed -i 's/CONFIG_PACKAGE_cgdisk=y/# CONFIG_PACKAGE_cgdisk is not set/' .config
sed -i 's/CONFIG_PACKAGE_gdisk=y/# CONFIG_PACKAGE_gdisk is not set/' .config

# 4. 禁用文件系统工具与挂载服务
sed -i 's/CONFIG_DEFAULT_e2fsprogs=y/# CONFIG_DEFAULT_e2fsprogs is not set/' .config
sed -i 's/CONFIG_DEFAULT_f2fs-tools=y/# CONFIG_DEFAULT_f2fs-tools is not set/' .config
sed -i 's/CONFIG_PACKAGE_block-mount=y/# CONFIG_PACKAGE_block-mount is not set/' .config

# 5. 禁用 USB 核心内核模块 (kmod-usb-*)
sed -i 's/CONFIG_PACKAGE_kmod-usb-common=y/# CONFIG_PACKAGE_kmod-usb-common is not set/' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-core=y/# CONFIG_PACKAGE_kmod-usb-core is not set/' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-storage=y/# CONFIG_PACKAGE_kmod-usb-storage is not set/' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-storage-extras=y/# CONFIG_PACKAGE_kmod-usb-storage-extras is not set/' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-storage-uas=y/# CONFIG_PACKAGE_kmod-usb-storage-uas is not set/' .config


mkdir -p package/base-files/files/etc/uci-defaults && \
curl -L https://github.com/Mike-qian/OpenWRT-CI/raw/refs/heads/main/99-Configure-ZRam -o package/base-files/files/etc/uci-defaults/99-Configure-ZRam && \
curl -L https://github.com/Mike-qian/OpenWRT-CI/raw/refs/heads/main/99-replace-apk-mirrors -o package/base-files/files/etc/uci-defaults/99-replace-apk-mirrors

# 启用 MU-MIMO / Beamforming
cat > package/base-files/files/etc/uci-defaults/99-wifi-mumimo <<'MUMIMO'
#!/bin/sh
for radio in radio1 radio2; do
	uci -q get wireless.${radio} >/dev/null 2>&1 || continue
	uci set wireless.${radio}.mu_beamformer='1'
	uci set wireless.${radio}.mu_beamformee='1'
	uci set wireless.${radio}.he_mu_beamformer='1'
done
uci commit wireless
MUMIMO


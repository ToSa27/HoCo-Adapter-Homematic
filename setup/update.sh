#!/bin/bash
cd "${0%/*}"
. ${HOCO_HOME}/data/config.sh

SETUP_PWD=$PWD
sudo chown -R hoco:hoco /opt/hm
cd /opt/hm/src/occu
git pull
cd $SETUP_PWD

sudo systemctl stop hoco-homematic.service
sudo systemctl stop hmipserver.service
sudo systemctl stop rfd.service
sudo systemctl stop multimacd.service

rm -rf /opt/hm/firmware.backup
mv /opt/hm/firmware /opt/hm/firmware.backup
cp -R /opt/hm/src/occu/firmware /opt/hm/
rm -rf /opt/hm/lib.backup
mv /opt/hm/lib /opt/hm/lib.backup
cp -R /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/RFD/lib /opt/hm/
rm -rf /opt/hm/bin.backup
mv /opt/hm/bin /opt/hm/bin.backup
cp -R /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/RFD/bin /opt/hm/
rm -rf /opt/hm/HMserver.backup
mv /opt/hm/HMserver /opt/hm/HMserver.backup
cp -R /opt/hm/src/occu/HMserver/opt/HMServer /opt/hm/
cp /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/LinuxBasis/bin/eq3configcmd /opt/hm/bin/
cp /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/LinuxBasis/lib/libeq3config.so /opt/hm/lib/
rm -f /opt/hm/etc/hmip_networkkey.conf.backup
mv /opt/hm/etc/hmip_networkkey.conf /opt/hm/etc/hmip_networkkey.conf.backup
cp /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/RFD/etc/config_templates/hmip_networkkey.conf /opt/hm/etc/

sed -i 's/\t/ /g' /opt/hm/firmware/HM-MOD-UART/fwmap
sed -i 's/  */ /g' /opt/hm/firmware/HM-MOD-UART/fwmap
sed -i 's/CCU2 copro/#CCU2 copro/g' /opt/hm/firmware/HM-MOD-UART/fwmap
sed -i 's/#CCU2 dualcopro/CCU2 dualcopro/g' /opt/hm/firmware/HM-MOD-UART/fwmap

SETUP_PWD=$PWD
rm -rf /opt/hm/src/bcm2835_raw_uart.backup
mv /opt/hm/src/bcm2835_raw_uart /opt/hm/src/bcm2835_raw_uart.backup
mkdir /opt/hm/src/bcm2835_raw_uart
cd /opt/hm/src/bcm2835_raw_uart
wget https://raw.githubusercontent.com/jens-maus/RaspberryMatic/master/buildroot-external/package/occu/kernel-modules/bcm2835_raw_uart/bcm2835_raw_uart.c
wget https://raw.githubusercontent.com/jens-maus/RaspberryMatic/master/buildroot-external/package/occu/kernel-modules/bcm2835_raw_uart/Makefile
make
sudo make -C /lib/modules/`uname -r`/build M=/opt/hm/src/bcm2835_raw_uart modules_install
rm -rf /opt/hm/src/eq3_char_loop.backup
mv /opt/hm/src/eq3_char_loop /opt/hm/src/eq3_char_loop.backup
mkdir /opt/hm/src/eq3_char_loop
cd /opt/hm/src/eq3_char_loop
wget https://raw.githubusercontent.com/jens-maus/RaspberryMatic/master/buildroot-external/package/occu/kernel-modules/eq3_char_loop/eq3_char_loop.c
wget https://raw.githubusercontent.com/jens-maus/RaspberryMatic/master/buildroot-external/package/occu/kernel-modules/eq3_char_loop/Makefile
make
sudo make -C /lib/modules/`uname -r`/build M=/opt/hm/src/eq3_char_loop modules_install
sudo depmod
mkdir /opt/hm/src/overlay
cd /opt/hm/src/overlay
wget https://raw.githubusercontent.com/jens-maus/RaspberryMatic/master/buildroot-external/package/occu/kernel-modules/bcm2835_raw_uart/bcm2835-raw-uart.dts
dtc -@ -I dts -O dtb -o bcm2835-raw-uart.dtbo bcm2835-raw-uart.dts
sudo cp bcm2835-raw-uart.dtbo /boot/overlays/
cd $SETUP_PWD

sudo ldconfig

cp multimacd.conf /opt/hm/etc/
cp rfd.conf /opt/hm/etc/
cp crRFD.conf /opt/hm/etc/
cp log4j.xml /opt/hm/etc/
cp hmserver.conf /opt/hm/etc/
cp InterfacesList.xml /opt/hm/etc/

sudo systemctl daemon-reload

sudo systemctl start multimacd.service
sudo systemctl start rfd.service
sudo systemctl start hmipserver.service
sudo systemctl start hoco-homematic.service

#!/bin/bash
cd "${0%/*}"
. ${HOCO_HOME}/data/config.sh

SETUP_PWD=$PWD
cd /opt/hm/src/occu
git pull
cd /opt/hm/src/RaspberryMatic
git pull
cd $SETUP_PWD

sudo systemctl stop hoco-homematic.service
sudo systemctl stop hmipserver.service
sudo systemctl stop rfd.service
sudo systemctl stop multimacd.service

mv /opt/hm/firmware /opt/hm/firmware.backup
cp -R /opt/hm/src/occu/firmware /opt/hm/
mv /opt/hm/lib /opt/hm/lib.backup
cp -R /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/RFD/lib /opt/hm/
mv /opt/hm/bin /opt/hm/bin.backup
cp -R /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/RFD/bin /opt/hm/
mv /opt/hm/HMserver /opt/hm/HMserver.backup
cp -R /opt/hm/src/occu/HMserver/opt/HMServer /opt/hm/
mv /opt/hm/bin/eq3configcmd /opt/hm/bin/eq3configcmd.backup
cp /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/LinuxBasis/bin/eq3configcmd /opt/hm/bin/
mv /opt/hm/lib/libeq3config.so /opt/hm/lib/libeq3config.so.backup
cp /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/LinuxBasis/lib/libeq3config.so /opt/hm/lib/
mv /opt/hm/etc/hmip_networkkey.conf /opt/hm/etc/hmip_networkkey.conf.backup
cp /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/RFD/etc/config_templates/hmip_networkkey.conf /opt/hm/etc/

sed -i 's/\t/ /g' /opt/hm/firmware/HM-MOD-UART/fwmap
sed -i 's/  */ /g' /opt/hm/firmware/HM-MOD-UART/fwmap
sed -i 's/CCU2 copro/#CCU2 copro/g' /opt/hm/firmware/HM-MOD-UART/fwmap
sed -i 's/#CCU2 dualcopro/CCU2 dualcopro/g' /opt/hm/firmware/HM-MOD-UART/fwmap

SETUP_PWD=$PWD
mv /opt/hm/src/bcm2835_raw_uart /opt/hm/src/bcm2835_raw_uart.backup
mkdir /opt/hm/src/bcm2835_raw_uart
cd /opt/hm/src/bcm2835_raw_uart
wget https://raw.githubusercontent.com/jens-maus/RaspberryMatic/master/buildroot-external/package/homematic/kernel-modules/bcm2835_raw_uart/bcm2835_raw_uart.c
wget https://raw.githubusercontent.com/jens-maus/RaspberryMatic/master/buildroot-external/package/homematic/kernel-modules/bcm2835_raw_uart/Makefile
make
sudo make -C /lib/modules/`uname -r`/build M=/opt/hm/src/bcm2835_raw_uart modules_install
mv /opt/hm/src/eq3_char_loop /opt/hm/src/eq3_char_loop.backup
mkdir /opt/hm/src/eq3_char_loop
cd /opt/hm/src/eq3_char_loop
wget https://raw.githubusercontent.com/jens-maus/RaspberryMatic/master/buildroot-external/package/homematic/kernel-modules/eq3_char_loop/eq3_char_loop.c
wget https://raw.githubusercontent.com/jens-maus/RaspberryMatic/master/buildroot-external/package/homematic/kernel-modules/eq3_char_loop/Makefile
make
sudo make -C /lib/modules/`uname -r`/build M=/opt/hm/src/eq3_char_loop modules_install
sudo depmod
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

#!/bin/bash
cd "${0%/*}"
. ${HOCO_HOME}/data/config.sh
sudo apt-get install -y raspberrypi-kernel-headers libusb-1.0-0 oracle-java8-jdk
sudo mkdir /opt/hm
sudo chown $HOCO_USER:$HOCO_USER /opt/hm
mkdir /opt/hm/src
mkdir /opt/hm/etc
mkdir /opt/hm/etc/config
mkdir /opt/hm/etc/rfd
mkdir /opt/hm/var
mkdir /opt/hm/var/log
mkdir /opt/hm/var/rfd
mkdir /opt/hm/var/rfd/devices
mkdir /opt/hm/var/status

git clone https://github.com/eq-3/occu /opt/hm/src/occu
git clone https://github.com/jens-maus/RaspberryMatic /opt/hm/src/RaspberryMatic

cp -R /opt/hm/src/occu/firmware /opt/hm/
cp -R /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/RFD/lib /opt/hm/
cp -R /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/RFD/bin /opt/hm/
cp -R /opt/hm/src/occu/HMserver/opt/HMServer /opt/hm/
cp /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/LinuxBasis/bin/eq3configcmd /opt/hm/bin/
cp /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/LinuxBasis/lib/libeq3config.so /opt/hm/lib/
cp /opt/hm/src/occu/arm-gnueabihf/packages-eQ-3/RFD/etc/config_templates/hmip_networkkey.conf /opt/hm/etc/

SETUP_PWD=$PWD
cp -R /opt/hm/src/RaspberryMatic/buildroot-external/package/homematic/kernel-modules/bcm2835_raw_uart /opt/hm/src/
cd /opt/hm/src/bcm2835_raw_uart
make
sudo make -C /lib/modules/`uname -r`/build M=/opt/hm/src/bcm2835_raw_uart modules_install
cp -R /opt/hm/src/RaspberryMatic/buildroot-external/package/homematic/kernel-modules/eq3_char_loop /opt/hm/src/
cd /opt/hm/src/eq3_char_loop
make
sudo make -C /lib/modules/`uname -r`/build M=/opt/hm/src/eq3_char_loop modules_install
sudo depmod
cd $SETUP_PWD

sudo su -c "echo 'PATH=\$PATH:/opt/hm/bin' > /etc/profile.d/homematic.sh"
sudo su -c "echo 'export PATH' >> /etc/profile.d/homematic.sh"
sudo chmod a+x /etc/profile.d/homematic.sh

sudo sed -i 's/dtparam=audio=on/#dtparam=audio=on/g' /boot/config.txt
sudo sed -i 's/enable_uart=0/enable_uart=1/g' /boot/config.txt
sudo su -c "echo 'dtoverlay=pi3-disable-bt' >> /boot/config.txt"
sudo su -c "echo 'dtparam=uart1=off' >> /boot/config.txt"

sudo su -c "echo '/opt/hm/lib/' > /etc/ld.so.conf.d/homematic.conf"
sudo ldconfig

cp multimacd.conf /opt/hm/etc/
cp rfd.conf /opt/hm/etc/
cp crRFD.conf /opt/hm/etc/
cp log4j.xml /opt/hm/etc/
cp hmserver.conf /opt/hm/etc/
sudo cp multimacd.init /etc/init.d/multimacd
sudo chmod a+x /etc/init.d/multimacd
sudo update-rc.d multimacd defaults
sudo cp rfd.init /etc/init.d/rfd
sudo chmod a+x /etc/init.d/rfd
sudo update-rc.d rfd defaults
sudo cp hmipserver.init /etc/init.d/hmipserver
sudo chmod a+x /etc/init.d/hmipserver
sudo update-rc.d hmipserver defaults

sudo systemctl daemon-reload

npm install
echo '{' > config.json
echo ' "mqtt": {'>> config.json
echo '  "url": "'${HOCO_MQTT_URL}'",'>> config.json
echo '  "username": "'${HOCO_MQTT_USER}'",'>> config.json
echo '  "password": "'${HOCO_MQTT_PASS}'",'>> config.json
echo '  "prefix": "'${HOCO_MQTT_PREFIX}'"'>> config.json
echo ' },'>> config.json
echo ' "adapter": ['>> config.json
echo '  {'>> config.json
echo '   "type": "homematic",'>> config.json
echo '   "module": "homematic",'>> config.json
echo '   "protocol": "binrpc",'>> config.json
echo '   "rfd_host": "127.0.0.1",'>> config.json
echo '   "rfd_port": 2001,'>> config.json
echo '   "interface_host": "127.0.0.1",'>> config.json
echo '   "interface_port": 2016'>> config.json
echo '  },'>> config.json
echo '  {'>> config.json
echo '   "type": "homematicip",'>> config.json
echo '   "module": "homematic",'>> config.json
echo '   "protocol": "xmlrpc",'>> config.json
echo '   "rfd_host": "127.0.0.1",'>> config.json
echo '   "rfd_port": 2010,'>> config.json
echo '   "interface_host": "127.0.0.1",'>> config.json
echo '   "interface_port": 2015'>> config.json
echo '  }'>> config.json
echo ' ]'>> config.json
echo '}'>> config.json
sudo cp hoco-homematic.service /etc/systemd/system/
sudo systemctl enable hoco-homemaic.service

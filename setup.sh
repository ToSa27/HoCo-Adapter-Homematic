#!/bin/bash
cd "${0%/*}"
. ${HOCO_HOME}/data/config.sh
. config.sh
sudo apt-get install -y raspberrypi-kernel-headers libusb-1.0-0 oracle-java8-jdk
sudo mkdir $HOCO_HOMEMATIC_HOME
sudo chown $HOCO_USER:$HOCO_USER $HOCO_HOMEMATIC_HOME
mkdir $HOCO_HOMEMATIC_HOME/src
mkdir $HOCO_HOMEMATIC_HOME/etc
mkdir $HOCO_HOMEMATIC_HOME/etc/config
mkdir $HOCO_HOMEMATIC_HOME/etc/rfd
mkdir $HOCO_HOMEMATIC_HOME/var
mkdir $HOCO_HOMEMATIC_HOME/var/log
mkdir $HOCO_HOMEMATIC_HOME/var/rfd
mkdir $HOCO_HOMEMATIC_HOME/var/rfd/devices
mkdir $HOCO_HOMEMATIC_HOME/var/status

git clone https://github.com/eq-3/occu $HOCO_HOMEMATIC_HOME/src/occu
git clone https://github.com/jens-maus/RaspberryMatic $HOCO_HOMEMATIC_HOME/src/RaspberryMatic

cp -R $HOCO_HOMEMATIC_HOME/src/occu/firmware $HOCO_HOMEMATIC_HOME/
cp -R $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/RFD/lib $HOCO_HOMEMATIC_HOME/
cp -R $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/RFD/bin $HOCO_HOMEMATIC_HOME/
cp -R $HOCO_HOMEMATIC_HOME/src/occu/HMserver/opt/HMServer $HOCO_HOMEMATIC_HOME/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/LinuxBasis/bin/eq3configcmd $HOCO_HOMEMATIC_HOME/bin/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/LinuxBasis/lib/libeq3config.so $HOCO_HOMEMATIC_HOME/lib/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/RFD/etc/config_templates/hmip_networkkey.conf $HOCO_HOMEMATIC_HOME/etc/

SETUP_PWD=$PWD
cp -R $HOCO_HOMEMATIC_HOME/src/RaspberryMatic/buildroot-external/package/homematic/kernel-modules/bcm2835_raw_uart $HOCO_HOMEMATIC_HOME/src/
cd $HOCO_HOMEMATIC_HOME/src/bcm2835_raw_uart
make
sudo make -C /lib/modules/`uname -r`/build M=$HOCO_HOMEMATIC_HOME/src/bcm2835_raw_uart modules_install
cp -R $HOCO_HOMEMATIC_HOME/src/RaspberryMatic/buildroot-external/package/homematic/kernel-modules/eq3_char_loop $HOCO_HOMEMATIC_HOME/src/
cd $HOCO_HOMEMATIC_HOME/src/eq3_char_loop
make
sudo make -C /lib/modules/`uname -r`/build M=$HOCO_HOMEMATIC_HOME/src/eq3_char_loop modules_install
sudo depmod
cd $SETUP_PWD

sudo modprobe bcm2835_raw_uart
sudo chown root:dialout /dev/bcm2835-raw-uart
sudo chmod 660 /dev/bcm2835-raw-uart
HOCO_HOMEMATIC_RF_SERIAL=$(eq3configcmd update-coprocessor -p /dev/bcm2835-raw-uart -c -se 2>&1 | grep "SerialNumber:" | cut -d' ' -f5)
HOCO_HOMEMATIC_RF_VERSION=$(eq3configcmd update-coprocessor -p /dev/bcm2835-raw-uart -c -v 2>&1 | grep "Version:" | cut -d' ' -f5)
HOCO_HOMEMATIC_RF_ADDRESS=$(eq3configcmd read-default-rf-address -f /dev/bcm2835-raw-uart -h 2>&1 | grep "^0x")

sudo su -c "echo 'PATH=\$PATH:'$HOCO_HOMEMATIC_HOME'/bin' > /etc/profile.d/homematic.sh"
sudo su -c "echo 'export PATH' >> /etc/profile.d/homematic.sh"
sudo chmod a+x /etc/profile.d/homematic.sh

sudo sed -i 's/dtparam=audio=on/#dtparam=audio=on/g' /boot/config.txt
sudo sed -i 's/enable_uart=0/enable_uart=1/g' /boot/config.txt
sudo su -c "echo 'dtoverlay=pi3-disable-bt' >> /boot/config.txt"
sudo su -c "echo 'dtparam=uart1=off' >> /boot/config.txt"

sudo su -c "echo ''$HOCO_HOMEMATIC_HOME'/lib/' > /etc/ld.so.conf.d/homematic.conf"
sudo ldconfig

cp multimacd.conf $HOCO_HOMEMATIC_HOME/etc/
sed -i "s|<<HOCO_HOMEMATIC_HOME>>|$HOCO_HOMEMATIC_HOME|g" $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
cp rfd.conf $HOCO_HOMEMATIC_HOME/etc/
sed -i "s|<<HOCO_HOMEMATIC_RFD_PORT>>|$HOCO_HOMEMATIC_RFD_PORT|g" $HOCO_HOMEMATIC_HOME/etc/rfd.conf
sed -i "s|<<HOCO_HOMEMATIC_HOME>>|$HOCO_HOMEMATIC_HOME|g" $HOCO_HOMEMATIC_HOME/etc/rfd.conf
cp crRFD.conf $HOCO_HOMEMATIC_HOME/etc/
sed -i "s|<<HOCO_HOMEMATIC_HOME>>|$HOCO_HOMEMATIC_HOME|g" $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
cp log4j.xml $HOCO_HOMEMATIC_HOME/etc/
sed -i "s|<<HOCO_HOMEMATIC_HOME>>|$HOCO_HOMEMATIC_HOME|g" $HOCO_HOMEMATIC_HOME/etc/log4j.xml
cp hmserver.conf $HOCO_HOMEMATIC_HOME/etc/
sed -i "s|<<HOCO_HOMEMATIC_HOME>>|$HOCO_HOMEMATIC_HOME|g" $HOCO_HOMEMATIC_HOME/etc/hmserver.conf
sudo cp multimacd.init /etc/init.d/multimacd
sudo sed -i "s|<<HOCO_HOMEMATIC_HOME>>|$HOCO_HOMEMATIC_HOME|g" /etc/init.d/multimacd
sudo chmod a+x /etc/init.d/multimacd
sudo update-rc.d multimacd defaults
sudo cp rfd.init /etc/init.d/rfd
sudo sed -i "s|<<HOCO_HOMEMATIC_HOME>>|$HOCO_HOMEMATIC_HOME|g" /etc/init.d/rfd
sudo chmod a+x /etc/init.d/rfd
sudo update-rc.d rfd defaults
sudo cp hmipserver.init /etc/init.d/hmipserver
sudo sed -i "s|<<HOCO_HOMEMATIC_HOME>>|$HOCO_HOMEMATIC_HOME|g" /etc/init.d/hmipserver
sudo chmod a+x /etc/init.d/hmipserver
sudo update-rc.d hmipserver defaults

sudo systemctl daemon-reload

sudo systemctl start multimacd
sudo systemctl start rfd
sudo systemctl start hmipserver

npm install
echo '{' > config.json
echo ' "mqtt": {'>> config.json
echo '  "url": "'${HOCO_MQTT_URL}'",'>> config.json
echo '  "username": "'${HOCO_MQTT_USER}'",'>> config.json
echo '  "password": "'${HOCO_MQTT_PASS}'",'>> config.json
echo '  "prefix": "'${HOCO_MQTT_PREFIX}'"'>> config.json
echo ' },'>> config.json
echo ' "homematic": {'>> config.json
echo '  "rfd_host": "'${HOCO_HOMEMATIC_RFD_HOST}'",'>> config.json
echo '  "rfd_port": '${HOCO_HOMEMATIC_RFD_PORT}','>> config.json
echo '  "interface_host": "'${HOCO_HOMEMATIC_INTERFACE_HOST}'",'>> config.json
echo '  "interface_port": '${HOCO_HOMEMATIC_INTERFACE_PORT}','>> config.json
echo '  "module_serial": "'${HOCO_HOMEMATIC_RF_SERIAL}'",'>> config.json
echo '  "module_version": "'${HOCO_HOMEMATIC_RF_VERSION'",'>> config.json
echo '  "module_address": "'${HOCO_HOMEMATIC_RF_ADDRESS'"'>> config.json
echo ' },'>> config.json
echo ' "homematicip": {'>> config.json
echo '  "rfd_host": "'${HOCO_HOMEMATICIP_RFD_HOST}'",'>> config.json
echo '  "rfd_port": '${HOCO_HOMEMATICIP_RFD_PORT}','>> config.json
echo '  "interface_host": "'${HOCO_HOMEMATICIP_INTERFACE_HOST}'",'>> config.json
echo '  "interface_port": '${HOCO_HOMEMATICIP_INTERFACE_PORT}','>> config.json
echo '  "module_serial": "'${HOCO_HOMEMATIC_RF_SERIAL}'",'>> config.json
echo '  "module_version": "'${HOCO_HOMEMATIC_RF_VERSION'",'>> config.json
echo '  "module_address": "'${HOCO_HOMEMATIC_RF_ADDRESS'"'>> config.json
echo ' }'>> config.json
echo '}'>> config.json
pm2 start ${PWD}/app.js --name "homematic" -- homematic
pm2 start ${PWD}/app.js --name "homematicip" -- homematic homematicip
pm2 save

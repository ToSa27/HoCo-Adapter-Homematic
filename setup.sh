#!/bin/bash
cd "${0%/*}"
. ${HOCO_HOME}/config.sh
. config.sh
sudo apt-get install -y raspberrypi-kernel-headers libusb-1.0-0
sudo mkdir $HOCO_HOMEMATIC_HOME
sudo chown hoco:hoco $HOCO_HOMEMATIC_HOME
cd $HOCO_HOMEMATIC_HOME
mkdir bin
mkdir lib
mkdir src

mkdir etc
mkdir var
mkdir var/log
mkdir var/rfd
mkdir var/rfd/devices

git clone https://github.com/eq-3/occu $HOCO_HOMEMATIC_HOME/src/occu
git clone https://github.com/jens-maus/RaspberryMatic $HOCO_HOMEMATIC_HOME/src/RaspberryMatic
cp -R $HOCO_HOMEMATIC_HOME/src/occu/firmware $HOCO_HOMEMATIC_HOME/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/LinuxBasis/bin/eq3configcmd $HOCO_HOMEMATIC_HOME/bin/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/LinuxBasis/lib/libeq3config.so $HOCO_HOMEMATIC_HOME/lib/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/RFD/bin/rfd $HOCO_HOMEMATIC_HOME/bin/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/RFD/bin/SetInterfaceClock $HOCO_HOMEMATIC_HOME/bin/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/RFD/bin/avrprog $HOCO_HOMEMATIC_HOME/bin/
KERNEL_VERSION=`uname -r`
cp -R $HOCO_HOMEMATIC_HOME/src/RaspberryMatic/buildroot-external/package/homematic/kernel-modules/bcm2835_raw_uart $HOCO_HOMEMATIC_HOME/src/
cd $HOCO_HOMEMATIC_HOME/src/bcm2835_raw_uart
make
sudo cp bcm2835_raw_uart.ko /lib/modules/${KERNEL_VERSION}/kernel/
sudo depmod -A
cp -R $HOCO_HOMEMATIC_HOME/src/RaspberryMatic/buildroot-external/package/homematic/kernel-modules/eq3_char_loop $HOCO_HOMEMATIC_HOME/src/
cd $HOCO_HOMEMATIC_HOME/src/eq3_char_loop
make
sudo cp eq3_char_loop.ko /lib/modules/${KERNEL_VERSION}/kernel/
sudo depmod -A




sudo su -c "echo 'PATH=\$PATH:'$HOCO_HOMEMATIC_HOME'/bin' > /etc/profile.d/homematic.sh"
sudo su -c "echo 'export PATH' >> /etc/profile.d/homematic.sh"
sudo chmod a+x /etc/profile.d/homematic.sh

sudo systemctl daemon-reload



wget http://old.openzwave.com/downloads/openzwave-${HOCO_ZWAVE_OZW_VERSION}.tar.gz
tar zxvf openzwave-*.gz
cd openzwave-*
make
sudo make install
cd ..
rm -rf openzwave-*
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
sudo su -c "echo 'LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib' >> /etc/environment"
npm install
echo '{' > config.json
echo ' "mqtt": {'>> config.json
echo '  "url": "'${HOCO_MQTT_URL}'",'>> config.json
echo '  "username": "'${HOCO_MQTT_USER}'",'>> config.json
echo '  "password": "'${HOCO_MQTT_PASS}'",'>> config.json
echo '  "prefix": "'${HOCO_MQTT_PREFIX}'"'>> config.json
echo ' },'>> config.json
echo ' "zwave": {'>> config.json
echo '  "device": "'${HOCO_ZWAVE_DEVICE}'"'>> config.json
echo ' }'>> config.json
echo '}'>> config.json
pm2 start ${PWD}/app.js --name "zwave"
pm2 dump

#!/bin/bash
cd "${0%/*}"
. ${HOCO_HOME}/config.sh
. config.sh
sudo apt-get install -y raspberrypi-kernel-headers libusb-1.0-0
sudo mkdir $HOCO_HOMEMATIC_HOME
sudo chown hoco:hoco $HOCO_HOMEMATIC_HOME
mkdir $HOCO_HOMEMATIC_HOME/bin
mkdir $HOCO_HOMEMATIC_HOME/lib
mkdir $HOCO_HOMEMATIC_HOME/src
mkdir $HOCO_HOMEMATIC_HOME/etc
mkdir $HOCO_HOMEMATIC_HOME/etc/rfd
mkdir $HOCO_HOMEMATIC_HOME/var
mkdir $HOCO_HOMEMATIC_HOME/var/log
mkdir $HOCO_HOMEMATIC_HOME/var/rfd
mkdir $HOCO_HOMEMATIC_HOME/var/rfd/devices

git clone https://github.com/eq-3/occu $HOCO_HOMEMATIC_HOME/src/occu
git clone https://github.com/jens-maus/RaspberryMatic $HOCO_HOMEMATIC_HOME/src/RaspberryMatic
cp -R $HOCO_HOMEMATIC_HOME/src/occu/firmware $HOCO_HOMEMATIC_HOME/
cp -R $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/RFD/lib $HOCO_HOMEMATIC_HOME/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/LinuxBasis/bin/eq3configcmd $HOCO_HOMEMATIC_HOME/bin/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/LinuxBasis/lib/libeq3config.so $HOCO_HOMEMATIC_HOME/lib/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/RFD/bin/rfd $HOCO_HOMEMATIC_HOME/bin/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/RFD/bin/multimacd $HOCO_HOMEMATIC_HOME/bin/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/RFD/bin/SetInterfaceClock $HOCO_HOMEMATIC_HOME/bin/
cp $HOCO_HOMEMATIC_HOME/src/occu/arm-gnueabihf/packages-eQ-3/RFD/bin/avrprog $HOCO_HOMEMATIC_HOME/bin/

cp -R $HOCO_HOMEMATIC_HOME/src/RaspberryMatic/buildroot-external/package/homematic/kernel-modules/bcm2835_raw_uart $HOCO_HOMEMATIC_HOME/src/
cd $HOCO_HOMEMATIC_HOME/src/bcm2835_raw_uart
make
sudo make -C /lib/modules/`uname -r`/build M=$HOCO_HOMEMATIC_HOME/src/bcm2835_raw_uart modules_install
cp -R $HOCO_HOMEMATIC_HOME/src/RaspberryMatic/buildroot-external/package/homematic/kernel-modules/eq3_char_loop $HOCO_HOMEMATIC_HOME/src/
cd $HOCO_HOMEMATIC_HOME/src/eq3_char_loop
make
sudo make -C /lib/modules/`uname -r`/build M=$HOCO_HOMEMATIC_HOME/src/eq3_char_loop modules_install
sudo depmod

sudo su -c "echo 'PATH=\$PATH:'$HOCO_HOMEMATIC_HOME'/bin' > /etc/profile.d/homematic.sh"
sudo su -c "echo 'export PATH' >> /etc/profile.d/homematic.sh"
sudo chmod a+x /etc/profile.d/homematic.sh

sudo sed -i 's/dtparam=audio=on/#dtparam=audio=on/g' /boot/config.txt
sudo sed -i 's/enable_uart=0/enable_uart=1/g' /boot/config.txt
sudo su -c "echo 'dtoverlay=pi3-disable-bt' >> /boot/config.txt"
sudo su -c "echo 'dtparam=uart1=off' >> /boot/config.txt"

sudo su -c "echo ''$HOCO_HOMEMATIC_HOME'/lib/' > /etc/ld.so.conf.d/homematic.conf"
sudo ldconfig

echo '# USB HM/IP TRX Adapter Configuration' > $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Adapter.1.Type=HMIP_CCU2' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Adapter.1.Port=/dev/ttyS0' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Config.Dir=/etc/config/crRFD' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Config.Include=hmip_user.conf' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo '# Directory Configuration' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Persistence.Home=/etc/config/crRFD/data' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'FirmwareUpdate.BG.OTAU.Home=/etc/config/firmware' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo '# Legacy API Configuration' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'API.1.Type=XML-RPC' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Legacy.Encoding=ISO-8859-1' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Legacy.ResponseTimeout=20' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Legacy.ReplacementURL=127.0.0.1' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Legacy.Parameter.Definition.File=/opt/HmIP/legacy-parameter-definition.config' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo '# Legacy.RemoveUnreachableClients=false' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Legacy.AddressPrefix=3014F711A0' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Legacy.SwitchTypeAndSubtype=true' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Legacy.HandlersFilename=/var/LegacyService.handlers' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Legacy.DiscardDutyCycleEvents=true' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo '# Miscellaneous Configuration' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'CyclicTimeout.TimerStartMaxDelay=90' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'CyclicTimeout.TimerCycleTime=600' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'Legacy.Parameter.ReplaceEnumValueWithOrdinal=true' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo '### Configuration for Inclusion with key server (internet) or local key (offline)' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'KeyServer.Mode=KEYSERVER_LOCAL' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf
echo 'KeyServer.Gateway.URL=secgtw.homematic.com' >> $HOCO_HOMEMATIC_HOME/etc/crRFD.conf

echo 'Coprocessor Device Path = /dev/bcm2835-raw-uart' > $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'Log Destination = File' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'Log Filename = '$HOCO_HOMEMATIC_HOME'/var/log/multimacd.log' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'Log Level = 3' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'Log Identifier = multimac' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'Persist Keys = 1' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'HmIP Cmdline Pattern = */crRFD*' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'Bidcos Cmdline Pattern = *rfd -c*' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'Transparent Cmdline Pattern = *update*' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'Bidcos Exe Pattern = */bin/rfd' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'Default Subsystem = HmIP' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'Loop Master Device = /dev/eq3loop' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'Loop Slave Device Bidcos = mmd_bidcos' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf
echo 'Loop Slave Device HmIP = ttyS0' >> $HOCO_HOMEMATIC_HOME/etc/multimacd.conf

sudo cat > /etc/init.d/multimacd <<- EOM
#! /bin/sh
### BEGIN INIT INFO
# Provides:          multimacd
# Required-Start:    \$remote_fs \$syslog
# Required-Stop:     \$remote_fs \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: HomeMatic multimacd
# Description:       HomeMatic multimacd process
### END INIT INFO

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$HOCO_HOMEMATIC_HOME/bin
DESC="HomeMatic multimacd interface process"
NAME=multimacd
DAEMON=$HOCO_HOMEMATIC_HOME/bin/\$NAME
DAEMON_ARGS="-f $HOCO_HOMEMATIC_HOME/etc/multimacd.conf -l 5"
PIDFILE=$HOCO_HOMEMATIC_HOME/var/rfd/\$NAME.pid
SCRIPTNAME=/etc/init.d/\$NAME

[ -x "\$DAEMON" ] || exit 0

. /lib/init/vars.sh

. /lib/lsb/init-functions

case "\$1" in
  start)
    log_daemon_msg "Starting \$DESC" "\$NAME"
    insmod /lib/modules/`uname -r`/extra/bcm2835_raw_uart.ko
    chown root:dialout /dev/bcm2835_raw_uart
    chmod 660 /dev/bcm2835_raw_uart
    insmod /lib/modules/`uname -r`/extra/eq3_char_loop.ko
    chown root:dialout /dev/eq3loop
    chmod 660 /dev/eq3loop
    start-stop-daemon -S -N -10 -q -b -m -p \$PIDFILE --exec \$DAEMON -- \$DAEMON_ARGS
    ;;
  stop)
    log_daemon_msg "Stopping \$DESC" "\$NAME"
    start-stop-daemon -K -q -p \$PIDFILE
    ;;
  status)
    status_of_proc "\$DAEMON" "\$NAME" && exit 0 || exit \$?
    ;;
  *)
    echo "Usage: \$SCRIPTNAME {start|stop|status}" >&2
    exit 3
    ;;
esac

:
EOM
sudo chmod a+x /etc/init.d/multimacd
sudo update-rc.d multimacd defaults

echo 'Listen Port = 2001' > $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'Log Destination = File' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'Log Filename = '$HOCO_HOMEMATIC_HOME'/var/log/rfd.log' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'Log Identifier = rfd' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'Log Level = 1' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'Persist Keys = 1' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'Device Description Dir = '$HOCO_HOMEMATIC_HOME'/firmware/rftypes' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'Device Files Dir = '$HOCO_HOMEMATIC_HOME'/var/rfd/devices' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'Key File = '$HOCO_HOMEMATIC_HOME'/var/rfd/keys' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'Address File = '$HOCO_HOMEMATIC_HOME'/etc/rfd/ids' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'Firmware Dir = '$HOCO_HOMEMATIC_HOME'/firmware/HM-MOD-UART' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'User Firmware Dir = '$HOCO_HOMEMATIC_HOME'/var/firmware' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'XmlRpcHandlersFile = '$HOCO_HOMEMATIC_HOME'/var/RFD.handlers' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'Replacemap File = '$HOCO_HOMEMATIC_HOME'/firmware/rftypes/replaceMap/rfReplaceMap.xml' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo '[Interface 0]' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'Type = CCU2' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'ComPortFile = /dev/mmd_bidcos' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'AccessFile = /dev/null' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf
echo 'ResetFile = /sys/class/gpio/gpio18/value' >> $HOCO_HOMEMATIC_HOME/etc/rfd.conf

sudo cat > /etc/init.d/rfd <<- EOM
#! /bin/sh
### BEGIN INIT INFO
# Provides:          rfd
# Required-Start:    \$remote_fs \$syslog
# Required-Stop:     \$remote_fs \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: HomeMatic rfd
# Description:       HomeMatic BidCoS-RF interface process
### END INIT INFO

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$HOCO_HOMEMATIC_HOME/bin
DESC="HomeMatic BidCoS-RF interface process"
NAME=rfd
DAEMON=$HOCO_HOMEMATIC_HOME/bin/\$NAME
DAEMON_ARGS="-f $HOCO_HOMEMATIC_HOME/etc/rfd.conf -d"
PIDFILE=$HOCO_HOMEMATIC_HOME/var/rfd/\$NAME.pid
SCRIPTNAME=/etc/init.d/\$NAME
USER=hoco

[ -x "\$DAEMON" ] || exit 0

. /lib/init/vars.sh
. /lib/lsb/init-functions

if [ ! -d /sys/class/gpio/gpio18 ] ; then
  echo 18 > /sys/class/gpio/export
  echo out > /sys/class/gpio/gpio18/direction
fi

case "\$1" in
  start)
    log_daemon_msg "Starting \$DESC" "\$NAME"
    start-stop-daemon --start --quiet -c \$USER --exec \$DAEMON -- \$DAEMON_ARGS
    ;;
  stop)
    log_daemon_msg "Stopping \$DESC" "\$NAME"
    start-stop-daemon -K -q -u \$USER -n \$NAME
    ;;
  status)
    status_of_proc "\$DAEMON" "\$NAME" && exit 0 || exit \$?
    ;;
  *)
    echo "Usage: \$SCRIPTNAME {start|stop|status}" >&2
    exit 3
    ;;
esac

:
EOM
sudo chmod a+x /etc/init.d/rfd
sudo update-rc.d rfd defaults

sudo systemctl daemon-reload

cd "${0%/*}"
npm install
echo '{' > config.json
echo ' "mqtt": {'>> config.json
echo '  "url": "'${HOCO_MQTT_URL}'",'>> config.json
echo '  "username": "'${HOCO_MQTT_USER}'",'>> config.json
echo '  "password": "'${HOCO_MQTT_PASS}'",'>> config.json
echo '  "prefix": "'${HOCO_MQTT_PREFIX}'"'>> config.json
echo ' },'>> config.json
echo ' "homematic": {'>> config.json
echo '  "device": "'${HOCO_ZWAVE_DEVICE}'"'>> config.json
echo ' }'>> config.json
echo '}'>> config.json
pm2 start ${PWD}/app.js --name "homematic"
pm2 dump

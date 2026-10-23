#!/system/bin/sh
# Removing the module: bring back a Wi-Fi network an unfinished AirDrop session left.
MODDIR=${0%/*}
[ -f /data/adb/xairdrop/wifi-left ] || exit 0
CLASSPATH="$MODDIR/xos/xairdrop-broker.dex" /system/bin/app_process /system/bin io.github.leekin2.xairdrop.NetworkBroker restore > /data/local/tmp/xairdrop-wifi-recovery.log 2>&1

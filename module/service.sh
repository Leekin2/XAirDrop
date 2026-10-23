#!/system/bin/sh
# Boot: no AirDrop radio, no patches. Only bring back a Wi-Fi network that an AirDrop session
# left when the phone restarted (or Xiaomi Share died) before it could reconnect.
MODDIR=${0%/*}
[ -f /data/adb/xairdrop/wifi-left ] || exit 0
n=0
while [ "$(getprop sys.boot_completed)" != 1 ] && [ $n -lt 90 ]; do sleep 2; n=$((n+1)); done
sleep 10
CLASSPATH="$MODDIR/xos/xairdrop-broker.dex" /system/bin/app_process /system/bin io.github.leekin2.xairdrop.NetworkBroker restore > /data/local/tmp/xairdrop-wifi-recovery.log 2>&1

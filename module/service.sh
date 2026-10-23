#!/system/bin/sh
# Boot: bring back a Wi-Fi network an unfinished AirDrop session left, then start AirDrop the
# way the action button does, so Xiaomi Share's Apple target works without pressing anything.
# The AirDrop radio itself (AWDL) only runs while the Apple share screen is open.
#   - no autostart: touch /data/adb/xairdrop/no-autostart (the action button still works)
#   - if a boot start did not finish (the phone restarted during it), the next boot skips it
MODDIR=${0%/*}
STATE=/data/adb/xairdrop
MARK=$STATE/autostart.running
status() { sed -i "s|^description=.*|description=$1|" "$MODDIR/module.prop" 2>/dev/null; }

status "⏳ AirDrop is starting after boot... / AirDrop açılışta başlatılıyor..."
n=0
while [ "$(getprop sys.boot_completed)" != 1 ] && [ $n -lt 90 ]; do sleep 2; n=$((n+1)); done
# Let Wi-Fi, Bluetooth and Xiaomi Share settle first.
sleep 30

if [ -f "$STATE/wifi-left" ]; then
    CLASSPATH="$MODDIR/xos/xairdrop-broker.dex" /system/bin/app_process /system/bin io.github.leekin2.xairdrop.NetworkBroker restore > /data/local/tmp/xairdrop-wifi-recovery.log 2>&1
fi

if [ -f "$STATE/no-autostart" ]; then
    status "AirDrop: press the action button to start (autostart is off). / AirDrop: başlatmak için Action'a basın (otomatik başlatma kapalı)."
    exit 0
fi
if [ -f "$MARK" ]; then
    rm -f "$MARK"
    status "⚠️ The last automatic start did not finish, so it was skipped: press the action button. / Son otomatik başlatma tamamlanmadı, atlandı: Action'a basın."
    exit 0
fi
mkdir -p "$STATE"
touch "$MARK"
sh "$MODDIR/action.sh" > /dev/null 2>&1
rm -f "$MARK"

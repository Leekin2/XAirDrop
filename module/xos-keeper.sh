#!/system/bin/sh
# Keeps Xiaomi's AirDrop service available to MIShare while the AirDrop Wi-Fi stack is
# loaded: restarts DomesticXOsComm if it exits and holds one reference to it (the service
# is lazy and would otherwise exit when MIShare lets go). Ends when wonder is unloaded,
# i.e. at reboot. Started by step2.sh.
MODDIR=${0%/*}
XOS="$MODDIR/xos"
KLOG=/data/local/tmp/xairdrop-keeper.log
export LD_LIBRARY_PATH="$XOS:/system/lib64:/vendor/lib64"

echo "keeper start $(date)" > "$KLOG"
while grep -q '^wonder ' /proc/modules; do
    if ! pidof DomesticXOsComm > /dev/null; then
        echo "$(date +%T) starting DomesticXOsComm" >> "$KLOG"
        "$XOS/DomesticXOsComm" >> /data/local/tmp/xairdrop-xos.log 2>&1 &
        sleep 2
    fi
    if [ -z "$HOLDER" ] || [ ! -d "/proc/$HOLDER" ]; then
        CLASSPATH="$XOS/xosclient.dex" /system/bin/app_process /system/bin XosClient hold >> "$KLOG" 2>&1 &
        HOLDER=$!
    fi
    sleep 3
done
echo "keeper end $(date): wonder unloaded" >> "$KLOG"

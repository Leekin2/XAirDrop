#!/system/bin/sh
# XAirDrop step 2: make the phone look like a Xiaomi with AirDrop to MIShare.
# MIShare shows AirDrop when /proc/sys/net/wonder/wonder_enable reads 1 and Xiaomi's
# DomesticXOsComm service is reachable; it then starts/stops the radio itself.
# Sourced by action.sh (say/run/fw/LOG/K).
SVC=com.domestic.xoscomm.IDomesticXOsComm/default
XOS="$MODDIR/xos"
MANIFEST=/vendor/etc/vintf/manifest/manifest_com.domestic.xoscomm.xml
WE=/proc/sys/net/wonder/wonder_enable

say "== Step 2: MIShare AirDrop"
if [ ! -r "$MANIFEST" ]; then
    # Module files are not mounted (no metamodule): put a copy of the vendor manifest
    # directory plus ours over it, in init's mount namespace so servicemanager sees it.
    MDIR=/vendor/etc/vintf/manifest
    VDIR=/dev/xairdrop/vintf
    rm -rf "$VDIR"; mkdir -p "$VDIR"
    cp -rp "$MDIR"/. "$VDIR"/ && cp "$MODDIR/system$MANIFEST" "$VDIR"/
    chmod 0755 "$VDIR"; chmod 0644 "$VDIR"/*
    chcon -R --reference="$MDIR" "$VDIR" 2>/dev/null || chcon -R u:object_r:vendor_configs_file:s0 "$VDIR"
    nsenter -t 1 -m -- mount --bind "$VDIR" "$MDIR" 2>> "$LOG" || mount --bind "$VDIR" "$MDIR" 2>> "$LOG"
    if [ -r "$MANIFEST" ] && nsenter -t 1 -m -- test -r "$MANIFEST"; then
        say "manifest bind-mounted over $MDIR ($(ls "$MDIR" | wc -l) files)"
    else
        say "STOP: could not add $MANIFEST"
        die "AirDrop service could not start. Reboot and try again." "AirDrop servisi başlatılamadı. Yeniden başlatıp tekrar deneyin."
    fi
fi

# 1. wonder_enable, as Xiaomi's own wonder.ko provides it
grep -q '^wonder_sysctl ' /proc/modules || run insmod "$K/wonder_sysctl.ko"
if [ "$(cat $WE 2>/dev/null)" = 1 ]; then say "wonder_enable=1"; else say "FAILED: $WE is not 1"; dmesg | grep -iE 'wonder_sysctl|disagrees|Unknown symbol' | tail -n 20 >> "$LOG"; die "AirDrop service could not start. Reboot and try again." "AirDrop servisi başlatılamadı. Yeniden başlatıp tekrar deneyin."; fi
say "label: $(ls -Z $WE 2>&1)"

# 2. Xiaomi's service, kept available by the keeper
chmod 0755 "$XOS/DomesticXOsComm" "$MODDIR/xos-keeper.sh"
# servicemanager re-reads VINTF only when the mtime of apex-info-list.xml changes.
touch /apex/apex-info-list.xml && say "VINTF cache refreshed"
pkill -f xos-keeper.sh 2>/dev/null
pid=$(pidof DomesticXOsComm); [ -n "$pid" ] && kill $pid
sleep 1
setsid nohup sh "$MODDIR/xos-keeper.sh" > /dev/null 2>&1 &
n=0
while [ $n -lt 15 ]; do
    /system/bin/service check "$SVC" 2>/dev/null | grep -q ': found' && break
    sleep 1; n=$((n+1))
done
out=$(/system/bin/service check "$SVC" 2>&1); say "$out"
if ! echo "$out" | grep -q ': found'; then
    say "FAILED: the service did not register"
    cat /data/local/tmp/xairdrop-keeper.log /data/local/tmp/xairdrop-xos.log >> "$LOG" 2>/dev/null
    die "AirDrop service could not start. Reboot and try again." "AirDrop servisi başlatılamadı. Yeniden başlatıp tekrar deneyin."
fi
say "service ready, pid $(pidof DomesticXOsComm)"

# 3. MIShare (platform_app_36 on HyperOS 4) may find and call the service. sepolicy.rule is
# applied at boot; apply it now too, so a module update works without a reboot.
KSUD=/data/adb/ksud
if [ -x "$KSUD" ]; then
    out=$("$KSUD" sepolicy apply "$MODDIR/sepolicy.rule" 2>&1); rc=$?
    if [ $rc != 0 ]; then
        n=0; while IFS= read -r rule; do [ -n "$rule" ] && "$KSUD" sepolicy patch "$rule" > /dev/null 2>&1 && n=$((n+1)); done < "$MODDIR/sepolicy.rule"
        out="apply failed ($out); patched $n rules one by one"
    fi
    say "sepolicy: ${out:-applied}"
fi
MS=com.miui.mishare.connectivity
MSAPK=$(/system/bin/pm path $MS 2>/dev/null | sed -n 's/^package://p' | head -n 1)
DUMP=$(/system/bin/dumpsys package $MS 2>/dev/null)
say "MIShare: $(echo "$DUMP" | grep -m1 versionName | tr -d ' ') $MSAPK"
NF=$(echo "$DUMP" | grep -m1 'android.permission.NETWORK_FACTORY: granted=' | tr -d ' ')
say "MIShare NETWORK_FACTORY: ${NF:-not granted (no grant entry)}"
for d in /product /system_ext /system; do
    [ -r $d/etc/permissions/privapp-permissions-xairdrop.xml ] && say "privapp permission file: $d present" || say "privapp permission file: $d not mounted"
done
say "MIShare system copy: $(echo "$DUMP" | sed -n '/Hidden system packages/,$p' | grep -m1 'codePath=' | tr -d ' ')"

# 4. Patched Xiaomi Share (region limits, network fallback) and share sheet (Apple target).
. "$MODDIR/apply-patches.sh"

# 5. Root broker that registers the xos0 network when Xiaomi Share may not (NETWORK_FACTORY).
# Patched Xiaomi Share uses it only after its own registration fails.
APPID=$(echo "$DUMP" | sed -n -e 's/^[[:space:]]*appId=\([0-9][0-9]*\).*/\1/p' -e 's/^[[:space:]]*userId=\([0-9][0-9]*\).*/\1/p' | head -n 1)
BROKER_CP="$XOS/xairdrop-broker.dex:$MSAPK"
BLOG=/data/local/tmp/xairdrop-broker.log
broker_ping() { CLASSPATH="$BROKER_CP" /system/bin/app_process /system/bin io.github.leekin2.xairdrop.NetworkBroker ping > /dev/null 2>&1; }
if broker_ping; then
    say "network broker already running"
elif [ -n "$APPID" ] && [ -n "$MSAPK" ]; then
    chmod 0644 "$XOS/xairdrop-broker.dex"
    CLASSPATH="$BROKER_CP" setsid nohup /system/bin/app_process /system/bin io.github.leekin2.xairdrop.NetworkBroker "$APPID" > "$BLOG" 2>&1 &
    n=0; while [ $n -lt 10 ] && ! broker_ping; do sleep 1; n=$((n+1)); done
    if broker_ping; then say "network broker ready (MIShare appId $APPID)"; else say "WARNING: network broker did not start"; tail -n 30 "$BLOG" >> "$LOG"; die "AirDrop service could not start. Reboot and try again." "AirDrop servisi başlatılamadı. Yeniden başlatıp tekrar deneyin."; fi
else
    say "WARNING: no MIShare appId/APK; network broker not started"
    die "Xiaomi Share is not installed: install MIShare-5.4.2.apk from the release." "Xiaomi Share kurulu değil: sürümdeki MIShare-5.4.2.apk'yı kurun."
fi

fw am force-stop $MS
show "AirDrop is ready until reboot: Share > Transfer to and from Apple devices."
show "AirDrop yeniden başlatmaya kadar hazır: Paylaş > Transfer to and from Apple devices."
[ "$MS_OK" = 1 ] || show "Note: install MIShare-5.4.2.apk from the release, reboot and press again. / Sürümdeki MIShare-5.4.2.apk'yı kurup yeniden başlatın ve tekrar basın."
if [ $DEBUG != 1 ]; then
    say "== kernel warnings"
    dmesg | grep -nE 'WARNING:|Call trace|Oops|BUG:' | tail -n 20 >> "$LOG"
    return 0
fi
T=$(date '+%m-%d %H:%M:%S.000')
say ""
say ">>> NOW: share a photo (Gallery or Files) and pick 'Transfer to and from Apple devices'."
say ">>> On the iPhone: Settings > General > AirDrop > Everyone for 10 Minutes; keep it unlocked."
say ">>> Keep the Apple search screen open. Collecting logs for 90 seconds (not a transfer limit)..."
# Record while the test runs: Android drops older lines of a busy app before a later dump.
LC=/data/local/tmp/xairdrop-logcat.txt
/system/bin/logcat -b all -T "$T" > "$LC" 2>/dev/null &
LCPID=$!
sleep 90
kill $LCPID 2>/dev/null
say "== Xiaomi Share / share sheet log"
cat "$LC" | grep -E 'MiShare|Awdl|AirDrop|XOS|xos0|XAirDrop|DomesticXOs|ChooserActivityStubImpl|AndroidRuntime|avc: +denied' | grep -vE 'hyos_spawner|PowerInsight|ANDR-PWR' | grep -vE "_prop:s0|gpuclk|cgroup|migt" | tail -n 3000 >> "$LOG"
say "== processes"
/system/bin/ps -AZ 2>/dev/null | grep -E 'mishare|DomesticXOsComm|app_process|intentresolver' >> "$LOG"
say "== keeper"
cat /data/local/tmp/xairdrop-keeper.log >> "$LOG"
say "== XOS daemon (last 80 lines)"
tail -n 80 /data/local/tmp/xairdrop-xos.log >> "$LOG" 2>/dev/null
say "== Wi-Fi after the test"
/system/bin/cmd wifi status 2>&1 | grep -E "Wifi is|connected" | head -n 4 >> "$LOG"
[ -f /data/adb/xairdrop/wifi-left ] && say "WARNING: a Wi-Fi network is still left for AirDrop (netId $(cat /data/adb/xairdrop/wifi-left)); it comes back with the next AirDrop session or action"
say "== network broker"
tail -n 80 "$BLOG" >> "$LOG" 2>/dev/null
say "== kernel log (AirDrop)"
dmesg | grep -iE 'wonder|OPAIRSHARE[A-Z]*(RSP|FAIL|READY|AUTO)|Vendor init' | tail -n 80 >> "$LOG"
say "== kernel warnings"
dmesg | grep -nE 'WARNING:|Call trace|Oops|BUG:|Modules linked in' | tail -n 20 >> "$LOG"
L=$(dmesg | grep -nE 'WARNING:|Oops|BUG:' | tail -n 1 | cut -d: -f1)
[ -n "$L" ] && dmesg | sed -n "$((L>5 ? L-5 : 1)),$((L+45))p" >> "$LOG"
say "RESULT 2: AirDrop stays available until reboot. Send this log."
show "Log: $LOG"
return 0

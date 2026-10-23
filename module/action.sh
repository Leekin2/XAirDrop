#!/system/bin/sh
# XAirDrop action: swap in the AirDrop-capable Wi-Fi stack (OPAirDrop, OnePlus 13 / SM8750,
# CRCs adapted to the Xiaomi 15 family) in RAM only, then start Xiaomi's AirDrop service and
# patch Xiaomi Share (step2.sh). If the new driver does not bring Wi-Fi up, the stock driver is
# put back. A reboot always restores the stock driver. Nothing here runs at boot.
# The screen gets a few plain lines; everything else goes to the log for support.
# Debug mode (touch /data/adb/xairdrop/debug): all lines on screen, a timestamped log and
# 90 s of Xiaomi Share logs while you test.
MODDIR=${0%/*}
K="$MODDIR/kernel"
DEBUG=0; [ -f /data/adb/xairdrop/debug ] && DEBUG=1
if [ $DEBUG = 1 ]; then LOG=/sdcard/Download/xairdrop-test-$(date +%Y%m%d-%H%M%S).log; else LOG=/data/local/tmp/xairdrop.log; fi
STOCK_DIR=/vendor/lib/modules
[ -f "$STOCK_DIR/qca_cld3_peach_v2.ko" ] || STOCK_DIR=/vendor_dlkm/lib/modules
INI=/vendor/firmware/wlan/WCNSS_qcom_cfg.ini

# say: log (and screen in debug mode); show: always on screen. Messages in English and Turkish.
say() { [ $DEBUG = 1 ] && echo "$*"; echo "$*" >> "$LOG"; }
show() { echo "$*"; echo "$*" >> "$LOG"; }
# The module's description in KernelSU shows whether AirDrop is on.
status() { sed -i "s|^description=.*|description=$1|" "$MODDIR/module.prop" 2>/dev/null; }
NOT_ACTIVE="❌ AirDrop is off: press the action button. / AirDrop kapalı: Action'a basın."
# A failure the user can act on: the message, then where the details are.
die() { show "$1"; show "$2"; show "Log: $LOG"; status "$NOT_ACTIVE"; exit 1; }

# One run at a time: the boot start and the action button must not swap drivers together.
if ! mkdir /dev/xairdrop.lock 2>/dev/null; then
    echo "AirDrop is already starting, please wait. / AirDrop zaten başlatılıyor, lütfen bekleyin."
    exit 0
fi
trap 'rmdir /dev/xairdrop.lock 2>/dev/null' EXIT
run() { echo "\$ $*" >> "$LOG"; "$@" >> "$LOG" 2>&1; rc=$?; [ $rc = 0 ] || echo "  -> exit $rc" >> "$LOG"; return $rc; }
# Framework tools: pin the Android binaries (KernelSU's shell prefers BusyBox applets) and
# capture their output, so system_server never receives a file descriptor it may not use.
fw() { tool=$1; shift; out=$(/system/bin/$tool "$@" 2>&1); rc=$?; echo "\$ $tool $*" >> "$LOG"; [ -n "$out" ] && echo "$out" >> "$LOG"; return $rc; }
loaded() { grep -q "^$1 " /proc/modules; }
wifi_state() { s=$(/system/bin/cmd wifi status 2>&1); case "$s" in 'Wifi is enabled'*) echo 1;; 'Wifi is disabled'*) echo 0;; *) echo ?;; esac; }
wifi_wait() { n=0; while [ "$(wifi_state)" != "$1" ] && [ $n -lt 20 ]; do sleep 1; n=$((n+1)); done; [ "$(wifi_state)" = "$1" ]; }
wlan_wait() { n=0; while [ ! -d /sys/class/net/wlan0 ] && [ $n -lt "$1" ]; do sleep 1; n=$((n+1)); done; [ -d /sys/class/net/wlan0 ]; }
hal_services() { getprop | sed -n 's/^\[init\.svc\.\(vendor\.wifi_hal[^]]*\)\]: \[running\]$/\1/p'; }

: > "$LOG"
say "== XAirDrop 1.0 ($(date))"
show "XAirDrop: starting AirDrop... / AirDrop başlatılıyor..."
say "device=$(getprop ro.product.device) model=$(getprop ro.product.model) build=$(getprop ro.build.version.incremental)"
say "kernel=$(uname -r)"
say "== Wi-Fi modules before"
grep -E '^(qca_cld3|cnss|mac80211|cfg80211|wonder|oneplus13)' /proc/modules >> "$LOG"
say "wifi_state=$(wifi_state)"

# Kernel log of the previous boot, in case the phone rebooted by itself.
for f in /sys/fs/pstore/console-ramoops* /sys/fs/pstore/dmesg-ramoops*; do
    [ -r "$f" ] || continue
    say "== previous boot: $f"
    grep -iE 'panic|Oops|BUG|Unable to handle|Call trace|pc :|lr :|wonder|opairshare|passthru|qca_cld|wlan_hdd|sap|hostapd|softap' "$f" | tail -n 120 >> "$LOG"
done

# Swapping the Wi-Fi driver under a running hotspot can crash the kernel.
AP=$(ls /sys/class/net | grep -E '^(ap|swlan|softap)|^wlan[1-9]|^ap_br' | tr '\n' ' ')
if [ -n "$AP" ]; then
    say "hotspot interfaces: $AP"
    die "Turn off the hotspot, then press the action button again." "Hotspot'u kapatıp Action'a tekrar basın."
fi

if ! loaded qca_cld3_peach_v2; then
    say "stock driver qca_cld3_peach_v2 is not loaded"
    die "This phone is not supported (Xiaomi 15 / 15 Ultra only)." "Bu telefon desteklenmiyor (yalnızca Xiaomi 15 / 15 Ultra)."
fi
if loaded wonder && loaded oneplus13_wonder_provider && [ -d /sys/class/net/wlan0 ]; then
    say "Step 1 stack already loaded in this boot; going to step 2."
    . "$MODDIR/step2.sh"
    exit $?
fi
if loaded wonder || loaded oneplus13_wonder_provider; then
    say "half-loaded stack present"
    die "Reboot the phone, then press the action button again." "Telefonu yeniden başlatıp Action'a tekrar basın."
fi
# Without a mount metamodule (stock SukiSU/KernelSU) the module's system/ is never mounted.
# Then hand the kernel the ini directly: a copy in /dev labeled like vendor firmware, found
# first through firmware_class.path while the driver loads.
FW_PATH=/sys/module/firmware_class/parameters/path
FW_OLD=
if [ ! -r "$INI" ]; then
    MOD_INI="$MODDIR/system/vendor/firmware/wlan/WCNSS_qcom_cfg.ini"
    if [ ! -r "$MOD_INI" ]; then
        say "$MOD_INI is missing"
        die "Module files are missing: reinstall XAirDrop." "Modül dosyaları eksik: XAirDrop'u yeniden kurun."
    fi
    FW_DIR=/dev/xairdrop/fw
    mkdir -p "$FW_DIR/wlan" && cp "$MOD_INI" "$FW_DIR/wlan/" && chmod -R 0755 /dev/xairdrop && chmod 0644 "$FW_DIR/wlan/WCNSS_qcom_cfg.ini"
    chcon -R u:object_r:vendor_firmware_file:s0 "$FW_DIR"
    FW_OLD=$(cat "$FW_PATH" 2>/dev/null)
    echo -n "$FW_DIR" > "$FW_PATH" || die "Could not prepare the Wi-Fi driver." "Wi-Fi sürücüsü hazırlanamadı."
    INI="$FW_DIR/wlan/WCNSS_qcom_cfg.ini"
    say "module files are not mounted (no metamodule); ini served from $FW_DIR via firmware_class.path"
fi
say "ini ok: $(ls -lZ "$INI" 2>&1)"
grep -q "^monitor_mode_concurrency=1" "$INI" && say "ini: monitor_mode_concurrency=1" || say "WARNING: ini has no monitor_mode_concurrency=1; reinstall the v0.9 module and reboot"

WIFI_BEFORE=$(wifi_state)
[ "$WIFI_BEFORE" = ? ] && WIFI_BEFORE=1
HALS=$(hal_services)
say "wifi_before=$WIFI_BEFORE hal=[$HALS]"
# Radio profile. "airdrop" (default) is the profile that has delivered files to an iPhone
# (Mi 15, 2026-10-23): the AirDrop channel gets the radio and Wi-Fi may drop during AirDrop.
# "wifi-keep" keeps the Wi-Fi connection receiving alongside AirDrop; not yet proven.
# Choose it with: su -c touch /data/adb/xairdrop/wifi-keep
if [ -f /data/adb/xairdrop/wifi-keep ]; then
    PROFILE=wifi-keep; STA="passthru_sta_coexist=3 passthru_sta_regular_rx=1"
else
    PROFILE=airdrop; STA="passthru_sta_coexist=1 passthru_sta_regular_rx=0"
fi
say "radio profile: $PROFILE ($STA)"

restore_stock() {
    say "== Restoring the stock Wi-Fi driver"
    fw svc wifi disable; wifi_wait 0
    for h in $HALS; do run stop "$h"; done
    sleep 2
    loaded wonder_sysctl && run rmmod wonder_sysctl
    loaded wonder && run rmmod wonder
    if [ "$MAC_SWAPPED" = 1 ]; then
        loaded mac80211 && run rmmod mac80211
        run insmod "$STOCK_DIR/mac80211.ko"
    fi
    loaded qca_cld3_peach_v2 && run rmmod qca_cld3_peach_v2
    loaded oneplus13_wonder_provider && run rmmod oneplus13_wonder_provider
    loaded qca_cld3_peach_v2 || run insmod "$STOCK_DIR/qca_cld3_peach_v2.ko"
    for h in $HALS; do run start "$h"; done
    sleep 2
    [ "$WIFI_BEFORE" = 1 ] && fw svc wifi enable
    if wlan_wait 20; then say "stock Wi-Fi is back (wlan0 present)"; else say "stock Wi-Fi did not come back: reboot the phone"; fi
}
fail() {
    say "FAILED: $*"
    show "AirDrop could not start; stock Wi-Fi is being restored. / AirDrop başlatılamadı; stok Wi-Fi geri yükleniyor."
    [ -n "$FW_DIR" ] && echo -n "$FW_OLD" > "$FW_PATH"
    dmesg | grep -iE 'qca_cld|wonder|opairshare|passthru|disagrees|unknown symbol|Failed to probe|WCNSS' | tail -n 80 >> "$LOG"
    restore_stock
    show "Log: $LOG"; status "$NOT_ACTIVE"; exit 1
}

MAC_SWAPPED=0
say "== 1. Wi-Fi off, HAL stopped"
fw svc wifi disable
wifi_wait 0 || say "warning: Wi-Fi did not report disabled"
sleep 3
for h in $HALS; do run stop "$h"; done
sleep 2

say "== 2. Driver swap"
run rmmod qca_cld3_peach_v2 || { for h in $HALS; do run start "$h"; done; fw svc wifi enable; die "The Wi-Fi driver is busy; reboot and press the action button right away." "Wi-Fi sürücüsü meşgul; yeniden başlatıp hemen Action'a basın."; }
run insmod "$K/oneplus13_wonder_provider.ko" || fail "provider did not load"
run insmod "$K/qca_cld3_peach_v2.ko" \
    passthru_awdl_addba=1 passthru_awdl_native_rx=1 passthru_ht=1 passthru_fwtype=7 passthru_mon_rings=0 passthru_dry_run=0 \
    passthru_mon_chan_sync=1 passthru_ndi_peer=1 passthru_ndi_no_up=1 \
    passthru_mgmt_bridge=1 passthru_aux_monitor=1 passthru_tx_audit=1 \
    passthru_ndi_fw_authorize=0 passthru_awdl_wmi_raw=1 \
    passthru_awdl_target_mac="" passthru_awdl_target_auto=1 passthru_awdl_target_enable=1 passthru_awdl_target_auth=2 \
    passthru_native_data_rx=1 passthru_awdl_backpressure=1 passthru_awdl_raw_rx=1 passthru_awdl_rate_mbps=54 \
    passthru_awdl_host_seq=1 passthru_awdl_rx_dedup=1 passthru_awdl_attempts=3 passthru_awdl_rx_auto=1 passthru_awdl_rx_rearm=1 \
    $STA passthru_sta_action_rx=1 passthru_pas_discovery_actions=1 \
    || fail "AirDrop Wi-Fi driver did not load"
if wlan_wait 25; then say "new driver is up: wlan0 present"; else fail "new driver loaded but Wi-Fi (wlan0) did not come up"; fi
[ -n "$FW_DIR" ] && { echo -n "$FW_OLD" > "$FW_PATH"; dmesg | grep -iE 'WCNSS_qcom_cfg|firmware.*wlan' | tail -n 5 >> "$LOG"; }
if loaded mac80211; then
    run rmmod mac80211 && MAC_SWAPPED=1 || say "warning: stock mac80211 in use, keeping it"
else
    MAC_SWAPPED=1
fi
[ $MAC_SWAPPED = 1 ] && { run insmod "$K/mac80211.ko" || fail "mac80211 did not load"; }
run insmod "$K/wonder.ko" physical_name=wondertap0 virtual_name=wonder0 || fail "wonder did not load"

say "== 3. HAL and Wi-Fi back on"
for h in $HALS; do run start "$h"; done
sleep 2
[ "$WIFI_BEFORE" = 1 ] && fw svc wifi enable
wifi_wait "$WIFI_BEFORE" || say "warning: Wi-Fi state did not return to $WIFI_BEFORE"
sleep 10

say "== 4. Result"
grep -E '^(qca_cld3|cnss2|mac80211|cfg80211|wonder|oneplus13)' /proc/modules >> "$LOG"
say "wifi_state=$(wifi_state)"
fw cmd wifi status
say "interfaces: $(ls /sys/class/net | tr '\n' ' ')"
say "phys: $(ls /sys/class/ieee80211 2>&1 | tr '\n' ' ')"
for p in opairshare_channel_state opairshare_awdl_rx_mac_filter passthru_fwtype; do
    f=/sys/module/qca_cld3_peach_v2/parameters/$p
    [ -r "$f" ] && say "$p=$(cat "$f")"
done
say "== kernel log (wonder / wlan, since the swap)"
dmesg | sed -n '/Hard Unloading driver/,$p' | grep -iE 'wonder|passthru|opairshare|qca_cld|peach_v2|cnss|wlan_hdd|disagrees|unknown symbol|Failed|WCNSS' | tail -n 200 >> "$LOG"

if [ -d /sys/class/net/wlan0 ] && loaded wonder; then
    say "RESULT 1: AirDrop Wi-Fi stack loaded and wlan0 is up."
    . "$MODDIR/step2.sh"
    exit $?
else
    say "RESULT 1: stack incomplete"
    die "AirDrop could not start. Reboot and try again." "AirDrop başlatılamadı. Yeniden başlatıp tekrar deneyin."
fi

#!/system/bin/sh
# The AirDrop radio and the patches load only from the action button; at boot service.sh only
# restores a Wi-Fi network an unfinished AirDrop session left.
case "$(uname -r)" in
    6.6.118-android15-8*) ui_print "- Kernel $(uname -r): OK" ;;
    *) abort "! Kernel $(uname -r) is not 6.6.118-android15-8" ;;
esac
case "$(getprop ro.product.device)" in
    xuanyuan|dada) ui_print "- Xiaomi 15 Ultra / Xiaomi 15: OK" ;;
    *) ui_print "! Not a Xiaomi 15 Ultra (xuanyuan) or Xiaomi 15 (dada); the test may refuse to run" ;;
esac
# The test builds were installed as "xairdrop_test"; two copies would both load the radio.
if [ -d /data/adb/modules/xairdrop_test ]; then
    touch /data/adb/modules/xairdrop_test/remove
    ui_print "- Old XAirDrop test module will be removed at reboot"
fi
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/apply-patches.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
# The OnePlus driver reads wlan/WCNSS_qcom_cfg.ini; Xiaomi keeps it under qca_cld/peach_v2.
# Give the OnePlus path a copy of the phone's own file plus the one setting the OnePlus ini
# has and Xiaomi's lacks: monitor_mode_concurrency=1 (STA + monitor), which the AirDrop
# receive path needs. Only the OnePlus driver reads this path; the stock driver is untouched.
SRC_INI=/vendor/etc/wifi/peach_v2/WCNSS_qcom_cfg.ini
DST_INI="$MODPATH/system/vendor/firmware/wlan/WCNSS_qcom_cfg.ini"
mkdir -p "${DST_INI%/*}"
rm -f "$DST_INI"
[ -r "$SRC_INI" ] || abort "! $SRC_INI is missing"
awk '/^monitor_mode_concurrency=/ { next }
     /^END[ \t\r]*$/ && !done { print "monitor_mode_concurrency=1"; done = 1 }
     { print }
     END { if (!done) print "monitor_mode_concurrency=1" }' "$SRC_INI" > "$DST_INI" || abort "! could not write the Wi-Fi ini"
set_perm "$DST_INI" 0 0 0644
ui_print "- Wi-Fi ini: $(grep -c '' "$DST_INI") lines, $(grep '^monitor_mode_concurrency=' "$DST_INI")"
ui_print "- Needs Xiaomi Share (MIShare) 5.4.2 from the Xiaomi 18 Pro Max installed."
ui_print "- No LSPosed: the action patches Xiaomi Share and the share sheet until reboot."
ui_print "- Uninstall the XAirDrop LSPosed test app (v0.23) if it is installed."
ui_print "- Reboot once, then press the action button to run the test."

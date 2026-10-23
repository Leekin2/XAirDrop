#!/system/bin/sh
# Put XAirDrop's patched Xiaomi Share and share sheet over the installed APKs, for this boot only.
# The patched APKs carry the original signature files but changed code, so they cannot be
# installed; PackageManager scanned the originals at boot and keeps their certificates, and
# apps started after the bind mount load the patched code. Only the exact APKs the patches were
# made from are replaced; anything else is left alone. A reboot restores the originals.
# Sourced by step2.sh (say/LOG/MODDIR); "--mount <target> <payload>" runs inside a namespace.
if [ "$1" = --mount ]; then
    target=$2; payload=$3
    label=$(/system/bin/ls -Zd "$target" | awk '{print $1}')
    case "$label" in u:object_r:*) ;; *) echo "cannot read the label of $target"; exit 1 ;; esac
    chcon "$label" "$payload" || exit 1
    grep -q " $target " /proc/self/mountinfo && umount "$target" 2>/dev/null
    mount --bind "$payload" "$target" || exit 1
    exit 0
fi

# package, sha256 of the original APK, payload
PATCHES="com.miui.mishare.connectivity 394203fc35714c4c5d4b4e0b6d17ecaab239f5562a79bcf0a449ca36316cfa44 MIShare-xairdrop.apk
com.android.intentresolver a60ad59f762f5181de8289f6d013e50f294088d980241205acb666e229904d97 MiIntentResolver-xairdrop.apk"

ns_hash() { nsenter -t "$1" -m -- sha256sum "$2" 2>/dev/null | cut -d ' ' -f 1; }

echo "$PATCHES" | while read -r pkg orig file; do
    payload="$MODDIR/payload/$file"
    want=$(sha256sum "$payload" | cut -d ' ' -f 1)
    apk=$(/system/bin/pm path "$pkg" 2>/dev/null | sed -n 's/^package://p' | head -n 1)
    if [ -z "$apk" ]; then say "patch $pkg: not installed, skipped"; continue; fi
    chmod 0644 "$payload"
    ok=1
    for nspid in 1 $(pidof zygote64 zygote); do
        have=$(ns_hash "$nspid" "$apk")
        if [ "$have" = "$want" ]; then continue; fi
        if [ "$have" != "$orig" ]; then
            say "patch $pkg: $apk is another version ($have), left as it is"
            ok=0; break
        fi
        nsenter -t "$nspid" -m -- sh "$MODDIR/apply-patches.sh" --mount "$apk" "$payload" >> "$LOG" 2>&1
        [ "$(ns_hash "$nspid" "$apk")" = "$want" ] || { say "patch $pkg: mount failed in namespace of pid $nspid"; ok=0; break; }
    done
    if [ $ok = 1 ]; then
        say "patch $pkg: active ($apk)"
        /system/bin/am force-stop "$pkg" > /dev/null 2>&1
    fi
done

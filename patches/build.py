"""Build XAirDrop's patched APKs without any hook framework.

  MIShare 5.4.2 (from the Xiaomi 18 Pro Max):
    - d2.T.b / d2.Z.a / e1.j.b: no region, device whitelist or Quick Share hand-off limits
    - AwdlServiceClient.a / unregisterNetworkAgent: fall back to the root NetworkBroker for the
      xos0 network when MIShare may not register it (NETWORK_FACTORY); new classes3.dex = Bridge
    - a.k0 (WifiConflictManager) b / e / d: a Wi-Fi connection on any band, not only 5 GHz,
      conflicts with the AirDrop channel; leave it for the session (broker when MIShare may not)
    - a.u0 (AirDropBleAdvertiser): AirDrop BLE advertisement in Apple's layout (version byte,
      hashes at offset 11)
  MiIntentResolver (Xiaomi 15 Ultra OS4.0.0.18):
    - gallery-return callback starts the Apple target like the 18 Pro Max share sheet does;
      new classes2.dex = ChooserFix
  broker.dex: NetworkBroker, run as root by the module.

Only the dex entries change; every other APK entry is copied byte for byte and the APK is
zip-aligned. The APK signatures no longer match the dex: the module mounts these over the
installed APKs after boot (PackageManager keeps the original certificates); a ROM signs them.

python build.py <out dir>
"""
import os, re, shutil, subprocess, sys, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
AIRDROP = os.path.abspath(os.path.join(HERE, "..", ".."))
SDK = os.path.join(os.environ["LOCALAPPDATA"], "Android", "Sdk")
ANDROID_JAR = os.path.join(SDK, "platforms", "android-37.0", "android.jar")
BT = os.path.join(SDK, "build-tools", "36.0.0")
APKTOOL = os.path.expanduser(r"~\.gemini\antigravity\scratch\apktool.jar")
MISHARE_APK = os.path.expanduser(r"~\Desktop\MIShare-5.4.2-18ProMax.apk")
RESOLVER_APK = os.path.join(AIRDROP, r"x\xy_ir\system_ext\priv-app\MiIntentResolver\MiIntentResolver.apk")
WORK = os.path.join(AIRDROP, "patch")
PKG = "Lio/github/leekin2/xairdrop"


def run(*cmd):
    print("$", " ".join(cmd))
    subprocess.run(cmd, check=True, shell=cmd[0].endswith(".bat"))


def replace_once(text, old, new, what):
    if text.count(old) != 1:
        sys.exit(f"patch '{what}': expected 1 match, found {text.count(old)}")
    return text.replace(old, new)


def method(text, header):
    """Return (start, end) of the method whose .method line is header."""
    start = text.find(header + "\n")
    if start < 0 or text.find(header + "\n", start + 1) >= 0:
        sys.exit(f"method not found exactly once: {header}")
    end = text.index(".end method", start) + len(".end method")
    return start, end


def set_body(path, header, body):
    text = open(path, encoding="utf-8").read()
    s, e = method(text, header)
    text = text[:s] + header + "\n" + body + "\n.end method" + text[e:]
    open(path, "w", encoding="utf-8", newline="\n").write(text)


def smali_file(root, cls):
    """apktool renames files that collide on case-insensitive disks (e1 vs E1 -> e1.1)."""
    want = f".class {cls}" if cls.startswith("L") else cls
    for d in sorted(os.listdir(root)):
        if not d.startswith("smali"):
            continue
        rel = cls[1:-1].split("/")
        for cand_dir in [os.path.join(root, d, *rel[:-1])] + [os.path.join(root, d, *rel[:-2], rel[-2] + ".1")]:
            if not os.path.isdir(cand_dir):
                continue
            for name in os.listdir(cand_dir):
                if name.split(".")[0] != rel[-1] or not name.endswith(".smali"):
                    continue
                p = os.path.join(cand_dir, name)
                with open(p, encoding="utf-8") as f:
                    first = f.readline()
                if re.match(r"\.class .*" + re.escape(cls) + r"\s*$", first.strip() + "\n") or first.strip().endswith(" " + cls):
                    return p
    sys.exit(f"smali for {cls} not found")


def decode(apk, out):
    if os.path.isdir(out):
        shutil.rmtree(out)
    run("java", "-jar", APKTOOL, "d", "-r", "-f", "-o", out, apk)


def build_dex_from_smali(src_dir, out_apk):
    run("java", "-jar", APKTOOL, "b", "-o", out_apk, src_dir)


def compile_helpers(out):
    classes = os.path.join(WORK, "helpers-classes")
    shutil.rmtree(classes, ignore_errors=True)
    os.makedirs(classes)
    src = os.path.join(HERE, "src", "io", "github", "leekin2", "xairdrop")
    run("javac", "-source", "17", "-target", "17", "-nowarn", "-cp", ANDROID_JAR, "-d", classes,
        *[os.path.join(src, f) for f in os.listdir(src) if f.endswith(".java")])
    cdir = os.path.join(classes, "io", "github", "leekin2", "xairdrop")
    dexes = {}
    for name, prefixes in {"bridge": ["Bridge"], "chooserfix": ["ChooserFix"], "broker": ["NetworkBroker", "WifiControl"]}.items():
        files = [os.path.join(cdir, f) for f in os.listdir(cdir) if f.split("$")[0].split(".")[0] in prefixes]
        d = os.path.join(WORK, "dex-" + name)
        shutil.rmtree(d, ignore_errors=True)
        os.makedirs(d)
        run(os.path.join(BT, "d8.bat"), "--release", "--min-api", "35", "--lib", ANDROID_JAR, "--output", d, *files)
        dexes[name] = os.path.join(d, "classes.dex")
    shutil.copy(dexes["broker"], os.path.join(out, "xairdrop-broker.dex"))
    return dexes


def patch_mishare(root):
    t = smali_file(root, "Ld2/T;")
    set_body(t, ".method public static b()Z", "    .locals 1\n    const/4 v0, 0x1\n    return v0")
    z = smali_file(root, "Ld2/Z;")
    set_body(z, ".method public static a()Z", "    .locals 1\n    const/4 v0, 0x1\n    return v0")
    j = smali_file(root, "Le1/j;")
    set_body(j, ".method public static b(Landroid/content/Context;)Z", "    .locals 1\n    const/4 v0, 0x0\n    return v0")

    c = smali_file(root, "Lcom/xiaomi/sharop/awdl/AwdlServiceClient;")
    text = open(c, encoding="utf-8").read()
    cls = "Lcom/xiaomi/sharop/awdl/AwdlServiceClient;"
    text = replace_once(text, ".method public final declared-synchronized a()Z\n",
                        ".method private final declared-synchronized xairdropRegister()Z\n", "rename a()")
    text = replace_once(text, ".method public declared-synchronized unregisterNetworkAgent()V\n",
                        ".method private declared-synchronized xairdropUnregister()V\n", "rename unregisterNetworkAgent()")
    text += f"""
.method public final a()Z
    .locals 2

    invoke-direct {{p0}}, {cls}->xairdropRegister()Z
    move-result v0
    if-nez v0, :done

    invoke-static {{}}, {PKG}/Bridge;->acquire()Landroid/net/Network;
    move-result-object v1
    if-eqz v1, :done

    invoke-virtual {{p0, v1}}, {cls}->setRegisteredNetwork(Landroid/net/Network;)V
    const/4 v0, 0x1

    :done
    return v0
.end method

.method public unregisterNetworkAgent()V
    .locals 1

    invoke-direct {{p0}}, {cls}->xairdropUnregister()V
    invoke-static {{}}, {PKG}/Bridge;->release()Z
    move-result v0
    if-eqz v0, :done

    const/4 v0, 0x0
    invoke-virtual {{p0, v0}}, {cls}->setRegisteredNetwork(Landroid/net/Network;)V

    :done
    return-void
.end method
"""
    open(c, "w", encoding="utf-8", newline="\n").write(text)

    # AirDropBleAdvertiser: Apple manufacturer data (0x4C) for AirDrop is type 0x05, length 0x12,
    # 8 zero bytes, version 0x01 at offset 10, then the four 2-byte contact hashes from offset 11.
    # MIShare 5.4.2 leaves out the version and writes the hashes at offset 4, so iPhones do not
    # take the advertisement as AirDrop and never wake their AWDL. (v0 = 1, v1 = 0 here.)
    u = smali_file(root, "La/u0;")
    text = open(u, encoding="utf-8").read()
    text = replace_once(text, "    const/16 v3, 0x12\n\n    aput-byte v3, v2, v0\n",
                        "    const/16 v3, 0x12\n\n    aput-byte v3, v2, v0\n\n    const/16 v3, 0xa\n\n    aput-byte v0, v2, v3\n",
                        "BLE version byte")
    text = replace_once(text, "    const/4 v5, 0x4\n\n    invoke-static {v3, v1, v2, v5, v4}, Ljava/lang/System;->arraycopy",
                        "    const/16 v5, 0xb\n\n    invoke-static {v3, v1, v2, v5, v4}, Ljava/lang/System;->arraycopy",
                        "BLE hash offset")
    open(u, "w", encoding="utf-8", newline="\n").write(text)

    k = smali_file(root, "La/k0;")
    wm = "La/k0;->a:Landroid/net/wifi/WifiManager;"
    set_body(k, ".method public final b()Z", f"""    .locals 1
    iget-object v0, p0, {wm}
    invoke-static {{v0}}, {PKG}/Bridge;->wifiConnected(Landroid/net/wifi/WifiManager;)Z
    move-result v0
    return v0""")
    set_body(k, ".method public final e()Z", f"""    .locals 1
    iget-object v0, p0, {wm}
    invoke-static {{p0, v0}}, {PKG}/Bridge;->leaveWifi(Ljava/lang/Object;Landroid/net/wifi/WifiManager;)Z
    move-result v0
    return v0""")
    text = open(k, encoding="utf-8").read()
    text = replace_once(text, ".method public final d()V\n", ".method private final xairdropReconnect()V\n", "rename k0.d()")
    text += f"""
.method public final d()V
    .locals 0

    invoke-direct {{p0}}, La/k0;->xairdropReconnect()V
    invoke-static {{}}, {PKG}/Bridge;->restoreWifi()V
    return-void
.end method
"""
    open(k, "w", encoding="utf-8", newline="\n").write(text)


def patch_resolver(root):
    p = smali_file(root, "Lcom/android/intentresolver/ChooserActivityStubImpl$$ExternalSyntheticLambda2;")
    text = open(p, encoding="utf-8").read()
    old = ("    invoke-virtual {p0}, Lcom/android/intentresolver/ApplicationStub;->isInternationalBuild()Z\n\n"
           "    move-result p0\n")
    new = old + (f"\n    invoke-static {{p0, v0}}, {PKG}/ChooserFix;->startApp(ZLjava/lang/Object;)Z\n\n"
                 "    move-result p0\n")
    if text.count(old) != 2:
        sys.exit(f"resolver callback: expected 2 isInternationalBuild calls, found {text.count(old)}")
    # v0 holds f$0 (ChooserActivityStubImpl) for the whole method.
    if "iget-object v0, p0, Lcom/android/intentresolver/ChooserActivityStubImpl$$ExternalSyntheticLambda2;->f$0" not in text:
        sys.exit("resolver callback: v0 is not f$0")
    open(p, "w", encoding="utf-8", newline="\n").write(text.replace(old, new))


def assemble(original_apk, rebuilt_apk, extra_dex, extra_name, out_apk):
    """Original APK with dex entries from rebuilt_apk plus extra_dex as extra_name."""
    rebuilt = zipfile.ZipFile(rebuilt_apk)
    new_dex = {n: rebuilt.read(n) for n in rebuilt.namelist() if re.fullmatch(r"classes\d*\.dex", n)}
    tmp = out_apk + ".unaligned"
    with zipfile.ZipFile(original_apk) as src, zipfile.ZipFile(tmp, "w") as dst:
        names = src.namelist()
        if extra_name in names:
            sys.exit(f"{original_apk} already has {extra_name}")
        for info in src.infolist():
            data = new_dex.pop(info.filename) if info.filename in new_dex else src.read(info.filename)
            dst.writestr(info, data, compress_type=info.compress_type)
        if new_dex:
            sys.exit(f"rebuilt APK has unexpected dex files: {sorted(new_dex)}")
        info = zipfile.ZipInfo(extra_name, date_time=(2009, 1, 1, 0, 0, 0))
        dst.writestr(info, open(extra_dex, "rb").read(), compress_type=zipfile.ZIP_DEFLATED)
    if os.path.exists(out_apk):
        os.remove(out_apk)
    run(os.path.join(BT, "zipalign.exe"), "-f", "-p", "4", tmp, out_apk)
    os.remove(tmp)


def main():
    out = os.path.abspath(sys.argv[1])
    os.makedirs(out, exist_ok=True)
    dexes = compile_helpers(out)

    ms = os.path.join(WORK, "mishare")
    decode(MISHARE_APK, ms)
    patch_mishare(ms)
    build_dex_from_smali(ms, os.path.join(WORK, "mishare-rebuilt.apk"))
    assemble(MISHARE_APK, os.path.join(WORK, "mishare-rebuilt.apk"), dexes["bridge"], "classes3.dex",
             os.path.join(out, "MIShare-xairdrop.apk"))

    ir = os.path.join(WORK, "intentresolver")
    decode(RESOLVER_APK, ir)
    patch_resolver(ir)
    build_dex_from_smali(ir, os.path.join(WORK, "intentresolver-rebuilt.apk"))
    assemble(RESOLVER_APK, os.path.join(WORK, "intentresolver-rebuilt.apk"), dexes["chooserfix"], "classes2.dex",
             os.path.join(out, "MiIntentResolver-xairdrop.apk"))


if __name__ == "__main__":
    main()

package io.github.leekin2.xairdrop;

import android.net.wifi.WifiInfo;
import android.os.IBinder;
import java.io.File;
import java.io.FileOutputStream;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;

/**
 * Part of the root NetworkBroker. On these phones the AirDrop channel (5 GHz ch149) and a Wi-Fi
 * connection on any band do not share the radio: while Wi-Fi is connected nothing is received
 * from the iPhone. Xiaomi Share leaves Wi-Fi itself where it may (a ROM signing it with the
 * platform key); otherwise it asks here. Leaving disables the saved network for the AirDrop
 * session, so Android does not rejoin it at once, and a file remembers it until it is restored.
 *
 * Talks to IWifiManager directly: WifiManager would send the system context's package
 * ("android"), which does not belong to uid 0; "root" does.
 */
final class WifiControl {
    private static final File STATE = new File("/data/adb/xairdrop/wifi-left");
    private static final String[] PACKAGES = {"root", "android", "com.android.shell"};

    /** Counts leaves, so a delayed restore can tell whether a new session left Wi-Fi since. */
    private static int generation;

    private WifiControl() { }

    static synchronized int generation() {
        return generation;
    }

    /** Restore unless a newer AirDrop session has left Wi-Fi since {@code seen}. */
    static synchronized String restoreIfStill(int seen) {
        return generation == seen ? restore() : "newer session active";
    }

    static synchronized String leave() {
        try {
            if (STATE.exists()) return "already left (netId " + read() + ")";
            WifiInfo info = (WifiInfo) call("getConnectionInfo");
            if (info == null || info.getFrequency() <= 0) return "not connected";
            int netId = info.getNetworkId();
            if (netId < 0) return "connected network has no id";
            write(netId);
            generation++;
            Object disabled = call("disableNetwork", netId);
            Object disconnected = call("disconnect");
            return "left netId " + netId + " (" + info.getFrequency() + " MHz): disable=" + disabled + " disconnect=" + disconnected;
        } catch (Throwable t) {
            return "ERROR " + t;
        }
    }

    static synchronized String restore() {
        if (!STATE.exists()) return "nothing to restore";
        try {
            int netId = read();
            Object enabled = call("enableNetwork", netId, Boolean.FALSE);
            Object reconnected = call("reconnect");
            STATE.delete();
            return "restored netId " + netId + ": enable=" + enabled + " reconnect=" + reconnected;
        } catch (Throwable t) {
            return "ERROR " + t;
        }
    }

    /** Calls IWifiManager.name(args..., package[, null...]) with the first package Wi-Fi accepts. */
    private static Object call(String name, Object... args) throws Exception {
        Class<?> sm = Class.forName("android.os.ServiceManager");
        IBinder binder = (IBinder) sm.getMethod("getService", String.class).invoke(null, "wifi");
        Object wifi = Class.forName("android.net.wifi.IWifiManager$Stub").getMethod("asInterface", IBinder.class).invoke(null, binder);
        Method method = null;
        for (Method m : wifi.getClass().getMethods()) {
            Class<?>[] p = m.getParameterTypes();
            if (m.getName().equals(name) && p.length > args.length && p[args.length] == String.class) {
                method = m;
                break;
            }
        }
        if (method == null) throw new NoSuchMethodException("IWifiManager." + name);
        Throwable last = null;
        for (String pkg : PACKAGES) {
            Object[] full = new Object[method.getParameterTypes().length];
            System.arraycopy(args, 0, full, 0, args.length);
            full[args.length] = pkg;
            try {
                return method.invoke(wifi, full);
            } catch (java.lang.reflect.InvocationTargetException e) {
                last = e.getCause();
                if (!(last instanceof SecurityException)) break;
            }
        }
        throw new IllegalStateException(name + " refused: " + last);
    }

    private static int read() throws Exception {
        return Integer.parseInt(new String(Files.readAllBytes(STATE.toPath()), StandardCharsets.UTF_8).trim());
    }

    private static void write(int netId) throws Exception {
        STATE.getParentFile().mkdirs();
        try (FileOutputStream out = new FileOutputStream(STATE)) {
            out.write(String.valueOf(netId).getBytes(StandardCharsets.UTF_8));
        }
    }
}

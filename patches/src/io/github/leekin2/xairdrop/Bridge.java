package io.github.leekin2.xairdrop;

import android.net.LocalSocket;
import android.net.LocalSocketAddress;
import android.net.Network;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.util.Log;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.net.NetworkInterface;

/**
 * Added to Xiaomi Share (MIShare 5.4.2). AwdlServiceClient registers the xos0 AirDrop interface
 * as a NetworkAgent, which needs NETWORK_FACTORY. When that registration fails, the patched
 * AwdlServiceClient.a() asks XAirDrop's root NetworkBroker for the network instead; the broker
 * keeps it registered while the socket stays open.
 */
public final class Bridge {
    private static final String TAG = "XAirDrop";
    private static Network network;
    private static LocalSocket socket;

    private Bridge() { }

    public static synchronized Network acquire() {
        if (network != null) return network;
        // MIShare also retries after it stopped the XOS session; nothing to register then.
        // (Not /sys/class/net: SELinux keeps Xiaomi Share's domain out of sysfs_net.)
        try {
            if (NetworkInterface.getByName("xos0") == null) return null;
        } catch (Exception e) {
            Log.w(TAG, "xos0 lookup failed", e);
        }
        LocalSocket s = new LocalSocket();
        try {
            s.connect(new LocalSocketAddress(NetworkBroker.SOCKET));
            if (s.getPeerCredentials().getUid() != 0) throw new SecurityException("broker is not root");
            s.setSoTimeout(10000);
            DataOutputStream out = new DataOutputStream(s.getOutputStream());
            out.writeUTF(NetworkBroker.ACQUIRE);
            out.flush();
            DataInputStream in = new DataInputStream(s.getInputStream());
            String answer = in.readUTF();
            if (!NetworkBroker.OK.equals(answer)) throw new IllegalStateException(answer);
            Network n = Network.fromNetworkHandle(in.readLong());
            s.setSoTimeout(0);
            socket = s;
            network = n;
            Log.i(TAG, "xos0 registered by the XAirDrop broker: " + n);
            return n;
        } catch (Throwable t) {
            Log.e(TAG, "xos0 registration through the broker failed; AirDrop stays off", t);
            try { s.close(); } catch (Exception ignored) { }
            return null;
        }
    }

    // --- Wi-Fi during AirDrop (patched a.k0 = WifiConflictManager) --------------------------
    // Xiaomi Share only treats a 5 GHz Wi-Fi connection as a conflict with the AirDrop channel
    // (ch149). Here a connection on any band is one: while Wi-Fi is connected, nothing is
    // received from the iPhone.

    /** Patched a.k0.b(): Wi-Fi is connected on any band. */
    public static boolean wifiConnected(WifiManager wifi) {
        try {
            WifiInfo info = wifi.getConnectionInfo();
            return info != null && info.getFrequency() > 0;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Patched a.k0.e(): leave Wi-Fi for the AirDrop session. The root broker does it when it runs:
     * it keeps a record, so the network also comes back if Xiaomi Share dies or the phone
     * restarts. Otherwise (a ROM signing Xiaomi Share with its platform key) Xiaomi Share itself
     * disables and disconnects the network. The WifiConflictManager fields (b = networkId,
     * c = frequency, d = BSSID, e = left) are filled so its own d() reconnects afterwards.
     */
    public static boolean leaveWifi(Object manager, WifiManager wifi) {
        WifiInfo info;
        try {
            info = wifi.getConnectionInfo();
        } catch (Exception e) {
            return false;
        }
        if (info == null || info.getFrequency() <= 0) return false;
        int netId = info.getNetworkId();
        try {
            Class<?> c = manager.getClass();
            c.getDeclaredField("b").setInt(manager, netId);
            c.getDeclaredField("c").setInt(manager, info.getFrequency());
            c.getDeclaredField("d").set(manager, info.getBSSID());
            c.getDeclaredField("e").setBoolean(manager, true);
        } catch (Exception e) {
            Log.w(TAG, "WifiConflictManager fields unavailable", e);
        }
        String broker = command(NetworkBroker.WIFI_LEAVE);
        if (broker != null && broker.startsWith("left")) {
            Log.i(TAG, "Wi-Fi " + info.getFrequency() + " MHz left for AirDrop by the broker: " + broker);
            return true;
        }
        boolean own = false;
        try {
            own = netId >= 0 && wifi.disableNetwork(netId);
            own = wifi.disconnect() && own;
        } catch (Exception ignored) { }
        Log.i(TAG, "Wi-Fi " + info.getFrequency() + " MHz left for AirDrop by Xiaomi Share: " + own
                + (broker != null ? " (broker: " + broker + ")" : ""));
        return true;
    }

    /** After the patched a.k0.d() reconnected what it could: let the broker undo its leave. */
    public static void restoreWifi() {
        String result = command(NetworkBroker.WIFI_RESTORE);
        if (result != null) Log.i(TAG, "Wi-Fi restore through the broker: " + result);
    }

    private static String command(String command) {
        try (LocalSocket s = new LocalSocket()) {
            s.connect(new LocalSocketAddress(NetworkBroker.SOCKET));
            if (s.getPeerCredentials().getUid() != 0) return null;
            s.setSoTimeout(5000);
            DataOutputStream out = new DataOutputStream(s.getOutputStream());
            out.writeUTF(command);
            out.flush();
            return new DataInputStream(s.getInputStream()).readUTF();
        } catch (Exception e) {
            return null;
        }
    }

    /** Returns true when a broker network was held (and is now released). */
    public static synchronized boolean release() {
        if (socket == null) return false;
        try { socket.close(); } catch (Exception ignored) { }
        socket = null;
        network = null;
        Log.i(TAG, "xos0 released to the broker");
        return true;
    }
}

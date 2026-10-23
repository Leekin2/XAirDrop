package io.github.leekin2.xairdrop;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.LinkProperties;
import android.net.LocalServerSocket;
import android.net.LocalSocket;
import android.net.Network;
import android.os.Handler;
import android.os.Looper;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.lang.reflect.Method;
import java.util.concurrent.FutureTask;
import java.util.concurrent.TimeUnit;

/**
 * Root helper, started by the XAirDrop root module with app_process and MIShare's APK on the
 * class path: registers the xos0 AirDrop interface with MIShare's own NetworkAgent class (a.p0)
 * for a MIShare process that is not allowed to (NETWORK_FACTORY), and keeps it registered while
 * that process holds its socket open.
 *
 * app_process ... io.github.leekin2.xairdrop.NetworkBroker <MIShare appId> | ping
 */
public final class NetworkBroker {
    static final String SOCKET = "xairdrop.xos0";
    static final String ACQUIRE = "ACQUIRE_XOS0";
    static final String PING = "PING";
    static final String OK = "OK";
    static final String WIFI_LEAVE = "WIFI_LEAVE";
    static final String WIFI_RESTORE = "WIFI_RESTORE";

    private static int appId;
    private static Context context;
    private static Handler main;
    private static Class<?> agentClass;
    private static Object agent;
    private static int holders;

    public static void main(String[] args) throws Exception {
        if (android.os.Process.myUid() != 0) throw new SecurityException("root required");
        if (args.length > 0 && "restore".equals(args[0])) {
            // Boot recovery and uninstall: bring back a network an unfinished session left.
            System.out.println("Wi-Fi restore: " + WifiControl.restore());
            System.exit(0);
        }
        if (args.length > 0 && "ping".equals(args[0])) {
            boolean ready = ping();
            System.out.println(ready ? "READY" : "NOT READY");
            System.exit(ready ? 0 : 1);
        }
        appId = Integer.parseInt(args[0]);
        if (appId < 10000 || appId >= 100000) throw new IllegalArgumentException("bad appId " + appId);
        Looper.prepareMainLooper();
        Class<?> thread = Class.forName("android.app.ActivityThread");
        Object system = thread.getMethod("systemMain").invoke(null);
        context = (Context) thread.getMethod("getSystemContext").invoke(system);
        agentClass = Class.forName("a.p0");
        main = new Handler(Looper.getMainLooper());
        LocalServerSocket server = new LocalServerSocket(SOCKET);
        Thread accept = new Thread(() -> {
            while (true) {
                try {
                    LocalSocket client = server.accept();
                    new Thread(() -> serve(client), "XAirDropClient").start();
                } catch (Exception e) {
                    e.printStackTrace();
                    System.exit(1);
                }
            }
        }, "XAirDropAccept");
        accept.setDaemon(true);
        accept.start();
        // A network left for an AirDrop session that never ended (reboot, crash) comes back now.
        System.out.println("startup Wi-Fi restore: " + WifiControl.restore());
        System.out.println("READY appId=" + appId);
        Looper.loop();
    }

    private static boolean ping() {
        try (LocalSocket socket = new LocalSocket()) {
            socket.connect(new android.net.LocalSocketAddress(SOCKET));
            if (socket.getPeerCredentials().getUid() != 0) return false;
            socket.setSoTimeout(1500);
            new DataOutputStream(socket.getOutputStream()).writeUTF(PING);
            return OK.equals(new DataInputStream(socket.getInputStream()).readUTF());
        } catch (Exception e) {
            return false;
        }
    }

    private static void serve(LocalSocket socket) {
        boolean holding = false;
        int leaveSeen = 0;
        try {
            int uid = socket.getPeerCredentials().getUid();
            socket.setSoTimeout(8000);
            DataInputStream in = new DataInputStream(socket.getInputStream());
            DataOutputStream out = new DataOutputStream(socket.getOutputStream());
            String command = in.readUTF();
            if (PING.equals(command) && uid == 0) {
                out.writeUTF(OK);
                out.flush();
                return;
            }
            if (uid % 100000 != appId) throw new SecurityException("uid " + uid + " is not Xiaomi Share");
            if (WIFI_LEAVE.equals(command) || WIFI_RESTORE.equals(command)) {
                String result = WIFI_LEAVE.equals(command) ? WifiControl.leave() : WifiControl.restore();
                System.out.println(command + ": " + result);
                out.writeUTF(result);
                out.flush();
                return;
            }
            if (!ACQUIRE.equals(command)) throw new IllegalArgumentException("unknown command " + command);
            Network network = onMain(NetworkBroker::acquire);
            holding = true;
            // This session left Wi-Fi before asking for xos0; a later session would leave again.
            leaveSeen = WifiControl.generation();
            waitForXos0(network);
            out.writeUTF(OK);
            out.writeLong(network.getNetworkHandle());
            out.flush();
            System.out.println("xos0 " + network + " -> uid " + uid + ", holders " + holders);
            // Held until Xiaomi Share closes the socket (or dies).
            socket.setSoTimeout(0);
            while (in.read() != -1) { }
        } catch (Exception e) {
            e.printStackTrace();
            try {
                DataOutputStream out = new DataOutputStream(socket.getOutputStream());
                out.writeUTF("ERROR " + e);
                out.flush();
            } catch (Exception ignored) { }
        } finally {
            if (holding) {
                try { onMain(NetworkBroker::release); } catch (Exception e) { e.printStackTrace(); }
                // Xiaomi Share reconnects Wi-Fi itself when AirDrop ends; if it died instead,
                // nobody does. Restore shortly after the last holder went away, unless a new
                // session has left Wi-Fi in the meantime.
                int seen = leaveSeen;
                main.postDelayed(() -> {
                    if (holders == 0) System.out.println("Wi-Fi restore after release: " + WifiControl.restoreIfStill(seen));
                }, 3000);
            }
            try { socket.close(); } catch (Exception ignored) { }
        }
    }

    private static Network acquire() throws Exception {
        if (!new File("/sys/class/net/xos0").exists()) throw new IllegalStateException("xos0 does not exist; is the XOS session running?");
        if (agent == null) {
            Object created = agentClass.getMethod("a", Context.class, Looper.class).invoke(null, context, Looper.getMainLooper());
            if (created == null) throw new IllegalStateException("NetworkAgent could not be created");
            if (!(Boolean) agentClass.getMethod("g").invoke(created)) {
                agentClass.getMethod("i").invoke(created);
                throw new IllegalStateException("NetworkAgent registration rejected");
            }
            agent = created;
        }
        Network network = (Network) agentClass.getMethod("getNetwork").invoke(agent);
        if (network == null) throw new IllegalStateException("NetworkAgent has no network");
        holders++;
        return network;
    }

    private static Boolean release() throws Exception {
        holders = Math.max(0, holders - 1);
        if (holders == 0 && agent != null) {
            Object old = agent;
            agent = null;
            agentClass.getMethod("i").invoke(old);
            System.out.println("xos0 released");
        }
        return Boolean.TRUE;
    }

    private static void waitForXos0(Network network) throws Exception {
        ConnectivityManager cm = context.getSystemService(ConnectivityManager.class);
        for (int i = 0; i < 40; i++) {
            LinkProperties lp = cm.getLinkProperties(network);
            if (lp != null && "xos0".equals(lp.getInterfaceName())) return;
            Thread.sleep(50);
        }
        throw new IllegalStateException("xos0 is not attached to " + network);
    }

    private static <T> T onMain(java.util.concurrent.Callable<T> call) throws Exception {
        FutureTask<T> task = new FutureTask<>(call);
        if (!main.post(task)) throw new IllegalStateException("main looper stopped");
        return task.get(6, TimeUnit.SECONDS);
    }
}

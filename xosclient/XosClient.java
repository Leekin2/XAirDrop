import android.os.Binder;
import android.os.IBinder;
import android.os.Parcel;

/**
 * Drives Xiaomi's DomesticXOsComm service the way MIShare's AwdlServiceClient does:
 * start(token, channel), poll getStatus, then stop. Run with app_process as root.
 * Usage: XosClient [channel] [seconds]
 */
public class XosClient {
    static final String NAME = "com.domestic.xoscomm.IDomesticXOsComm/default";
    static final String DESCRIPTOR = "com.domestic.xoscomm.IDomesticXOsComm";
    static final int START = 1, STOP = 2, STATUS = 3;

    static IBinder service() throws Exception {
        Class<?> sm = Class.forName("android.os.ServiceManager");
        try {
            return (IBinder) sm.getMethod("waitForDeclaredService", String.class).invoke(null, NAME);
        } catch (Throwable t) {
            return (IBinder) sm.getMethod("getService", String.class).invoke(null, NAME);
        }
    }

    static String status(IBinder b) throws Exception {
        Parcel data = Parcel.obtain(), reply = Parcel.obtain();
        try {
            data.writeInterfaceToken(DESCRIPTOR);
            b.transact(STATUS, data, reply, 0);
            reply.readException();
            return reply.readString();
        } finally { data.recycle(); reply.recycle(); }
    }

    static void call(IBinder b, int code, IBinder token, int channel) throws Exception {
        Parcel data = Parcel.obtain(), reply = Parcel.obtain();
        try {
            data.writeInterfaceToken(DESCRIPTOR);
            if (code == START) { data.writeStrongBinder(token); data.writeInt(channel); }
            b.transact(code, data, reply, 0);
            reply.readException();
        } finally { data.recycle(); reply.recycle(); }
    }

    /** Keeps one reference to the lazy service so it stays registered for MIShare. */
    static void hold() throws Exception {
        IBinder b = service();
        if (b == null) { System.out.println("service not found"); System.exit(2); }
        System.out.println("holding service, status: " + status(b));
        while (b.isBinderAlive()) Thread.sleep(5000);
        System.out.println("service died");
    }

    public static void main(String[] args) throws Exception {
        if (args.length > 0 && args[0].equals("hold")) { hold(); return; }
        int channel = args.length > 0 ? Integer.parseInt(args[0]) : 149;
        int seconds = args.length > 1 ? Integer.parseInt(args[1]) : 20;
        IBinder b = service();
        if (b == null) { System.out.println("service not found"); System.exit(2); }
        System.out.println("status before: " + status(b));
        Binder token = new Binder();
        try {
            call(b, START, token, channel);
            System.out.println("start(" + channel + "): ok");
        } catch (Exception e) {
            System.out.println("start(" + channel + ") failed: " + e);
        }
        for (int i = 0; i < seconds; i += 2) {
            Thread.sleep(2000);
            try { System.out.println("t+" + (i + 2) + "s status: " + status(b)); }
            catch (Exception e) { System.out.println("status failed: " + e); break; }
        }
        try { call(b, STOP, null, 0); System.out.println("stop: ok"); }
        catch (Exception e) { System.out.println("stop failed: " + e); }
        System.out.println("status after: " + status(b));
    }
}

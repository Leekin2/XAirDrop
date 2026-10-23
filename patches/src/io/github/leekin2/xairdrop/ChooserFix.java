package io.github.leekin2.xairdrop;

import android.content.pm.ActivityInfo;
import android.content.pm.ResolveInfo;
import android.util.Log;
import java.lang.reflect.Field;

/**
 * Added to the share sheet (MiIntentResolver). Sharing from Gallery goes through Gallery first;
 * when it returns, the share sheet sends any Xiaomi Share target to its own Xiaomi Share device
 * strip unless the ROM is international. The Xiaomi 18 Pro Max share sheet also starts the app
 * for the Apple target (shouldStartAppWhenMishare); the patched callback asks here instead of
 * isInternationalBuild() alone.
 */
public final class ChooserFix {
    private static final String MISHARE = "com.miui.mishare.connectivity";
    private static final String TRAMPOLINE = "com.xiaomi.sharop.AirDropShareTrampolineActivity";

    private ChooserFix() { }

    public static boolean startApp(boolean international, Object stubImpl) {
        if (international) return true;
        try {
            Field field = stubImpl.getClass().getDeclaredField("mTargetInfo");
            field.setAccessible(true);
            Object target = field.get(stubImpl);
            if (target == null) return false;
            ResolveInfo info = (ResolveInfo) target.getClass().getMethod("getResolveInfo").invoke(target);
            ActivityInfo activity = info != null ? info.activityInfo : null;
            return activity != null && MISHARE.equals(activity.packageName) && TRAMPOLINE.equals(activity.name);
        } catch (Throwable t) {
            Log.e("XAirDrop", "share target unreadable", t);
            return false;
        }
    }
}

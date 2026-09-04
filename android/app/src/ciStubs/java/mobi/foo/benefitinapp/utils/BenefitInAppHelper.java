package mobi.foo.benefitinapp.utils;

import android.content.Intent;

public final class BenefitInAppHelper {
    private BenefitInAppHelper() {}

    public static void handleResult(Intent intent) {
        // CI-only shim: production builds compile against the vendor SDK.
    }
}

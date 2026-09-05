package mobi.foo.benefitinapp.utils;

import android.app.Activity;
import mobi.foo.benefitinapp.listener.CheckoutListener;

public final class BenefitInAppCheckout {
    private BenefitInAppCheckout() {}

    public static void newInstance(
        Activity activity,
        String appId,
        String referenceId,
        String merchantId,
        String secret,
        String amount,
        String countryCode,
        String currencyCode,
        String merchantCategoryCode,
        String merchantName,
        String merchantCity,
        CheckoutListener listener
    ) {
        // CI-only shim: production builds compile against the vendor SDK.
    }
}

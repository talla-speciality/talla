package mobi.foo.benefitinapp.utils;

import android.content.Context;
import android.view.View;
import mobi.foo.benefitinapp.listener.BenefitInAppButtonListener;

public final class BenefitInAppButton extends View {
    public BenefitInAppButton(Context context) {
        super(context);
    }

    public void setListener(BenefitInAppButtonListener listener) {
        // CI-only shim: production builds compile against the vendor SDK.
    }
}

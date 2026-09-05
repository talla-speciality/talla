package mobi.foo.benefitinapp.listener;

import mobi.foo.benefitinapp.data.Transaction;

public interface CheckoutListener {
    void onTransactionSuccess(Transaction transaction);
    void onTransactionFail(Transaction transaction);
}

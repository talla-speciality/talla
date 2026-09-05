package mobi.foo.benefitinapp.data;

public final class Transaction {
    private final String transactionMessage;

    public Transaction() {
        this(null);
    }

    public Transaction(String transactionMessage) {
        this.transactionMessage = transactionMessage;
    }

    public String getTransactionMessage() {
        return transactionMessage;
    }
}

function refundAmountForOrder(order, amount, { numericOrderTotal, bhdFils }) {
    const amountFils = bhdFils(amount);
    const totalFils = bhdFils(numericOrderTotal(order));
    if (amountFils === null || amountFils <= 0 || totalFils === null || totalFils <= 0
        || amountFils > totalFils) {
        throw new Error("REFUND_AMOUNT_OUT_OF_RANGE");
    }
    return { amountFils, totalFils, fullRefund: amountFils === totalFils };
}

function refundSettled(refund, expectedFils, bhdFils) {
    const transactions = refund?.transactions?.nodes;
    if (!Array.isArray(transactions) || transactions.length === 0) return false;
    let totalFils = 0;
    for (const transaction of transactions) {
        if (String(transaction.kind).toUpperCase() !== "REFUND"
            || String(transaction.status).toUpperCase() !== "SUCCESS"
            || transaction.amountSet?.shopMoney?.currencyCode !== "BHD") return false;
        const amountFils = bhdFils(transaction.amountSet.shopMoney.amount);
        if (amountFils === null) return false;
        totalFils += amountFils;
    }
    return totalFils === expectedFils;
}

module.exports = { refundAmountForOrder, refundSettled };

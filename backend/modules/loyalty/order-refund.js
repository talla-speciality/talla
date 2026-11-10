function applyOrderBeanReversal(account, { awardID, reversalID, points, createdAt }) {
    const transactions = Array.isArray(account.transactions) ? account.transactions : [];
    if (transactions.some((transaction) => transaction.id === reversalID)) {
        return { reversed: true, reason: "ALREADY_REVERSED" };
    }
    if (!transactions.some((transaction) => transaction.id === awardID)) {
        return { reversed: false, reason: "AWARD_NOT_FOUND" };
    }
    if (Number(account.pointsBalance || 0) < points) {
        return { reversed: false, reason: "INSUFFICIENT_BALANCE" };
    }
    account.pointsBalance -= points;
    account.transactions = transactions;
    account.transactions.unshift({
        id: reversalID,
        type: "reversal",
        points: -points,
        note: `Refunded order • reversed ${points} Beans`,
        createdAt
    });
    return { reversed: true, reason: "REVERSED" };
}

module.exports = { applyOrderBeanReversal };

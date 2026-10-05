const {
    isCoffeeBag,
    isArabicCoffee,
    isCoffeeFilterPack,
    isEquipmentConsumable,
    isSeasonalDiscoveryBox
} = require("./checkout-pricing");

function isDripBag(node) {
    const handles = (node?.product?.collections?.nodes || [])
        .map((collection) => String(collection?.handle || "").trim().toLowerCase());
    const source = [node?.product?.title, node?.product?.productType, ...(node?.product?.tags || [])]
        .map((value) => String(value || "").trim().toLowerCase()).join(" ");
    return handles.includes("drip-bags") || /drip[- ]bags?/.test(source);
}

function coffeeClubProductEligible(planType, node) {
    switch (String(planType || "").trim().toLowerCase()) {
    case "office":
        return isCoffeeBag(node) && !isDripBag(node);
    case "arabic-coffee":
        return isCoffeeBag(node) && isArabicCoffee(node) && !isDripBag(node);
    case "beans":
        return isCoffeeBag(node) && !isArabicCoffee(node) && !isDripBag(node)
            && !isCoffeeFilterPack(node) && !isEquipmentConsumable(node) && !isSeasonalDiscoveryBox(node);
    case "drip-bags":
        return isDripBag(node);
    case "filters":
        return isCoffeeFilterPack(node);
    case "equipment":
        return isEquipmentConsumable(node);
    case "seasonal-box":
        return isSeasonalDiscoveryBox(node);
    default:
        return false;
    }
}

module.exports = { coffeeClubProductEligible };

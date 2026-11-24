import SwiftUI

struct AdminPromoCodeView: View {
    var body: some View {
        AdminActionForm(
            title: "Create Promo Code",
            endpoint: "/admin/api/promo-codes/create",
            groups: [
                .init("Discount", [
                    .init("code", "Code", required: true),
                    .init("discountType", "Discount type", .choice(["percentage", "fixed"]), required: true),
                    .init("discountValue", "Discount value", .number, required: true),
                    .init("detail", "Customer-facing detail", .multiline),
                    .init("expiresInDays", "Expires in days", .integer, required: true)
                ])
            ],
            confirmation: "Create this public promo code. Percentage values must be 100 or less; fixed values are in BHD.",
            document: .object([
                "discountType": .string("percentage"),
                "discountValue": .number(10),
                "expiresInDays": .number(30)
            ])
        )
    }
}

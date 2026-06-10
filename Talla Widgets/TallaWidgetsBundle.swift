#if canImport(WidgetKit)
import SwiftUI
import WidgetKit

@main
struct TallaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TallaQuickActionsWidget()

        if #available(iOS 18.0, *) {
            TallaConciergeControl()
            TallaShopControl()
        }
    }
}
#endif

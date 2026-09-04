import Foundation
import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(FoundationModels)
import FoundationModels
#endif
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(WatchConnectivity) && os(iOS)
import WatchConnectivity
#endif
#if canImport(UIKit)
import UIKit
#endif

extension BrewingSectionView {
    var brewGuideProfiles: [BrewGuideProfile] {
        [
            BrewGuideProfile(
                id: "balanced-filter",
                title: AppLocalization.text("balanced_filter", fallback: "Balanced Filter"),
                subtitle: AppLocalization.text("balanced_filter_detail", fallback: "A clean daily cup with sweetness first and acidity kept tidy."),
                icon: "drop.fill",
                methodKeywords: ["pour", "filter", "v60", "chemex"],
                coffeeGrams: 20,
                ratio: 16,
                grind: AppLocalization.text("medium_fine", fallback: "Medium-fine"),
                temperature: "92–94 °C",
                time: "3:30",
                targetSeconds: 210,
                goal: AppLocalization.text("sweet_clean_goal", fallback: "Sweet, clean, balanced"),
                steps: [
                    AppLocalization.text("balanced_filter_step_1", fallback: "Rinse the filter, warm the brewer, and level 20 g of coffee."),
                    AppLocalization.text("balanced_filter_step_2", fallback: "Bloom with 60 g water for 35-45 seconds."),
                    AppLocalization.text("balanced_filter_step_3", fallback: "Pour steadily to 220 g, then finish at 320 g."),
                    AppLocalization.text("balanced_filter_step_4", fallback: "Target a drawdown around 3:15-3:45 and adjust grind from there.")
                ],
                learningNotes: [
                    AppLocalization.text("filter_note_bloom", fallback: "Blooming releases gas so the main pour extracts more evenly."),
                    AppLocalization.text("filter_note_grind", fallback: "If it tastes sharp, grind a touch finer or pour slower; if heavy, grind coarser.")
                ]
            ),
            BrewGuideProfile(
                id: "v60-iced",
                title: "V60 Iced",
                subtitle: "Talla's flash-chilled V60 recipe with the ice included in the final 1:15 ratio.",
                icon: "snowflake",
                methodKeywords: ["v60 iced"],
                coffeeGrams: 20,
                ratio: 15,
                grind: "Medium",
                temperature: "93 °C",
                time: "2:15",
                targetSeconds: 135,
                goal: "Crisp, sweet, aromatic",
                steps: [
                    "Put 120 g ice in the server and add 20 g medium-ground coffee to the rinsed V60.",
                    "Bloom with 50 g hot water, then pour 70 g at 0:45.",
                    "Pour the final 60 g at 1:30 to reach 180 g hot water.",
                    "Finish near 2:15, swirl to melt the brewing ice evenly, and serve over fresh ice."
                ],
                learningNotes: [
                    "The 1:15 ratio includes both 180 g brewing water and 120 g ice.",
                    "Flash chilling preserves aroma while the stronger hot-water portion prevents a watery cup."
                ]
            ),
            BrewGuideProfile(
                id: "classic-cold-brew",
                title: "Classic Cold Brew",
                subtitle: "Talla's smooth concentrate recipe, brewed at 1:8 and served diluted over ice.",
                icon: "snowflake.circle.fill",
                methodKeywords: ["classic cold brew"],
                coffeeGrams: 60,
                ratio: 8,
                grind: "Coarse",
                temperature: "Room temperature",
                time: "12–16 hr",
                targetSeconds: 50_400,
                goal: "Velvety, sweet, low acidity",
                steps: [
                    "Combine 60 g coarse-ground coffee with 480 g filtered water.",
                    "Stir gently until every ground is wet, then cover.",
                    "Steep at room temperature for 12–16 hours and filter into a clean vessel.",
                    "Serve 1 part concentrate with 2 parts water or milk over plenty of ice."
                ],
                learningNotes: [
                    "This is a concentrate recipe at 1:8, not a ready-to-drink 1:16 brew.",
                    "For one serving, use 100 g concentrate, 200 g water or milk, and about 100 g fresh ice."
                ]
            ),
            BrewGuideProfile(
                id: "espresso-base",
                title: AppLocalization.text("espresso_base", fallback: "Espresso Base"),
                subtitle: AppLocalization.text("espresso_base_detail", fallback: "A practical starting point for milk drinks or a short, syrupy shot."),
                icon: "cup.and.saucer.fill",
                methodKeywords: ["espresso"],
                coffeeGrams: 18,
                ratio: 2,
                grind: AppLocalization.text("fine", fallback: "Fine"),
                temperature: "92–94 °C",
                time: "0:30",
                targetSeconds: 30,
                goal: AppLocalization.text("syrupy_sweet_goal", fallback: "Syrupy, sweet, focused"),
                steps: [
                    AppLocalization.text("espresso_step_1", fallback: "Dose 18 g, distribute evenly, and tamp level."),
                    AppLocalization.text("espresso_step_2", fallback: "Aim for 36 g out in 25-32 seconds."),
                    AppLocalization.text("espresso_step_3", fallback: "If sour, grind finer; if bitter and dry, grind coarser or shorten the yield."),
                    AppLocalization.text("espresso_step_4", fallback: "Taste before milk so you know what the shot is doing.")
                ],
                learningNotes: [
                    AppLocalization.text("espresso_note_ratio", fallback: "A 1:2 ratio gives you a reliable baseline before changing dose or yield."),
                    AppLocalization.text("espresso_note_time", fallback: "Time is a guide; taste decides the final adjustment.")
                ]
            ),
            BrewGuideProfile(
                id: "french-press-sweet",
                title: AppLocalization.text("sweet_press", fallback: "Sweet Press"),
                subtitle: AppLocalization.text("sweet_press_detail", fallback: "A round, easy French press recipe with less grit and more sweetness."),
                icon: "cylinder.split.1x2.fill",
                methodKeywords: ["french", "press", "immersion"],
                coffeeGrams: 24,
                ratio: 15,
                grind: AppLocalization.text("coarse", fallback: "Coarse"),
                temperature: "94 °C",
                time: "4:00",
                targetSeconds: 240,
                goal: AppLocalization.text("round_full_goal", fallback: "Round, full, sweet"),
                steps: [
                    AppLocalization.text("press_step_1", fallback: "Add 24 g coarse coffee and pour 360 g water."),
                    AppLocalization.text("press_step_2", fallback: "Stir gently after the pour and steep for 4 minutes."),
                    AppLocalization.text("press_step_3", fallback: "Break the crust, skim the foam, and press slowly."),
                    AppLocalization.text("press_step_4", fallback: "Pour everything out so the coffee stops extracting.")
                ],
                learningNotes: [
                    AppLocalization.text("press_note_body", fallback: "Immersion brewing builds body because the coffee sits with the water."),
                    AppLocalization.text("press_note_clean", fallback: "Skimming before pressing keeps the cup cleaner.")
                ]
            ),
            BrewGuideProfile(
                id: "arabic-majlis",
                title: AppLocalization.text("arabic_majlis", fallback: "Arabic Majlis"),
                subtitle: AppLocalization.text("arabic_majlis_detail", fallback: "A calm Arabic coffee guide for service, aroma, and a clean pour."),
                icon: "flame.fill",
                methodKeywords: ["arabic", "dallah", "traditional"],
                coffeeGrams: 18,
                ratio: 18,
                grind: AppLocalization.text("medium_coarse", fallback: "Medium-coarse"),
                temperature: AppLocalization.text("gentle_simmer", fallback: "Gentle simmer"),
                time: "8:00",
                targetSeconds: 480,
                goal: AppLocalization.text("aromatic_light_goal", fallback: "Aromatic, light, clean"),
                steps: [
                    AppLocalization.text("arabic_step_1", fallback: "Heat the water gently, then add coffee without boiling hard."),
                    AppLocalization.text("arabic_step_2", fallback: "Simmer low so the aroma opens without harshness."),
                    AppLocalization.text("arabic_step_3", fallback: "Add spices near the end if you use them."),
                    AppLocalization.text("arabic_step_4", fallback: "Rest briefly, then pour slowly into the dallah or cups.")
                ],
                learningNotes: [
                    AppLocalization.text("arabic_note_heat", fallback: "Gentle heat protects the lighter aromatic side of Arabic coffee."),
                    AppLocalization.text("arabic_note_rest", fallback: "Resting helps sediment settle for a cleaner service.")
                ]
            )
        ]
    }
}

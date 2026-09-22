import Foundation
import Testing
@testable import Talla_Speciality

struct EspressoWorkspaceTests {
    @Test func espressoRatioUsesDoseAndYield() {
        var shot = EspressoShot()
        shot.dose = 18
        shot.yield = 40
        #expect(abs(shot.ratio - (40.0 / 18.0)) < 0.001)
    }

    @Test func positiveEspressoRequiresFourOrFiveStars() {
        var shot = EspressoShot()
        shot.rating = 3
        #expect(!shot.isPositive)
        shot.rating = 4
        #expect(shot.isPositive)
    }

    @Test func espressoDefaultsMatchBaseRecipe() {
        let shot = EspressoShot()
        #expect(shot.dose == 18)
        #expect(shot.yield == 36)
        #expect(shot.temperature == 93)
        #expect(shot.firstDripSeconds == 8)
    }
}

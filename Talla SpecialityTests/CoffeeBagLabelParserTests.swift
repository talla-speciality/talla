import Testing
@testable import Talla_Speciality

struct CoffeeBagLabelParserTests {
    @Test func extractsInlineAndFollowingLineDetails() {
        let result = CoffeeBagLabelParser.parse(lines: [
            "TALLA SPECIALITY ROASTERY",
            "Coffee: Hambela Wamena",
            "Origin",
            "Ethiopia",
            "Region: Guji",
            "Altitude 1,900 masl",
            "Variety: Heirloom",
            "Process: Natural",
            "Tasting Notes: Jasmine, peach, honey"
        ])

        #expect(result.name == "Hambela Wamena")
        #expect(result.roaster == "TALLA SPECIALITY ROASTERY")
        #expect(result.origin == "Ethiopia")
        #expect(result.region == "Guji")
        #expect(result.altitude == "1,900 masl")
        #expect(result.variety == "Heirloom")
        #expect(result.process == "Natural")
        #expect(result.tastingNotes == "Jasmine, peach, honey")
    }

    @Test func infersUsefulUnlabelledDetailsWithoutInventingValues() {
        let result = CoffeeBagLabelParser.parse(lines: [
            "NOMAD COFFEE ROASTERS",
            "Los Pirineos",
            "El Salvador",
            "Anaerobic Natural",
            "1650 masl"
        ])

        #expect(result.roaster == "NOMAD COFFEE ROASTERS")
        #expect(result.name == "Los Pirineos")
        #expect(result.origin == "El Salvador")
        #expect(result.process == "Anaerobic Natural")
        #expect(result.altitude == "1650 masl")
        #expect(result.region == nil)
        #expect(result.variety == nil)
        #expect(result.tastingNotes == nil)
    }

    @Test func extractsArabicCoffeeBagDetails() {
        let result = CoffeeBagLabelParser.parse(lines: [
            "محمصة تله المختصة",
            "اسم القهوة: شاكيسو",
            "بلد المنشأ: إثيوبيا",
            "المنطقة: قوجي",
            "الارتفاع: ١٩٠٠ متر",
            "السلالة: هيرلوم",
            "المعالجة: مجففة",
            "إيحاءات النكهة: ياسمين، خوخ، عسل"
        ])

        #expect(result.name == "شاكيسو")
        #expect(result.roaster == "محمصة تله المختصة")
        #expect(result.origin == "إثيوبيا")
        #expect(result.region == "قوجي")
        #expect(result.altitude == "١٩٠٠ متر")
        #expect(result.variety == "هيرلوم")
        #expect(result.process == "مجففة")
        #expect(result.tastingNotes == "ياسمين، خوخ، عسل")
    }
}

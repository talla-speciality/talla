import Foundation
import UIKit
@preconcurrency import Vision

struct CoffeeBagScanResult: Equatable {
    var name: String?
    var roaster: String?
    var origin: String?
    var region: String?
    var altitude: String?
    var variety: String?
    var process: String?
    var tastingNotes: String?

    var populatedFieldCount: Int {
        [name, roaster, origin, region, altitude, variety, process, tastingNotes]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .count
    }
}

enum CoffeeBagImageAnalyzer {
    enum AnalysisError: Error {
        case invalidImage
        case noTextFound
    }

    static func analyze(_ image: UIImage) async throws -> CoffeeBagScanResult {
        guard let cgImage = image.cgImage else { throw AnalysisError.invalidImage }
        let orientation = image.imagePropertyOrientation

        let lines: [String] = try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let recognized = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: recognized)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "ar-SA"]

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try VNImageRequestHandler(
                        cgImage: cgImage,
                        orientation: orientation,
                        options: [:]
                    ).perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        guard lines.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw AnalysisError.noTextFound
        }
        return CoffeeBagLabelParser.parse(lines: lines)
    }
}

enum CoffeeBagLabelParser {
    private static let labelGroups: [(key: String, labels: [String])] = [
        ("name", ["coffee name", "coffee", "lot name", "lot", "اسم القهوة", "القهوة", "اسم المحصول", "المحصول"]),
        ("roaster", ["roasted by", "roaster", "roastery", "المحمصة", "تحميص"]),
        ("origin", ["country of origin", "origin", "country", "بلد المنشأ", "المنشأ", "الدولة"]),
        ("region", ["growing region", "region", "farm", "producer", "المنطقة", "المزرعة", "المنتج"]),
        ("altitude", ["elevation", "altitude", "الارتفاع"]),
        ("variety", ["varietal", "variety", "cultivar", "السلالة", "الصنف"]),
        ("process", ["processing method", "process", "processing", "طريقة المعالجة", "المعالجة"]),
        ("notes", ["tasting notes", "taste notes", "flavour notes", "flavor notes", "notes", "إيحاءات النكهة", "النكهات", "الإيحاءات"])
    ]

    private static let processTerms = [
        "anaerobic natural", "anaerobic washed", "double fermented", "carbonic maceration",
        "wet hulled", "semi washed", "semi-washed", "black honey", "red honey", "yellow honey",
        "washed", "natural", "honey", "anaerobic", "experimental",
        "مغسولة", "مجففة", "طبيعية", "عسلية", "لاهوائية", "تجريبية"
    ]

    private static let countries = [
        "Bolivia", "Brazil", "Burundi", "China", "Colombia", "Costa Rica", "Ecuador", "El Salvador",
        "Ethiopia", "Guatemala", "Honduras", "India", "Indonesia", "Jamaica", "Kenya", "Mexico",
        "Nicaragua", "Panama", "Papua New Guinea", "Peru", "Rwanda", "Tanzania", "Thailand", "Uganda", "Yemen",
        "إثيوبيا", "كولومبيا", "البرازيل", "كينيا", "رواندا", "اليمن", "بنما", "كوستاريكا", "غواتيمالا", "السلفادور", "هندوراس", "بيرو", "إندونيسيا", "أوغندا", "تنزانيا", "بوروندي"
    ]

    static func parse(lines rawLines: [String]) -> CoffeeBagScanResult {
        let lines = rawLines
            .map { clean($0) }
            .filter { !$0.isEmpty }

        var result = CoffeeBagScanResult()
        result.name = value(for: "name", in: lines)
        result.roaster = value(for: "roaster", in: lines)
        result.origin = value(for: "origin", in: lines) ?? inferredCountry(in: lines)
        result.region = value(for: "region", in: lines)
        result.altitude = value(for: "altitude", in: lines) ?? firstMatch(in: lines, pattern: #"\b(?:\d{1,2},\d{3}|\d{3,4})(?:\s*[-–—]\s*(?:\d{1,2},\d{3}|\d{3,4}))?\s*(?:m\.?a\.?s\.?l\.?|masl|meters?|metres?|m)\b"#)
        result.variety = value(for: "variety", in: lines)
        result.process = value(for: "process", in: lines) ?? inferredProcess(in: lines)
        result.tastingNotes = value(for: "notes", in: lines)

        inferHeaderFields(lines: lines, result: &result)
        return result
    }

    private static func value(for key: String, in lines: [String]) -> String? {
        guard let labels = labelGroups.first(where: { $0.key == key })?.labels else { return nil }

        for (index, line) in lines.enumerated() {
            let folded = normalized(line)
            for label in labels.sorted(by: { $0.count > $1.count }) {
                let normalizedLabel = normalized(label)
                guard folded == normalizedLabel || folded.hasPrefix(normalizedLabel + ":") || folded.hasPrefix(normalizedLabel + " ") else {
                    continue
                }

                let suffix = String(line.dropFirst(min(label.count, line.count)))
                    .trimmingCharacters(in: CharacterSet(charactersIn: " :-–—\t"))
                if isUsefulValue(suffix) { return suffix }

                if index + 1 < lines.count, isUsefulValue(lines[index + 1]), !isLabelLine(lines[index + 1]) {
                    return lines[index + 1]
                }
            }
        }
        return nil
    }

    private static func inferHeaderFields(lines: [String], result: inout CoffeeBagScanResult) {
        let candidates = lines.prefix(6).filter { line in
            let folded = normalized(line)
            return isUsefulValue(line)
                && !isLabelLine(line)
                && !folded.contains("www.")
                && !folded.contains("http")
                && !folded.contains("roasted on")
                && firstMatch(in: [line], pattern: #"\b\d{3,4}\s*(?:m|masl)\b"#) == nil
        }

        guard !candidates.isEmpty else { return }
        if result.roaster == nil,
           let branded = candidates.first(where: {
               let value = normalized($0)
               return value.contains("roaster")
                   || value.contains("roastery")
                   || value.contains("coffee co")
                   || value.contains("محمصة")
           }) {
            result.roaster = branded
        }

        if result.name == nil {
            result.name = candidates.first(where: { candidate in
                guard candidate != result.roaster else { return false }
                let folded = normalized(candidate)
                return !countries.contains(where: { folded == normalized($0) })
                    && !processTerms.contains(where: { folded.contains($0) })
            })
        }
    }

    private static func inferredCountry(in lines: [String]) -> String? {
        for line in lines {
            let folded = normalized(line)
            if let country = countries.first(where: { folded == normalized($0) || folded.contains(normalized($0)) }) {
                return country
            }
        }
        return nil
    }

    private static func inferredProcess(in lines: [String]) -> String? {
        for line in lines {
            let folded = normalized(line)
            if let process = processTerms.first(where: { folded.contains($0) }) {
                return process.split(separator: " ").map { $0.capitalized }.joined(separator: " ")
            }
        }
        return nil
    }

    private static func firstMatch(in lines: [String], pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        for line in lines {
            let range = NSRange(line.startIndex..., in: line)
            guard let match = regex.firstMatch(in: line, range: range),
                  let swiftRange = Range(match.range, in: line) else { continue }
            return String(line[swiftRange])
        }
        return nil
    }

    private static func isLabelLine(_ line: String) -> Bool {
        let folded = normalized(line)
        return labelGroups.flatMap(\.labels).contains { label in
            let normalizedLabel = normalized(label)
            return folded == normalizedLabel || folded.hasPrefix(normalizedLabel + ":") || folded.hasPrefix(normalizedLabel + " ")
        }
    }

    private static func isUsefulValue(_ value: String) -> Bool {
        let trimmed = clean(value)
        guard (2...100).contains(trimmed.count) else { return false }
        return trimmed.rangeOfCharacter(from: .letters) != nil
    }

    private static func clean(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalized(_ value: String) -> String {
        clean(value).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).lowercased()
    }
}

private extension UIImage {
    var imagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

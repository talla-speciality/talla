package com.talla.speciality.data

import java.text.Normalizer

data class CoffeeBagScanResult(
    val name: String? = null,
    val roaster: String? = null,
    val origin: String? = null,
    val region: String? = null,
    val altitude: String? = null,
    val variety: String? = null,
    val process: String? = null,
    val tastingNotes: String? = null,
) {
    val populatedFieldCount: Int
        get() = listOf(name, roaster, origin, region, altitude, variety, process, tastingNotes)
            .count { !it.isNullOrBlank() }

    fun journalNotes(): String = listOfNotNull(
        origin?.let { "Origin: $it" },
        region?.let { "Region: $it" },
        altitude?.let { "Altitude: $it" },
        variety?.let { "Variety: $it" },
        process?.let { "Process: $it" },
        tastingNotes?.let { "Tasting notes: $it" },
    ).joinToString(" · ")
}

object CoffeeBagLabelParser {
    private val labelGroups = mapOf(
        "name" to listOf("coffee name", "coffee", "lot name", "lot", "اسم القهوة", "القهوة", "اسم المحصول", "المحصول"),
        "roaster" to listOf("roasted by", "roaster", "roastery", "المحمصة", "تحميص"),
        "origin" to listOf("country of origin", "origin", "country", "بلد المنشأ", "المنشأ", "الدولة"),
        "region" to listOf("growing region", "region", "farm", "producer", "المنطقة", "المزرعة", "المنتج"),
        "altitude" to listOf("elevation", "altitude", "الارتفاع"),
        "variety" to listOf("varietal", "variety", "cultivar", "السلالة", "الصنف"),
        "process" to listOf("processing method", "process", "processing", "طريقة المعالجة", "المعالجة"),
        "notes" to listOf("tasting notes", "taste notes", "flavour notes", "flavor notes", "notes", "إيحاءات النكهة", "النكهات", "الإيحاءات"),
    )

    private val processTerms = listOf(
        "anaerobic natural", "anaerobic washed", "double fermented", "carbonic maceration",
        "wet hulled", "semi washed", "semi-washed", "black honey", "red honey", "yellow honey",
        "washed", "natural", "honey", "anaerobic", "experimental",
        "مغسولة", "مجففة", "طبيعية", "عسلية", "لاهوائية", "تجريبية",
    )

    private val countries = listOf(
        "Bolivia", "Brazil", "Burundi", "China", "Colombia", "Costa Rica", "Ecuador", "El Salvador",
        "Ethiopia", "Guatemala", "Honduras", "India", "Indonesia", "Jamaica", "Kenya", "Mexico",
        "Nicaragua", "Panama", "Papua New Guinea", "Peru", "Rwanda", "Tanzania", "Thailand", "Uganda", "Yemen",
        "إثيوبيا", "كولومبيا", "البرازيل", "كينيا", "رواندا", "اليمن", "بنما", "كوستاريكا",
        "غواتيمالا", "السلفادور", "هندوراس", "بيرو", "إندونيسيا", "أوغندا", "تنزانيا", "بوروندي",
    )

    private val altitudePattern = Regex(
        "\\b(?:\\d{1,2},\\d{3}|\\d{3,4})(?:\\s*[-–—]\\s*(?:\\d{1,2},\\d{3}|\\d{3,4}))?\\s*(?:m\\.?a\\.?s\\.?l\\.?|masl|meters?|metres?|m)\\b",
        RegexOption.IGNORE_CASE,
    )

    fun parse(rawLines: List<String>): CoffeeBagScanResult {
        val lines = rawLines.map(::clean).filter(String::isNotEmpty)
        var result = CoffeeBagScanResult(
            name = value("name", lines),
            roaster = value("roaster", lines),
            origin = value("origin", lines) ?: inferredCountry(lines),
            region = value("region", lines),
            altitude = value("altitude", lines) ?: lines.firstNotNullOfOrNull { altitudePattern.find(it)?.value },
            variety = value("variety", lines),
            process = value("process", lines) ?: inferredProcess(lines),
            tastingNotes = value("notes", lines),
        )

        val candidates = lines.take(6).filter { line ->
            val folded = normalized(line)
            isUsefulValue(line) && !isLabelLine(line) && !folded.contains("www.") && !folded.contains("http") &&
                !folded.contains("roasted on") && altitudePattern.find(line) == null
        }
        if (result.roaster == null) {
            result = result.copy(roaster = candidates.firstOrNull {
                val value = normalized(it)
                value.contains("roaster") || value.contains("roastery") || value.contains("coffee co") || value.contains("محمصة")
            })
        }
        if (result.name == null) {
            result = result.copy(name = candidates.firstOrNull { candidate ->
                candidate != result.roaster && countries.none { normalized(candidate) == normalized(it) } &&
                    processTerms.none { normalized(candidate).contains(normalized(it)) }
            })
        }
        return result
    }

    private fun value(key: String, lines: List<String>): String? {
        val labels = labelGroups[key].orEmpty().sortedByDescending(String::length)
        lines.forEachIndexed { index, line ->
            val folded = normalized(line)
            labels.forEach { label ->
                val normalizedLabel = normalized(label)
                if (folded == normalizedLabel || folded.startsWith("$normalizedLabel:") || folded.startsWith("$normalizedLabel ")) {
                    val suffix = line.drop(label.length.coerceAtMost(line.length)).trim(' ', ':', '-', '–', '—', '\t')
                    if (isUsefulValue(suffix) || key == "variety" && isUsefulNumericValue(suffix)) return suffix
                    val next = lines.getOrNull(index + 1)
                    if (next != null && (isUsefulValue(next) || key == "variety" && isUsefulNumericValue(next)) && !isLabelLine(next)) return next
                }
            }
        }
        return null
    }

    private fun inferredCountry(lines: List<String>): String? = lines.firstNotNullOfOrNull { line ->
        val folded = normalized(line)
        countries.firstOrNull { folded == normalized(it) || folded.contains(normalized(it)) }
    }

    private fun inferredProcess(lines: List<String>): String? = lines.firstNotNullOfOrNull { line ->
        val folded = normalized(line)
        processTerms.firstOrNull { folded.contains(normalized(it)) }?.split(' ')?.joinToString(" ") { word ->
            word.replaceFirstChar { character -> character.uppercase() }
        }
    }

    private fun isLabelLine(line: String): Boolean {
        val folded = normalized(line)
        return labelGroups.values.flatten().any { label ->
            val normalizedLabel = normalized(label)
            folded == normalizedLabel || folded.startsWith("$normalizedLabel:") || folded.startsWith("$normalizedLabel ")
        }
    }

    private fun isUsefulValue(value: String): Boolean {
        val trimmed = clean(value)
        return trimmed.length in 2..100 && trimmed.any(Char::isLetter)
    }

    private fun isUsefulNumericValue(value: String): Boolean {
        val trimmed = clean(value)
        return trimmed.length in 2..30 && trimmed.any(Char::isDigit)
    }

    private fun clean(value: String): String = value.replace('\n', ' ').trim().split(Regex("\\s+")).joinToString(" ")

    private fun normalized(value: String): String = Normalizer.normalize(clean(value), Normalizer.Form.NFD)
        .replace(Regex("\\p{M}+"), "")
        .lowercase()
}

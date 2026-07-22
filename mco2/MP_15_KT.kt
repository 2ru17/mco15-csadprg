/********************
 ┃     Last names: Gutang, Wong, Tolentino, Degullado
 ┃     Language: Kotlin
 ┃     Paradigm(s): Multi-paradigm (Structured, Imperative, Functional, OOP)
 ┃     ********************/
/**
 * De La Salle University, Manila
 * College of Computer Studies
 * Department of Software Technology
 *
 * Course Code: CSADPRG (Advanced Programming)
 * Major Course Output #2: Data Analysis Pipeline for Flood Control Projects
 *
 * File Name: MP_15_KT.kt
 * Group Number: 15
 *
 * Description:
 * This Kotlin command-line application implements a Data Analysis Pipeline
 * that ingests DPWH flood control project data from CSV, preprocesses it
 * (filtering, cleaning, derived field computation), and generates three
 * tabular reports plus a JSON summary for infrastructure analysis.
 *
 * Academic Integrity Statement:
 * We hereby declare that this submission is our own work and that, to the
 * best of our knowledge and belief, it contains no material previously
 * written or published by another person, nor material which has been
 * accepted for the award of any other degree or diploma, except where due
 * acknowledgment has been made in the text.
 */

import java.io.File
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import kotlin.math.abs

// CONSTANTS
// CSV column indices (0-based)
const val COL_MAIN_ISLAND = 0
const val COL_REGION = 1
const val COL_PROVINCE = 2
const val COL_TYPE_OF_WORK = 8
const val COL_FUNDING_YEAR = 9
const val COL_APPROVED_BUDGET = 11
const val COL_CONTRACT_COST = 12
const val COL_ACTUAL_COMPLETION = 13
const val COL_CONTRACTOR = 14
const val COL_START_DATE = 16
const val COL_PROJECT_LAT = 17
const val COL_PROJECT_LNG = 18

const val EXPECTED_COLUMNS = 22

val OUT_DIR = "KT_out"
val REPORT1_FILE = "$OUT_DIR/report1_regional_summary.csv"
val REPORT2_FILE = "$OUT_DIR/report2_contractor_ranking.csv"
val REPORT3_FILE = "$OUT_DIR/report3_annual_trends.csv"
val SUMMARY_FILE = "$OUT_DIR/summary.json"

// Data Classes
data class Project(
    val mainIsland: String,
    val region: String,
    val province: String,
    val typeOfWork: String,
    val fundingYear: Int,
    val approvedBudget: Double,
    val contractCost: Double,
    val startDate: LocalDate,
    val actualCompletionDate: LocalDate,
    val contractor: String,
    var projectLat: Double,
    var projectLng: Double,
    val costSavings: Double,
    val completionDelayDays: Long
)

data class ProvinceCoords(
    var latSum: Double = 0.0,
    var lngSum: Double = 0.0,
    var count: Int = 0
)

// Application State
object State {
    val projects = mutableListOf<Project>()
    var totalRawRows = 0
    var parseErrors = 0
    var dataLoaded = false
}

// CSV PARSER 
fun parseCsvLine(line: String): List<String> {
    val fields = mutableListOf<String>()
    var current = StringBuilder()
    var inQuotes = false
    var i = 0
    
    while (i < line.length) {
        val ch = line[i]
        
        when {
            inQuotes -> {
                if (ch == '"') {
                    if (i + 1 < line.length && line[i + 1] == '"') {
                        current.append('"')
                        i++
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(ch)
                }
            }
            ch == '"' -> {
                inQuotes = true
            }
            ch == ',' -> {
                fields.add(current.toString())
                current = StringBuilder()
            }
            else -> {
                current.append(ch)
            }
        }
        i++
    }
    fields.add(current.toString())
    return fields
}

// DATE UTILITIES - More strict validation
fun parseDate(s: String): LocalDate? {
    return try {
        if (s.isNotEmpty() && s != "null" && s != "N/A" && s != "") {
            val trimmed = s.trim()
            // Try ISO format first (yyyy-MM-dd)
            try {
                return LocalDate.parse(trimmed, DateTimeFormatter.ISO_LOCAL_DATE)
            } catch (e: Exception) {
                // Try other formats
                val formatters = listOf(
                    DateTimeFormatter.ofPattern("M/d/yyyy"),
                    DateTimeFormatter.ofPattern("M/d/yy"),
                    DateTimeFormatter.ofPattern("yyyy-M-d")
                )
                for (formatter in formatters) {
                    try {
                        return LocalDate.parse(trimmed, formatter)
                    } catch (e2: Exception) {
                        // Continue to next formatter
                    }
                }
            }
            null
        } else null
    } catch (e: Exception) {
        null
    }
}

// FORMATTING HELPER
fun formatNumber(value: Double, decimals: Int): String {
    val isNegative = value < 0
    val absValue = abs(value)
    
    val formatted = "%.${decimals}f".format(absValue)
    val parts = formatted.split(".")
    val integerPart = parts[0]
    
    val withCommas = StringBuilder()
    for (i in integerPart.indices) {
        if (i > 0 && (integerPart.length - i) % 3 == 0) {
            withCommas.append(',')
        }
        withCommas.append(integerPart[i])
    }
    
    val result = StringBuilder()
    if (isNegative) result.append('-')
    result.append(withCommas)
    if (decimals > 0 && parts.size > 1) {
        result.append('.').append(parts[1])
    }
    return result.toString()
}

// MATH HELPER
fun getMedian(values: List<Double>): Double {
    if (values.isEmpty()) return 0.0
    val sorted = values.sorted()
    val half = sorted.size / 2
    return if (sorted.size % 2 == 0) {
        (sorted[half - 1] + sorted[half]) / 2.0
    } else {
        sorted[half]
    }
}

// CSV WRITER HELPER
fun writeCsv(filename: String, headers: List<String>, rows: List<List<String>>) {
    val content = StringBuilder()
    content.append(headers.joinToString(",")).append("\n")
    
    for (row in rows) {
        val quotedRow = row.map { field ->
            val fieldStr = field
            if (fieldStr.contains(",") || fieldStr.contains("\"") || fieldStr.contains("\n")) {
                "\"${fieldStr.replace("\"", "\"\"")}\""
            } else {
                fieldStr
            }
        }
        content.append(quotedRow.joinToString(",")).append("\n")
    }
    
    File(filename).writeText(content.toString())
}

// DATA INGESTION
fun loadData() {
    State.projects.clear()
    State.totalRawRows = 0
    State.parseErrors = 0

    val filepath = "dpwh_flood_control_projects.csv"
    val file = File(filepath)
    if (!file.exists()) {
        println("Error: Failed to open CSV file: $filepath")
        return
    }

    val lines = file.readLines()
    val rawProjects = mutableListOf<Project>()

    for (i in 1 until lines.size) {
        val line = lines[i].trimEnd()
        if (line.isEmpty()) continue

        State.totalRawRows++
        val fields = parseCsvLine(line)

        // Skip rows with wrong number of fields
        if (fields.size < EXPECTED_COLUMNS) {
            State.parseErrors++
            continue
        }

        try {
            // Validate required fields are non-empty
            val region = fields[COL_REGION].trim()
            val province = fields[COL_PROVINCE].trim()
            val contractor = fields[COL_CONTRACTOR].trim()
            val mainIsland = fields[COL_MAIN_ISLAND].trim()
            val typeOfWork = fields[COL_TYPE_OF_WORK].trim()
            
            if (region.isEmpty() || province.isEmpty() || contractor.isEmpty() || 
                mainIsland.isEmpty() || typeOfWork.isEmpty()) {
                State.parseErrors++
                continue
            }

            val fundingYear = fields[COL_FUNDING_YEAR].trim().toIntOrNull()
            if (fundingYear == null || fundingYear !in 2021..2023) {
                State.parseErrors++
                continue
            }

            val approvedBudgetStr = fields[COL_APPROVED_BUDGET].trim()
            val contractCostStr = fields[COL_CONTRACT_COST].trim()
            
            if (approvedBudgetStr.isEmpty() || contractCostStr.isEmpty()) {
                State.parseErrors++
                continue
            }
            
            val approvedBudget = approvedBudgetStr.toDoubleOrNull()
            val contractCost = contractCostStr.toDoubleOrNull()
            
            if (approvedBudget == null || contractCost == null || 
                approvedBudget < 0 || contractCost < 0) {
                State.parseErrors++
                continue
            }

            val startDateStr = fields[COL_START_DATE].trim()
            val actualCompletionStr = fields[COL_ACTUAL_COMPLETION].trim()
            
            if (startDateStr.isEmpty() || actualCompletionStr.isEmpty()) {
                State.parseErrors++
                continue
            }
            
            val startDate = parseDate(startDateStr)
            val actualCompletionDate = parseDate(actualCompletionStr)
            
            if (startDate == null || actualCompletionDate == null) {
                State.parseErrors++
                continue
            }

            // Validate dates are in a reasonable range
            if (startDate.year < 2000 || actualCompletionDate.year < 2000 ||
                startDate.year > 2025 || actualCompletionDate.year > 2025) {
                State.parseErrors++
                continue
            }

            // Validate that completion date is after start date (or at least reasonable)
            if (actualCompletionDate.isBefore(startDate)) {
                State.parseErrors++
                continue
            }

            var projectLat = fields[COL_PROJECT_LAT].trim().toDoubleOrNull() ?: 0.0
            var projectLng = fields[COL_PROJECT_LNG].trim().toDoubleOrNull() ?: 0.0

            val costSavings = approvedBudget - contractCost
            val completionDelayDays = ChronoUnit.DAYS.between(startDate, actualCompletionDate)

            rawProjects.add(
                Project(
                    mainIsland = mainIsland,
                    region = region,
                    province = province,
                    typeOfWork = typeOfWork,
                    fundingYear = fundingYear,
                    approvedBudget = approvedBudget,
                    contractCost = contractCost,
                    startDate = startDate,
                    actualCompletionDate = actualCompletionDate,
                    contractor = contractor,
                    projectLat = projectLat,
                    projectLng = projectLng,
                    costSavings = costSavings,
                    completionDelayDays = completionDelayDays
                )
            )
        } catch (e: Exception) {
            State.parseErrors++
        }
    }

    imputeCoordinates(rawProjects)

    State.projects.addAll(rawProjects)
    State.dataLoaded = true

    println("Processing dataset... (${formatNumber(State.totalRawRows.toDouble(), 0)} rows loaded, ${formatNumber(rawProjects.size.toDouble(), 0)} filtered for 2021-2023)")
    println("Parse errors: ${State.parseErrors}")
}

fun imputeCoordinates(projects: MutableList<Project>) {
    val provinceSums = mutableMapOf<String, ProvinceCoords>()

    for (p in projects) {
        if (p.projectLat != 0.0 && p.projectLng != 0.0) {
            val coords = provinceSums.getOrPut(p.province) { ProvinceCoords() }
            coords.latSum += p.projectLat
            coords.lngSum += p.projectLng
            coords.count++
        }
    }

    val provinceAvgs = mutableMapOf<String, Pair<Double, Double>>()
    for ((prov, data) in provinceSums) {
        provinceAvgs[prov] = data.latSum / data.count to data.lngSum / data.count
    }

    var imputedCount = 0
    for (p in projects) {
        if (p.projectLat == 0.0 || p.projectLng == 0.0) {
            provinceAvgs[p.province]?.let { (lat, lng) ->
                p.projectLat = lat
                p.projectLng = lng
                imputedCount++
            }
        }
    }
    if (imputedCount > 0) {
        println("Imputed coordinates for $imputedCount projects using provincial averages")
    }
}

// REPORTS
fun generateAllReports() {
    val outDir = File(OUT_DIR)
    if (!outDir.exists()) {
        try {
            outDir.mkdirs()
        } catch (e: Exception) {
            println("Error: Failed to create output directory '$OUT_DIR': ${e.message}")
            return
        }
    }

    println("Generating reports...")
    println("Outputs saved to individual files...\n")

    generateReport1(State.projects)
    println()
    generateReport2(State.projects)
    println()
    generateReport3(State.projects)
    println()
    generateSummary(State.projects)
}

fun generateReport1(projects: List<Project>) {
    val groups = mutableMapOf<String, MutableList<Int>>()
    
    projects.forEachIndexed { i, p ->
        val key = "${p.region}|${p.mainIsland}"
        groups.getOrPut(key) { mutableListOf() }.add(i)
    }

    val rows = mutableListOf<MutableMap<String, Any>>()
    
    for ((key, indices) in groups) {
        val parts = key.split("|")
        val region = parts[0]
        val mainIsland = parts[1]
        val count = indices.size

        var totalBudget = 0.0
        val savings = mutableListOf<Double>()
        var totalDelay = 0L
        var highDelayCount = 0

        for (i in indices) {
            val p = projects[i]
            totalBudget += p.approvedBudget
            savings.add(p.costSavings)
            totalDelay += p.completionDelayDays
            if (p.completionDelayDays > 30) highDelayCount++
        }

        val medianSavings = getMedian(savings)
        val avgDelay = totalDelay.toDouble() / count
        val highDelayPct = (highDelayCount.toDouble() / count) * 100.0
        
        val rawScore = if (avgDelay == 0.0) Double.MAX_VALUE else (medianSavings / avgDelay) * 100.0
        
        rows.add(mutableMapOf(
            "region" to region,
            "mainIsland" to mainIsland,
            "totalBudget" to totalBudget,
            "medianSavings" to medianSavings,
            "avgDelay" to avgDelay,
            "highDelayPct" to highDelayPct,
            "rawScore" to rawScore
        ))
    }

    val finiteScores = rows.map { it["rawScore"] as Double }.filter { it.isFinite() }
    if (finiteScores.isNotEmpty()) {
        val minScore = finiteScores.minOrNull() ?: 0.0
        val maxScore = finiteScores.maxOrNull() ?: 1.0
        
        for (r in rows) {
            if (!(r["rawScore"] as Double).isFinite()) {
                r["rawScore"] = maxScore
            }
        }

        val range = maxScore - minScore
        for (r in rows) {
            val rawScore = r["rawScore"] as Double
            r["efficiencyScore"] = if (range == 0.0) 50.0 else ((rawScore - minScore) / range) * 100.0
        }
    } else {
        for (r in rows) {
            r["efficiencyScore"] = 0.0
        }
    }

    rows.sortByDescending { it["efficiencyScore"] as Double }

    val headers = listOf("Region", "MainIsland", "TotalBudget", "MedianSavings", "AvgDelay", "HighDelayPct", "EfficiencyScore")
    val csvRows = rows.map { r ->
        listOf(
            r["region"] as String,
            r["mainIsland"] as String,
            formatNumber(r["totalBudget"] as Double, 2),
            formatNumber(r["medianSavings"] as Double, 2),
            formatNumber(r["avgDelay"] as Double, 2),
            formatNumber(r["highDelayPct"] as Double, 2),
            formatNumber(r["efficiencyScore"] as Double, 2)
        )
    }
    
    writeCsv(REPORT1_FILE, headers, csvRows)

    println("Report 1: Regional Flood Mitigation Efficiency Summary")
    println("(Filtered: 2021-2023 Projects)")
    println("| ${"Region".padEnd(45)} | ${"MainIsland".padEnd(10)} | ${"TotalBudget".padStart(15)} | ${"MedianSavings".padStart(14)} | ${"AvgDelay".padStart(10)} | ${"HighDelayPct".padStart(12)} | ${"EfficiencyScore".padStart(15)} |")
    
    for (i in 0 until minOf(2, rows.size)) {
        val r = rows[i]
        val region = r["region"] as String
        val mainIsland = r["mainIsland"] as String
        println("| ${region.padEnd(45)} | ${mainIsland.padEnd(10)} | ${formatNumber(r["totalBudget"] as Double, 2).padStart(15)} | ${formatNumber(r["medianSavings"] as Double, 2).padStart(14)} | ${formatNumber(r["avgDelay"] as Double, 2).padStart(10)} | ${formatNumber(r["highDelayPct"] as Double, 2).padStart(12)} | ${formatNumber(r["efficiencyScore"] as Double, 2).padStart(15)} |")
    }
    println("(Full table exported to $REPORT1_FILE)")
}

fun generateReport2(projects: List<Project>) {
    val groups = mutableMapOf<String, MutableList<Int>>()
    
    projects.forEachIndexed { i, p ->
        groups.getOrPut(p.contractor) { mutableListOf() }.add(i)
    }

    val rows = mutableListOf<Map<String, Any>>()
    
    for ((contractor, indices) in groups) {
        if (indices.size < 5) continue
        
        val count = indices.size
        var totalCost = 0.0
        var totalDelay = 0L
        var totalSavings = 0.0
        
        for (i in indices) {
            val p = projects[i]
            totalCost += p.contractCost
            totalDelay += p.completionDelayDays
            totalSavings += p.costSavings
        }
        
        val avgDelay = totalDelay.toDouble() / count
        
        var reliabilityIndex = if (totalCost == 0.0) 0.0 else (1.0 - (avgDelay / 90.0)) * (totalSavings / totalCost) * 100.0
        if (reliabilityIndex > 100.0) reliabilityIndex = 100.0
        if (reliabilityIndex < 0.0) reliabilityIndex = 0.0
        
        val riskFlag = if (reliabilityIndex < 50.0) "High Risk" else "Low Risk"
        
        rows.add(mapOf(
            "contractor" to contractor,
            "totalCost" to totalCost,
            "count" to count,
            "avgDelay" to avgDelay,
            "totalSavings" to totalSavings,
            "reliabilityIndex" to reliabilityIndex,
            "riskFlag" to riskFlag
        ))
    }

    rows.sortByDescending { it["totalCost"] as Double }
    val top15 = rows.take(15)

    val headers = listOf("Rank", "Contractor", "TotalCost", "NumProjects", "AvgDelay", "TotalSavings", "ReliabilityIndex", "RiskFlag")
    val csvRows = top15.mapIndexed { index, r ->
        listOf(
            (index + 1).toString(),
            r["contractor"] as String,
            formatNumber(r["totalCost"] as Double, 2),
            (r["count"] as Int).toString(),
            formatNumber(r["avgDelay"] as Double, 2),
            formatNumber(r["totalSavings"] as Double, 2),
            formatNumber(r["reliabilityIndex"] as Double, 2),
            r["riskFlag"] as String
        )
    }
    
    writeCsv(REPORT2_FILE, headers, csvRows)

    println("Report 2: Top Contractors Performance Ranking")
    println("(Top 15 by TotalCost, >=5 Projects)")
    println("| ${"Rank".padStart(4)} | ${"Contractor".padEnd(45)} | ${"TotalCost".padStart(18)} | ${"NumProjects".padStart(11)} | ${"AvgDelay".padStart(10)} | ${"TotalSavings".padStart(18)} | ${"ReliabilityIndex".padStart(16)} | ${"RiskFlag".padStart(10)} |")
    
    for ((index, r) in top15.take(2).withIndex()) {
        val contractor = r["contractor"] as String
        val cont = if (contractor.length > 45) contractor.substring(0, 42) + "..." else contractor
        println("| ${(index + 1).toString().padStart(4)} | ${cont.padEnd(45)} | ${formatNumber(r["totalCost"] as Double, 2).padStart(18)} | ${(r["count"] as Int).toString().padStart(11)} | ${formatNumber(r["avgDelay"] as Double, 2).padStart(10)} | ${formatNumber(r["totalSavings"] as Double, 2).padStart(18)} | ${formatNumber(r["reliabilityIndex"] as Double, 2).padStart(16)} | ${(r["riskFlag"] as String).padStart(10)} |")
    }
    println("(Full table exported to $REPORT2_FILE)")
}

fun generateReport3(projects: List<Project>) {
    val groups = mutableMapOf<String, MutableList<Int>>()
    
    projects.forEachIndexed { i, p ->
        val key = "${p.fundingYear}|${p.typeOfWork}"
        groups.getOrPut(key) { mutableListOf() }.add(i)
    }

    val avgSavingsMap = mutableMapOf<String, Double>()
    for ((key, indices) in groups) {
        var totalSavings = 0.0
        for (i in indices) {
            totalSavings += projects[i].costSavings
        }
        avgSavingsMap[key] = totalSavings / indices.size
    }

    val rows = mutableListOf<Map<String, Any>>()
    
    for ((key, indices) in groups) {
        val parts = key.split("|")
        val year = parts[0].toInt()
        val typeOfWork = parts[1]
        val totalProjects = indices.size
        
        var totalSavings = 0.0
        var overrunCount = 0
        
        for (i in indices) {
            val p = projects[i]
            totalSavings += p.costSavings
            if (p.costSavings < 0.0) overrunCount++
        }
        
        val avgSavings = totalSavings / totalProjects
        val overrunRate = (overrunCount.toDouble() / totalProjects) * 100.0
        
        var yoyChange = 0.0
        if (year != 2021) {
            val prevYear = year - 1
            val prevAvg = avgSavingsMap["$prevYear|$typeOfWork"]
            if (prevAvg != null && abs(prevAvg) > 0.0) {
                yoyChange = ((avgSavings - prevAvg) / abs(prevAvg)) * 100.0
            }
        }
        
        rows.add(mapOf(
            "typeOfWork" to typeOfWork,
            "year" to year,
            "totalProjects" to totalProjects,
            "avgSavings" to avgSavings,
            "overrunRate" to overrunRate,
            "yoyChange" to yoyChange
        ))
    }

    rows.sortWith(compareBy({ it["year"] as Int }, { -(it["avgSavings"] as Double) }))

    val headers = listOf("TypeOfWork", "FundingYear", "TotalProjects", "AvgSavings", "OverrunRate", "YoYChange")
    val csvRows = rows.map { r ->
        listOf(
            r["typeOfWork"] as String,
            (r["year"] as Int).toString(),
            (r["totalProjects"] as Int).toString(),
            formatNumber(r["avgSavings"] as Double, 2),
            formatNumber(r["overrunRate"] as Double, 2),
            formatNumber(r["yoyChange"] as Double, 2)
        )
    }
    
    writeCsv(REPORT3_FILE, headers, csvRows)

    println("Report 3: Annual Project Type Cost Overrun Trends")
    println("(Grouped by FundingYear and TypeOfWork)")
    println("| ${"TypeOfWork".padEnd(50)} | ${"FundingYear".padStart(11)} | ${"TotalProjects".padStart(13)} | ${"AvgSavings".padStart(15)} | ${"OverrunRate".padStart(11)} | ${"YoYChange".padStart(11)} |")
    
    for (r in rows.take(3)) {
        var tw = r["typeOfWork"] as String
        if (tw.length > 50) tw = tw.substring(0, 47) + "..."
        println("| ${tw.padEnd(50)} | ${(r["year"] as Int).toString().padStart(11)} | ${(r["totalProjects"] as Int).toString().padStart(13)} | ${formatNumber(r["avgSavings"] as Double, 2).padStart(15)} | ${formatNumber(r["overrunRate"] as Double, 2).padStart(11)} | ${formatNumber(r["yoyChange"] as Double, 2).padStart(11)} |")
    }
    println("(Full table exported to $REPORT3_FILE)")
}

fun generateSummary(projects: List<Project>) {
    val totalProjects = projects.size
    
    val contractors = mutableSetOf<String>()
    val provinces = mutableSetOf<String>()
    var totalDelay = 0L
    var totalSavings = 0.0
    
    for (p in projects) {
        contractors.add(p.contractor)
        provinces.add(p.province)
        totalDelay += p.completionDelayDays
        totalSavings += p.costSavings
    }
    
    val globalAvgDelay = if (totalProjects > 0) totalDelay.toDouble() / totalProjects else 0.0
    
    val summaryData = mapOf(
        "total_projects" to totalProjects,
        "total_contractors" to contractors.size,
        "total_provinces" to provinces.size,
        "global_avg_delay" to String.format("%.2f", globalAvgDelay).toDouble(),
        "total_savings" to String.format("%.2f", totalSavings).toDouble()
    )
    
    File(SUMMARY_FILE).writeText(prettyPrintJson(summaryData))

    println("Summary Stats ($SUMMARY_FILE):")
    println("{\"total_projects\": ${summaryData["total_projects"]}, \"total_contractors\": ${summaryData["total_contractors"]}, \"total_provinces\": ${summaryData["total_provinces"]}, \"global_avg_delay\": ${String.format("%.2f", summaryData["global_avg_delay"])}, \"total_savings\": ${String.format("%.2f", summaryData["total_savings"])}}")
}

fun prettyPrintJson(map: Map<String, Any>): String {
    val sb = StringBuilder()
    sb.append("{\n")
    val entries = map.entries.toList()
    for ((index, entry) in entries.withIndex()) {
        sb.append("  \"${entry.key}\": ")
        when (val value = entry.value) {
            is String -> sb.append("\"$value\"")
            is Number -> sb.append(value)
            else -> sb.append(value)
        }
        if (index < entries.size - 1) sb.append(",")
        sb.append("\n")
    }
    sb.append("}")
    return sb.toString()
}

// MAIN MENU
fun promptMenu() {
    println("\nSelect Language Implementation:")
    println("[1] Load the file")
    println("[2] Generate Reports")
    println("[0] Exit")
    print("Enter choice: ")
}

fun main() {
    val scanner = java.util.Scanner(System.`in`)
    
    while (true) {
        promptMenu()
        val choice = scanner.nextLine().trim()
        
        when (choice) {
            "0" -> {
                println("\nExiting program. Goodbye!")
                break
            }
            "1" -> {
                loadData()
            }
            "2" -> {
                if (!State.dataLoaded) {
                    println("Error: Please load the file first (option 1).")
                } else {
                    generateAllReports()
                    println()
                    print("Back to Report Selection (Y/N): ")
                    val back = scanner.nextLine().trim().uppercase()
                    if (back == "N") {
                        println("Exiting program. Goodbye!")
                        break
                    }
                }
            }
            else -> {
                println("Invalid option. Please enter 0, 1, or 2.")
            }
        }
    }
}
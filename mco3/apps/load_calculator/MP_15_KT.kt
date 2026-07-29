import java.io.File

// [DATA_TYPE] Data class showing strong, static typing and composite types.
data class LoadData(val deadLoad: Double, val liveLoad: Double)

// [PARAM_PASSING] Pass by reference effect (sharing): modifying mutable properties of an object.
class LoadWrapper(var value: Double)

// [PARAM_PASSING] Pass by value: primitive Double values are copied.
fun calculateUltimateLoad(dl: Double, ll: Double): Double {
    return 1.2 * dl + 1.6 * ll
}

fun distributeLoad(loadObj: LoadWrapper, pillars: Int) {
    if (pillars > 0) {
        loadObj.value = loadObj.value / pillars
    }
}

fun main() {
    // [BINDING] Static type binding with type inference (val infers LoadData).
    val data = LoadData(150.5, 85.0)

    val ultimateLoadValue = calculateUltimateLoad(data.deadLoad, data.liveLoad)
    val totalPillars = 4

    val loadWrapper = LoadWrapper(ultimateLoadValue)
    distributeLoad(loadWrapper, totalPillars)

    // [INTEGRATION] String interpolation and File I/O.
    val outputStr = """
        Dead Load: ${String.format("%.2f", data.deadLoad)}
        Live Load: ${String.format("%.2f", data.liveLoad)}
        Total Pillars: $totalPillars
        Load per Pillar: ${String.format("%.2f", loadWrapper.value)}
    """.trimIndent() + "\n"

    println(outputStr)

    val outDir = File("../outputs/KT_out")
    if (!outDir.exists()) outDir.mkdirs()
    
    File(outDir, "load_results.txt").writeText(outputStr)
    println("Results saved to outputs/KT_out/load_results.txt")
}

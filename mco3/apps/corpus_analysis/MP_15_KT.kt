import java.io.File

// [PARAM_PASSING] Pass by value: String primitive is passed.
fun tokenize(text: String): List<String> {
    // [DATA_TYPE] Collection List<String> used for storing data.
    return text.lowercase()
        .replace(Regex("[^a-z0-9\\s]"), "")
        .split(Regex("\\s+"))
        .filter { it.isNotEmpty() }
}

// [PARAM_PASSING] Pass by reference effect (sharing): List passed to count frequencies.
fun countFrequencies(words: List<String>): Map<String, Int> {
    // [BINDING] Dynamic map, static types (Map<String, Int>).
    val frequencies = mutableMapOf<String, Int>()
    for (word in words) {
        frequencies[word] = frequencies.getOrDefault(word, 0) + 1
    }
    return frequencies
}

fun main() {
    val corpusFile = File("corpora/sample_corpus.txt")
    val text = if (corpusFile.exists()) {
        corpusFile.readText()
    } else {
        "default text fallback"
    }

    val words = tokenize(text)
    val freqMap = countFrequencies(words)

    // Sort entries by value descending
    val sortedEntries = freqMap.entries.sortedByDescending { it.value }

    val outputBuilder = java.lang.StringBuilder("Corpus Word Frequencies:\n")
    for (entry in sortedEntries) {
        outputBuilder.append("${entry.key}: ${entry.value}\n")
    }

    val outputStr = outputBuilder.toString()
    println(outputStr)

    // [INTEGRATION] File I/O
    val outDir = File("../outputs/KT_out")
    if (!outDir.exists()) outDir.mkdirs()
    
    val outPath = File(outDir, "corpus_results.txt")
    outPath.writeText(outputStr)

    println("Results saved to outputs/KT_out/corpus_results.txt")
}

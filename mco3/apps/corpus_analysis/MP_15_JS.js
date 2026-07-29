const fs = require('fs');
const path = require('path');

// [PARAM_PASSING] Pass by value: string primitive is passed.
function tokenize(text) {
    // [DATA_TYPE] Array (Composite Type) dynamically created.
    return text.toLowerCase()
        .replace(/[^a-z0-9\s]/g, '')
        .split(/\s+/)
        .filter(w => w.length > 0);
}

// [PARAM_PASSING] Pass by reference (sharing): Object passed to function.
function countFrequencies(words) {
    // [BINDING] Dynamic binding of Object properties.
    let frequencies = {};
    for (let word of words) {
        if (frequencies[word]) {
            frequencies[word]++;
        } else {
            frequencies[word] = 1;
        }
    }
    return frequencies;
}

function main() {
    const corpusPath = path.join(__dirname, 'corpora', 'sample_corpus.txt');
    let text = "";
    try {
        text = fs.readFileSync(corpusPath, 'utf8');
    } catch (e) {
        text = "default text fallback";
    }

    let words = tokenize(text);
    let freqMap = countFrequencies(words);

    // Convert object to array for sorting
    let sortedEntries = Object.entries(freqMap).sort((a, b) => b[1] - a[1]);

    let outputStr = "Corpus Word Frequencies:\n";
    for (let [word, count] of sortedEntries) {
        outputStr += `${word}: ${count}\n`;
    }

    console.log(outputStr);

    // [INTEGRATION] File I/O
    const outDir = path.join(__dirname, '..', 'outputs', 'JS_out');
    if (!fs.existsSync(outDir)) {
        fs.mkdirSync(outDir, { recursive: true });
    }
    
    const outPath = path.join(outDir, 'corpus_results.txt');
    fs.writeFileSync(outPath, outputStr);
    
    console.log(`Results saved to outputs/JS_out/corpus_results.txt`);
}

main();

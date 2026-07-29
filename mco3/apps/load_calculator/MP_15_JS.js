const fs = require('fs');
const path = require('path');

// [BINDING] Dynamic type binding: Variables don't have fixed types.
let deadLoad = 150.5;
let liveLoad = 85.0;

// [PARAM_PASSING] Pass by value: primitive numbers are copied.
function calculateUltimateLoad(dl, ll) {
    return 1.2 * dl + 1.6 * ll;
}

// [DATA_TYPE] Using an object (composite type) to demonstrate pass-by-reference effect.
// [PARAM_PASSING] Pass by reference (sharing): modifying object properties affects the original object.
function distributeLoad(loadObj, pillars) {
    if (pillars > 0) {
        loadObj.value = loadObj.value / pillars;
    }
}

function main() {
    let ultimateLoadValue = calculateUltimateLoad(deadLoad, liveLoad);
    let totalPillars = 4;

    // Wrap in object for pass-by-reference effect
    let loadWrapper = { value: ultimateLoadValue };
    
    distributeLoad(loadWrapper, totalPillars);

    // [INTEGRATION] Output formatting using template literals
    const outputStr = `Dead Load: ${deadLoad.toFixed(2)}
Live Load: ${liveLoad.toFixed(2)}
Total Pillars: ${totalPillars}
Load per Pillar: ${loadWrapper.value.toFixed(2)}
`;

    console.log(outputStr);

    const outDir = path.join(__dirname, '..', 'outputs', 'JS_out');
    if (!fs.existsSync(outDir)) {
        fs.mkdirSync(outDir, { recursive: true });
    }
    
    const outPath = path.join(outDir, 'load_results.txt');
    fs.writeFileSync(outPath, outputStr);
    
    console.log(`Results saved to outputs/JS_out/load_results.txt`);
}

main();

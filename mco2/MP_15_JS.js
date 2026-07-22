/********************
 ┃     Last names: Gutang, Wong, Tolentino, Degullado
 ┃     Language: JavaScript (Node.js)
 ┃     Paradigm(s): Multi-paradigm (Structured, Imperative, Functional)
 ┃     ********************/
/**
 * De La Salle University, Manila
 * College of Computer Studies
 * Department of Software Technology
 *
 * Course Code: CSADPRG (Advanced Programming)
 * Major Course Output #2: Data Analysis Pipeline for Flood Control Projects
 *
 * File Name: MP_15_JS.js
 * Group Number: 15
 *
 * Description:
 * This Node.js command-line application implements a Data Analysis Pipeline
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

const fs = require('fs');
const readline = require('readline');
const path = require('path');

// CONSTANTS
// CSV column indices (0-based)
const COL_MAIN_ISLAND = 0;
const COL_REGION = 1;
const COL_PROVINCE = 2;
const COL_TYPE_OF_WORK = 8;
const COL_FUNDING_YEAR = 9;
const COL_APPROVED_BUDGET = 11;
const COL_CONTRACT_COST = 12;
const COL_ACTUAL_COMPLETION = 13;
const COL_CONTRACTOR = 14;
const COL_START_DATE = 16;
const COL_PROJECT_LAT = 17;
const COL_PROJECT_LNG = 18;

const EXPECTED_COLUMNS = 22;

const OUT_DIR = 'JS_out';
const REPORT1_FILE = path.join(OUT_DIR, 'report1_regional_summary.csv');
const REPORT2_FILE = path.join(OUT_DIR, 'report2_contractor_ranking.csv');
const REPORT3_FILE = path.join(OUT_DIR, 'report3_annual_trends.csv');
const SUMMARY_FILE = path.join(OUT_DIR, 'summary.json');

// Application State
const state = {
    projects: [],
    total_raw_rows: 0,
    parse_errors: 0,
    data_loaded: false
};

// CSV PARSER
function parseCsvLine(line) {
    const fields = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
        const ch = line[i];
        if (inQuotes) {
            if (ch === '"') {
                if (i + 1 < line.length && line[i + 1] === '"') {
                    current += '"';
                    i++;
                } else {
                    inQuotes = false;
                }
            } else {
                current += ch;
            }
        } else {
            if (ch === '"') {
                inQuotes = true;
            } else if (ch === ',') {
                fields.push(current);
                current = '';
            } else {
                current += ch;
            }
        }
    }
    fields.push(current);
    return fields;
}

// DATE UTILITIES
function parseDate(s) {
    const parts = s.split('-');
    if (parts.length !== 3) return null;
    const year = parseInt(parts[0], 10);
    const month = parseInt(parts[1], 10);
    const day = parseInt(parts[2], 10);
    if (isNaN(year) || isNaN(month) || isNaN(day)) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return { year, month, day };
}

function toJulianDay(y, m, d) {
    const a = Math.floor((14 - m) / 12);
    const y_adj = y + 4800 - a;
    const m_adj = m + 12 * a - 3;
    return d + Math.floor((153 * m_adj + 2) / 5) + 365 * y_adj +
           Math.floor(y_adj / 4) - Math.floor(y_adj / 100) + Math.floor(y_adj / 400) - 32045;
}

function daysBetween(start, end) {
    return toJulianDay(end.year, end.month, end.day) - toJulianDay(start.year, start.month, start.day);
}

// FORMATTING HELPER
function formatNumber(value, decimals) {
    const isNegative = value < 0;
    value = Math.abs(value);
    
    // Fix to specified decimals
    let formatted = value.toFixed(decimals);
    let parts = formatted.split('.');
    let integerPart = parts[0];
    
    // Add commas
    let withCommas = '';
    for (let i = integerPart.length - 1, j = 0; i >= 0; i--, j++) {
        if (j > 0 && j % 3 === 0) {
            withCommas = ',' + withCommas;
        }
        withCommas = integerPart[i] + withCommas;
    }
    
    let result = (isNegative ? '-' : '') + withCommas;
    if (decimals > 0 && parts.length > 1) {
        result += '.' + parts[1];
    }
    return result;
}

// MATH HELPER
function getMedian(values) {
    if (values.length === 0) return 0.0;
    values.sort((a, b) => a - b);
    const half = Math.floor(values.length / 2);
    if (values.length % 2 === 0) {
        return (values[half - 1] + values[half]) / 2.0;
    }
    return values[half];
}

// CSV WRITER HELPER
function writeCsv(filename, headers, rows) {
    let content = headers.join(',') + '\n';
    
    for (const row of rows) {
        const quotedRow = row.map(field => {
            const fieldStr = String(field);
            if (fieldStr.includes(',') || fieldStr.includes('"') || fieldStr.includes('\n')) {
                return `"${fieldStr.replace(/"/g, '""')}"`;
            }
            return fieldStr;
        });
        content += quotedRow.join(',') + '\n';
    }
    
    fs.writeFileSync(filename, content);
}

// DATA INGESTION
async function loadData() {
    state.projects = [];
    state.total_raw_rows = 0;
    state.parse_errors = 0;

    const filepath = 'dpwh_flood_control_projects.csv';
    if (!fs.existsSync(filepath)) {
        console.log(`Error: Failed to open CSV file: ${filepath}`);
        return;
    }

    const fileStream = fs.createReadStream(filepath);
    const rl = readline.createInterface({
        input: fileStream,
        crlfDelay: Infinity
    });

    let isFirstLine = true;
    const rawProjects = [];

    for await (const line of rl) {
        if (isFirstLine) {
            isFirstLine = false;
            continue;
        }

        const trimmedLine = line.trimEnd();
        if (!trimmedLine) continue;

        state.total_raw_rows++;
        const fields = parseCsvLine(trimmedLine);

        if (fields.length < EXPECTED_COLUMNS) {
            state.parse_errors++;
            continue;
        }

        const fundingYear = parseInt(fields[COL_FUNDING_YEAR].trim(), 10);
        if (isNaN(fundingYear)) {
            state.parse_errors++;
            continue;
        }

        if (fundingYear < 2021 || fundingYear > 2023) {
            continue;
        }

        const approvedBudget = parseFloat(fields[COL_APPROVED_BUDGET].trim());
        const contractCost = parseFloat(fields[COL_CONTRACT_COST].trim());
        if (isNaN(approvedBudget) || isNaN(contractCost)) {
            state.parse_errors++;
            continue;
        }

        const startDate = parseDate(fields[COL_START_DATE].trim());
        const actualCompletionDate = parseDate(fields[COL_ACTUAL_COMPLETION].trim());
        if (!startDate || !actualCompletionDate) {
            state.parse_errors++;
            continue;
        }

        let projectLat = parseFloat(fields[COL_PROJECT_LAT].trim());
        let projectLng = parseFloat(fields[COL_PROJECT_LNG].trim());
        if (isNaN(projectLat)) projectLat = 0.0;
        if (isNaN(projectLng)) projectLng = 0.0;

        const costSavings = approvedBudget - contractCost;
        const completionDelayDays = daysBetween(startDate, actualCompletionDate);

        rawProjects.push({
            mainIsland: fields[COL_MAIN_ISLAND].trim(),
            region: fields[COL_REGION].trim(),
            province: fields[COL_PROVINCE].trim(),
            typeOfWork: fields[COL_TYPE_OF_WORK].trim(),
            fundingYear,
            approvedBudget,
            contractCost,
            startDate,
            actualCompletionDate,
            contractor: fields[COL_CONTRACTOR].trim(),
            projectLat,
            projectLng,
            costSavings,
            completionDelayDays
        });
    }

    imputeCoordinates(rawProjects);

    const filteredCount = rawProjects.length;
    state.projects = rawProjects;
    state.data_loaded = true;

    console.log(`Processing dataset... (${formatNumber(state.total_raw_rows, 0)} rows loaded, ${formatNumber(filteredCount, 0)} filtered for 2021-2023)`);
}

function imputeCoordinates(projects) {
    const provinceSums = {}; // province -> { latSum, lngSum, count }

    for (const p of projects) {
        if (p.projectLat !== 0.0 && p.projectLng !== 0.0) {
            if (!provinceSums[p.province]) {
                provinceSums[p.province] = { latSum: 0.0, lngSum: 0.0, count: 0 };
            }
            provinceSums[p.province].latSum += p.projectLat;
            provinceSums[p.province].lngSum += p.projectLng;
            provinceSums[p.province].count += 1;
        }
    }

    const provinceAvgs = {};
    for (const [prov, data] of Object.entries(provinceSums)) {
        provinceAvgs[prov] = {
            lat: data.latSum / data.count,
            lng: data.lngSum / data.count
        };
    }

    for (const p of projects) {
        if (p.projectLat === 0.0 || p.projectLng === 0.0) {
            if (provinceAvgs[p.province]) {
                p.projectLat = provinceAvgs[p.province].lat;
                p.projectLng = provinceAvgs[p.province].lng;
            }
        }
    }
}

// REPORTS
function generateAllReports() {
    if (!fs.existsSync(OUT_DIR)) {
        try {
            fs.mkdirSync(OUT_DIR, { recursive: true });
        } catch (e) {
            console.log(`Error: Failed to create output directory '${OUT_DIR}': ${e}`);
            return;
        }
    }

    console.log("Generating reports...");
    console.log("Outputs saved to individual files...\n");

    generateReport1(state.projects);
    console.log();
    generateReport2(state.projects);
    console.log();
    generateReport3(state.projects);
    console.log();
    generateSummary(state.projects);
}

function generateReport1(projects) {
    const groups = {}; // "Region|MainIsland" -> array of indices
    
    projects.forEach((p, i) => {
        const key = `${p.region}|${p.mainIsland}`;
        if (!groups[key]) groups[key] = [];
        groups[key].push(i);
    });

    const rows = [];
    
    for (const [key, indices] of Object.entries(groups)) {
        const [region, mainIsland] = key.split('|');
        const count = indices.length;

        let totalBudget = 0;
        const savings = [];
        let totalDelay = 0;
        let highDelayCount = 0;

        indices.forEach(i => {
            const p = projects[i];
            totalBudget += p.approvedBudget;
            savings.push(p.costSavings);
            totalDelay += p.completionDelayDays;
            if (p.completionDelayDays > 30) highDelayCount++;
        });

        const medianSavings = getMedian(savings);
        const avgDelay = totalDelay / count;
        const highDelayPct = (highDelayCount / count) * 100.0;
        
        let rawScore = avgDelay === 0.0 ? Number.MAX_VALUE : (medianSavings / avgDelay) * 100.0;
        
        rows.push({
            region, mainIsland, totalBudget, medianSavings, avgDelay, highDelayPct, rawScore
        });
    }

    const finiteScores = rows.map(r => r.rawScore).filter(s => isFinite(s));
    if (finiteScores.length > 0) {
        const minScore = Math.min(...finiteScores);
        const maxScore = Math.max(...finiteScores);
        
        rows.forEach(r => {
            if (!isFinite(r.rawScore)) r.rawScore = maxScore;
        });

        const range = maxScore - minScore;
        rows.forEach(r => {
            r.efficiencyScore = range === 0.0 ? 50.0 : ((r.rawScore - minScore) / range) * 100.0;
        });
    } else {
        rows.forEach(r => r.efficiencyScore = 0.0);
    }

    rows.sort((a, b) => b.efficiencyScore - a.efficiencyScore);

    const headers = ["Region", "MainIsland", "TotalBudget", "MedianSavings", "AvgDelay", "HighDelayPct", "EfficiencyScore"];
    const csvRows = rows.map(r => [
        r.region,
        r.mainIsland,
        formatNumber(r.totalBudget, 2),
        formatNumber(r.medianSavings, 2),
        formatNumber(r.avgDelay, 2),
        formatNumber(r.highDelayPct, 2),
        formatNumber(r.efficiencyScore, 2)
    ]);
    
    writeCsv(REPORT1_FILE, headers, csvRows);

    console.log("Report 1: Regional Flood Mitigation Efficiency Summary");
    console.log("Regional Flood Mitigation Efficiency Summary");
    console.log("(Filtered: 2021-2023 Projects)");
    console.log(`| ${"Region".padEnd(45)} | ${"MainIsland".padEnd(10)} | ${"TotalBudget".padStart(15)} | ${"MedianSavings".padStart(14)} | ${"AvgDelay".padStart(10)} | ${"HighDelayPct".padStart(12)} | ${"EfficiencyScore".padStart(15)} |`);
    
    rows.slice(0, 2).forEach(r => {
        console.log(`| ${r.region.padEnd(45)} | ${r.mainIsland.padEnd(10)} | ${formatNumber(r.totalBudget, 2).padStart(15)} | ${formatNumber(r.medianSavings, 2).padStart(14)} | ${formatNumber(r.avgDelay, 2).padStart(10)} | ${formatNumber(r.highDelayPct, 2).padStart(12)} | ${formatNumber(r.efficiencyScore, 2).padStart(15)} |`);
    });
    console.log(`(Full table exported to ${REPORT1_FILE})`);
}

function generateReport2(projects) {
    const groups = {}; // Contractor -> array of indices
    
    projects.forEach((p, i) => {
        if (!groups[p.contractor]) groups[p.contractor] = [];
        groups[p.contractor].push(i);
    });

    const rows = [];
    
    for (const [contractor, indices] of Object.entries(groups)) {
        if (indices.length < 5) continue;
        
        const count = indices.length;
        let totalCost = 0;
        let totalDelay = 0;
        let totalSavings = 0;
        
        indices.forEach(i => {
            const p = projects[i];
            totalCost += p.contractCost;
            totalDelay += p.completionDelayDays;
            totalSavings += p.costSavings;
        });
        
        const avgDelay = totalDelay / count;
        
        let reliabilityIndex = totalCost === 0.0 ? 0.0 : (1.0 - (avgDelay / 90.0)) * (totalSavings / totalCost) * 100.0;
        if (reliabilityIndex > 100.0) reliabilityIndex = 100.0;
        
        const riskFlag = reliabilityIndex < 50.0 ? "High Risk" : "Low Risk";
        
        rows.push({
            contractor, totalCost, count, avgDelay, totalSavings, reliabilityIndex, riskFlag
        });
    }

    rows.sort((a, b) => b.totalCost - a.totalCost);
    const top15 = rows.slice(0, 15);

    const headers = ["Rank", "Contractor", "TotalCost", "NumProjects", "AvgDelay", "TotalSavings", "ReliabilityIndex", "RiskFlag"];
    const csvRows = top15.map((r, i) => [
        (i + 1).toString(),
        r.contractor,
        formatNumber(r.totalCost, 2),
        r.count.toString(),
        formatNumber(r.avgDelay, 2),
        formatNumber(r.totalSavings, 2),
        formatNumber(r.reliabilityIndex, 2),
        r.riskFlag
    ]);
    
    writeCsv(REPORT2_FILE, headers, csvRows);

    console.log("Report 2: Top Contractors Performance Ranking");
    console.log("Top Contractors Performance Ranking");
    console.log("(Top 15 by TotalCost, >=5 Projects)");
    console.log(`| ${"Rank".padStart(4)} | ${"Contractor".padEnd(45)} | ${"TotalCost".padStart(18)} | ${"NumProjects".padStart(11)} | ${"AvgDelay".padStart(10)} | ${"TotalSavings".padStart(18)} | ${"ReliabilityIndex".padStart(16)} | ${"RiskFlag".padStart(10)} |`);
    
    top15.slice(0, 2).forEach((r, i) => {
        // Truncate contractor string if too long for console display consistency
        const cont = r.contractor.length > 45 ? r.contractor.substring(0, 42) + '...' : r.contractor;
        console.log(`| ${String(i + 1).padStart(4)} | ${cont.padEnd(45)} | ${formatNumber(r.totalCost, 2).padStart(18)} | ${String(r.count).padStart(11)} | ${formatNumber(r.avgDelay, 2).padStart(10)} | ${formatNumber(r.totalSavings, 2).padStart(18)} | ${formatNumber(r.reliabilityIndex, 2).padStart(16)} | ${r.riskFlag.padStart(10)} |`);
    });
    console.log(`(Full table exported to ${REPORT2_FILE})`);
}

function generateReport3(projects) {
    const groups = {}; // "FundingYear|TypeOfWork" -> array of indices
    
    projects.forEach((p, i) => {
        const key = `${p.fundingYear}|${p.typeOfWork}`;
        if (!groups[key]) groups[key] = [];
        groups[key].push(i);
    });

    const avgSavingsMap = {};
    for (const [key, indices] of Object.entries(groups)) {
        const [yearStr, typeOfWork] = key.split('|');
        const year = parseInt(yearStr, 10);
        let totalSavings = 0;
        indices.forEach(i => totalSavings += projects[i].costSavings);
        avgSavingsMap[`${year}|${typeOfWork}`] = totalSavings / indices.length;
    }

    const rows = [];
    
    for (const [key, indices] of Object.entries(groups)) {
        const [yearStr, typeOfWork] = key.split('|');
        const year = parseInt(yearStr, 10);
        const totalProjects = indices.length;
        
        let totalSavings = 0;
        let overrunCount = 0;
        
        indices.forEach(i => {
            const p = projects[i];
            totalSavings += p.costSavings;
            if (p.costSavings < 0.0) overrunCount++;
        });
        
        const avgSavings = totalSavings / totalProjects;
        const overrunRate = (overrunCount / totalProjects) * 100.0;
        
        let yoyChange = 0.0;
        if (year !== 2021) {
            const prevYear = year - 1;
            const prevAvg = avgSavingsMap[`${prevYear}|${typeOfWork}`];
            if (prevAvg !== undefined && Math.abs(prevAvg) > 0.0) {
                yoyChange = ((avgSavings - prevAvg) / Math.abs(prevAvg)) * 100.0;
            }
        }
        
        rows.push({
            typeOfWork, year, totalProjects, avgSavings, overrunRate, yoyChange
        });
    }

    rows.sort((a, b) => {
        if (a.year !== b.year) return a.year - b.year;
        return b.avgSavings - a.avgSavings;
    });

    const headers = ["TypeOfWork", "FundingYear", "TotalProjects", "AvgSavings", "OverrunRate", "YoYChange"];
    const csvRows = rows.map(r => [
        r.typeOfWork,
        r.year.toString(),
        r.totalProjects.toString(),
        formatNumber(r.avgSavings, 2),
        formatNumber(r.overrunRate, 2),
        formatNumber(r.yoyChange, 2)
    ]);
    
    writeCsv(REPORT3_FILE, headers, csvRows);

    console.log("Report 3: Annual Project Type Cost Overrun Trends");
    console.log("Annual Project Type Cost Overrun Trends");
    console.log("(Grouped by FundingYear and TypeOfWork)");
    console.log(`| ${"TypeOfWork".padEnd(50)} | ${"FundingYear".padStart(11)} | ${"TotalProjects".padStart(13)} | ${"AvgSavings".padStart(15)} | ${"OverrunRate".padStart(11)} | ${"YoYChange".padStart(11)} |`);
    
    rows.slice(0, 3).forEach(r => {
        const tw = r.typeOfWork.length > 50 ? r.typeOfWork.substring(0, 47) + '...' : r.typeOfWork;
        console.log(`| ${tw.padEnd(50)} | ${String(r.year).padStart(11)} | ${String(r.totalProjects).padStart(13)} | ${formatNumber(r.avgSavings, 2).padStart(15)} | ${formatNumber(r.overrunRate, 2).padStart(11)} | ${formatNumber(r.yoyChange, 2).padStart(11)} |`);
    });
    console.log(`(Full table exported to ${REPORT3_FILE})`);
}

function generateSummary(projects) {
    const totalProjects = projects.length;
    
    const contractors = new Set();
    const provinces = new Set();
    let totalDelay = 0;
    let totalSavings = 0;
    
    projects.forEach(p => {
        contractors.add(p.contractor);
        provinces.add(p.province);
        totalDelay += p.completionDelayDays;
        totalSavings += p.costSavings;
    });
    
    const globalAvgDelay = totalProjects > 0 ? totalDelay / totalProjects : 0.0;
    
    const summaryData = {
        total_projects: totalProjects,
        total_contractors: contractors.size,
        total_provinces: provinces.size,
        global_avg_delay: parseFloat(globalAvgDelay.toFixed(2)),
        total_savings: parseFloat(totalSavings.toFixed(2))
    };
    
    fs.writeFileSync(SUMMARY_FILE, JSON.stringify(summaryData, null, 2));

    console.log(`Summary Stats (${SUMMARY_FILE}):`);
    console.log(`{"total_projects": ${summaryData.total_projects}, "total_contractors": ${summaryData.total_contractors}, "total_provinces": ${summaryData.total_provinces}, "global_avg_delay": ${summaryData.global_avg_delay.toFixed(2)}, "total_savings": ${summaryData.total_savings.toFixed(2)}}`);
}

// MAIN MENU
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function promptMenu() {
    console.log("\nSelect Language Implementation:");
    console.log("[1] Load the file");
    console.log("[2] Generate Reports");
    console.log("[0] Exit");
    rl.question("Enter choice: ", handleInput);
}

async function handleInput(answer) {
    const choice = answer.trim();
    if (choice === '0') {
        console.log("\nExiting program. Goodbye!");
        rl.close();
        return;
    } else if (choice === '1') {
        await loadData();
        promptMenu();
    } else if (choice === '2') {
        if (!state.data_loaded) {
            console.log("Error: Please load the file first (option 1).");
            promptMenu();
        } else {
            generateAllReports();
            promptBack();
        }
    } else {
        console.log("Invalid option. Please enter 0, 1, or 2.");
        promptMenu();
    }
}

function promptBack() {
    rl.question("Back to Report Selection (Y/N): ", (answer) => {
        const choice = answer.trim().toUpperCase();
        if (choice === 'Y') {
            promptMenu();
        } else if (choice === 'N') {
            console.log("Exiting program. Goodbye!");
            rl.close();
        } else {
            console.log("Invalid input. Please enter Y or N.");
            promptBack();
        }
    });
}

// Start Program
promptMenu();

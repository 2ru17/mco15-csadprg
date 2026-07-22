/********************
 ┃     Last names: Gutang, Wong, Tolentino, Degullado
 ┃     Language: Rust
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
 * File Name: MP_15_Rust.rs
 * Group Number: 15
 *
 * Description:
 * This Rust command-line application implements a Data Analysis Pipeline
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

use std::io::{self, Write, BufRead, BufReader};
use std::fs::File;
use std::collections::{HashMap, HashSet};

// CONSTANTS
// CSV column indices (0-based).
const COL_MAIN_ISLAND: usize = 0;
const COL_REGION: usize = 1;
const COL_PROVINCE: usize = 2;
const COL_TYPE_OF_WORK: usize = 8;
const COL_FUNDING_YEAR: usize = 9;
const COL_APPROVED_BUDGET: usize = 11;
const COL_CONTRACT_COST: usize = 12;
const COL_ACTUAL_COMPLETION: usize = 13;
const COL_CONTRACTOR: usize = 14;
const COL_START_DATE: usize = 16;
const COL_PROJECT_LAT: usize = 17;
const COL_PROJECT_LNG: usize = 18;

const EXPECTED_COLUMNS: usize = 22;

const OUT_DIR: &str = "Rust_out";
const REPORT1_FILE: &str = "Rust_out/report1_regional_summary.csv";
const REPORT2_FILE: &str = "Rust_out/report2_contractor_ranking.csv";
const REPORT3_FILE: &str = "Rust_out/report3_annual_trends.csv";
const SUMMARY_FILE: &str = "Rust_out/summary.json";

// Cleaned, validated project row. Financial values in PHP (f64), dates as tuples.
struct Project {
    main_island: String,
    region: String,
    province: String,
    type_of_work: String,
    funding_year: u32,
    approved_budget: f64,
    contract_cost: f64,
    start_date: (i32, u32, u32),
    actual_completion_date: (i32, u32, u32),
    contractor: String,
    project_lat: f64,
    project_lng: f64,
    cost_savings: f64,          // ApprovedBudget - ContractCost
    completion_delay_days: i64, // Days between StartDate and ActualCompletionDate
}

struct AppState {
    projects: Vec<Project>,
    total_raw_rows: usize,
    parse_errors: usize,
    data_loaded: bool,
}

// MAIN
fn main() {
    let mut state = AppState {
        projects: Vec::new(),
        total_raw_rows: 0,
        parse_errors: 0,
        data_loaded: false,
    };

    loop {
        println!("\nSelect Language Implementation:");
        println!("[1] Load the file");
        println!("[2] Generate Reports");
        println!("[0] Exit");
        prompt("Enter choice: ");

        let input = read_input();
        match input.as_str() {
            "0" => {
                println!("\nExiting program. Goodbye!");
                break;
            }
            "1" => load_data(&mut state),
            "2" => {
                if !state.data_loaded {
                    println!("Error: Please load the file first (option 1).");
                    continue;
                }
                generate_all_reports(&state);
            }
            _ => println!("Invalid option. Please enter 0, 1, or 2."),
        }
    }
}

// HELPER - Reads trimmed input from stdin.
fn read_input() -> String {
    let mut input = String::new();
    io::stdin().read_line(&mut input).unwrap_or_default();
    input.trim().to_string()
}

// HELPER - Prints prompt text without newline.
fn prompt(text: &str) {
    print!("{}", text);
    io::stdout().flush().unwrap();
}

// CSV PARSER - Parses a line respecting RFC 4180 quoting rules.
fn parse_csv_line(line: &str) -> Vec<String> {
    let mut fields: Vec<String> = Vec::new();
    let mut current = String::new();
    let mut in_quotes = false;
    let chars: Vec<char> = line.chars().collect();
    let len = chars.len();
    let mut i = 0;

    while i < len {
        let ch = chars[i];
        if in_quotes {
            if ch == '"' {
                if i + 1 < len && chars[i + 1] == '"' {
                    current.push('"');
                    i += 2;
                } else {
                    in_quotes = false;
                    i += 1;
                }
            } else {
                current.push(ch);
                i += 1;
            }
        } else {
            if ch == '"' {
                in_quotes = true;
                i += 1;
            } else if ch == ',' {
                fields.push(current.clone());
                current.clear();
                i += 1;
            } else {
                current.push(ch);
                i += 1;
            }
        }
    }
    fields.push(current);
    fields
}

// Parses a "YYYY-MM-DD" string into a (year, month, day) tuple.
fn parse_date(s: &str) -> Option<(i32, u32, u32)> {
    let parts: Vec<&str> = s.split('-').collect();
    if parts.len() != 3 {
        return None;
    }
    let year = parts[0].parse::<i32>().ok()?;
    let month = parts[1].parse::<u32>().ok()?;
    let day = parts[2].parse::<u32>().ok()?;
    if month < 1 || month > 12 || day < 1 || day > 31 {
        return None;
    }
    Some((year, month, day))
}

// Converts a date to a Julian Day Number for day-difference computation.
fn to_julian_day(y: i32, m: u32, d: u32) -> i64 {
    let a = (14 - m as i64) / 12;
    let y_adj = y as i64 + 4800 - a;
    let m_adj = m as i64 + 12 * a - 3;
    d as i64 + (153 * m_adj + 2) / 5 + 365 * y_adj
        + y_adj / 4 - y_adj / 100 + y_adj / 400 - 32045
}

// Computes the number of days between two dates.
fn days_between(start: (i32, u32, u32), end: (i32, u32, u32)) -> i64 {
    to_julian_day(end.0, end.1, end.2) - to_julian_day(start.0, start.1, start.2)
}

// DATA INGESTION
// Reads the CSV, validates, filters 2021-2023, computes derived fields.
fn load_data(state: &mut AppState) {

    state.projects.clear();
    state.total_raw_rows = 0;
    state.parse_errors = 0;


    let file = match File::open("dpwh_flood_control_projects.csv") {
        Ok(f) => f,
        Err(e) => {
            println!("Error: Failed to open CSV file: {}", e);
            return;
        }
    };
    let reader = BufReader::new(file);
    let mut lines = reader.lines();


    if lines.next().is_none() {
        println!("Error: CSV file is empty.");
        return;
    }

    let mut raw_projects: Vec<Project> = Vec::new();

    for line_result in lines {
        state.total_raw_rows += 1;

        let line = match line_result {
            Ok(l) => l.trim_end_matches('\r').to_string(),
            Err(_) => {
                state.parse_errors += 1;
                continue;
            }
        };

        if line.is_empty() {
            continue;
        }

        let fields = parse_csv_line(&line);


        if fields.len() < EXPECTED_COLUMNS {
            state.parse_errors += 1;
            continue;
        }

        // Filter for 2021-2023.
        let funding_year = match fields[COL_FUNDING_YEAR].trim().parse::<u32>() {
            Ok(y) => y,
            Err(_) => {
                state.parse_errors += 1;
                continue;
            }
        };
        if funding_year < 2021 || funding_year > 2023 {
            continue;
        }

        // Convert financial fields to floats.
        let approved_budget = match fields[COL_APPROVED_BUDGET].trim().parse::<f64>() {
            Ok(v) => v,
            Err(_) => {
                state.parse_errors += 1;
                continue;
            }
        };
        let contract_cost = match fields[COL_CONTRACT_COST].trim().parse::<f64>() {
            Ok(v) => v,
            Err(_) => {
                state.parse_errors += 1;
                continue;
            }
        };

        // Parse dates.
        let start_date = match parse_date(fields[COL_START_DATE].trim()) {
            Some(d) => d,
            None => {
                state.parse_errors += 1;
                continue;
            }
        };
        let actual_completion_date = match parse_date(fields[COL_ACTUAL_COMPLETION].trim()) {
            Some(d) => d,
            None => {
                state.parse_errors += 1;
                continue;
            }
        };


        let project_lat = fields[COL_PROJECT_LAT].trim().parse::<f64>().unwrap_or(0.0);
        let project_lng = fields[COL_PROJECT_LNG].trim().parse::<f64>().unwrap_or(0.0);

        // Compute derived fields.
        let cost_savings = approved_budget - contract_cost;
        let completion_delay_days = days_between(start_date, actual_completion_date);

        raw_projects.push(Project {
            main_island: fields[COL_MAIN_ISLAND].trim().to_string(),
            region: fields[COL_REGION].trim().to_string(),
            province: fields[COL_PROVINCE].trim().to_string(),
            type_of_work: fields[COL_TYPE_OF_WORK].trim().to_string(),
            funding_year,
            approved_budget,
            contract_cost,
            start_date,
            actual_completion_date,
            contractor: fields[COL_CONTRACTOR].trim().to_string(),
            project_lat,
            project_lng,
            cost_savings,
            completion_delay_days,
        });
    }

    // Impute missing lat/long via provincial averages.
    impute_coordinates(&mut raw_projects);

    let filtered_count = raw_projects.len();
    state.projects = raw_projects;
    state.data_loaded = true;


    println!(
        "Processing dataset... ({} rows loaded, {} filtered for 2021-2023)",
        format_number(state.total_raw_rows as f64, 0),
        format_number(filtered_count as f64, 0)
    );
}

// Imputes missing coordinates using provincial averages.
fn impute_coordinates(projects: &mut Vec<Project>) {

    let mut province_sums: HashMap<String, (f64, f64, usize)> = HashMap::new();
    for p in projects.iter() {
        if p.project_lat != 0.0 && p.project_lng != 0.0 {
            let entry = province_sums
                .entry(p.province.clone())
                .or_insert((0.0, 0.0, 0));
            entry.0 += p.project_lat;
            entry.1 += p.project_lng;
            entry.2 += 1;
        }
    }

    let province_avgs: HashMap<String, (f64, f64)> = province_sums
        .into_iter()
        .map(|(k, (lat, lng, count))| (k, (lat / count as f64, lng / count as f64)))
        .collect();


    for p in projects.iter_mut() {
        if p.project_lat == 0.0 || p.project_lng == 0.0 {
            if let Some(&(avg_lat, avg_lng)) = province_avgs.get(&p.province) {
                p.project_lat = avg_lat;
                p.project_lng = avg_lng;
            }
        }
    }
}

// REPORT GENERATION
fn generate_all_reports(state: &AppState) {
    if let Err(e) = std::fs::create_dir_all(OUT_DIR) {
        println!("Error: Failed to create output directory '{}': {}", OUT_DIR, e);
        return;
    }

    println!("Generating reports...");
    println!("Outputs saved to individual files...");

    generate_report1(&state.projects);
    println!();
    generate_report2(&state.projects);
    println!();
    generate_report3(&state.projects);
    println!();
    generate_summary(&state.projects);


    loop {
        prompt("Back to Report Selection (Y/N): ");
        let input = read_input().to_uppercase();
        match input.as_str() {
            "Y" => break,
            "N" => std::process::exit(0),
            _ => println!("Invalid input. Please enter Y or N."),
        }
    }
}

// Report 1: Regional Flood Mitigation Efficiency Summary.
fn generate_report1(projects: &[Project]) {

    let mut groups: HashMap<(String, String), Vec<usize>> = HashMap::new();
    for (i, p) in projects.iter().enumerate() {
        let key = (p.region.clone(), p.main_island.clone());
        groups.entry(key).or_default().push(i);
    }


    let mut rows: Vec<(String, String, f64, f64, f64, f64, f64)> = Vec::new();

    for ((region, main_island), indices) in &groups {
        let count = indices.len() as f64;


        let total_budget: f64 = indices.iter().map(|&i| projects[i].approved_budget).sum();


        let mut savings: Vec<f64> = indices.iter().map(|&i| projects[i].cost_savings).collect();
        let median_savings = median(&mut savings);


        let total_delay: f64 = indices
            .iter()
            .map(|&i| projects[i].completion_delay_days as f64)
            .sum();
        let avg_delay = total_delay / count;


        let high_delay_count = indices
            .iter()
            .filter(|&&i| projects[i].completion_delay_days > 30)
            .count();
        let high_delay_pct = high_delay_count as f64 / count * 100.0;


        let raw_score = if avg_delay == 0.0 {
            f64::MAX
        } else {
            (median_savings / avg_delay) * 100.0
        };

        rows.push((
            region.clone(),
            main_island.clone(),
            total_budget,
            median_savings,
            avg_delay,
            high_delay_pct,
            raw_score,
        ));
    }

    // Min-max normalize Efficiency Scores to 0-100.
    let finite_scores: Vec<f64> = rows
        .iter()
        .map(|r| r.6)
        .filter(|s| s.is_finite())
        .collect();

    if !finite_scores.is_empty() {
        let min_score = finite_scores.iter().cloned().fold(f64::INFINITY, f64::min);
        let max_score = finite_scores
            .iter()
            .cloned()
            .fold(f64::NEG_INFINITY, f64::max);


        for row in &mut rows {
            if !row.6.is_finite() {
                row.6 = max_score;
            }
        }

        let range = max_score - min_score;
        for row in &mut rows {
            row.6 = if range == 0.0 {
                50.0
            } else {
                ((row.6 - min_score) / range) * 100.0
            };
        }
    }


    rows.sort_by(|a, b| b.6.partial_cmp(&a.6).unwrap_or(std::cmp::Ordering::Equal));


    let headers = ["Region", "MainIsland", "TotalBudget", "MedianSavings", "AvgDelay", "HighDelayPct", "EfficiencyScore"];
    let csv_rows: Vec<Vec<String>> = rows
        .iter()
        .map(|r| {
            vec![
                r.0.clone(),
                r.1.clone(),
                format_number(r.2, 2),
                format_number(r.3, 2),
                format_number(r.4, 2),
                format_number(r.5, 2),
                format_number(r.6, 2),
            ]
        })
        .collect();
    write_csv(REPORT1_FILE, &headers, &csv_rows);


    println!("\nReport 1: Regional Flood Mitigation Efficiency Summary");
    println!("Regional Flood Mitigation Efficiency Summary");
    println!("(Filtered: 2021-2023 Projects)");
    println!(
        "| {:<45} | {:<10} | {:>15} | {:>14} | {:>10} | {:>12} | {:>15} |",
        "Region", "MainIsland", "TotalBudget", "MedianSavings", "AvgDelay", "HighDelayPct", "EfficiencyScore"
    );
    for row in rows.iter().take(2) {
        println!(
            "| {:<45} | {:<10} | {:>15} | {:>14} | {:>10} | {:>12} | {:>15} |",
            row.0,
            row.1,
            format_number(row.2, 2),
            format_number(row.3, 2),
            format_number(row.4, 2),
            format_number(row.5, 2),
            format_number(row.6, 2),
        );
    }
    println!("(Full table exported to {})", REPORT1_FILE);
}

// Report 2: Top Contractors Performance Ranking.
fn generate_report2(projects: &[Project]) {

    let mut groups: HashMap<String, Vec<usize>> = HashMap::new();
    for (i, p) in projects.iter().enumerate() {
        groups.entry(p.contractor.clone()).or_default().push(i);
    }


    let mut rows: Vec<(String, f64, usize, f64, f64, f64, String)> = Vec::new();

    for (contractor, indices) in &groups {
        if indices.len() < 5 {
            continue;
        }

        let count = indices.len();
        let total_cost: f64 = indices.iter().map(|&i| projects[i].contract_cost).sum();
        let avg_delay: f64 = indices
            .iter()
            .map(|&i| projects[i].completion_delay_days as f64)
            .sum::<f64>()
            / count as f64;
        let total_savings: f64 = indices.iter().map(|&i| projects[i].cost_savings).sum();


        let mut reliability_index = if total_cost == 0.0 {
            0.0
        } else {
            (1.0 - (avg_delay / 90.0)) * (total_savings / total_cost) * 100.0
        };

        if reliability_index > 100.0 {
            reliability_index = 100.0;
        }

        let risk_flag = if reliability_index < 50.0 {
            "High Risk".to_string()
        } else {
            "Low Risk".to_string()
        };

        rows.push((
            contractor.clone(),
            total_cost,
            count,
            avg_delay,
            total_savings,
            reliability_index,
            risk_flag,
        ));
    }


    rows.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
    rows.truncate(15);


    let headers = ["Rank", "Contractor", "TotalCost", "NumProjects", "AvgDelay", "TotalSavings", "ReliabilityIndex", "RiskFlag"];
    let csv_rows: Vec<Vec<String>> = rows
        .iter()
        .enumerate()
        .map(|(i, r)| {
            vec![
                (i + 1).to_string(),
                r.0.clone(),
                format_number(r.1, 2),
                r.2.to_string(),
                format_number(r.3, 2),
                format_number(r.4, 2),
                format_number(r.5, 2),
                r.6.clone(),
            ]
        })
        .collect();
    write_csv(REPORT2_FILE, &headers, &csv_rows);


    println!("Report 2: Top Contractors Performance Ranking");
    println!("Top Contractors Performance Ranking");
    println!("(Top 15 by TotalCost, >=5 Projects)");
    println!(
        "| {:>4} | {:<45} | {:>18} | {:>11} | {:>10} | {:>18} | {:>16} | {:>10} |",
        "Rank", "Contractor", "TotalCost", "NumProjects", "AvgDelay", "TotalSavings", "ReliabilityIndex", "RiskFlag"
    );
    for (i, row) in rows.iter().take(2).enumerate() {
        println!(
            "| {:>4} | {:<45} | {:>18} | {:>11} | {:>10} | {:>18} | {:>16} | {:>10} |",
            i + 1,
            row.0,
            format_number(row.1, 2),
            row.2,
            format_number(row.3, 2),
            format_number(row.4, 2),
            format_number(row.5, 2),
            row.6,
        );
    }
    println!("(Full table exported to {})", REPORT2_FILE);
}

// Report 3: Annual Project Type Cost Overrun Trends.
fn generate_report3(projects: &[Project]) {

    let mut groups: HashMap<(u32, String), Vec<usize>> = HashMap::new();
    for (i, p) in projects.iter().enumerate() {
        let key = (p.funding_year, p.type_of_work.clone());
        groups.entry(key).or_default().push(i);
    }


    let mut avg_savings_map: HashMap<(String, u32), f64> = HashMap::new();
    for ((year, type_of_work), indices) in &groups {
        let avg_savings: f64 = indices.iter().map(|&i| projects[i].cost_savings).sum::<f64>()
            / indices.len() as f64;
        avg_savings_map.insert((type_of_work.clone(), *year), avg_savings);
    }


    let mut rows: Vec<(String, u32, usize, f64, f64, f64)> = Vec::new();

    for ((year, type_of_work), indices) in &groups {
        let total_projects = indices.len();
        let avg_savings: f64 =
            indices.iter().map(|&i| projects[i].cost_savings).sum::<f64>() / total_projects as f64;
        let overrun_count = indices
            .iter()
            .filter(|&&i| projects[i].cost_savings < 0.0)
            .count();
        let overrun_rate = overrun_count as f64 / total_projects as f64 * 100.0;

        // YoY change: 2021 is baseline, later years compare to prior year.
        let yoy_change = if *year == 2021 {
            0.0
        } else {
            let prev_year = year - 1;
            match avg_savings_map.get(&(type_of_work.clone(), prev_year)) {
                Some(&prev_avg) if prev_avg.abs() > 0.0 => {
                    ((avg_savings - prev_avg) / prev_avg.abs()) * 100.0
                }
                _ => 0.0,
            }
        };

        rows.push((
            type_of_work.clone(),
            *year,
            total_projects,
            avg_savings,
            overrun_rate,
            yoy_change,
        ));
    }


    rows.sort_by(|a, b| {
        a.1.cmp(&b.1)
            .then(b.3.partial_cmp(&a.3).unwrap_or(std::cmp::Ordering::Equal))
    });


    let headers = ["TypeOfWork", "FundingYear", "TotalProjects", "AvgSavings", "OverrunRate", "YoYChange"];
    let csv_rows: Vec<Vec<String>> = rows
        .iter()
        .map(|r| {
            vec![
                r.0.clone(),
                r.1.to_string(),
                r.2.to_string(),
                format_number(r.3, 2),
                format_number(r.4, 2),
                format_number(r.5, 2),
            ]
        })
        .collect();
    write_csv(REPORT3_FILE, &headers, &csv_rows);

    // Console preview.
    println!("Report 3: Annual Project Type Cost Overrun Trends");
    println!("Annual Project Type Cost Overrun Trends");
    println!("(Grouped by FundingYear and TypeOfWork)");
    println!(
        "| {:<50} | {:>11} | {:>13} | {:>15} | {:>11} | {:>11} |",
        "TypeOfWork", "FundingYear", "TotalProjects", "AvgSavings", "OverrunRate", "YoYChange"
    );
    for row in rows.iter().take(3) {
        println!(
            "| {:<50} | {:>11} | {:>13} | {:>15} | {:>11} | {:>11} |",
            row.0,
            row.1,
            row.2,
            format_number(row.3, 2),
            format_number(row.4, 2),
            format_number(row.5, 2),
        );
    }
    println!("(Full table exported to {})", REPORT3_FILE);
}

// Summary JSON — aggregates key stats across all reports.
fn generate_summary(projects: &[Project]) {
    let total_projects = projects.len();

    let unique_contractors: HashSet<&str> =
        projects.iter().map(|p| p.contractor.as_str()).collect();

    let unique_provinces: HashSet<&str> = projects.iter().map(|p| p.province.as_str()).collect();

    let global_avg_delay = if total_projects > 0 {
        projects
            .iter()
            .map(|p| p.completion_delay_days as f64)
            .sum::<f64>()
            / total_projects as f64
    } else {
        0.0
    };

    let total_savings: f64 = projects.iter().map(|p| p.cost_savings).sum();


    let global_avg_delay_rounded = (global_avg_delay * 100.0).round() / 100.0;
    let total_savings_rounded = (total_savings * 100.0).round() / 100.0;


    let json = format!(
        "{{\n  \"total_projects\": {},\n  \"total_contractors\": {},\n  \"total_provinces\": {},\n  \"global_avg_delay\": {:.2},\n  \"total_savings\": {:.2}\n}}",
        total_projects,
        unique_contractors.len(),
        unique_provinces.len(),
        global_avg_delay_rounded,
        total_savings_rounded
    );


    match std::fs::write(SUMMARY_FILE, &json) {
        Ok(_) => {}
        Err(e) => {
            println!("Error: Failed to write {}: {}", SUMMARY_FILE, e);
            return;
        }
    }


    println!("Summary Stats ({}):", SUMMARY_FILE);
    println!(
        "{{\"total_projects\": {}, \"total_contractors\": {}, \"total_provinces\": {}, \"global_avg_delay\": {:.2}, \"total_savings\": {:.2}}}",
        total_projects,
        unique_contractors.len(),
        unique_provinces.len(),
        global_avg_delay_rounded,
        total_savings_rounded
    );
}

// Writes report data to a CSV file with proper quoting.
fn write_csv(filename: &str, headers: &[&str], rows: &[Vec<String>]) {
    let file = match File::create(filename) {
        Ok(f) => f,
        Err(e) => {
            println!("Error: Failed to create {}: {}", filename, e);
            return;
        }
    };
    let mut writer = io::BufWriter::new(file);


    writeln!(writer, "{}", headers.join(",")).unwrap();


    for row in rows {
        let quoted_fields: Vec<String> = row
            .iter()
            .map(|field| {
                if field.contains(',') || field.contains('"') || field.contains('\n') {

                    format!("\"{}\"", field.replace('"', "\"\""))
                } else {
                    field.clone()
                }
            })
            .collect();
        writeln!(writer, "{}", quoted_fields.join(",")).unwrap();
    }

    writer.flush().unwrap();
}

// Computes the median of a Vec<f64>.
fn median(values: &mut Vec<f64>) -> f64 {
    if values.is_empty() {
        return 0.0;
    }
    values.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
    let n = values.len();
    if n % 2 == 0 {
        (values[n / 2 - 1] + values[n / 2]) / 2.0
    } else {
        values[n / 2]
    }
}

// Formats a float with comma thousands separators and N decimal places.
fn format_number(value: f64, decimals: usize) -> String {
    let formatted = format!("{:.prec$}", value, prec = decimals);
    let parts: Vec<&str> = formatted.split('.').collect();
    let integer_part = parts[0];

    let negative = integer_part.starts_with('-');
    let digits: &str = if negative {
        &integer_part[1..]
    } else {
        integer_part
    };


    let mut result = String::new();
    for (i, ch) in digits.chars().rev().enumerate() {
        if i > 0 && i % 3 == 0 {
            result.push(',');
        }
        result.push(ch);
    }
    let int_str: String = result.chars().rev().collect();

    if decimals > 0 && parts.len() > 1 {
        format!(
            "{}{}.{}",
            if negative { "-" } else { "" },
            int_str,
            parts[1]
        )
    } else {
        format!("{}{}", if negative { "-" } else { "" }, int_str)
    }
}

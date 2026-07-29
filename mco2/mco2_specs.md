# MAJOR COURSE OUTPUT #2: DATA ANALYSIS PIPELINE FOR FLOOD CONTROL PROJECTS

**DE LA SALLE UNIVERSITY MANILA**
College of Computer Studies
DEPARTMENT OF SOFTWARE TECHNOLOGY

---

## INTRODUCTION
This major course output presents the development of a Data Analysis Pipeline that demonstrates fundamental concepts in programming paradigms and data processing. The application is designed to ingest a real-world CSV dataset on DPWH flood control projects, perform preprocessing, and generate three tabular reports to facilitate analysis of infrastructure trends, financial efficiencies, and performance metrics. A key component of this project is the use of libraries or packages to process the data.

## FUNCTIONAL SPECIFICATIONS

### MANAGING DATA INGESTION

| REQ # | DETAILS |
| :--- | :--- |
| **REQ-0001** | Provision to read the CSV file `dpwh_flood_control_projects.csv` containing 9,800+ rows of flood mitigation projects. |
| **REQ-0002** | Provision to perform basic validation: Log total row count and detect/parse errors (e.g., invalid dates or missing values). |
| **REQ-0003** | Provision to filter projects from 2021-2023 (exclude 2024 entries for analysis stability). |
| **REQ-0004** | Provision to compute derived fields:<br>• `CostSavings = ApprovedBudgetForContract - ContractCost`<br>• `CompletionDelayDays = days between StartDate and ActualCompletionDate` (positive if delayed). |
| **REQ-0005** | Provision to clean data uniformly:<br>• Convert financial fields to floats (PHP)<br>• Parse dates or use date data types when possible<br>• Impute or filter incomplete rows (e.g., null lat/long via provincial averages). |

### MANAGING REPORT GENERATION

| REQ # | DETAILS |
| :--- | :--- |
| **REQ-0006** | Provision to generate **Report 1: Regional Flood Mitigation Efficiency Summary**. This table will have the following columns:<br>• aggregate total `ApprovedBudgetForContract`<br>• median `CostSavings`<br>• average `CompletionDelayDays`<br>• percentage of projects with delays >30 days by `Region` and `MainIsland`.<br><br>Include **"Efficiency Score"**, which is computed as: `(median savings / average delay) * 100`, normalized to 0-100.<br>Output as sorted CSV (descending by `EfficiencyScore`). |
| **REQ-0007** | Provision to generate **Report 2: Top Contractors Performance Ranking**. Rank top 15 Contractors by total `ContractCost` (descending, filter >= 5 projects), with columns for the following:<br>• number of projects<br>• average `CompletionDelayDays`<br>• total `CostSavings`<br>• **"Reliability Index"**, which is computed as `(1 - (avg delay / 90)) * (total savings / total cost) * 100` (capped at 100). Flag <50 as "High Risk".<br><br>Output as sorted CSV. |
| **REQ-0008** | Provision to generate **Report 3: Annual Project Type Cost Overrun Trends**. Group by `FundingYear` and `TypeOfWork`, computing the following:<br>• total projects<br>• average `CostSavings` (negative if overrun)<br>• overrun rate (% with negative savings)<br>• year-over-year % change in average savings (2021 baseline).<br><br>Output as sorted CSV (ascending by year, descending by `AvgSavings`). |
| **REQ-0009** | Provision to produce a `summary.json` aggregating key stats across reports (e.g., total number of projects, total number of contractors, total provinces with projects, global average delay, total savings). |

## TECHNICAL SPECIFICATION

| REQ # | DETAILS |
| :--- | :--- |
| **REQ-0010** | Application should be developed / built on the following programming languages: R, JavaScript, Kotlin, Rust. |
| **REQ-0011** | Provision for output standardization: Generate identical CSV files for each report (comma-formatted numbers, rounded to 2 decimals); one run command per language (e.g., `Rscript main.R`, `node index.js`). |

## SAMPLE OUTPUT

```text
Select Language Implementation:
[1] Load the file
[2] Generate Reports
Enter choice: 1
Processing dataset... (9,852 rows loaded, 9,234 filtered for 2021-2023)

Select Language Implementation:
[1] Load the file
[2] Generate Reports
Enter choice: 2
Generating reports...
Outputs saved to individual files...

Report 1: Regional Flood Mitigation Efficiency Summary
Regional Flood Mitigation Efficiency Summary
(Filtered: 2021-2023 Projects)
| Region | MainIsland | TotalBudget | MedianSavings | AvgDelay | HighDelayPct | EfficiencyScore |
| Cordillera Administrative Region | Luzon | 1,234,567,890 | 1,234.56 | 25.3 | 15.20 | 48.75 |
| Region XIII | Mindanao | 1,987,654,321 | 1,987.65 | 145.2 | 135.40 | 21.85 |
(Full table exported to report1_regional_summary.csv)

Report 2: Top Contractors Performance Ranking
Top Contractors Performance Ranking
(Top 15 by TotalCost, >=5 Projects)
| Rank | Contractor | TotalCost | NumProjects | AvgDelay | TotalSavings | ReliabilityIndex | RiskFlag |
| 1 | ASC CONSTRUCTION & CONCRETE PRODUCTS | 500,000,000 | 15 | 2,500,000 | 30.5 | 75.20 | Low Risk |
| 2 | GICAR CONSTRUCTION, INC. | 400,000,000 | 12 | 15.2 | 1,800,000 | 88.50 | Low Risk |
(Full table exported to report2_contractor_ranking.csv)

Report 3: Annual Project Type Cost Overrun Trends
Annual Project Type Cost Overrun Trends
(Grouped by FundingYear and TypeOfWork)
| TypeOfWork | FundingYear | TotalProjects | AvgSavings | OverrunRate | YoYChange |
| Construction of Flood Mitigation Structure | 2021 | 1,200 | 1,500.00 | 12.50 | 10.00 |
| Construction of Revetment | 2021 | 800 | -250.75 | 25.30 | 10.00 |
| Construction of Flood Mitigation Structure | 2022 | 1,100 | 1,200.00 | 18.20 | -20.00 |
(Full table exported to report3_annual_trends.csv)

Summary Stats (summary.json):
{"global_avg_delay": 45.2, "total_savings": 15000000}
Back to Report Selection (Y/N):
```

## EVALUATION CRITERIA

| Criteria | Description | Points | Details |
| :--- | :--- | :--- | :--- |
| **Code Simplicity** | Measures how straightforward and minimal the code is. | 5 | **5 pts:** Code is simple and efficient.<br>**3-4 pts:** Mostly simple, with minor inefficiencies.<br>**1-2 pts:** Code has unnecessary complexity.<br>**0 pts:** Code is overly complex or unclear. |
| **Performance** | Evaluates how quickly the program executes, especially with large inputs. | 5 | **5 pts:** Excellent performance across all inputs.<br>**3-4 pts:** Minor performance issues with large inputs.<br>**1-2 pts:** Noticeable lags.<br>**0 pts:** Poor performance. |
| **Code Readability** | Assesses the clarity of the code, including formatting, variable naming, and use of comments. | 5 | **5 pts:** Clean, well-organized code.<br>**3-4 pts:** Some minor readability issues.<br>**1-2 pts:** Difficult to follow.<br>**0 pts:** Unreadable code. |
| **Correctness** | Checks if the program produces the correct outputs and handles edge cases. | 3 | **3 pts:** Correct outputs for all cases.<br>**2 pts:** Minor mistakes in edge cases.<br>**1 pt:** Frequent errors.<br>**0 pts:** Fails to provide correct output. |
| **User Experience** | Measures how intuitive and user-friendly the program is, including clear input/output and instructions. | 2 | **2 pts:** Smooth, intuitive experience.<br>**1 pt:** Somewhat confusing interface.<br>**0 pts:** Poor user experience. |

# MCO3 Group Presentation & Reflection (Group 15)

## Slide 1: Introduction
- **Group 15**
- **Members:** Neil (Rust), Allisha (Javascript), Winelle (Kotlin), Joseph (R)
- **Agenda:** Reflecting on the development journey of MCO1 (Lexical Analyzer) and MCO2 (Flood Control Data Processing).

## Slide 2: Hardest Language for MCO1 (Lexical Analyzer)
**Answer: Rust**
- **Why?** MCO1 required heavy string manipulation and token state tracking. 
- **Factors:**
  - **Learning Curve & Debugging:** Rust’s strict ownership rules and the constant battle between `String` and `&str` made parsing text and managing token lifetimes extremely challenging.
  - **Development Time:** Because we were restricted to standard libraries, implementing a state machine that satisfied the borrow checker took significantly longer than in garbage-collected languages.

## Slide 3: Hardest Language for MCO2 (Data Processing)
**Answer: Javascript**
- **Why?** MCO2 involved parsing a 4.6MB CSV and performing complex aggregations and sorting.
- **Factors:**
  - **Availability of Tools:** Without external libraries (like `pandas` in Python or DataFrames in R), we had to manually implement an RFC 4180-compliant CSV parser to handle escaped quotes and commas.
  - **Maintainability:** While flexible, grouping and aggregating data required heavy chains of `.reduce()` and `.filter()`, which made the code harder to read and debug compared to languages with native collection grouping.

## Slide 4: Easiest Language for MCO1
**Answer: Kotlin**
- **Why?** Kotlin's modern syntax and robust standard library made building a Lexical Analyzer very straightforward.
- **Factors:**
  - **Overall Developer Experience:** Kotlin's highly expressive `when` statements acted as powerful pattern-matching tools for classifying tokens.
  - **Maintainability:** The use of `data class` and `enum class` provided a clean, readable way to structure the Lexical Analyzer's output, and null-safety (`?.`, `?:`) eliminated an entire category of runtime errors.

## Slide 5: Easiest Language for MCO2
**Answer: R**
- **Why?** MCO2 was inherently a data manipulation and statistical analysis task—the exact domain R was built for.
- **Factors:**
  - **Performance & Tools:** R's native `data.frame` and vectorized operations (`aggregate()`, `tapply()`) allowed us to group data and compute statistics (median, standard deviation) in just a few lines of code.
  - **Development Time:** What took hundreds of lines of manual hashing in Rust or Javascript was accomplished natively and instantly in R.

## Slide 6: The "One Language" Choice
**If we could only choose ONE language for both MCO1 and MCO2, we would choose: KOTLIN.**
- **Why Kotlin?** It offers the best compromise across all paradigms.
  - **For MCO1 (Logic & State):** Strong static typing, excellent string manipulation, and expressive control flow (`when`).
  - **For MCO2 (Data & Collections):** Incredible standard library collection functions (`groupBy`, `sumOf`, `sortedByDescending`) that rival R's ease of use, without the steep learning curve of Rust or the architectural chaos of Javascript.
  - **Verdict:** It provided the fastest development time, easiest debugging experience, and the most maintainable code across two completely different problem domains.

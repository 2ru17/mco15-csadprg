---
title: "An Evaluation Paper on Javascript, R, Kotlin, and Rust"
subtitle: "Submitted in partial fulfillment of CSADPRG requirements"
author: 
  - "[Group member names in alphabetical order]"
date: "[Date]"
---

# 1. Introduction

## 1.1 Overview of Programming Paradigms
Programming paradigms provide fundamental styles and structural approaches to software development. The four languages examined in this paper, Javascript, R, Kotlin, and Rust, span across multiple paradigms, offering diverse solutions to modern programming challenges. Imperative and object-oriented programming (OOP) paradigms remain dominant, but functional and concurrent paradigms have increasingly influenced modern language design. 

## 1.2 Language History & Evolution
**Javascript** was created in 1995 by Brendan Eich at Netscape to add interactivity to web pages. It has since evolved from a simple client-side scripting language into a ubiquitous, multi-paradigm language powering both front-end interfaces and back-end servers (via Node.js).
**R** was developed in 1993 by Ross Ihaka and Robert Gentleman. It is a domain-specific language widely used for statistical computing, data analysis, and graphical modeling, built heavily around a functional and vectorized paradigm based on the S language.
**Kotlin**, developed by JetBrains and officially released in 2011, was created as a modern, statically typed language targeting the JVM. It focuses on safety (particularly null safety), interoperability with Java, and concise syntax.
**Rust** was introduced by Mozilla in 2010. It was designed as a systems programming language to solve the challenges of memory safety and concurrency without relying on a garbage collector, prioritizing zero-cost abstractions.

## 1.3 Current State & Application Domains
Javascript is the de-facto language of the web, ubiquitous in web development and widely used in full-stack applications. R remains the standard for academic and enterprise data science, bioinformatics, and statistical research. Kotlin is the officially recommended language for Android development and is extensively used in server-side application development. Rust is predominantly used in cloud-native infrastructure, systems tooling, embedded systems, and WebAssembly due to its high performance and safety guarantees.

# 2. Language Comparison

## 2.1 Type Systems & Binding
The four languages handle type binding and type checking quite differently. Kotlin and Rust utilize static type binding, meaning variable types are determined and enforced at compile-time. Javascript and R employ dynamic type binding, where types are resolved at runtime.

In the Load Calculator application, the static typing of Rust requires explicit structures and definitions, ensuring memory safety and preventing runtime type mismatches:
```rust
// Rust: Static type binding via struct
struct LoadData {
    dead_load: f64,
    live_load: f64,
}
```

Conversely, Javascript's dynamic binding allows for flexible assignment without strict structure definitions:
```javascript
// Javascript: Dynamic type binding
let deadLoad = 150.5;
let liveLoad = 85.0;
```
While Javascript allows for rapid prototyping, it lacks the compile-time guarantees that Kotlin and Rust provide, which can lead to unintended implicit type coercions during mathematical operations.

## 2.2 Memory Management & Parameter Passing
Memory management strategies vary significantly across the studied languages. Kotlin strictly passes by value, but for complex objects, the value passed is the reference to the object in the heap, producing a pass-by-reference effect. R uses a unique "copy-on-write" semantics for its functional data structures, preventing unintended mutations, except when using explicit environments which act as reference types.

Javascript operates on object references and is garbage collected, mimicking pass-by-reference when mutating object properties. Rust uses a strict ownership and borrowing model without a garbage collector. To mutate state, Rust requires explicit mutable references:
```rust
// Rust: Pass by reference (mutable borrow)
fn distribute_load(load: &mut f64, pillars: i32) {
    if pillars > 0 {
        *load = *load / (pillars as f64);
    }
}
```
In contrast, R strictly passes by value. To achieve a similar mutation effect, R requires the use of environments:
```R
# R: Pass by reference effect using Environments
distributeLoad <- function(loadEnv, pillars) {
  if (pillars > 0) {
    loadEnv$value <- loadEnv$value / pillars
  }
}
```

## 2.3 Control Flow & Pattern Matching
Each language offers distinct control flow mechanisms. Rust provides a minimalist approach with explicit pattern matching (`match`) and strict iteration loops. Kotlin provides expressive `when` statements that act as powerful pattern-matching tools, alongside functional collection operators.

In the Corpus Analysis application, Kotlin's functional control flow easily handles string tokenization:
```kotlin
// Kotlin: Functional control flow and regex manipulation
fun tokenize(text: String): List<String> {
    return text.lowercase()
        .replace(Regex("[^a-z0-9\\s]"), "")
        .split(Regex("\\s+"))
        .filter { it.isNotEmpty() }
}
```
R relies heavily on vectorized operations, discouraging explicit loops in favor of highly optimized built-in functions:
```R
# R: Vectorized function for frequency counting
countFrequencies <- function(words) {
  freq_table <- table(words)
  return(freq_table)
}
```

## 2.4 Application-Specific Analysis

### 2.4.1 Load Calculator
The Load Calculator required strict mathematical precision. Rust and Kotlin excelled here, as their static typing prevented accidental string-to-number coercions that could result in `NaN` (Not-a-Number) errors. Javascript's dynamic typing made the implementation faster but required careful manual validation of inputs. R seamlessly handled the numeric computations, natively treating all inputs as double-precision numeric vectors, which made formula execution highly efficient.

### 2.4.2 Corpus Analysis
The Corpus Analysis tool heavily relied on string parsing and dictionary (hash map) operations. Javascript's native Object and array prototypes made word frequency counting exceptionally straightforward. R's `table()` function provided a one-line solution to counting frequencies, proving its dominance in data-centric operations. Rust required the most verbose implementation, forcing the developer to explicitly handle string ownership and memory allocation during tokenization, though it resulted in the most memory-efficient execution.

# 3. Conclusion

## 3.1 Summary of Findings
The development of the Load Calculator and Corpus Analysis applications revealed that while all four languages are highly capable, their underlying paradigms heavily influence their practical application. Rust excelled in memory safety and raw performance, albeit with a steeper learning curve due to its borrowing rules. Kotlin provided the most robust safety features and modern syntax for general-purpose development. R proved unmatched in its vectorized approach to data manipulation, providing built-in functions that drastically reduced codebase size. Javascript offered the highest level of expressiveness and flexibility, allowing for rapid iterations and flexible object manipulation.

## 3.2 Recommendations
For applications requiring high concurrency, memory safety, and systems-level performance, **Rust** is highly recommended. **Kotlin** is the ideal choice for large-scale enterprise applications requiring strict type safety and modern OOP idioms. **R** should be exclusively utilized for projects where data analysis and statistical processing are the core focus, as its vectorization is unmatched. **Javascript** remains an excellent option for I/O-heavy applications and rapid prototyping where developer speed and cross-platform flexibility are prioritized over raw execution speed.

# 4. References

JetBrains. (2024). *Kotlin Documentation*. https://kotlinlang.org/docs/home.html

Mozilla Corporation. (2024). *JavaScript - MDN Web Docs*. https://developer.mozilla.org/en-US/docs/Web/JavaScript

R Core Team. (2024). *R: A Language and Environment for Statistical Computing*. R Foundation for Statistical Computing. https://www.R-project.org/

The Rust Project Developers. (2024). *The Rust Reference*. https://doc.rust-lang.org/reference/

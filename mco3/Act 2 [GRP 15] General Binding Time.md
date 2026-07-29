# 

| Degullado, Joseph Edward Kelvin D. | Gutang, Neil Jr.  | Tolentino, Winelle R. | Wong, Allisha Kate |
| :---- | :---- | :---- | :---- |

# **Assignment: Binding Time (Group 15\)**

1\.  Given the generic statement **x \= x \+ y** (i.e. the values of x and y are added and assigned to x), identify the binding time of each of the questions listed below. Is the information known at language definition time, language implementation time, compilation/translation time, or runtime? 

| Questions | Kotlin | Javascript | Rust | R |
| :---- | :---- | :---- | :---- | :---- |
| Set of possible types of x? | Language definition time | Language definition time | Language definition time | Language definition time |
| Data type of x? | Compilation/translation time | Runtime | Compilation/translation time | Runtime |
| Set of possible values of x? | Language definition time | Runtime | Language definition time | Runtime |
| Value of x? | Runtime | Runtime | Runtime | Runtime |
| Meaning of \+? | Compilation/translation time | Runtime | Compilation/translation time | Runtime |

\***Note**: If the exact time of binding cannot be determined, specify either pre-runtime or runtime. If the group specifies pre-runtime but the information on which pre-runtime stage is available or can be deduced, only half the points are given for the answer.

2\. Provide the appropriate answers to the questions in the table below.

| Questions | Kotlin | Ruby | Rust | R |
| :---- | :---- | :---- | :---- | :---- |
| How is a variable’s data type specified? | Explicitly (type declaration) or implicitly (type inference) | Implicitly (through assignment) | Explicitly declared by the programmer (e.g., let x: i32;) or implicitly inferred by the compiler using type inference (e.g., let x \= 5;) | Implicitly inferred based on the value assigned to it. |
| When is a data type bound to a variable? | Compile time | Runtime | Compilation/translation time | Runtime |
| Can the data type of a variable change?  | No | Yes | No | Yes |
| When is memory space allocated to the variable? | Runtime | Runtime | Runtime | Runtime |
| When is memory space de-allocated from a variable? | Runtime | Runtime | Runtime | Runtime |
| When are variables initialized? | Runtime (default) | Runtime | Runtime | Runtime |

**\*\*Note**: Your answers do not need to be lengthy, but they should be concise and capture the idea properly. However, do not hesitate to write long answers if needed.

3\. Kindly list your references/sources here:

1. Kotlin Help. (2025). Kotlin Help. https://kotlinlang.org/docs/types-overview.html  
2. Rust Project Developers. (2026). Rust Documentation. https://doc.rust-lang.org/stable/  
3. R Core Team. (2026). R Language Definition. https://cran.r-project.org/doc/manuals/r-release/R-lang.html
use std::collections::HashMap;
use std::fs::{self, File};
use std::io::{self, Write};
use std::path::Path;

// [PARAM_PASSING] Pass by reference (borrowing): takes a reference to a string slice.
fn tokenize(text: &str) -> Vec<String> {
    text.to_lowercase()
        .split_whitespace()
        .map(|word| {
            // [DATA_TYPE] Strong typing and string manipulation
            let cleaned: String = word.chars().filter(|c| c.is_alphanumeric()).collect();
            cleaned
        })
        .filter(|w| !w.is_empty())
        .collect()
}

// [PARAM_PASSING] Pass by value-result / move semantics: takes ownership of Vec, returns HashMap.
fn count_frequencies(words: Vec<String>) -> HashMap<String, i32> {
    // [BINDING] Dynamic collection sizing but statically typed (HashMap<String, i32>)
    let mut frequencies = HashMap::new();
    for word in words {
        let count = frequencies.entry(word).or_insert(0);
        *count += 1;
    }
    frequencies
}

fn main() -> io::Result<()> {
    let corpus_path = "corpora/sample_corpus.txt";
    // Read file (error handling with Result)
    let text = fs::read_to_string(corpus_path).unwrap_or_else(|_| "default text fallback".to_string());
    
    let words = tokenize(&text);
    let freq_map = count_frequencies(words);

    let mut output_str = String::from("Corpus Word Frequencies:\n");
    let mut sorted_entries: Vec<_> = freq_map.into_iter().collect();
    // Sort by frequency descending
    sorted_entries.sort_by(|a, b| b.1.cmp(&a.1));

    for (word, count) in sorted_entries {
        output_str.push_str(&format!("{}: {}\n", word, count));
    }

    println!("{}", output_str);

    // [INTEGRATION] File I/O
    let out_dir = Path::new("../outputs/Rust_out");
    fs::create_dir_all(out_dir)?;
    
    let out_path = out_dir.join("corpus_results.txt");
    let mut file = File::create(out_path)?;
    file.write_all(output_str.as_bytes())?;

    println!("Results saved to outputs/Rust_out/corpus_results.txt");
    Ok(())
}

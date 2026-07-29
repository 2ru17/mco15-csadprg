use std::fs::File;
use std::io::{self, Write};
use std::path::Path;

// [BINDING] Static type binding: Struct fields have fixed types at compile time.
struct LoadData {
    dead_load: f64,
    live_load: f64,
}

// [PARAM_PASSING] Pass by value: primitive types like f64 are copied.
fn calculate_ultimate_load(dl: f64, ll: f64) -> f64 {
    1.2 * dl + 1.6 * ll
}

// [PARAM_PASSING] Pass by reference (mutable borrow): allowing modification of the struct.
fn distribute_load(load: &mut f64, pillars: i32) {
    if pillars > 0 {
        *load = *load / (pillars as f64);
    }
}

fn main() -> io::Result<()> {
    // [DATA_TYPE] Explicit numeric types (f64) and String for output.
    let data = LoadData {
        dead_load: 150.5,
        live_load: 85.0,
    };

    let mut ultimate_load = calculate_ultimate_load(data.dead_load, data.live_load);
    let total_pillars = 4;

    distribute_load(&mut ultimate_load, total_pillars);

    // [INTEGRATION] Output formatting and File I/O.
    let output_str = format!(
        "Dead Load: {:.2}\nLive Load: {:.2}\nTotal Pillars: {}\nLoad per Pillar: {:.2}\n",
        data.dead_load, data.live_load, total_pillars, ultimate_load
    );

    println!("{}", output_str);

    let path = Path::new("../outputs/Rust_out/load_results.txt");
    let mut file = File::create(&path)?;
    file.write_all(output_str.as_bytes())?;

    println!("Results saved to outputs/Rust_out/load_results.txt");
    Ok(())
}

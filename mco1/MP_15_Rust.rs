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
 * Major Course Output #1: Banking and Currency Exchange Application
 *
 * File Name: MP_15_Rust.rs
 * Group Number: 15
 *
 * Description:
 * This Rust command-line application implements a Banking and Currency Exchange System.
 * It provides core banking features including account registration, deposits, withdrawals,
 * currency exchange computations, and compounding interest projections.
 *
 * To ensure exact financial precision and prevent floating-point rounding issues,
 * all account balances and currency amounts are represented internally in the smallest
 * monetary unit (centavos/cents) using 64-bit signed integers (i64).
 *
 * Academic Integrity Statement:
 * We hereby declare that this submission is our own work and that, to the best of our
 * knowledge and belief, it contains no material previously written or published by
 * another person, nor material which has been accepted for the award of any other
 * degree or diploma, except where due acknowledgment has been made in the text.
 */

use std::io::{self, Write};

// CONSTANTS
// Supported currency codes and their full display names.
// Fixed as per functional specification REQ-0001 and REQ-0002.
const CURRENCIES: [&str; 6] = ["PHP", "USD", "JPY", "GBP", "EUR", "CNY"];
const CURRENCY_FULL_NAMES: [&str; 6] = [
    "Philippine Peso (PHP)",
    "United States Dollar (USD)",
    "Japanese Yen (JPY)",
    "British Pound Sterling (GBP)",
    "Euro (EUR)",
    "Chinese Yuan Renminni (CNY)",
];

// 
// This struct holds all the data our program needs while it is running.
// When the program closes, all data is lost (no file/database saving).
struct AppState {
    // The user's registered name. It starts as None (empty/unregistered).
    // We use Option<String> because the name may or may not exist yet. (REQ-0009)
    account_name: Option<String>,

    // The account balance stored in centavos (1/100 of a peso).
    // Storing it as a whole number avoids floating-point rounding errors.
    // Example: 1000.50 PHP is stored as 100050.
    balance_cents: i64,

    // Exchange rates for all 6 currencies relative to PHP.
    // Index 0 = PHP (always 1.0), Index 1 = USD, 2 = JPY, 3 = GBP, 4 = EUR, 5 = CNY.
    // None means the rate has not been set yet. (REQ-0001, REQ-0002)
    exchange_rates: [Option<f64>; 6],
}

// MAIN
fn main() {
    // Create the initial application state.
    // PHP rate is fixed at 1.0 as the base currency. All others start as None (unset).
    let mut state = AppState {
        account_name: None,
        balance_cents: 0,
        exchange_rates: [Some(1.0), None, None, None, None, None],
    };

    // The main loop. 
    loop {
        let choice = show_main_menu();
        match choice {
            0 => {
                // User chose to exit the program.
                println!("\nThank you for using the Banking and Currency Exchange Application. Goodbye!");
                break; // This exits the loop, ending the program.
            }
            1 => register_account_name(&mut state),
            2 => deposit_amount(&mut state),
            3 => withdraw_amount(&mut state),
            4 => currency_exchange(&state),
            5 => record_exchange_rate(&mut state),
            6 => show_interest_computation(&state),
            _ => unreachable!(), // This line should never be reached.
        }
    }
}

// HELPER - Prints trimmed version of the string
fn read_input() -> String {
    let mut input = String::new();
    io::stdin().read_line(&mut input).unwrap_or_default();
    input.trim().to_string()
}

// HELPER - Prints the prompt before the user types
fn prompt(text: &str) {
    print!("{}", text);
    io::stdout().flush().unwrap();
}

// MAIN MENU
fn show_main_menu() -> u32 {
    loop {
        println!();
        println!("Select Transaction:");
        println!("[1] Register Account Name");
        println!("[2] Deposit Amount");
        println!("[3] Withdraw Amount");
        println!("[4] Currency Exchange");
        println!("[5] Record Exchange Rates");
        println!("[6] Show Interest Computation");
        println!("[0] Exit");
        prompt("Select Option: ");

        let input = read_input();

        // Try to parse the input as a number. If it fails, show an error.
        match input.parse::<u32>() {
            Ok(n) if n <= 6 => return n,
            _ => println!("Invalid option. Please enter a number from 0 to 6."),
        }
    }
}

// HELPER - Currency Selector
// Used by Deposit, Withdraw, and Currency Exchange to let the user pick a currency.
// Returns Some(index) if the user picked a currency, or None if they pressed 0 to cancel.
fn select_currency(state: &AppState, prompt_text: &str, require_registered: bool) -> Option<usize> {
    loop {
        println!("\n{}", prompt_text);
        println!("[0] Cancel (go back)");
        for i in 0..6 {
            // Show the registered status so the user knows which currencies are available.
            if state.exchange_rates[i].is_some() {
                println!("[{}] {}", i + 1, CURRENCY_FULL_NAMES[i]);
            } else {
                // Mark unregistered currencies so the user knows they can't use them yet.
                println!("[{}] {} (rate not set)", i + 1, CURRENCY_FULL_NAMES[i]);
            }
        }
        prompt("Select Currency: ");

        let input = read_input();

        match input.parse::<usize>() {
            Ok(0) => {
                println!("Selection cancelled.");
                return None;
            }
            Ok(n) if n >= 1 && n <= 6 => {
                let idx = n - 1; // Convert from 1-based display to 0-based array index.
                // If we require a registered rate, check before accepting the choice.
                if require_registered && state.exchange_rates[idx].is_none() {
                    println!(
                        "Error: Exchange rate for {} is not set. Please register it under option [5] first.",
                        CURRENCIES[idx]
                    );
                } else {
                    return Some(idx);
                }
            }
            _ => println!("Invalid selection. Enter a number from 0 to 6."),
        }
    }
}

// Register account name
// Lets the user enter their name. This must be done before deposits, withdrawals, and interest.
fn register_account_name(state: &mut AppState) {
    println!("\nRegister Account Name");

    loop {
        prompt("Account Name: ");
        let name = read_input();

        if name.is_empty() {
            println!("Error: Account name cannot be empty. Please try again.");
        } else {
            state.account_name = Some(name.clone());
            println!("Account name '{}' registered successfully.", name);
            break;
        }
    }
}

// Deposit Amount
// Adds money to the account. Supports deposits in foreign currencies.
fn deposit_amount(state: &mut AppState) {
    println!("\nDeposit Amount");

    // Block the transaction if no account is registered yet.
    let name = match &state.account_name {
        Some(n) => n.clone(),
        None => {
            println!("Error: No account registered. Please use option [1] to register first.");
            return;
        }
    };

    println!("Account Name: {}", name);
    println!("Current Balance: {:.2} PHP", state.balance_cents as f64 / 100.0);

    // Let the user pick a currency. [0] cancels and goes back to the main menu.
    let currency_idx = match select_currency(state, "Select Deposit Currency:", true) {
        Some(idx) => idx,
        None => return, 
    };

    // The exchange rate for the selected currency (PHP is always 1.0).
    let rate = state.exchange_rates[currency_idx].unwrap();

    // Keep asking 
    loop {
        prompt(&format!("Deposit Amount (in {}): ", CURRENCIES[currency_idx]));
        let input = read_input();

        match input.parse::<f64>() {
            Ok(amount) if amount > 0.0 => {
                let amount_cents = (amount * 100.0).round() as i64;
                let php_cents = (amount_cents as f64 * rate).round() as i64;
                state.balance_cents += php_cents;
                println!("\nDeposit successful.");
                println!("Deposited: {:.2} {} = {:.2} PHP", amount, CURRENCIES[currency_idx], php_cents as f64 / 100.0);
                println!("Updated Balance: {:.2} PHP", state.balance_cents as f64 / 100.0);
                break;
            }
            _ => println!("Error: Please enter a positive number (e.g., 500.00)."),
        }
    }
}

// Withdraw Amount
// Removes money from the account. Prevents overdraft. Supports foreign currencies.
fn withdraw_amount(state: &mut AppState) {
    println!("\nWithdraw Amount");

    // Block the transaction if no account is registered yet.
    let name = match &state.account_name {
        Some(n) => n.clone(),
        None => {
            println!("Error: No account registered. Please use option [1] to register first.");
            return;
        }
    };

    println!("Account Name: {}", name);
    println!("Current Balance: {:.2} PHP", state.balance_cents as f64 / 100.0);

    let currency_idx = match select_currency(state, "Select Withdrawal Currency:", true) {
        Some(idx) => idx,
        None => return,
    };

    let rate = state.exchange_rates[currency_idx].unwrap();

    // Keep asking 
    loop {
        prompt(&format!("Withdraw Amount (in {}): ", CURRENCIES[currency_idx]));
        let input = read_input();

        match input.parse::<f64>() {
            Ok(amount) if amount > 0.0 => {
                let amount_cents = (amount * 100.0).round() as i64;
                // Convert the withdrawal to PHP centavos to check against the balance.
                let php_cents = (amount_cents as f64 * rate).round() as i64;

                if php_cents <= state.balance_cents {
                    // Sufficient balance: proceed with the withdrawal.
                    state.balance_cents -= php_cents;
                    println!("\nWithdrawal successful.");
                    println!("Withdrawn: {:.2} {} = {:.2} PHP", amount, CURRENCIES[currency_idx], php_cents as f64 / 100.0);
                    println!("Updated Balance: {:.2} PHP", state.balance_cents as f64 / 100.0);
                    break;
                } else {
                    // Not enough balance: show how much can be withdrawn and let them retry.
                    let max_in_currency = state.balance_cents as f64 / rate / 100.0;
                    println!(
                        "Transaction Denied: Insufficient balance. You can withdraw up to {:.2} {} ({:.2} PHP).",
                        max_in_currency,
                        CURRENCIES[currency_idx],
                        state.balance_cents as f64 / 100.0
                    );
                }
            }
            _ => println!("Error: Please enter a positive number (e.g., 200.00)."),
        }
    }
}

// Currency Exchange
// Converts an amount from one currency to another using registered rates.
fn currency_exchange(state: &AppState) {
    loop {
        println!("\nForeign Currency Exchange");

        // Pick Source Currency
        let src_idx = match select_currency(state, "Select Source Currency:", true) {
            Some(idx) => idx,
            None => return,
        };

        // Enter source ammount
        let src_amount = loop {
            prompt(&format!("Source Amount (in {}): ", CURRENCIES[src_idx]));
            let input = read_input();

            match input.parse::<f64>() {
                Ok(amount) if amount > 0.0 => break amount,
                _ => println!("Error: Please enter a positive number."),
            }
        };

        // Pick Target Currency
        let target_idx = match select_currency(state, "Select Target Currency:", true) {
            Some(idx) => idx,
            None => return,
        };

        // COMPUTE CONVERSION
        // 1 Convert source amount to PHP centavos using the source currency's rate.
        // 2 Convert PHP centavos to target currency centavos using the target rate.
        let src_rate = state.exchange_rates[src_idx].unwrap();
        let target_rate = state.exchange_rates[target_idx].unwrap();

        let src_cents = (src_amount * 100.0).round() as i64;
        let php_cents = (src_cents as f64 * src_rate).round() as i64;
        let target_cents = (php_cents as f64 / target_rate).round() as i64;
        let target_amount = target_cents as f64 / 100.0;

        println!(
            "\n{:.2} {} = {:.2} {}",
            src_amount, CURRENCIES[src_idx], target_amount, CURRENCIES[target_idx]
        );

        loop {
            prompt("Convert another currency? (Y/N): ");
            let input = read_input().to_uppercase();
            if input == "Y" {
                break; // Break the inner loop, which continues the outer loop.
            } else if input == "N" {
                return; // Exit the function entirely, back to main menu.
            } else {
                println!("Invalid input. Please enter Y or N.");
            }
        }
    }
}

// Record Exchange Rate
// Lets the user set the exchange rate for a foreign currency relative to 1 PHP.
fn record_exchange_rate(state: &mut AppState) {
    println!("\nRecord Exchange Rate");
    println!("Note: Rates are how many PHP equals 1 unit of the foreign currency.");
    println!("      Example: USD rate of 52.00 means 1 USD = 52.00 PHP.");

    // We pass 'false' for require_registered because we want to allow setting ANY currency's rate.
    let currency_idx = match select_currency(state, "Select Currency to Set Rate For:", false) {
        Some(idx) => idx,
        None => return,
    };

    if currency_idx == 0 {
        println!("Philippine Peso (PHP) is the base currency. Its rate is always 1.0 and cannot be changed.");
        return;
    }

    loop {
        prompt(&format!("Enter exchange rate for {} (PHP per 1 {}): ", CURRENCIES[currency_idx], CURRENCIES[currency_idx]));
        let input = read_input();

        match input.parse::<f64>() {
            Ok(rate) if rate > 0.0 => {
                state.exchange_rates[currency_idx] = Some(rate);
                println!(
                    "Exchange rate set: 1 {} = {:.4} PHP",
                    CURRENCIES[currency_idx], rate
                );
                break;
            }
            _ => println!("Error: Please enter a positive number (e.g., 52.00)."),
        }
    }
}

// Show Interest Computation
// Shows a day-by-day table of how the account balance grows with 5% annual compounding interest.
fn show_interest_computation(state: &AppState) {
    println!("\nShow Interest Amount");

    let name = match &state.account_name {
        Some(n) => n,
        None => {
            println!("Error: No account registered. Please use option [1] to register first.");
            return;
        }
    };

    println!("Account Name: {}", name);
    println!("Current Balance: {:.2} PHP", state.balance_cents as f64 / 100.0);
    println!("Interest Rate: 5% per annum");

    // Ask how many days to simulate.
    let days: u32 = loop {
        prompt("Total Number of Days: ");
        let input = read_input();

        match input.parse::<u32>() {
            Ok(d) if d > 0 => break d,
            _ => println!("Error: Please enter a whole number greater than 0 (e.g., 30)."),
        }
    };

    // Print the table header.
    println!("\n{:<5} | {:<12} | {}", "Day", "Interest", "Balance");
    println!("{}", "-".repeat(35));

    // Daily interest formula:
    // Daily Interest = Current Balance * (Annual Rate / Days in Year)
    // We round to the nearest centavo each day.
    let mut current_balance_cents = state.balance_cents;
    const ANNUAL_RATE: f64 = 0.05;
    const DAYS_IN_YEAR: f64 = 365.0;

    for day in 1..=days {
        let daily_interest_cents =
            (current_balance_cents as f64 * (ANNUAL_RATE / DAYS_IN_YEAR)).round() as i64;
        current_balance_cents += daily_interest_cents;

        println!(
            "{:<5} | {:<12.2} | {:.2}",
            day,
            daily_interest_cents as f64 / 100.0,
            current_balance_cents as f64 / 100.0
        );
    }
    println!();
}

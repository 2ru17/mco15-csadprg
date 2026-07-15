# ********************
# ┃ Last names: Gutang, Wong, Tolentino, Degullado
# ┃ Language: R
# ┃ Paradigm(s): Multi-paradigm (Structured, Imperative, Functional)
# ********************
# /**
#  * De La Salle University, Manila
#  * College of Computer Studies
#  * Department of Software Technology
#  *
#  * Course Code: CSADPRG (Advanced Programming)
#  * Major Course Output #1: Banking and Currency Exchange Application
#  *
#  * File Name: MP_15_R.R
#  * Group Number: 15
#  *
#  * Description:
#  * This R command-line application implements a Banking and
#  * Currency Exchange System. It provides core banking features including account
#  * registration, deposits, withdrawals, currency exchange computations, and
#  * compounding interest projections.
#  *
#  * To ensure exact financial precision and prevent floating-point rounding issues,
#  * all account balances and currency amounts are represented internally in the
#  * smallest monetary unit (centavos/cents) using integer arithmetic via round().
#  * Example: 1000.50 PHP is stored as 100050.
#  *
#  * Academic Integrity Statement:
#  * We hereby declare that this submission is our own work and that, to the best of
#  * our knowledge and belief, it contains no material previously written or published
#  * by another person, nor material which has been accepted for the award of any other
#  * degree or diploma, except where due acknowledgment has been made in the text.
#  */

account_names <- c()
balances_in_cents <- c()

currency_symbols <- c("PHP", "USD", "JPY", "GBP", "EUR", "CNY")
currency_full_names <- c(
  "Philippine Peso (PHP)",
  "United States Dollar (USD)",
  "Japanese Yen (JPY)",
  "British Pound Sterling (GBP)",
  "Euro (EUR)",
  "Chinese Yuan Renminni (CNY)"
)

# Exchange rates based by rates on July 15, 2026, source is Google
exchange_rates <- c(1.0, 61.64, 0.38, 82.89, 70.46, 9.10) 

math_round <- function(number) {
  return(floor(number + 0.5))
}

ask_back_to_menu <- function() {
  repeat {
    user_answer <- readline(prompt="Back to the Main Menu (Y/N): ")
    user_answer <- toupper(user_answer)
    
    if (user_answer == "Y") {
      return(TRUE)
    } else if (user_answer == "N") {
      return(FALSE)
    } else {
      cat("Invalid input. Please enter 'Y' or 'N'.\n\n")
    }
  }
}

select_currency <- function(prompt_text, require_registered) {
  repeat {
    cat(sprintf("\n%s\n", prompt_text))
    cat("[0] Cancel (go back)\n")
    for (index_counter in 1:6) {
      if (!is.na(exchange_rates[index_counter])) {
        cat(sprintf("[%d] %s\n", index_counter, currency_full_names[index_counter]))
      } else {
        cat(sprintf("[%d] %s (rate not set)\n", index_counter, currency_full_names[index_counter]))
      }
    }
    
    cat("\n")
    flush.console()
    user_currency_choice <- as.integer(readline(prompt="Select Currency: "))
    
    if (!is.na(user_currency_choice) && user_currency_choice == 0) {
      cat("Selection cancelled.\n")
      return(NA)
    }
    
    if (!is.na(user_currency_choice) && user_currency_choice >= 1 && user_currency_choice <= 6) {
      if (require_registered && is.na(exchange_rates[user_currency_choice])) {
        cat(sprintf("Error: Exchange rate for %s is not set. Please register it under option [5] first.\n", currency_symbols[user_currency_choice]))
      } else {
        return(user_currency_choice)
      }
    } else {
      cat("Invalid selection. Enter a number from 0 to 6.\n")
    }
  }
}

repeat {
  cat("Select Transaction:\n")
  cat("[1] Register Account Name\n")
  cat("[2] Deposit Amount\n")
  cat("[3] Withdraw Amount\n")
  cat("[4] Currency Exchange\n")
  cat("[5] Record Exchange Rates\n")
  cat("[6] Show Interest Computation\n")
  cat("[7] View Account Balances\n")
  cat("[0] Exit Application\n")
  
  cat("\n")
  flush.console()
  user_menu_choice <- as.integer(readline(prompt="Select Option: "))
  
  if (is.na(user_menu_choice)) {
    cat("Invalid option. Please enter a number from 0 to 7.\n\n")
    next
  }
  
  if (user_menu_choice == 1) {
    cat("\nRegister Account Name\n")
    new_account_name <- readline(prompt="Account Name: ")
    
    if (new_account_name == "") {
      cat("Error: Account name cannot be empty. Please try again.\n\n")
      next
    } else if (toupper(new_account_name) %in% toupper(account_names)) {
      cat("An account with this name already exists!\n\n")
      next
    } else {
      account_names <- c(account_names, new_account_name)
      balances_in_cents <- c(balances_in_cents, 0)
      cat(sprintf("Account name '%s' registered successfully.\n\n", new_account_name))
    }
    
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking and Currency Exchange Application. Goodbye!\n")
      break
    }
    cat("\n")
  } 
  
  else if (user_menu_choice %in% c(2, 3, 6, 7) && length(account_names) == 0) {
    cat("\nError: No accounts registered yet. Please register an account first!\n\n")
    next
  }
  
  else if (user_menu_choice == 2) {
    cat("\nDeposit Amount\n")
    search_account_name <- readline(prompt="Enter Account Name: ")
    
    account_index <- match(toupper(search_account_name), toupper(account_names))
    
    if (!is.na(account_index)) {
      cat(sprintf("Account Name: %s\n", account_names[account_index]))
      cat(sprintf("Current Balance: %.2f PHP\n", balances_in_cents[account_index] / 100))
      
      deposit_currency_index <- select_currency("Select Deposit Currency:", TRUE)
      
      if (is.na(deposit_currency_index)) {
        next
      }
      
      current_rate <- exchange_rates[deposit_currency_index]
      
      repeat {
        deposit_amount_input <- as.numeric(readline(prompt=sprintf("Deposit Amount (in %s): ", currency_symbols[deposit_currency_index])))
        
        if (!is.na(deposit_amount_input) && deposit_amount_input > 0) {
          converted_php_cents <- math_round(math_round(deposit_amount_input * 100) * current_rate)
          balances_in_cents[account_index] <- balances_in_cents[account_index] + converted_php_cents
          
          cat("\nDeposit successful.\n")
          cat(sprintf("Deposited: %.2f %s = %.2f PHP\n", deposit_amount_input, currency_symbols[deposit_currency_index], converted_php_cents / 100))
          cat(sprintf("Updated Balance: %.2f PHP\n", balances_in_cents[account_index] / 100))
          break
        } else {
          cat("Error: Please enter a positive number (e.g., 500.00).\n")
        }
      }
    } else {
      cat("\nError: Account name not found.\n\n")
      next
    }
    
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking and Currency Exchange Application. Goodbye!\n")
      break
    }
    cat("\n")
  } 
  
  else if (user_menu_choice == 3) {
    cat("\nWithdraw Amount\n")
    search_account_name <- readline(prompt="Enter Account Name: ")
    
    account_index <- match(toupper(search_account_name), toupper(account_names))
    
    if (!is.na(account_index)) {
      cat(sprintf("Account Name: %s\n", account_names[account_index]))
      cat(sprintf("Current Balance: %.2f PHP\n", balances_in_cents[account_index] / 100))
      
      withdraw_currency_index <- select_currency("Select Withdrawal Currency:", TRUE)
      
      if (is.na(withdraw_currency_index)) {
        next
      }
      
      current_rate <- exchange_rates[withdraw_currency_index]
      
      repeat {
        withdraw_amount_input <- as.numeric(readline(prompt=sprintf("Withdraw Amount (in %s): ", currency_symbols[withdraw_currency_index])))
        
        if (!is.na(withdraw_amount_input) && withdraw_amount_input > 0) {
          converted_php_cents <- math_round(math_round(withdraw_amount_input * 100) * current_rate)
          
          if (converted_php_cents <= balances_in_cents[account_index]) {
            balances_in_cents[account_index] <- balances_in_cents[account_index] - converted_php_cents
            cat("\nWithdrawal successful.\n")
            cat(sprintf("Withdrawn: %.2f %s = %.2f PHP\n", withdraw_amount_input, currency_symbols[withdraw_currency_index], converted_php_cents / 100))
            cat(sprintf("Updated Balance: %.2f PHP\n", balances_in_cents[account_index] / 100))
            break
          } else {
            maximum_withdrawal_in_currency <- balances_in_cents[account_index] / current_rate / 100
            cat(sprintf("Transaction Denied: Insufficient balance. You can withdraw up to %.2f %s (%.2f PHP).\n", maximum_withdrawal_in_currency, currency_symbols[withdraw_currency_index], balances_in_cents[account_index] / 100))
            break
          }
        } else {
          cat("Error: Please enter a positive number (e.g., 200.00).\n")
        }
      }
    } else {
      cat("\nError: Account name not found.\n\n")
      next
    }
    
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking and Currency Exchange Application. Goodbye!\n")
      break
    }
    cat("\n")
  } 
  
  else if (user_menu_choice == 4) {
    repeat {
      cat("\nForeign Currency Exchange\n")
      
      source_currency_index <- select_currency("Select Source Currency:", TRUE)
      if (is.na(source_currency_index)) {
        break
      }
      
      source_amount_to_convert <- NA
      repeat {
        source_amount_input <- as.numeric(readline(prompt=sprintf("Source Amount (in %s): ", currency_symbols[source_currency_index])))
        if (!is.na(source_amount_input) && source_amount_input > 0) {
          source_amount_to_convert <- source_amount_input
          break
        }
        cat("Error: Please enter a positive number.\n")
      }
      
      target_currency_index <- select_currency("Select Target Currency:", TRUE)
      if (is.na(target_currency_index)) {
        break
      }
      
      converted_php_cents <- math_round(math_round(source_amount_to_convert * 100) * exchange_rates[source_currency_index])
      target_converted_amount <- math_round(converted_php_cents / exchange_rates[target_currency_index]) / 100
      
      cat(sprintf("\n%.2f %s = %.2f %s\n", source_amount_to_convert, currency_symbols[source_currency_index], target_converted_amount, currency_symbols[target_currency_index]))
      
      repeat {
        convert_again_choice <- readline(prompt="Convert another currency? (Y/N): ")
        convert_again_choice <- toupper(convert_again_choice)
        if (convert_again_choice == "Y" || convert_again_choice == "N") {
          break
        }
        cat("Invalid input. Please enter Y or N.\n")
      }
      
      if (convert_again_choice == "N") {
        break
      }
    }
    cat("\n")
  } 
  
  else if (user_menu_choice == 5) {
    cat("\nRecord Exchange Rate\n")
    cat("Note: Rates are how many PHP equals 1 unit of the foreign currency.\n")
    cat("      Example: USD rate of 52.00 means 1 USD = 52.00 PHP.\n")
    
    record_currency_index <- select_currency("Select Currency to Set Rate For:", FALSE)
    
    if (is.na(record_currency_index)) {
      next
    }
    
    if (record_currency_index == 1) {
      cat("Philippine Peso (PHP) is the base currency. Its rate is always 1.0 and cannot be changed.\n")
      next
    } else {
      repeat {
        new_exchange_rate_input <- as.numeric(readline(prompt=sprintf("Enter exchange rate for %s (PHP per 1 %s): ", currency_symbols[record_currency_index], currency_symbols[record_currency_index])))
        
        if (!is.na(new_exchange_rate_input) && new_exchange_rate_input > 0) {
          exchange_rates[record_currency_index] <- new_exchange_rate_input
          cat(sprintf("Exchange rate set: 1 %s = %.4f PHP\n", currency_symbols[record_currency_index], new_exchange_rate_input))
          break
        } else {
          cat("Error: Please enter a positive number (e.g., 52.00).\n")
        }
      }
    }
    
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking and Currency Exchange Application. Goodbye!\n")
      break
    }
    cat("\n")
  } 
  
  else if (user_menu_choice == 6) {
    cat("\nShow Interest Amount\n")
    search_account_name <- readline(prompt="Enter Account Name: ")
    
    account_index <- match(toupper(search_account_name), toupper(account_names))
    
    if (!is.na(account_index)) {
      cat(sprintf("Account Name: %s\n", account_names[account_index]))
      cat(sprintf("Current Balance: %.2f PHP\n", balances_in_cents[account_index] / 100))
      cat("Interest Rate: 5% per annum\n")
      
      total_number_of_days <- NA
      repeat {
        days_input <- as.integer(readline(prompt="Total Number of Days: "))
        if (!is.na(days_input) && days_input > 0) {
          total_number_of_days <- days_input
          break
        }
        cat("Error: Please enter a whole number greater than 0 (e.g., 30).\n")
      }
      
      cat(sprintf("\n%-5s | %-12s | %s\n", "Day", "Interest", "Balance"))
      cat(paste0(rep("-", 35), collapse=""), "\n")
      
      temporary_balance_cents <- balances_in_cents[account_index]
      daily_compound_rate <- 0.05 / 365
      
      for (day_counter in 1:total_number_of_days) {
        daily_interest_cents <- math_round(temporary_balance_cents * daily_compound_rate)
        temporary_balance_cents <- temporary_balance_cents + daily_interest_cents
        
        cat(sprintf("%-5d | %-12.2f | %.2f\n", day_counter, daily_interest_cents / 100, temporary_balance_cents / 100))
      }
    } else {
      cat("\nError: Account name not found.\n\n")
      next
    }
    
    cat("\n")
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking and Currency Exchange Application. Goodbye!\n")
      break
    }
    cat("\n")
  } 
  
  else if (user_menu_choice == 7) {
    cat("\nView Account Balances\n")
    search_account_name <- readline(prompt="Enter Account Name: ")
    
    account_index <- match(toupper(search_account_name), toupper(account_names))
    
    if (!is.na(account_index)) {
      cat(sprintf("\nSuccess! Balance for account '%s':\n", account_names[account_index]))
      cat(sprintf("- Philippine Peso (PHP): %.2f\n", balances_in_cents[account_index] / 100))
    } else {
      cat("\nError: Account name not found or access denied.\n\n")
      next
    }
    
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking and Currency Exchange Application. Goodbye!\n")
      break
    }
    cat("\n")
  }
  
  else if (user_menu_choice == 0) {
    cat("\nThank you for using the Banking and Currency Exchange Application. Goodbye!\n")
    break
  } 
  
  else {
    cat("Invalid option. Please enter a number from 0 to 7.\n\n")
  }
}

account_names <- c()
balances_matrix <- matrix(double(0), nrow = 0, ncol = 6)

currency_names <- c("Philippine Peso (PHP)", 
                    "United States Dollar (USD)", 
                    "Japanese Yen (JPY)", 
                    "British Pound Sterling (GBP)", 
                    "Euro (EUR)", 
                    "Chinese Yuan Renminni (CNY)")

# Exchange rates based by rates on July 15, 2026, source is Google
exchange_rates <- c(1.0, 61.64, 0.38, 82.89, 70.46, 9.10) 

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

repeat {
  cat("Select Transaction:\n")
  cat("[1] Register Account Name\n")
  cat("[2] Deposit Amount\n")
  cat("[3] Withdraw Amount\n")
  cat("[4] Currency Exchange\n")
  cat("[5] Record Exchange Rates\n")
  cat("[6] Show Interest Computation\n")
  cat("[7] View Account Balances\n")
  cat("[8] Exit Application\n")
  
  cat("\n")
  flush.console()
  user_menu_choice <- as.integer(readline(prompt="Enter choice: "))
  
  if (is.na(user_menu_choice)) {
    cat("Invalid input. Please enter a number from 1 to 8.\n\n")
    next
  }
  
  if (user_menu_choice == 1) {
    cat("\nRegister Account Name\n")
    new_account_name <- readline(prompt="Account Name: ")
    
    if (new_account_name == "") {
      cat("Invalid name. Account name cannot be blank.\n\n")
    } else if (toupper(new_account_name) %in% toupper(account_names)) {
      cat("An account with this name already exists!\n\n")
    } else {
      account_names <- c(account_names, new_account_name)
      balances_matrix <- rbind(balances_matrix, c(0, 0, 0, 0, 0, 0))
      cat(sprintf("\nAccount '%s' successfully registered!\n\n", new_account_name))
    }
    
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking Application. Goodbye!\n")
      break
    }
    cat("\n")
  } 
  
  else if (user_menu_choice %in% c(2, 3, 4, 6, 7) && length(account_names) == 0) {
    cat("\nError: No accounts registered yet. Please register an account first!\n\n")
    
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking Application. Goodbye!\n")
      break
    }
    cat("\n")
  }
  
  else if (user_menu_choice == 2) {
    cat("\nDeposit Amount\n")
    search_account_name <- readline(prompt="Enter Account Name: ")
    
    account_index <- match(toupper(search_account_name), toupper(account_names))
    
    if (!is.na(account_index)) {
      cat(sprintf("\nAccessing Account: %s\n\n", account_names[account_index]))
      cat("Select Currency to Deposit:\n")
      for(index_counter in 1:length(currency_names)) {
        cat(sprintf("[%d] %s\n", index_counter, currency_names[index_counter]))
      }
      
      cat("\n")
      flush.console()
      deposit_currency_choice <- as.integer(readline(prompt="Currency Choice (1-6): "))
      
      if (!is.na(deposit_currency_choice) && deposit_currency_choice >= 1 && deposit_currency_choice <= 6) {
        deposit_amount <- as.numeric(readline(prompt="Deposit Amount: "))
        
        if (!is.na(deposit_amount) && deposit_amount > 0) {
          balances_matrix[account_index, deposit_currency_choice] <- balances_matrix[account_index, deposit_currency_choice] + deposit_amount
          cat(sprintf("\nUpdated %s Balance: %.2f\n\n", currency_names[deposit_currency_choice], balances_matrix[account_index, deposit_currency_choice]))
        } else {
          cat("\nInvalid deposit amount.\n\n")
        }
      } else {
        cat("\nInvalid currency selection.\n\n")
      }
    } else {
      cat("\nError: Account name not found.\n\n")
    }
    
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking Application. Goodbye!\n")
      break
    }
    cat("\n")
  } 
  
  else if (user_menu_choice == 3) {
    cat("\nWithdraw Amount\n")
    search_account_name <- readline(prompt="Enter Account Name: ")
    
    account_index <- match(toupper(search_account_name), toupper(account_names))
    
    if (!is.na(account_index)) {
      cat(sprintf("\nAccessing Account: %s\n\n", account_names[account_index]))
      cat("Your Current Balances:\n")
      for(index_counter in 1:length(currency_names)) {
        cat(sprintf("[%d] %s: %.2f\n", index_counter, currency_names[index_counter], balances_matrix[account_index, index_counter]))
      }
      
      cat("\n")
      flush.console()
      withdraw_currency_choice <- as.integer(readline(prompt="Select Currency to Withdraw From (1-6): "))
      
      if (!is.na(withdraw_currency_choice) && withdraw_currency_choice >= 1 && withdraw_currency_choice <= 6) {
        withdraw_amount <- as.numeric(readline(prompt="Withdraw Amount: "))
        
        if (!is.na(withdraw_amount) && withdraw_amount > 0 && withdraw_amount <= balances_matrix[account_index, withdraw_currency_choice]) {
          balances_matrix[account_index, withdraw_currency_choice] <- balances_matrix[account_index, withdraw_currency_choice] - withdraw_amount
          cat(sprintf("\nUpdated %s Balance: %.2f\n\n", currency_names[withdraw_currency_choice], balances_matrix[account_index, withdraw_currency_choice]))
        } else {
          cat("\nInvalid amount or insufficient balance in that currency.\n\n")
        }
      } else {
        cat("\nInvalid currency selection.\n\n")
      }
    } else {
      cat("\nError: Account name not found.\n\n")
    }
    
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking Application. Goodbye!\n")
      break
    }
    cat("\n")
  } 
  
  else if (user_menu_choice == 4) {
    cat("\nForeign Currency Exchange\n")
    search_account_name <- readline(prompt="Enter Account Name: ")
    
    account_index <- match(toupper(search_account_name), toupper(account_names))
    
    if (!is.na(account_index)) {
      repeat {
        cat(sprintf("\nAccessing Account: %s\n\n", account_names[account_index]))
        
        cat("Current Exchange Rates (Base: PHP):\n")
        for(index_counter in 1:length(currency_names)) {
          cat(sprintf("[%d] %s: %.2f\n", index_counter, currency_names[index_counter], exchange_rates[index_counter]))
        }
        cat("\n")
        
        cat("Your Available Balances:\n")
        for(index_counter in 1:length(currency_names)) {
          cat(sprintf("[%d] %s: %.2f\n", index_counter, currency_names[index_counter], balances_matrix[account_index, index_counter]))
        }
        cat("\n")
        
        cat("Source Currency Option:\n")
        source_currency_choice <- as.integer(readline(prompt="Source Currency (1-6): "))
        source_amount_to_convert <- as.numeric(readline(prompt="Source Amount: "))
        
        cat("\nExchanged Currency Options:\n")
        target_currency_choice <- as.integer(readline(prompt="Exchange Currency (1-6): "))
        
        if (!is.na(source_currency_choice) && !is.na(target_currency_choice) && !is.na(source_amount_to_convert)) {
          
          if (source_amount_to_convert <= balances_matrix[account_index, source_currency_choice] && source_amount_to_convert > 0) {
            
            base_value <- source_amount_to_convert * exchange_rates[source_currency_choice]
            converted_amount <- base_value / exchange_rates[target_currency_choice]
            
            balances_matrix[account_index, source_currency_choice] <- balances_matrix[account_index, source_currency_choice] - source_amount_to_convert
            balances_matrix[account_index, target_currency_choice] <- balances_matrix[account_index, target_currency_choice] + converted_amount
            
            cat(sprintf("\nSuccessfully converted! You received: %.2f %s\n\n", converted_amount, currency_names[target_currency_choice]))
            
            cat("Updated Account Balances:\n")
            for(index_counter in 1:length(currency_names)) {
              cat(sprintf("[%d] %s: %.2f\n", index_counter, currency_names[index_counter], balances_matrix[account_index, index_counter]))
            }
            cat("\n")
            
          } else {
            cat("\nInsufficient funds in the source currency or invalid amount.\n\n")
          }
          
        } else {
          cat("\nInvalid input detected.\n\n")
        }
        
        repeat {
          convert_again_choice <- readline(prompt="Convert another currency (Y/N)? ")
          convert_again_choice <- toupper(convert_again_choice)
          if (convert_again_choice == "Y" || convert_again_choice == "N") {
            break
          }
          cat("Invalid input. Please enter 'Y' or 'N'.\n\n")
        }
        
        if (convert_again_choice == "N") {
          break
        }
      }
    } else {
      cat("\nError: Account name not found.\n\n")
    }
    cat("\n")
  } 
  
  else if (user_menu_choice == 5) {
    cat("\nRecord Exchange Rate\n")
    for(index_counter in 1:length(currency_names)) {
      cat(sprintf("[%d] %s\n", index_counter, currency_names[index_counter]))
    }
    
    cat("\n")
    flush.console()
    selected_currency_index <- as.integer(readline(prompt="Select Foreign Currency: "))
    
    if (!is.na(selected_currency_index) && selected_currency_index >= 1 && selected_currency_index <= 6) {
      new_exchange_rate_input <- as.numeric(readline(prompt="Exchange Rate: "))
      if (!is.na(new_exchange_rate_input) && new_exchange_rate_input > 0) {
        exchange_rates[selected_currency_index] <- new_exchange_rate_input
      } else {
        cat("Invalid exchange rate.\n")
      }
    } else {
      cat("Invalid currency selection.\n")
    }
    
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking Application. Goodbye!\n")
      break
    }
    cat("\n")
  } 
  
  else if (user_menu_choice == 6) {
    cat("\nShow Interest Amount\n")
    search_account_name <- readline(prompt="Enter Account Name: ")
    
    account_index <- match(toupper(search_account_name), toupper(account_names))
    
    if (!is.na(account_index)) {
      cat(sprintf("\nAccount Name: %s\n", account_names[account_index]))
      cat(sprintf("Current PHP Balance: %.2f\n", balances_matrix[account_index, 1])) 
      cat("Currency: PHP\n")
      cat("Interest Rate: 5%\n")
      
      total_number_of_days <- as.integer(readline(prompt="Total Number of Days: "))
      
      if (!is.na(total_number_of_days) && total_number_of_days > 0) {
        cat("\nDay | Interest | Balance \n")
        temporary_balance <- balances_matrix[account_index, 1] 
        
        for(day_counter in 1:total_number_of_days) {
          daily_interest <- temporary_balance * (0.05 / 365)
          temporary_balance <- temporary_balance + daily_interest
          
          cat(sprintf("%-3d | %-8.2f | %.2f \n", day_counter, daily_interest, temporary_balance))
        }
      } else {
        cat("\nInvalid number of days.\n")
      }
    } else {
      cat("\nError: Account name not found.\n\n")
    }
    
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking Application. Goodbye!\n")
      break
    }
    cat("\n")
  } 
  
  else if (user_menu_choice == 7) {
    cat("\nView Account Balances\n")
    search_account_name <- readline(prompt="Enter Account Name: ")
    
    account_index <- match(toupper(search_account_name), toupper(account_names))
    
    if (!is.na(account_index)) {
      cat(sprintf("\nSuccess! Balances for account '%s':\n", account_names[account_index]))
      for(index_counter in 1:length(currency_names)) {
        cat(sprintf("- %s: %.2f\n", currency_names[index_counter], balances_matrix[account_index, index_counter]))
      }
    } else {
      cat("\nError: Account name not found or access denied.\n")
    }
    
    if (!ask_back_to_menu()) {
      cat("\nThank you for using the Banking Application. Goodbye!\n")
      break
    }
    cat("\n")
  }
  
  else if (user_menu_choice == 8) {
    cat("\nThank you for using the Banking Application. Goodbye!\n")
    break
  } 
  
  else {
    cat("\nInvalid choice. Please select a valid option from the menu (1-8).\n\n")
  }
}
/********************
 ┃     Last names: Gutang, Wong, Tolentino, Degullado
 ┃     Language: Kotlin
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
 * File Name: MP_15_Kotlin.kt
 * Group Number: 15
 *
 * Description:
 * This command-line application implements a Banking and Currency
 * Exchange System written in Kotlin. It provides core banking features including account
 * registration, deposits, withdrawals, currency exchange computations, and
 * compounding interest projections.
 *
 * To ensure exact financial precision and prevent floating-point rounding issues,
 * all account balances and currency amounts are represented internally in the
 * smallest monetary unit (centavos/cents) using integer (Long) arithmetic via
 * kotlin.math.round(). Example: 1000.50 PHP is stored as 100050.
 *
 * Academic Integrity Statement:
 * We hereby declare that this submission is our own work and that, to the best of
 * our knowledge and belief, it contains no material previously written or published
 * by another person, nor material which has been accepted for the award of any other
 * degree or diploma, except where due acknowledgment has been made in the text.
 *
 * Run using: kotlinc MP_15_Kotlin.kt -include-runtime -d MP_15_Kotlin.jar
 *            java -jar MP_15_Kotlin.jar
 */

import kotlin.math.round

// CONSTANTS
val CURRENCIES = arrayOf("PHP", "USD", "JPY", "GBP", "EUR", "CNY")
val CURRENCY_FULL_NAMES = arrayOf(
    "Philippine Peso (PHP)",
    "United States Dollar (USD)",
    "Japanese Yen (JPY)",
    "British Pound Sterling (GBP)",
    "Euro (EUR)",
    "Chinese Yuan Renminni (CNY)"
)

// STATE
class AppState {
    var accountName: String? = null                 // unregistered by default
    var balanceCents: Long = 0L                      // balance stored in centavos to avoid float rounding
    val exchangeRates: Array<Double?> = arrayOf(1.0, null, null, null, null, null) // PHP fixed at 1.0
}

// rounds a Double to the nearest Long (equivalent of JS's Math.round)
fun roundToLong(value: Double): Long = round(value).toLong()

// prints prompt text and returns the trimmed line of user input.
fun prompt(text: String): String {
    print(text)
    return readLine()?.trim().orEmpty()
}

fun main() {
    val state = AppState()

    while (true) {
        when (val choice = showMainMenu()) {
            0 -> {
                println("\nThank you for using the Banking and Currency Exchange Application. Goodbye!")
                return
            }
            1 -> registerAccountName(state)
            2 -> depositAmount(state)
            3 -> withdrawAmount(state)
            4 -> currencyExchange(state)
            5 -> recordExchangeRate(state)
            6 -> showInterestComputation(state)
            else -> {} // only returns 0-6
        }
    }
}

// MAIN MENU
fun showMainMenu(): Int {
    while (true) {
        println()
        println("Select Transaction:")
        println("[1] Register Account Name")
        println("[2] Deposit Amount")
        println("[3] Withdraw Amount")
        println("[4] Currency Exchange")
        println("[5] Record Exchange Rates")
        println("[6] Show Interest Computation")
        println("[0] Exit")

        val n = prompt("Select Option: ").toIntOrNull()
        if (n != null && n in 0..6) return n
        println("Invalid option. Please enter a number from 0 to 6.")
    }
}

// Returns the 0-based currency index
fun selectCurrency(state: AppState, promptText: String, requireRegistered: Boolean): Int? {
    while (true) {
        println("\n$promptText")
        println("[0] Cancel (go back)")
        for (i in 0..5) {
            val label = if (state.exchangeRates[i] != null)
                CURRENCY_FULL_NAMES[i]
            else
                "${CURRENCY_FULL_NAMES[i]} (rate not set)"
            println("[${i + 1}] $label")
        }

        val n = prompt("Select Currency: ").toIntOrNull()

        if (n == 0) {
            println("Selection cancelled.")
            return null
        }

        if (n != null && n in 1..6) {
            val idx = n - 1
            if (requireRegistered && state.exchangeRates[idx] == null) {
                println("Error: Exchange rate for ${CURRENCIES[idx]} is not set. Please register it under option [5] first.")
            } else {
                return idx
            }
        } else {
            println("Invalid selection. Enter a number from 0 to 6.")
        }
    }
}

// Register account name
fun registerAccountName(state: AppState) {
    println("\nRegister Account Name")

    while (true) {
        val name = prompt("Account Name: ")
        if (name.isEmpty()) {
            println("Error: Account name cannot be empty. Please try again.")
        } else {
            state.accountName = name
            println("Account name '$name' registered successfully.")
            break
        }
    }
}

// Deposit Amount
fun depositAmount(state: AppState) {
    println("\nDeposit Amount")

    if (state.accountName == null) {
        println("Error: No account registered. Please use option [1] to register first.")
        return
    }

    println("Account Name: ${state.accountName}")
    println("Current Balance: ${"%.2f".format(state.balanceCents / 100.0)} PHP")

    val currencyIdx = selectCurrency(state, "Select Deposit Currency:", true) ?: return
    val rate = state.exchangeRates[currencyIdx]!!

    while (true) {
        val amount = prompt("Deposit Amount (in ${CURRENCIES[currencyIdx]}): ").toDoubleOrNull()

        if (amount != null && amount > 0) {
            val phpCents = roundToLong(roundToLong(amount * 100) * rate)
            state.balanceCents += phpCents
            println("\nDeposit successful.")
            println("Deposited: ${"%.2f".format(amount)} ${CURRENCIES[currencyIdx]} = ${"%.2f".format(phpCents / 100.0)} PHP")
            println("Updated Balance: ${"%.2f".format(state.balanceCents / 100.0)} PHP")
            break
        } else {
            println("Error: Please enter a positive number (e.g., 500.00).")
        }
    }
}

// Withdraw Amount
fun withdrawAmount(state: AppState) {
    println("\nWithdraw Amount")

    if (state.accountName == null) {
        println("Error: No account registered. Please use option [1] to register first.")
        return
    }

    println("Account Name: ${state.accountName}")
    println("Current Balance: ${"%.2f".format(state.balanceCents / 100.0)} PHP")

    val currencyIdx = selectCurrency(state, "Select Withdrawal Currency:", true) ?: return
    val rate = state.exchangeRates[currencyIdx]!!

    while (true) {
        val amount = prompt("Withdraw Amount (in ${CURRENCIES[currencyIdx]}): ").toDoubleOrNull()

        if (amount != null && amount > 0) {
            val phpCents = roundToLong(roundToLong(amount * 100) * rate)

            if (phpCents <= state.balanceCents) {
                state.balanceCents -= phpCents
                println("\nWithdrawal successful.")
                println("Withdrawn: ${"%.2f".format(amount)} ${CURRENCIES[currencyIdx]} = ${"%.2f".format(phpCents / 100.0)} PHP")
                println("Updated Balance: ${"%.2f".format(state.balanceCents / 100.0)} PHP")
                break
            } else {
                val maxInCurrency = state.balanceCents / rate / 100
                println("Transaction Denied: Insufficient balance. You can withdraw up to ${"%.2f".format(maxInCurrency)} ${CURRENCIES[currencyIdx]} (${"%.2f".format(state.balanceCents / 100.0)} PHP).")
            }
        } else {
            println("Error: Please enter a positive number (e.g., 200.00).")
        }
    }
}

// Currency Exchange
fun currencyExchange(state: AppState) {
    while (true) {
        println("\nForeign Currency Exchange")

        val srcIdx = selectCurrency(state, "Select Source Currency:", true) ?: return

        var srcAmount: Double
        while (true) {
            val amount = prompt("Source Amount (in ${CURRENCIES[srcIdx]}): ").toDoubleOrNull()
            if (amount != null && amount > 0) {
                srcAmount = amount
                break
            }
            println("Error: Please enter a positive number.")
        }

        val targetIdx = selectCurrency(state, "Select Target Currency:", true) ?: return

        // Cross-rate conversion: source -> PHP -> target
        val phpCents = roundToLong(roundToLong(srcAmount * 100) * state.exchangeRates[srcIdx]!!)
        val targetAmount = roundToLong(phpCents / state.exchangeRates[targetIdx]!!) / 100.0

        println("\n${"%.2f".format(srcAmount)} ${CURRENCIES[srcIdx]} = ${"%.2f".format(targetAmount)} ${CURRENCIES[targetIdx]}")

        while (true) {
            val answer = prompt("Convert another currency? (Y/N): ").uppercase()
            if (answer == "Y") break
            if (answer == "N") return
            println("Invalid input. Please enter Y or N.")
        }
    }
}

// Record Exchange Rate
fun recordExchangeRate(state: AppState) {
    println("\nRecord Exchange Rate")
    println("Note: Rates are how many PHP equals 1 unit of the foreign currency.")
    println("      Example: USD rate of 52.00 means 1 USD = 52.00 PHP.")

    val currencyIdx = selectCurrency(state, "Select Currency to Set Rate For:", false) ?: return

    if (currencyIdx == 0) {
        println("Philippine Peso (PHP) is the base currency. Its rate is always 1.0 and cannot be changed.")
        return
    }

    while (true) {
        val rate = prompt("Enter exchange rate for ${CURRENCIES[currencyIdx]} (PHP per 1 ${CURRENCIES[currencyIdx]}): ").toDoubleOrNull()
        if (rate != null && rate > 0) {
            state.exchangeRates[currencyIdx] = rate
            println("Exchange rate set: 1 ${CURRENCIES[currencyIdx]} = ${"%.4f".format(rate)} PHP")
            break
        } else {
            println("Error: Please enter a positive number (e.g., 52.00).")
        }
    }
}

// Show Interest Computation
// Daily Interest = (End-of-Day Balance) x (5% / 365)
fun showInterestComputation(state: AppState) {
    println("\nShow Interest Amount")

    if (state.accountName == null) {
        println("Error: No account registered. Please use option [1] to register first.")
        return
    }

    println("Account Name: ${state.accountName}")
    println("Current Balance: ${"%.2f".format(state.balanceCents / 100.0)} PHP")
    println("Interest Rate: 5% per annum")

    var days: Int
    while (true) {
        val d = prompt("Total Number of Days: ").toIntOrNull()
        if (d != null && d > 0) {
            days = d
            break
        }
        println("Error: Please enter a whole number greater than 0 (e.g., 30).")
    }

    println("\n${"Day".padEnd(5)} | ${"Interest".padEnd(12)} | Balance")
    println("-".repeat(35))

    var currentBalanceCents = state.balanceCents
    val DAILY_RATE = 0.05 / 365

    for (day in 1..days) {
        val interestCents = roundToLong(currentBalanceCents * DAILY_RATE)
        currentBalanceCents += interestCents
        println("${day.toString().padEnd(5)} | ${"%.2f".format(interestCents / 100.0).padEnd(12)} | ${"%.2f".format(currentBalanceCents / 100.0)}")
    }
    println()
}
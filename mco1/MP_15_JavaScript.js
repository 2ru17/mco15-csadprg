/********************
 ┃     Last names: Gutang, Wong, Tolentino, Degullado
 ┃     Language: JavaScript
 ┃     Paradigm(s): Multi-paradigm (Structured, Imperative, Functional, Event-Driven)
 ┃     ********************/
/**
 * De La Salle University, Manila
 * College of Computer Studies
 * Department of Software Technology
 *
 * Course Code: CSADPRG (Advanced Programming)
 * Major Course Output #1: Banking and Currency Exchange Application
 *
 * File Name: MP_15_JavaScript.js
 * Group Number: 15
 *
 * Description:
 * This JavaScript (Node.js) command-line application implements a Banking and
 * Currency Exchange System. It provides core banking features including account
 * registration, deposits, withdrawals, currency exchange computations, and
 * compounding interest projections.
 *
 * To ensure exact financial precision and prevent floating-point rounding issues,
 * all account balances and currency amounts are represented internally in the
 * smallest monetary unit (centavos/cents) using integer arithmetic via Math.round().
 * Example: 1000.50 PHP is stored as 100050.
 *
 * Academic Integrity Statement:
 * We hereby declare that this submission is our own work and that, to the best of
 * our knowledge and belief, it contains no material previously written or published
 * by another person, nor material which has been accepted for the award of any other
 * degree or diploma, except where due acknowledgment has been made in the text.
 *
 * Run using: node MP_15_JavaScript.js
 */

// CONSTANTS
const CURRENCIES = ["PHP", "USD", "JPY", "GBP", "EUR", "CNY"];
const CURRENCY_FULL_NAMES = [
  "Philippine Peso (PHP)",
  "United States Dollar (USD)",
  "Japanese Yen (JPY)",
  "British Pound Sterling (GBP)",
  "Euro (EUR)",
  "Chinese Yuan Renminni (CNY)",
];

// INPUT
// Line-queue approach so prompt() works in both interactive and piped (demo/test) modes.
import readline from "readline";

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: process.stdin.isTTY ?? false,
});

const lineQueue = [];
const waitQueue = [];

rl.on("line", (line) => {
  if (waitQueue.length > 0) {
    waitQueue.shift()(line.trim());
  } else {
    lineQueue.push(line.trim());
  }
});

// HELPER - Prints prompt text and returns the next line of user input.
async function prompt(text) {
  process.stdout.write(text);
  if (lineQueue.length > 0) return lineQueue.shift();
  return new Promise((resolve) => waitQueue.push(resolve));
}

// MAIN
async function main() {
  const state = {
    accountName: null, // null = unregistered
    balanceCents: 0, // balance stored in centavos to avoid float rounding
    exchangeRates: [1.0, null, null, null, null, null], // PHP fixed at 1.0
  };

  while (true) {
    const choice = await showMainMenu();
    switch (choice) {
      case 0:
        console.log(
          "\nThank you for using the Banking and Currency Exchange Application. Goodbye!",
        );
        rl.close();
        return;
      case 1:
        await registerAccountName(state);
        break;
      case 2:
        await depositAmount(state);
        break;
      case 3:
        await withdrawAmount(state);
        break;
      case 4:
        await currencyExchange(state);
        break;
      case 5:
        await recordExchangeRate(state);
        break;
      case 6:
        await showInterestComputation(state);
        break;
    }
  }
}

// MAIN MENU
async function showMainMenu() {
  while (true) {
    console.log();
    console.log("Select Transaction:");
    console.log("[1] Register Account Name");
    console.log("[2] Deposit Amount");
    console.log("[3] Withdraw Amount");
    console.log("[4] Currency Exchange");
    console.log("[5] Record Exchange Rates");
    console.log("[6] Show Interest Computation");
    console.log("[0] Exit");

    const n = parseInt(await prompt("Select Option: "));
    if (!isNaN(n) && n >= 0 && n <= 6) return n;
    console.log("Invalid option. Please enter a number from 0 to 6.");
  }
}

// HELPER - Currency Selector
// Returns the 0-based currency index, or null if the user pressed [0] to cancel.
async function selectCurrency(state, promptText, requireRegistered) {
  while (true) {
    console.log(`\n${promptText}`);
    console.log("[0] Cancel (go back)");
    for (let i = 0; i < 6; i++) {
      const label =
        state.exchangeRates[i] !== null
          ? CURRENCY_FULL_NAMES[i]
          : `${CURRENCY_FULL_NAMES[i]} (rate not set)`;
      console.log(`[${i + 1}] ${label}`);
    }

    const n = parseInt(await prompt("Select Currency: "));

    if (n === 0) {
      console.log("Selection cancelled.");
      return null;
    }

    if (!isNaN(n) && n >= 1 && n <= 6) {
      const idx = n - 1;
      if (requireRegistered && state.exchangeRates[idx] === null) {
        console.log(
          `Error: Exchange rate for ${CURRENCIES[idx]} is not set. Please register it under option [5] first.`,
        );
      } else {
        return idx;
      }
    } else {
      console.log("Invalid selection. Enter a number from 0 to 6.");
    }
  }
}

// Register account name
async function registerAccountName(state) {
  console.log("\nRegister Account Name");

  while (true) {
    const name = await prompt("Account Name: ");
    if (name === "") {
      console.log("Error: Account name cannot be empty. Please try again.");
    } else {
      state.accountName = name;
      console.log(`Account name '${name}' registered successfully.`);
      break;
    }
  }
}

// Deposit Amount
async function depositAmount(state) {
  console.log("\nDeposit Amount");

  if (state.accountName === null) {
    console.log(
      "Error: No account registered. Please use option [1] to register first.",
    );
    return;
  }

  console.log(`Account Name: ${state.accountName}`);
  console.log(`Current Balance: ${(state.balanceCents / 100).toFixed(2)} PHP`);

  const currencyIdx = await selectCurrency(
    state,
    "Select Deposit Currency:",
    true,
  );
  if (currencyIdx === null) return;

  const rate = state.exchangeRates[currencyIdx];

  while (true) {
    const amount = parseFloat(
      await prompt(`Deposit Amount (in ${CURRENCIES[currencyIdx]}): `),
    );

    if (!isNaN(amount) && amount > 0) {
      const phpCents = Math.round(Math.round(amount * 100) * rate);
      state.balanceCents += phpCents;
      console.log("\nDeposit successful.");
      console.log(
        `Deposited: ${amount.toFixed(2)} ${CURRENCIES[currencyIdx]} = ${(phpCents / 100).toFixed(2)} PHP`,
      );
      console.log(
        `Updated Balance: ${(state.balanceCents / 100).toFixed(2)} PHP`,
      );
      break;
    } else {
      console.log("Error: Please enter a positive number (e.g., 500.00).");
    }
  }
}

// Withdraw Amount
async function withdrawAmount(state) {
  console.log("\nWithdraw Amount");

  if (state.accountName === null) {
    console.log(
      "Error: No account registered. Please use option [1] to register first.",
    );
    return;
  }

  console.log(`Account Name: ${state.accountName}`);
  console.log(`Current Balance: ${(state.balanceCents / 100).toFixed(2)} PHP`);

  const currencyIdx = await selectCurrency(
    state,
    "Select Withdrawal Currency:",
    true,
  );
  if (currencyIdx === null) return;

  const rate = state.exchangeRates[currencyIdx];

  while (true) {
    const amount = parseFloat(
      await prompt(`Withdraw Amount (in ${CURRENCIES[currencyIdx]}): `),
    );

    if (!isNaN(amount) && amount > 0) {
      const phpCents = Math.round(Math.round(amount * 100) * rate);

      if (phpCents <= state.balanceCents) {
        state.balanceCents -= phpCents;
        console.log("\nWithdrawal successful.");
        console.log(
          `Withdrawn: ${amount.toFixed(2)} ${CURRENCIES[currencyIdx]} = ${(phpCents / 100).toFixed(2)} PHP`,
        );
        console.log(
          `Updated Balance: ${(state.balanceCents / 100).toFixed(2)} PHP`,
        );
        break;
      } else {
        const maxInCurrency = state.balanceCents / rate / 100;
        console.log(
          `Transaction Denied: Insufficient balance. You can withdraw up to ${maxInCurrency.toFixed(2)} ${CURRENCIES[currencyIdx]} (${(state.balanceCents / 100).toFixed(2)} PHP).`,
        );
      }
    } else {
      console.log("Error: Please enter a positive number (e.g., 200.00).");
    }
  }
}

// Currency Exchange
async function currencyExchange(state) {
  while (true) {
    console.log("\nForeign Currency Exchange");

    const srcIdx = await selectCurrency(state, "Select Source Currency:", true);
    if (srcIdx === null) return;

    let srcAmount;
    while (true) {
      const amount = parseFloat(
        await prompt(`Source Amount (in ${CURRENCIES[srcIdx]}): `),
      );
      if (!isNaN(amount) && amount > 0) {
        srcAmount = amount;
        break;
      }
      console.log("Error: Please enter a positive number.");
    }

    const targetIdx = await selectCurrency(
      state,
      "Select Target Currency:",
      true,
    );
    if (targetIdx === null) return;

    // Cross-rate conversion: source -> PHP -> target
    const phpCents = Math.round(
      Math.round(srcAmount * 100) * state.exchangeRates[srcIdx],
    );
    const targetAmount =
      Math.round(phpCents / state.exchangeRates[targetIdx]) / 100;

    console.log(
      `\n${srcAmount.toFixed(2)} ${CURRENCIES[srcIdx]} = ${targetAmount.toFixed(2)} ${CURRENCIES[targetIdx]}`,
    );

    while (true) {
      const answer = (
        await prompt("Convert another currency? (Y/N): ")
      ).toUpperCase();
      if (answer === "Y") break;
      if (answer === "N") return;
      console.log("Invalid input. Please enter Y or N.");
    }
  }
}

// Record Exchange Rate
async function recordExchangeRate(state) {
  console.log("\nRecord Exchange Rate");
  console.log(
    "Note: Rates are how many PHP equals 1 unit of the foreign currency.",
  );
  console.log("      Example: USD rate of 52.00 means 1 USD = 52.00 PHP.");

  const currencyIdx = await selectCurrency(
    state,
    "Select Currency to Set Rate For:",
    false,
  );
  if (currencyIdx === null) return;

  if (currencyIdx === 0) {
    console.log(
      "Philippine Peso (PHP) is the base currency. Its rate is always 1.0 and cannot be changed.",
    );
    return;
  }

  while (true) {
    const rate = parseFloat(
      await prompt(
        `Enter exchange rate for ${CURRENCIES[currencyIdx]} (PHP per 1 ${CURRENCIES[currencyIdx]}): `,
      ),
    );
    if (!isNaN(rate) && rate > 0) {
      state.exchangeRates[currencyIdx] = rate;
      console.log(
        `Exchange rate set: 1 ${CURRENCIES[currencyIdx]} = ${rate.toFixed(4)} PHP`,
      );
      break;
    } else {
      console.log("Error: Please enter a positive number (e.g., 52.00).");
    }
  }
}

// Show Interest Computation
// Daily Interest = (End-of-Day Balance) x (5% / 365)
async function showInterestComputation(state) {
  console.log("\nShow Interest Amount");

  if (state.accountName === null) {
    console.log(
      "Error: No account registered. Please use option [1] to register first.",
    );
    return;
  }

  console.log(`Account Name: ${state.accountName}`);
  console.log(`Current Balance: ${(state.balanceCents / 100).toFixed(2)} PHP`);
  console.log("Interest Rate: 5% per annum");

  let days;
  while (true) {
    const d = parseInt(await prompt("Total Number of Days: "));
    if (!isNaN(d) && d > 0) {
      days = d;
      break;
    }
    console.log(
      "Error: Please enter a whole number greater than 0 (e.g., 30).",
    );
  }

  console.log(`\n${"Day".padEnd(5)} | ${"Interest".padEnd(12)} | Balance`);
  console.log("-".repeat(35));

  let currentBalanceCents = state.balanceCents;
  const DAILY_RATE = 0.05 / 365;

  for (let day = 1; day <= days; day++) {
    const interestCents = Math.round(currentBalanceCents * DAILY_RATE);
    currentBalanceCents += interestCents;
    console.log(
      `${String(day).padEnd(5)} | ${(interestCents / 100).toFixed(2).padEnd(12)} | ${(currentBalanceCents / 100).toFixed(2)}`,
    );
  }
  console.log();
}

// Entry point
main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});

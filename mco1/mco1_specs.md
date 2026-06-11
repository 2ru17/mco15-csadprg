# MAJOR COURSE OUTPUT #1: BANKING AND CURRENCY EXCHANGE APPLICATION

> **DE LA SALLE UNIVERSITY, MANILA**
> 
> 
> **College of Computer Studies**
> 
> 
> **DEPARTMENT OF SOFTWARE TECHNOLOGY**
> 

## 1. INTRODUCTION



This major course output presents the development of a Banking and Currency Exchange Application that demonstrates fundamental concepts in financial technology systems. The application is designed to facilitate core banking operations, including account creation, deposits, withdrawals, and currency exchange computations.

---

## 2. FUNCTIONAL SPECIFICATIONS



### 2.1 Managing Exchange Rate



| REQ # | DETAILS |
| --- | --- |
| **REQ-0001** | Provision to record / register the current exchange rate for the following foreign currencies:<br>

<br>• United States Dollar (USD)<br>

<br>• Japanese Yen (JPY)<br>

<br>• British Pound Sterling (GBP)<br>

<br>• Euro (EUR)<br>

<br>• Chinese Yuan Renminni (CNY)

 |
| **REQ-0002** | Provision to set Philippine Peso (PHP) as Base Currency.

 |
| **REQ-0003** | Provision to convert amount from one currency to another currency.

 |

### 2.2 Managing Bank Transactions



| REQ # | DETAILS |
| --- | --- |
| **REQ-0004** | Provision to deposit money to the user's bank account.

 |
| **REQ-0005** | Provision to withdraw money from the user's bank account.

 |
| **REQ-0006** | Provision to compute the interest of the current value of user's bank account based on the computation below:<br>

<br>• Daily Interest = (End-of-Day Balance) x (Annual Interest Rate / 365)<br>

<br>• Annual Interest: 5% per Annum

 |
| **REQ-0007** | Provision to show the expected daily interest based on the inputted number of expected days.<br>

<br>**Example:**<br>

<br>• Input: 30 Days<br>

<br>• Expected Output: List from Day 1 to Day 30 includes the Balance and Interest Amount

 |
| **REQ-0008** | Provision to transact in different foreign currencies.

 |
| **REQ-0009** | Provision to register / input user's details.

 |

---

## 3. TECHNICAL SPECIFICATION



| REQ # | DETAILS |
| --- | --- |
| **REQ-0010** | Application should be develop / build on the following programming language:<br>

<br>• R<br>

<br>• JavaScript<br>

<br>• Kotlin<br>

<br>• Rust

 |

---

## 4. OUTPUT MOCKUPS



### 4.1 Main Menu



```text
Select Transaction:
[1] Register Account Name
[2] Deposit Amount
[3] Withdraw Amount
[4] Currency Exchange
[5] Record Exchange Rates
[6] Show Interest Computation

```

### 4.2 Register Account Name



```text
Register Account Name
Account Name: Dela Cruz, Juan
Back to the Main Menu (Y/N):

```

### 4.3 Deposit Amount



```text
Deposit Amount
Account Name: Dela Cruz, Juan
Current Balance: 1000.00
Currency: PHP
Deposit Amount: 500.00

Updated Balance: 1500.00

Back to the Main Menu (Y/N):

```

### 4.4 Withdraw Amount



```text
Withdraw Amount
Account Name: Dela Cruz, Juan
Current Balance: 1000.00
Currency: PHP
Withdraw Amount: 500.00

Updated Balance: 500.00

Back to the Main Menu (Y/N):

```

### 4.5 Record Exchange Rate



```text
Record Exchange Rate
[1] Philippine Peso (PHP)
[2] United States Dollar (USD)
[3] Japanese Yen (JPY)
[4] British Pound Sterling (GBP)
[5] Euro (EUR)
[6] Chinese Yuan Renminni (CNY)

Select Foreign Currency: [2]
Exchange Rate: 52.00
Back to the Main Menu (Y/N):

```

### 4.6 Currency Exchange



```text
Foreign Currency Exchange

Source Currency Option:
[1] Philippine Peso (PHP)
[2] United States Dollar (USD)
[3] Japanese Yen (JPY)
[4] British Pound Sterling (GBP)
[5] Euro (EUR)
[6] Chinese Yuan Renminni (CNY)
Source Currency: 2
Source Amount: 1000.00

Exchanged Currency Options:
[1] Philippine Peso (PHP)
[2] United States Dollar (USD)
[3] Japanese Yen (JPY)
[4] British Pound Sterling (GBP)
[5] Euro (EUR)
[6] Chinese Yuan Renminni (CNY)
Exchange Currency: 1
Exchange Amount: 52000.00

Convert another currency (Y/N)?

```

### 4.7 Show Interest Amount



```text
Show Interest Amount
Account Name: Dela Cruz, Juan
Current Balance: 1000.00
Currency: PHP
Interest Rate: 5%
Total Number of Days: 30 days

Day | Interest | Balance 
1   | 0.14     | 1000.14 
2   | 0.14     | 1000.28 
3   | 0.14     | 1000.42 
4   | 0.14     | 1000.56 
4   | 0.14     | 1000.70 

Back to the Main Menu (Y/N):

```

---

## 5. EVALUATION CRITERIA



| Criteria | Description | Points | Details |
| --- | --- | --- | --- |
| **Code Simplicity** | Measures how straightforward and minimal the code is.

 | 5 | **5 pts:** Code is simple and efficient.<br>

<br>**3-4 pts:** Mostly simple, with minor inefficiencies.<br>

<br>**1-2 pts:** Code has unnecessary complexity.<br>

<br>**0 pts:** Code is overly complex or unclear.

 |
| **Performance** | Evaluates how quickly the program executes, especially with large inputs.

 | 5 | **5 pts:** Excellent performance across all inputs.<br>

<br>**3-4 pts:** Minor performance issues with large inputs.<br>

<br>**1-2 pts:** Noticeable lags.<br>

<br>**0 pts:** Poor performance.

 |
| **Code Readability** | Assesses the clarity of the code, including formatting, variable naming, and use of comments.

 | 5 | **5 pts:** Clean, well-organized code.<br>

<br>**3-4 pts:** Some minor readability issues.<br>

<br>**1-2 pts:** Difficult to follow.<br>

<br>**0 pts:** Unreadable code.

 |
| **Correctness** | Checks if the program produces the correct outputs and handles edge cases.

 | 3 | **3 pts:** Correct outputs for all cases.<br>

<br>**2 pts:** Minor mistakes in edge cases.<br>

<br>**1 pt:** Frequent errors.<br>

<br>**0 pts:** Fails to provide correct output.

 |
| **User Experience** | Measures how intuitive and user-friendly the program is, including clear input/output and instructions.

 | 2 | **2 pts:** Smooth, intuitive experience.<br>

<br>**1 pt:** Somewhat confusing interface.<br>

<br>**0 pts:** Poor user experience.

 |

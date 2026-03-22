import json
import os
from datetime import datetime, timedelta
import random

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

def generate_transactions(salary, overspend_categories, savings_rate, num_tx, user_id):
    transactions = []
    # Salary Credit
    salary_date = "2026-03-01"
    transactions.append({
        "date": salary_date,
        "amount": float(salary),
        "type": "CREDIT",
        "narration": "SALARY CREDITED",
        "category": "Salary",
        "balance": float(salary)
    })
    
    current_balance = float(salary)
    categories = ["Food", "Entertainment", "Transport", "Shopping", "Utilities", "Investment"]
    
    # Generate random transactions
    for i in range(num_tx - 1):
        cat = random.choice(categories)
        amount = random.randint(200, 2000)
        # Higher amounts for overspend categories
        if cat in overspend_categories:
            amount = random.randint(1500, 5000)
            
        date = f"2026-03-{random.randint(2, 28):02d}"
        
        # Indian Style Narrations
        narrations = {
            "Food": ["ZOMATO", "SWIGGY", "PUNJABI DHABA", "STARBUCKS"],
            "Entertainment": ["PVR CINEMAS", "NETFLIX", "SPOTIFY", "BOOKMYSHOW"],
            "Transport": ["UBER", "OLA", "PETROL PUMP", "METRO RECHARGE"],
            "Shopping": ["AMAZON", "FLIPKART", "ZARA", "MYNTRA"],
            "Utilities": ["JIO RECHARGE", "AIRTEL BILL", "ELECTRICITY BOARD", "WATER BILL"],
            "Investment": ["ZERODHA SIP", "GROWW", "HDFC MUTUAL FUND"]
        }
        
        narration = random.choice(narrations.get(cat, ["UPI TRANSFER"]))
        
        current_balance -= amount
        transactions.append({
            "date": date,
            "amount": float(amount),
            "type": "DEBIT",
            "narration": narration,
            "category": cat,
            "balance": round(float(current_balance), 2)
        })

    # Sort by date
    transactions.sort(key=lambda x: x['date'])
    
    total_income = salary
    total_expenses = sum(t['amount'] for t in transactions if t['type'] == 'DEBIT')
    savings = total_income - total_expenses
    
    return {
        "transactions": transactions,
        "summary": {
            "total_income": float(total_income),
            "total_expenses": float(total_expenses),
            "savings": float(savings),
            "savings_rate": round((savings / total_income) * 100, 1) if total_income > 0 else 0
        }
    }

# USER 1 - Anirudhh
u1_tx = generate_transactions(35000, ["Food", "Entertainment", "Shopping"], 15, 15, 1)
u1_budget = {
    "Food": {"limit": 4000, "spent": 5200},
    "Entertainment": {"limit": 2000, "spent": 3100},
    "Transport": {"limit": 1500, "spent": 1800},
    "Shopping": {"limit": 3000, "spent": 4500},
    "Utilities": {"limit": 1200, "spent": 1100},
    "Investment": {"limit": 2000, "spent": 0}
}
u1_reminders = [
    {"name": "Jio Recharge", "amount": 299, "due_day": 25, "type": "Bill"},
    {"name": "Netflix", "amount": 649, "due_day": 28, "type": "Bill"}
]

# USER 2 - Priya
u2_tx = generate_transactions(75000, [], 42, 20, 2)
u2_budget = {
    "Food": {"limit": 5000, "spent": 3200},
    "Entertainment": {"limit": 2000, "spent": 800},
    "Transport": {"limit": 3000, "spent": 2100},
    "Shopping": {"limit": 5000, "spent": 3800},
    "Utilities": {"limit": 2000, "spent": 1800},
    "Investment": {"limit": 15000, "spent": 15000}
}
u2_reminders = [
    {"name": "Axis Bluechip SIP", "amount": 5000, "due_day": 5, "type": "SIP"},
    {"name": "LIC Premium", "amount": 8500, "due_day": 27, "type": "Bill"},
    {"name": "Airtel", "amount": 999, "due_day": 22, "type": "Bill"}
]

# USER 3 - Rahul
u3_tx = generate_transactions(120000, ["Shopping", "Entertainment"], 28, 25, 3)
u3_budget = {
    "Food": {"limit": 8000, "spent": 7200},
    "Entertainment": {"limit": 5000, "spent": 6800},
    "Transport": {"limit": 5000, "spent": 4200},
    "Shopping": {"limit": 10000, "spent": 12000},
    "Utilities": {"limit": 3000, "spent": 2800},
    "Investment": {"limit": 20000, "spent": 20000}
}
u3_reminders = [
    {"name": "Home Loan EMI", "amount": 28000, "due_day": 3, "type": "EMI"},
    {"name": "Car Loan EMI", "amount": 12000, "due_day": 5, "type": "EMI"},
    {"name": "Zerodha SIP", "amount": 10000, "due_day": 10, "type": "SIP"}
]

# USER 4 - Sneha
u4_tx = generate_transactions(12000, ["Entertainment", "Shopping"], 5, 10, 4)
u4_budget = {
    "Food": {"limit": 3000, "spent": 3100},
    "Entertainment": {"limit": 500, "spent": 800},
    "Transport": {"limit": 800, "spent": 750},
    "Shopping": {"limit": 1000, "spent": 1200},
    "Utilities": {"limit": 500, "spent": 500},
    "Investment": {"limit": 0, "spent": 0}
}
u4_reminders = [
    {"name": "Hostel Fee", "amount": 8000, "due_day": 1, "type": "Bill"},
    {"name": "Hotstar", "amount": 299, "due_day": 15, "type": "Bill"}
]

# USER 5 - Vikram
u5_tx = generate_transactions(200000, [], 55, 30, 5)
u5_budget = {
    "Food": {"limit": 8000, "spent": 6500},
    "Entertainment": {"limit": 5000, "spent": 3200},
    "Transport": {"limit": 8000, "spent": 7200},
    "Shopping": {"limit": 15000, "spent": 11000},
    "Utilities": {"limit": 5000, "spent": 4200},
    "Investment": {"limit": 80000, "spent": 75000}
}
u5_reminders = [
    {"name": "Mirae Asset SIP", "amount": 20000, "due_day": 3, "type": "SIP"},
    {"name": "HDFC Flexi Cap SIP", "amount": 15000, "due_day": 3, "type": "SIP"},
    {"name": "Axis Small Cap SIP", "amount": 10000, "due_day": 5, "type": "SIP"},
    {"name": "Term Insurance", "amount": 25000, "due_day": 20, "type": "Bill"}
]

# Save all
data_map = {
    1: (u1_tx, u1_budget, u1_reminders),
    2: (u2_tx, u2_budget, u2_reminders),
    3: (u3_tx, u3_budget, u3_reminders),
    4: (u4_tx, u4_budget, u4_reminders),
    5: (u5_tx, u5_budget, u5_reminders)
}

for uid, (tx, budget, reminders) in data_map.items():
    with open(os.path.join(DATA_DIR, f"{uid}_transactions.json"), 'w') as f:
        json.dump(tx, f, indent=2)
    with open(os.path.join(DATA_DIR, f"{uid}_budget.json"), 'w') as f:
        json.dump(budget, f, indent=2)
    with open(os.path.join(DATA_DIR, f"{uid}_reminders.json"), 'w') as f:
        json.dump(reminders, f, indent=2)

print(f"Generated demo data for users 1-5 in {DATA_DIR}")

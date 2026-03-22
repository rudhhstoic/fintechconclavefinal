import os
import json
import logging
import pandas as pd
from finsense.agent import load_json_safe

logger = logging.getLogger(__name__)

def check_warnings(user_id):
    """
    Checks for budget and savings warnings.
    """
    base_path = os.path.join(os.path.dirname(__file__), "..", "data")
    tx_file = os.path.join(base_path, f"{user_id}_transactions.json")
    budget_file = os.path.join(base_path, f"{user_id}_budget.json")

    # Load data
    tx_data = load_json_safe(tx_file, default={"transactions": [], "summary": {}})
    budget_data = load_json_safe(budget_file, default={})

    transactions = tx_data.get("transactions", [])
    summary = tx_data.get("summary", {})
    
    warnings = []

    # 1. Budget Warnings per category
    # budget_data format: {category: {limit: amount, spent: amount}}
    for category, b_info in budget_data.items():
        limit = b_info.get("limit", 0)
        spent = b_info.get("spent", 0)
        
        if limit > 0:
            percent_used = (spent / limit) * 100
            if percent_used >= 100:
                warnings.append({
                    "type": "EXCEEDED",
                    "category": category,
                    "message": f"Budget exceeded for {category}!",
                    "severity": "critical",
                    "amount_spent": spent,
                    "amount_limit": limit,
                    "percentage_used": percent_used
                })
            elif percent_used >= 80:
                warnings.append({
                    "type": "WARNING",
                    "category": category,
                    "message": f"Budget for {category} is nearly used up (80%+)",
                    "severity": "warning",
                    "amount_spent": spent,
                    "amount_limit": limit,
                    "percentage_used": percent_used
                })

    # 2. Savings Rate Warning (< 20%)
    savings_rate = summary.get("savings_rate", 100) # Default to 100 if unknown
    if savings_rate < 20:
        warnings.append({
            "type": "SAVINGS_WARNING",
            "category": "Overall",
            "message": f"Your savings rate is only {savings_rate:.1f}%, which is below the recommended 20%.",
            "severity": "warning",
            "amount_spent": summary.get("total_expenses", 0),
            "amount_limit": summary.get("total_income", 0),
            "percentage_used": 100 - savings_rate
        })

    # 3. Concentration Warning (> 40% in one category)
    total_spend = summary.get("total_expenses", 0)
    category_breakdown = summary.get("category_breakdown", []) # List of {Category, Amount, Percentage}
    
    for cat_summary in category_breakdown:
        cat_name = cat_summary.get("Category", "Other")
        cat_amount = cat_summary.get("Amount", 0)
        cat_percent = cat_summary.get("Percentage", (cat_amount / total_spend * 100) if total_spend > 0 else 0)
        
        if cat_name != "Salary" and cat_percent > 40:
            warnings.append({
                "type": "CONCENTRATION_WARNING",
                "category": cat_name,
                "message": f"Concentration warning: {cat_name} accounts for {cat_percent:.1f}% of your total spending.",
                "severity": "warning",
                "amount_spent": cat_amount,
                "amount_limit": total_spend,
                "percentage_used": cat_percent
            })

    return warnings

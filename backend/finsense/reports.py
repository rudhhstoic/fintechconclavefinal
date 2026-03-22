import os
import json
import logging
from datetime import datetime
import pandas as pd
from finsense.agent import load_json_safe

logger = logging.getLogger(__name__)

def generate_monthly_report(user_id):
    """
    Generates a structured monthly report.
    """
    base_path = os.path.join(os.path.dirname(__file__), "..", "data")
    tx_file = os.path.join(base_path, f"{user_id}_transactions.json")
    
    tx_data = load_json_safe(tx_file, default={"transactions": [], "summary": {}})
    transactions = tx_data.get("transactions", [])
    summary = tx_data.get("summary", {})
    
    if not transactions:
        return {"error": "No transaction data found to generate report."}

    today = datetime.now()
    current_month_name = today.strftime("%B")
    current_year = today.year
    
    # Get total metrics from summary (assuming summary is for current months sync)
    total_income = summary.get("total_income", 0)
    total_expenses = summary.get("total_expenses", 0)
    savings = total_income - total_expenses
    savings_rate_percent = summary.get("savings_rate", 0)
    
    top_3_categories = summary.get("top_spending_categories", [])
    
    # Placeholder for 'vs_last_month' and 'nudges'
    # In a real app, we'd compare against previous snapshots.
    # For now, we'll generate some sample/mock logic for nudges based on current data.
    
    nudges = []
    for cat in top_3_categories:
        if cat.get("Percentage", 0) > 30:
            nudges.append(f"{cat.get('Category')} spend is high at {cat.get('Percentage'):.1f}% of total.")
    
    if savings_rate_percent > 20:
        nudges.append(f"Great job! You saved {savings_rate_percent:.1f}% this month.")
    else:
        nudges.append(f"Consider reducing expenses to reach the 20% savings target.")

    report = {
        "month": current_month_name,
        "year": current_year,
        "total_income": total_income,
        "total_expenses": total_expenses,
        "savings": savings,
        "savings_rate_percent": savings_rate_percent,
        "top_3_categories": top_3_categories,
        "vs_last_month": [
            {"category": "Food", "change_amount": 0, "change_percent": 0}, # Placeholder
            {"category": "Transport", "change_amount": 0, "change_percent": 0}
        ],
        "nudges": nudges[:3] # Limit to 3
    }

    return report

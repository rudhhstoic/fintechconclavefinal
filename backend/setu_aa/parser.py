import json
import logging
from datetime import datetime
import pandas as pd

logger = logging.getLogger(__name__)

CATEGORY_KEYWORDS = {
    "Food": ["swiggy", "zomato", "hotel", "restaurant", "cafe"],
    "Transport": ["uber", "ola", "rapido", "petrol", "fuel"],
    "Shopping": ["amazon", "flipkart", "myntra", "meesho"],
    "Entertainment": ["netflix", "spotify", "prime", "hotstar"],
    "Health": ["pharmacy", "hospital", "clinic", "apollo"],
    "Utilities": ["electricity", "water", "broadband", "airtel", "jio"],
    "Investment": ["zerodha", "groww", "sip", "mutual", "nse", "bse"],
    "Salary": ["salary", "credited by employer"]
}

def categorize_narration(narration):
    narration_lower = narration.lower()
    for category, keywords in CATEGORY_KEYWORDS.items():
        if any(keyword in narration_lower for keyword in keywords):
            return category
    return "Other"

def parse_transactions(raw_fi_data):
    """
    Extract: date, amount, type (DEBIT/CREDIT), narration, balance from each transaction.
    Auto-categorize each transaction.
    """
    parsed_transactions = []
    
    # Setu AA sandbox structure typically:
    # { "FIEntities": [ { "data": [ { "Transactions": { "Transaction": [...] } } ] } ] }
    try:
        entities = raw_fi_data.get("FIEntities", [])
        for entity in entities:
            data_blocks = entity.get("data", [])
            for block in data_blocks:
                tx_container = block.get("Transactions", {})
                tx_list = tx_container.get("Transaction", [])
                
                for tx in tx_list:
                    # Map Setu fields to our standard format
                    # Setu fields: type (DEBIT/CREDIT), amount, narration, currentBalance, transactionTimestamp
                    amount = float(tx.get("amount", 0))
                    tx_type = tx.get("type", "DEBIT").upper()
                    narration = tx.get("narration", "")
                    balance = float(tx.get("currentBalance", 0))
                    timestamp = tx.get("transactionTimestamp", "")
                    
                    # Convert timestamp to a readable date
                    try:
                        date_obj = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                        date_str = date_obj.strftime("%d %b %Y")
                    except:
                        date_str = timestamp # fallback

                    parsed_tx = {
                        "Date": date_str,
                        "Amount": amount,
                        "Type": tx_type,
                        "Narration": narration,
                        "Balance": balance,
                        "Category": categorize_narration(narration)
                    }
                    parsed_transactions.append(parsed_tx)
    except Exception as e:
        logger.error(f"Error parsing FI data: {str(e)}")
        
    return parsed_transactions

def get_summary(transactions):
    """
    Total income, total expenses, savings rate.
    Breakdown by category with amount and percentage.
    Top 3 spending categories.
    Month over month comparison if 2+ months of data.
    """
    if not transactions:
        return {}

    df = pd.DataFrame(transactions)
    
    # Calculate totals
    total_income = df[df['Type'] == 'CREDIT']['Amount'].sum()
    total_expenses = df[df['Type'] == 'DEBIT']['Amount'].sum()
    savings_rate = ((total_income - total_expenses) / total_income * 100) if total_income > 0 else 0

    # Category breakdown
    expenses_df = df[df['Type'] == 'DEBIT']
    category_summary = expenses_df.groupby('Category')['Amount'].sum().reset_index()
    category_summary['Percentage'] = (category_summary['Amount'] / total_expenses * 100) if total_expenses > 0 else 0
    
    breakdown = category_summary.to_dict(orient="records")

    # Top 3 spending categories (excluding 'Other' if possible, or just top 3)
    top_3 = category_summary.sort_values(by='Amount', ascending=False).head(3).to_dict(orient="records")

    # Month over month comparison
    # First, ensure we have a datetime column
    df['dt'] = pd.to_datetime(df['Date'], format='%d %b %Y', errors='coerce')
    df = df.dropna(subset=['dt'])
    df['MonthYear'] = df['dt'].dt.to_period('M')
    
    mom_summary = df.groupby(['MonthYear', 'Type'])['Amount'].sum().unstack(fill_value=0).reset_index()
    mom_summary['MonthYear'] = mom_summary['MonthYear'].astype(str)
    
    mom_data = mom_summary.to_dict(orient="records")

    return {
        "total_income": total_income,
        "total_expenses": total_expenses,
        "savings_rate": savings_rate,
        "category_breakdown": breakdown,
        "top_spending_categories": top_3,
        "month_over_month": mom_data
    }

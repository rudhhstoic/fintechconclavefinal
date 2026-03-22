import json
import os
import requests
import logging
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

def load_json_safe(file_path, default=None):
    if default is None:
        default = {}
    if not os.path.exists(file_path):
        return default
    try:
        with open(file_path, 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading {file_path}: {str(e)}")
        return default

def chat(user_id, user_message, conversation_history=None):
    """
    Calls Groq API with full financial context.
    Groq is free and extremely fast (sub-second responses).
    """
    if conversation_history is None:
        conversation_history = []

    # File paths
    base_path = os.path.join(os.path.dirname(__file__), "..", "data")
    tx_file = os.path.join(base_path, f"{user_id}_transactions.json")
    budget_file = os.path.join(base_path, f"{user_id}_budget.json")

    # Load data
    tx_data = load_json_safe(tx_file, default={"transactions": [], "summary": {}, "overall_recommendations": []})
    budget_data = load_json_safe(budget_file, default={})

    transactions = tx_data.get("transactions", [])
    summary = tx_data.get("summary", {})

    # Build category spend summary from transactions
    category_spend = {}
    for tx in transactions:
        if tx.get("type") == "DEBIT":
            cat = tx.get("category", "Other")
            category_spend[cat] = category_spend.get(cat, 0) + tx.get("amount", 0)

    # Build system prompt with full financial context
    system_prompt = f"""You are FinSense, a proactive personal finance AI assistant built into a fintech app for Indian users.
You have access to the user's real financial data. Always answer based on their actual data.
Be concise, friendly, and use Indian currency format (₹).

USER'S FINANCIAL DATA:
━━━━━━━━━━━━━━━━━━━━
Monthly Summary:
- Total Income: ₹{summary.get('total_income', 0):,}
- Total Expenses: ₹{summary.get('total_expenses', 0):,}
- Savings: ₹{summary.get('savings', 0):,}
- Savings Rate: {summary.get('savings_rate', 0)}%

Spending by Category this month:
{json.dumps(category_spend, indent=2)}

Budget Status:
{json.dumps(budget_data, indent=2)}

Overall Recommendations from analysis:
{json.dumps(tx_data.get('overall_recommendations', []), indent=2)}
━━━━━━━━━━━━━━━━━━━━

Rules:
- Always answer from the user's actual data above
- Keep responses under 100 words unless asked for detail
- Use ₹ symbol for all amounts
- Be encouraging but honest about overspending
- If asked something not in the data, say you don't have that info yet
"""

    # Groq API call
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        return "Error: GROQ_API_KEY not found in environment variables."

    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    # Build messages with history
    messages = [{"role": "system", "content": system_prompt}]
    
    # Add conversation history (last 6 messages to keep context window small)
    for msg in conversation_history[-6:]:
        messages.append(msg)
    
    # Add current user message
    messages.append({"role": "user", "content": user_message})

    payload = {
        "model": "llama-3.1-8b-instant",  # Fast, free Groq model
        "messages": messages,
        "max_tokens": 300,
        "temperature": 0.7
    }

    try:
        response = requests.post(url, headers=headers, json=payload, timeout=10)
        response.raise_for_status()
        result = response.json()
        return result['choices'][0]['message']['content']
    except requests.exceptions.Timeout:
        return "Sorry, the response took too long. Please try again."
    except requests.exceptions.HTTPError as e:
        logger.error(f"Groq HTTP error: {e.response.text}")
        return f"I'm having trouble connecting right now. Please try again."
    except Exception as e:
        logger.error(f"Groq error: {str(e)}")
        return f"Something went wrong. Please try again."
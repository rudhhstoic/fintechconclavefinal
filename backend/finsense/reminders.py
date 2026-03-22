import os
import json
import logging
from datetime import datetime, timedelta
from finsense.agent import load_json_safe

logger = logging.getLogger(__name__)

def get_reminders(user_id):
    """
    Checks for reminders due in the next 3 days.
    """
    base_path = os.path.join(os.path.dirname(__file__), "..", "data")
    reminders_file = os.path.join(base_path, f"{user_id}_reminders.json")
    
    reminders_list = load_json_safe(reminders_file, default=[])
    
    today = datetime.now()
    due_results = []

    for rem in reminders_list:
        name = rem.get("name")
        amount = rem.get("amount")
        due_day = int(rem.get("due_day", 1))
        rem_type = rem.get("type", "Bill")
        
        # Calculate due date for current month
        try:
            # If due_day is 31 and month has 30, use last day of month
            import calendar
            last_day = calendar.monthrange(today.year, today.month)[1]
            actual_due_day = min(due_day, last_day)
            
            due_date = datetime(today.year, today.month, actual_due_day)
            
            # If due_date is in the past, it's likely for next month
            if (due_date - today).days < -1: # allow 1 day buffer for today
                next_month = today.month + 1
                year = today.year
                if next_month > 12:
                    next_month = 1
                    year += 1
                last_day_next = calendar.monthrange(year, next_month)[1]
                due_date = datetime(year, next_month, min(due_day, last_day_next))
            
            days_left = (due_date - today).days + 1
            
            if 0 <= days_left <= 3:
                due_results.append({
                    "name": name,
                    "amount": amount,
                    "due_date": due_date.strftime("%d %b %Y"),
                    "days_left": days_left,
                    "type": rem_type,
                    "message": f"Your ₹{amount} {name} {rem_type} is due in {days_left} day{'s' if days_left != 1 else ''}" if days_left > 0 else f"Your ₹{amount} {name} {rem_type} is due TODAY"
                })
        except Exception as e:
            logger.error(f"Error calculating due date for {name}: {str(e)}")

    return due_results

def save_reminder(user_id, reminder):
    """
    Saves a new reminder.
    reminder block: {name, amount, due_day, type}
    """
    base_path = os.path.join(os.path.dirname(__file__), "..", "data")
    reminders_file = os.path.join(base_path, f"{user_id}_reminders.json")
    
    reminders_list = load_json_safe(reminders_file, default=[])
    reminders_list.append(reminder)
    
    try:
        with open(reminders_file, 'w') as f:
            json.dump(reminders_list, f, indent=4)
        return True
    except Exception as e:
        logger.error(f"Error saving reminder: {str(e)}")
        return False

from flask import Flask, jsonify, request
from flask_cors import CORS
import logging
from finsense.agent import chat
from finsense.warnings import check_warnings
from finsense.reminders import get_reminders, save_reminder
from finsense.reports import generate_monthly_report

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route('/api/finsense/chat', methods=['POST'])
def finsense_chat():
    """
    Body: {user_id, message, history: [...]}
    Returns: {response: string}
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "No JSON payload provided"}), 400
        
    user_id = data.get('user_id')
    message = data.get('message')
    history = data.get('history', [])
    
    if not user_id or not message:
        return jsonify({"error": "user_id and message are required"}), 400
        
    response_text = chat(user_id, message, history)
    return jsonify({"response": response_text})

@app.route('/api/finsense/warnings/<user_id>', methods=['GET'])
def finsense_warnings(user_id):
    """
    Returns: {warnings: [...]}
    """
    try:
        warnings = check_warnings(user_id)
        return jsonify({"warnings": warnings})
    except Exception as e:
        logger.error(f"Error fetching warnings: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/finsense/reminders/<user_id>', methods=['GET'])
def finsense_get_reminders(user_id):
    """
    Returns: {reminders: [...]}
    """
    try:
        reminders = get_reminders(user_id)
        return jsonify({"reminders": reminders})
    except Exception as e:
        logger.error(f"Error fetching reminders: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/finsense/reminders/<user_id>', methods=['POST'])
def finsense_save_reminder(user_id):
    """
    Body: {name, amount, due_day, type}
    Returns: {success: true}
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "No JSON payload provided"}), 400
        
    name = data.get('name')
    amount = data.get('amount')
    due_day = data.get('due_day')
    rem_type = data.get('type')
    
    if not all([name, amount, due_day, rem_type]):
        return jsonify({"error": "name, amount, due_day, and type are required"}), 400
        
    reminder = {
        "name": name,
        "amount": amount,
        "due_day": due_day,
        "type": rem_type
    }
    
    success = save_reminder(user_id, reminder)
    return jsonify({"success": success})

@app.route('/api/finsense/report/<user_id>', methods=['GET'])
def finsense_report(user_id):
    """
    Returns full monthly report dict
    """
    try:
        report = generate_monthly_report(user_id)
        return jsonify(report)
    except Exception as e:
        logger.error(f"Error generating report: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Defaulting to 5013 to avoid collision with existing services
    app.run(debug=True, host='0.0.0.0', port=5013)

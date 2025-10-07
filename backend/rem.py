from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.executors.pool import ThreadPoolExecutor
from twilio.rest import Client
from datetime import datetime
import logging

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:anirudhh@localhost:5432/Archons'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)
CORS(app)

# Twilio configuration
account_sid = 'ACc4d98c59cb9035467810af9b427704f7'  # Replace with your Twilio Account SID
auth_token = '64b75198565a9d6f673117f5fc3d627e'      # Replace with your Twilio Auth Token
twilio_whatsapp_number = 'whatsapp:+14155238886'     # Twilio's WhatsApp sandbox number
client = Client(account_sid, auth_token)

# APScheduler configuration
scheduler = BackgroundScheduler(executors={'default': ThreadPoolExecutor(1)})
scheduler.start()

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Models
class Customer(db.Model):
    __tablename__ = 'customer'
    serial_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(20), unique=True, nullable=False)
    password = db.Column(db.String(10), nullable=False) 

class Reminder(db.Model):
    __tablename__ = 'reminder'
    reminder_id = db.Column(db.Integer, primary_key=True) 
    serial_id = db.Column(db.Integer, db.ForeignKey('customer.serial_id', ondelete='CASCADE'), nullable=False)
    date = db.Column(db.DateTime, nullable=False) 
    description = db.Column(db.String(100), nullable=False) 
    mobile_number = db.Column(db.String(15), nullable=False)

# Send WhatsApp message function
def send_whatsapp_message(to_number, message_body):
    try:
        message = client.messages.create(
            body=message_body,
            from_=twilio_whatsapp_number,
            to=f'whatsapp:{to_number}'
        )
        logger.info(f"WhatsApp message sent successfully! Message SID: {message.sid}")
    except Exception as e:
        logger.error(f"Failed to send WhatsApp message: {e}")

# Route to set reminder
@app.route('/set_reminder/<int:serial_id>', methods=['POST'])
def set_reminder(serial_id):
    data = request.json
    try:
        reminder_date_str = data.get('date')
        description = data.get('description')
        mobile_number = data.get('mobileno')

        if not all([serial_id, reminder_date_str, description, mobile_number]):
            return jsonify({'message': 'Missing required fields'}), 400

        reminder_date = datetime.strptime(reminder_date_str, "%Y-%m-%d %H:%M:%S")

        new_reminder = Reminder(serial_id=serial_id, date=reminder_date, description=description, mobile_number=mobile_number)
        db.session.add(new_reminder)
        db.session.commit()

        message_body = f"Reminder! 📅 You have an event on {reminder_date.strftime('%Y-%m-%d %H:%M')}. Description: {description}. Don't miss it!"
        send_whatsapp_message(mobile_number, message_body)
        
        return jsonify({'message': 'Reminder set successfully and WhatsApp notification sent!'}), 200

    except Exception as e:
        db.session.rollback()
        logger.error(f"Error setting reminder: {e}")
        return jsonify({'message': f'Error setting reminder: {str(e)}'}), 500

# Route to get reminders for a specific serial_id
@app.route('/get_reminders/<int:serial_id>', methods=['GET'])
def get_reminders(serial_id):
    try:
        reminders = Reminder.query.filter_by(serial_id=serial_id).all()
        return jsonify([{'reminder_id': r.reminder_id, 'date': r.date.isoformat(), 'description': r.description, 'mobile_number': r.mobile_number} for r in reminders]), 200
    except Exception as e:
        logger.error(f"Error fetching reminders: {e}")
        return jsonify({'message': f'Error fetching reminders: {str(e)}'}), 500

# Route to update reminder
@app.route('/update_reminder/<int:reminder_id>', methods=['POST'])
def update_reminder(reminder_id):
    try:
        description = request.json.get('description')
        date_str = request.json.get('date')
        mobile_number = request.json.get('mobile_number')
        
        reminder = Reminder.query.get(reminder_id)
        if not reminder:
            return jsonify({'message': 'Reminder not found'}), 404

        reminder.description = description
        reminder.date = datetime.strptime(date_str, "%Y-%m-%d %H:%M:%S")
        reminder.mobile_number = mobile_number
        
        db.session.commit()
        return jsonify({'message': 'Reminder updated successfully'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error updating reminder: {e}")
        return jsonify({'message': f'Error updating reminder: {str(e)}'}), 500

# Route to delete reminder
@app.route('/delete_reminder/<int:reminder_id>', methods=['POST'])
def delete_reminder(reminder_id):
    try:
        reminder_id = request.json.get('reminder_id')
        
        reminder = Reminder.query.get(reminder_id)
        if not reminder:
            return jsonify({'message': 'Reminder not found'}), 404
        
        db.session.delete(reminder)
        db.session.commit()
        return jsonify({'message': 'Reminder deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Error deleting reminder: {e}")
        return jsonify({'message': f'Error deleting reminder: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(debug=True)

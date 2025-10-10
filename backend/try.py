from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import func, and_
from decimal import Decimal
from dotenv import load_dotenv
import os
import bcrypt
import psycopg2
import binascii
import random
import pandas as pd
import requests
import joblib
from datetime import datetime, timedelta
from bot import FinanceChatbotModel  # Import your chatbot model class
import numpy as np
from savings import save_model
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.executors.pool import ThreadPoolExecutor
from twilio.rest import Client
import logging
from statement import read_and_concat_tables
import yfinance as yf

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Load environment variables
load_dotenv()

# App Configuration
app.config['SECRET_KEY'] = binascii.hexlify(os.urandom(24)).decode()
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:Archana@localhost:5432/Archons'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# API Keys
NEWS_API_KEY = os.getenv("NEWS_API_KEY")  # For NewsAPI
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")  # For chatbot
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

# Initialize chatbot model
chatbot = FinanceChatbotModel(GEMINI_API_KEY)

# Load budget recommendation model
model = joblib.load(r'D:\Project\fintechconclavefinal\backend\models\budget_recommendation_model.pkl')

# Define Database Models
class Customer(db.Model):
    __tablename__ = 'customer'
    serial_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(20), unique=True, nullable=False)
    password = db.Column(db.String(10), nullable=False)  # Note: Use hashing for passwords in production!

class Record(db.Model):
    __tablename__ = 'records'
    record_id = db.Column(db.Integer, primary_key=True)
    serial_id = db.Column(db.Integer, db.ForeignKey('customer.serial_id', ondelete='CASCADE'), nullable=False)
    transaction_date = db.Column(db.Date, nullable=False)
    transaction_type = db.Column(db.String(10), nullable=False)
    category = db.Column(db.String(50), nullable=False)
    amount = db.Column(db.Numeric(15, 2), nullable=False)
    total = db.Column(db.Numeric(15, 2))

class Budget(db.Model):
    __tablename__ = 'budgets'
    budget_id = db.Column(db.Integer, primary_key=True)
    serial_id = db.Column(db.Integer, db.ForeignKey('customer.serial_id', ondelete='CASCADE'), nullable=False)
    category = db.Column(db.String(50), nullable=False)
    budget_limit = db.Column(db.Numeric(15, 2), nullable=False)
    spent = db.Column(db.Numeric(15, 2), default=0)
    remaining = db.Column(db.Numeric(15, 2))
    # Foreign key relationship with the Customer model
    customer = db.relationship("Customer", backref=db.backref("budgets", cascade="all, delete-orphan"))

class Vacation(db.Model):
    __tablename__ = 'vacation'
    vacation_id = db.Column(db.Integer, primary_key=True)
    serial_id = db.Column(db.Integer, db.ForeignKey('customer.serial_id', ondelete='CASCADE'), nullable=False)
    place = db.Column(db.String(100), nullable=False)
    air_cost = db.Column(db.Numeric(15, 2), nullable=False)
    days = db.Column(db.Integer, nullable=False)
    budget_range = db.Column(db.String(50), nullable=False)
    time_range = db.Column(db.String(50), nullable=False)

class Reminder(db.Model):
    __tablename__ = 'reminder'
    reminder_id = db.Column(db.Integer, primary_key=True) 
    serial_id = db.Column(db.Integer, db.ForeignKey('customer.serial_id', ondelete='CASCADE'), nullable=False)
    date = db.Column(db.DateTime, nullable=False) 
    description = db.Column(db.String(100), nullable=False) 
    mobile_number = db.Column(db.String(15), nullable=False)

class MutualFund(db.Model):
    __tablename__ = 'mutual_funds'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column("name", db.String(100))
    category_main = db.Column("category_main", db.String(50))
    category_sub = db.Column("category_sub", db.String(50))
    amc = db.Column("amc", db.String(100))
    current_value = db.Column("current_value", db.String(20))
    return_per_annum = db.Column("return_per_annum", db.String(20))
    expense_ratio = db.Column("expense_ratio", db.String(10))
    return_1_month = db.Column("return1month", db.String(10))
    return_3_month = db.Column("return3month", db.String(10))
    return_6_month = db.Column("return6month", db.String(10))
    age = db.Column("age", db.String(20))

    def to_dict(self):
        return {
            'name': self.name or '',
            'category': {
                'main': self.category_main or '',
                'sub': self.category_sub or ''
            },
            'amc': self.amc or '',
            'current_value': self.current_value or '',
            'return_per_annum': self.return_per_annum or '',
            'return_1_month': self.return_1_month or '',
            'return_3_month': self.return_3_month or '',
            'return_6_month': self.return_6_month or '',
            'expense_ratio': self.expense_ratio or '',
            'age': self.age or ''
        }

def calculate_tax(data):
    # Extract inputs
    financial_year = data.get('financial_year')
    basic_income = float(data.get('basic_income', 0))
    special_income = float(data.get('special_income', 0))
    hra_received = float(data.get('hra_received', 0))
    deductions = data.get('deductions', {})
    capital_gains = data.get('capital_gains', {})

    # Calculate gross salary and other inputs
    gross_salary = basic_income + special_income + hra_received
    total_deductions = (
        deductions.get('deduction80C', 0) +
        deductions.get('deduction80D', 0) +
        deductions.get('deduction80E', 0) +
        deductions.get('deduction80G', 0)
    )
    # Capital gains (if needed for specific tax treatment)
    total_capital_gains = sum(capital_gains.values())

    # Calculate taxable income
    taxable_income = gross_salary - total_deductions
    income_tax = 0

    # Apply tax slabs based on the financial year
    if financial_year == '2023-24':
        if taxable_income <= 300000:
            income_tax = 0
        elif taxable_income <= 600000:
            income_tax = (taxable_income - 300000) * 0.05
        elif taxable_income <= 900000:
            income_tax = (taxable_income - 600000) * 0.1 + 15000
        elif taxable_income <= 1200000:
            income_tax = (taxable_income - 900000) * 0.15 + 45000
        elif taxable_income <= 1500000:
            income_tax = (taxable_income - 1200000) * 0.2 + 90000
        else:
            income_tax = (taxable_income - 1500000) * 0.3 + 150000
    elif financial_year == '2024-25':
        if taxable_income <= 300000:
            income_tax = 0
        elif taxable_income <= 700000:
            income_tax = (taxable_income - 300000) * 0.05
        elif taxable_income <= 1000000:
            income_tax = (taxable_income - 700000) * 0.1 + 20000
        elif taxable_income <= 1200000:
            income_tax = (taxable_income - 1000000) * 0.15 + 50000
        elif taxable_income <= 1500000:
            income_tax = (taxable_income - 1200000) * 0.2 + 80000
        else:
            income_tax = (taxable_income - 1500000) * 0.3 + 140000

    # Calculate rebate under Section 87A if applicable
    rebate = 0
    if financial_year == '2024-25' and taxable_income <= 700000:
        rebate = min(12500, income_tax)

    # Final tax after rebate
    tax_after_rebate = income_tax - rebate

    # Health and Education Cess at 4%
    cess = tax_after_rebate * 0.04
    total_tax_liability = tax_after_rebate + cess

    return {
        "actual_tax": income_tax,
        "rebate": rebate,
        "tax_after_rebate": tax_after_rebate,
        "cess": cess,
        "total_tax_liability": total_tax_liability,
        "total_deductions":total_deductions
    }


with app.app_context():
    db.create_all()

# Helper: Database connection
def get_db_connection():
    try:
        conn = psycopg2.connect(
            host="localhost",
            port="5432",
            database="Archons",
            user="postgres",
            password="Archana"
        )
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        return None

# User Authentication Endpoints
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'message': 'Username and password are required'}), 400

    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

    conn = get_db_connection()
    if conn is None:
        return jsonify({'message': 'Database connection failed'}), 500

    cur = conn.cursor()
    try:
        name = ''.join(filter(lambda z: not z.isdigit(), username.split('@')[0]))
        cur.execute("INSERT INTO customer (username, password) VALUES (%s, %s) RETURNING serial_id",
                    (username, hashed_password.decode('utf-8')))
        serial_id = cur.fetchone()[0]
        conn.commit()
        return jsonify({'message': 'User registered successfully', 'serial_id': serial_id, "name" : name.title()}), 201
    except psycopg2.IntegrityError:
        conn.rollback()
        return jsonify({'message': 'Username already exists'}), 409
    finally:
        cur.close()
        conn.close()

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'message': 'Username and password are required'}), 400

    conn = get_db_connection()
    if conn is None:
        return jsonify({'message': 'Database connection failed'}), 500

    cursor = conn.cursor()
    try:
        cursor.execute("SELECT password, serial_id FROM customer WHERE username = %s", (username,))
        result = cursor.fetchone()
        name = ''.join(filter(lambda z: not z.isdigit(), username.split('@')[0]))
        print(name)
        if result:
            stored_hashed_password, serial_id = result
            if bcrypt.checkpw(password.encode('utf-8'), stored_hashed_password.encode('utf-8')):
                return jsonify({'message': 'Login successful', 'serial_id': serial_id ,"name" : name.title()}), 200
            else:
                return jsonify({'message': 'Invalid credentials'}), 401
        else:
            return jsonify({'message': 'Invalid credentials'}), 401
    finally:
        cursor.close()
        conn.close()

# News Articles Endpoint
@app.route('/get_articles', methods=['GET'])
def get_articles():
    url = f'https://newsapi.org/v2/everything?q=finance management&apiKey={NEWS_API_KEY}'
    try:
        response = requests.get(url)
        data = response.json()
        if 'articles' in data:
            articles = data['articles'][:100]
            formatted_articles = [
                {
                    "title": article['title'],
                    "description": article['description'],
                    "url": article['url'],
                    "source": article['source']['name']
                }
                for article in articles
            ]
            return jsonify(formatted_articles), 200
        else:
            return jsonify({"error": "No articles found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Chatbot Endpoint
@app.route("/chatbot", methods=["POST"])
def chatbot_interaction():
    data = request.get_json()
    user_message = data.get("message", "")
    if not user_message:
        return jsonify({"error": "No message provided"}), 400
    try:
        bot_response = chatbot.get_response(user_message)
        return jsonify({"response": bot_response}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Dashboard
@app.route('/dashboard', methods=['GET'])
def dashboard():
    return "Welcome to the HomePage!"

@app.route('/add_transaction', methods=['POST'])
def add_transaction():
    #if 'serial_id' not in session:
    #    return jsonify({"message": "User not logged in"}), 401
    
    #serial_id = session['serial_id']  # Get serial_id from session
    data = request.get_json()
    serial_id = data['serial_id']
    amount = Decimal(data['amount'])  # Convert amount to Decimal
    transaction_type = data['transaction_type']
    category = data['category']

    # Calculate current total balance (income - expense) for this serial_id
    income_total = db.session.query(func.sum(Record.amount)).filter_by(serial_id=serial_id, transaction_type='Income').scalar() or Decimal('0')
    expense_total = db.session.query(func.sum(Record.amount)).filter_by(serial_id=serial_id, transaction_type='Expense').scalar() or Decimal('0')
    current_balance = income_total - expense_total

    # Get current date
    transaction_date = datetime.now().date()

    # Adjust balance based on the new transaction
    if transaction_type == 'Income':
        current_balance += amount
    elif transaction_type == 'Expense':
        current_balance -= amount
        # Update spent amount in the budget
        budget = Budget.query.filter_by(serial_id=serial_id, category=category).first()
        if budget:
            budget.spent += amount
            db.session.commit()

    # Create the new transaction record
    new_transaction = Record(
        serial_id=serial_id,
        transaction_date= transaction_date,
        transaction_type=transaction_type,
        category=data['category'],
        amount=amount,
        total=current_balance  # Store the calculated total balance here
    )
    db.session.add(new_transaction)
    db.session.commit()

    return jsonify({
        "message": "Transaction added successfully",
        "transaction": {
            "record_id": new_transaction.record_id,
            "serial_id": new_transaction.serial_id,
            "transaction_date": new_transaction.transaction_date,
            "transaction_type": new_transaction.transaction_type,
            "category": new_transaction.category,
            "amount": new_transaction.amount,
            "total": new_transaction.total  # Confirm the updated total balance
        }
    })


@app.route('/get_transaction/<int:serial_id>', methods=['GET'])
def get_transactions(serial_id):
    user = Customer.query.filter_by(serial_id=serial_id).first()
    if not user:
        return jsonify({"message": "User not found"}), 404
    
    records = Record.query.filter_by(serial_id=user.serial_id).all()
    output = []
    for record in records:
        record_data = {
            'record_id': record.record_id,
            'transaction_date': record.transaction_date.strftime('%a, %d %b %Y'),
            'transaction_type': record.transaction_type,
            'category': record.category,
            'amount': f"{record.amount:.2f}",
            'total': f"{record.total:.2f}" if record.total else None
        }
        output.append(record_data)
    return jsonify(output)

@app.route('/update_transaction/<int:record_id>', methods=['PUT'])
def update_transaction(record_id):
    data = request.get_json()
    record = Record.query.get(record_id)
    if not record:
        return jsonify({"message": "Transaction not found"}), 404

    # Update the transaction details
    record.transaction_date = datetime.strptime(data['transaction_date'], '%Y-%m-%d')
    record.transaction_type = data['transaction_type']
    record.category = data['category']
    record.amount = data['amount']
    
    # Get the serial_id of the user associated with this transaction (assuming you have a way to get it)
    serial_id = record.serial_id  # Assuming the Record model has a reference to serial_id

    # Calculate total income and total expense for this serial_id
    transactions = Record.query.filter_by(serial_id=serial_id).all()
    total_income = sum(Decimal(t.amount) for t in transactions if t.transaction_type == 'Income')
    total_expense = sum(Decimal(t.amount) for t in transactions if t.transaction_type == 'Expense')
    
    # Update the total based on the new income and expense calculations
    new_total = total_income - total_expense
    # If you want to store the total in the record itself, you could do this:
    record.total = new_total
    
    db.session.commit()
    return jsonify({"message": "Transaction updated successfully", "new_total": new_total})


@app.route('/delete_transaction/<int:record_id>', methods=['DELETE'])
def delete_transaction(record_id):
    record = Record.query.get(record_id)
    if not record:
        return jsonify({"message": "Transaction not found"}), 404

    serial_id = record.serial_id  # Get the serial_id of the user
    category = record.category

    # Deduct from the budget if it is an Expense transaction
    if record.transaction_type == 'Expense':
        budget = Budget.query.filter_by(serial_id=serial_id, category=category).first()
        if budget:
            budget.spent -= record.amount

    db.session.delete(record)  # Delete the record

    # Update remaining transactions with the new total
    remaining_transactions = Record.query.filter_by(serial_id=serial_id).filter(Record.record_id > record_id).all()
    for transaction in remaining_transactions:
        # Calculate new total income and total expense for the remaining transactions
        total_income = sum(Decimal(t.amount) for t in Record.query.filter_by(serial_id=serial_id, transaction_type='Income').filter(Record.record_id <= transaction.record_id).all())
        total_expense = sum(Decimal(t.amount) for t in Record.query.filter_by(serial_id=serial_id, transaction_type='Expense').filter(Record.record_id <= transaction.record_id).all())
        
        # Calculate the new total after deletion for all remaining transactions
        new_total = total_income - total_expense

        transaction.total = new_total

    db.session.commit()  # Commit the changes
    return jsonify({"message": "Transaction deleted successfully"})

@app.route('/set_budget', methods=['POST'])
def set_budget():
    data = request.get_json()
    serial_id = data['serial_id']
    category = data['category']
    limit = Decimal(data['limit'])

    # Calculate total spent amount for this category from previous transactions
    total_spent = db.session.query(func.sum(Record.amount)).filter(
        and_(Record.serial_id == serial_id, Record.category == category, Record.transaction_type == 'Expense')
    ).scalar() or Decimal('0')

    # Calculate remaining amount
    remaining = limit - total_spent

    # Create or update budget entry for the category
    budget = Budget.query.filter_by(serial_id=serial_id, category=category).first()
    if budget:
        # Update existing budget
        budget.budget_limit = limit
        budget.spent = total_spent
        budget.remaining = remaining
    else:
        # Create new budget entry
        budget = Budget(
            serial_id=serial_id,
            category=category,
            budget_limit=limit,
            spent=total_spent,
            remaining=remaining
        )
        db.session.add(budget)

    db.session.commit()

    return jsonify({
        "message": "Budget set successfully",
        "budget": {
            "category": budget.category,
            "budget_limit": str(budget.budget_limit),
            "spent": str(budget.spent),
            "remaining": str(budget.remaining)
        }
    })

def recommend_budgets(total_credit):
    categories = ["Food","Bills", "Health","Clothing","Savings","Beauty","Entertainment", "Education"]
    
    recommendations = []
    
    for category in categories:
        # Calculate spending_ratio and remaining_ratio (mock values for simplicity)
        spending_ratio = random.uniform(0.2, 0.8)  # Example random ratio for spending
        remaining_ratio = 1 - spending_ratio  # Complementary ratio for remaining amount
        
        # Prepare the input for prediction as a DataFrame with correct column names
        input_data = pd.DataFrame([[total_credit, spending_ratio, remaining_ratio]], 
                                  columns=['total_credit', 'spending_ratio', 'remaining_ratio'])
        
        # Predict the budget for this category
        predicted_limit = model.predict(input_data)[0]
        
        # Ensure the predicted limit doesn't exceed the remaining total_credit
        if predicted_limit > total_credit:
            predicted_limit = total_credit
        
        # Add the recommendation for this category
        recommendations.append({
            'category': category,
            'recommended_limit': round(predicted_limit, 2)
        })
        
        # Update the total_credit by subtracting the predicted budget for this category
        total_credit -= predicted_limit
    
    return recommendations

@app.route('/get_budgets/<int:serial_id>', methods=['GET'])
def get_budgets(serial_id):
    user = db.session.get(Customer, serial_id)
    if not user:
        return jsonify({"message": "User not found"}), 404
    
    budgets = Budget.query.filter_by(serial_id=serial_id).all()
    output = []
    for budget in budgets:
        output.append({
            "budget_id": budget.budget_id,
            "category": budget.category,
            "budget_limit": f"{budget.budget_limit:.2f}",
            "spent": f"{budget.spent:.2f}",
            "remaining": f"{(budget.budget_limit - budget.spent):.2f}"
        })
    return jsonify(output)

@app.route('/income_category_analysis/<int:serial_id>', methods=['GET'])
def income_category_analysis(serial_id):
    # Query income transactions grouped by category
    income_summary = db.session.query(
        Record.category,
        func.sum(Record.amount).label('total_amount')
    ).filter(
        Record.serial_id == serial_id,
        Record.transaction_type == 'Income'
    ).group_by(Record.category).all()

    # Format the output as a list of dictionaries
    output = [{'category': category, 'total_amount': float(total)} for category, total in income_summary]
    
    return jsonify(output)

@app.route('/expense_category_analysis/<int:serial_id>', methods=['GET'])
def expense_category_analysis(serial_id):
    # Query expense transactions grouped by category
    expense_summary = db.session.query(
        Record.category,
        func.sum(Record.amount).label('total_amount')
    ).filter(
        Record.serial_id == serial_id,
        Record.transaction_type == 'Expense'
    ).group_by(Record.category).all()

    # Format the output as a list of dictionaries
    output = [{'category': category, 'total_amount': float(total)} for category, total in expense_summary]
    
    return jsonify(output)

@app.route('/income_vs_expense_analysis/<int:serial_id>', methods=['GET'])
def income_vs_expense_analysis(serial_id):
    # Calculate total income
    total_income = db.session.query(
        func.sum(Record.amount)
    ).filter(
        Record.serial_id == serial_id,
        Record.transaction_type == 'Income'
    ).scalar() or 0

    # Calculate total expense
    total_expense = db.session.query(
        func.sum(Record.amount)
    ).filter(
        Record.serial_id == serial_id,
        Record.transaction_type == 'Expense'
    ).scalar() or 0

    # Prepare the output
    output = {
        'total_income': float(total_income),
        'total_expense': float(total_expense),
        'net_balance': float(total_income - total_expense)
    }

    return jsonify(output)

@app.route('/recurring_transactions', methods=['POST'])
def recurring_transactions():
    data = request.json
    serial_id = data['serial_id']
    category = data['category']
    amount = Decimal(data['amount'])
    transaction_type = data['transaction_type']
    recurrence = data['recurrence']  # Daily, Weekly, Monthly

    next_date = datetime.now()
    for _ in range(12):  # Add 12 recurrences
        next_date += timedelta(days=30 if recurrence == 'Monthly' else (7 if recurrence == 'Weekly' else 1))
        new_record = Record(
            serial_id=serial_id,
            transaction_date=next_date,
            transaction_type=transaction_type,
            category=category,
            amount=amount,
            total=0  # Will be recalculated
        )
        db.session.add(new_record)
    db.session.commit()
    return jsonify({"message": "Recurring transactions scheduled successfully."})

category_models, le_place, le_time = save_model().load_model()
@app.route('/recommend_vacation', methods=['POST'])
def recommend_vacation():
    data = request.json
    place = data['place']
    budget_range = data['budget_range']
    time_of_year = data['time_of_year']
    days = data['days']
    airline_cost = data['airline_ticket_cost']

    # Encode place and time using the respective OrdinalEncoders
    place_encoded = le_place.transform([[place]])[0][0]
    time_encoded = le_time.transform([[time_of_year]])[0][0]

    # Predict the recommended budget
    input_features = np.array([[place_encoded, time_encoded, days, 0,airline_cost ,0]])  # 0 for Avg Daily Cost and Popularity
    predicted_budget = save_model().model.predict(input_features)

    # Get top 5 vacation recommendations based on place, time, and budget range
    recommendations = save_model().df[
        (save_model().df['Place_encoded'] == place_encoded) & 
        (save_model().df['Budget Range'] >= budget_range[0]) &
        (save_model().df['Budget Range'] <= budget_range[1])
    ].sort_values(by='Popularity', ascending=False).head(5)
    rec = recommendations.to_dict(orient='records')
    return jsonify({
        "predicted_budget": str(predicted_budget[0]+airline_cost),
        "recommendations": rec
    })

@app.route('/add_vacation', methods=['POST'])
def add_vacation():
    data = request.json
    serial_id = data['serial_id']
    place = data['place']
    air_cost = Decimal(data['air_cost'])
    days = data['days']
    budget_range = data['budget_range']
    time_range = data['time_range']

    new_vacation = Vacation(
        serial_id=serial_id,
        place=place,
        air_cost=air_cost,
        days=days,
        budget_range=budget_range,
        time_range=time_range
    )
    db.session.add(new_vacation)
    db.session.commit()

    return jsonify({"message": "Vacation added successfully!"})

@app.route('/get_vacations/<int:serial_id>', methods=['GET'])
def get_vacations(serial_id):
    # Query the vacation records for the given serial_id
    vacations = Vacation.query.filter_by(serial_id=serial_id).all()
    
    # Convert the query result to a list of dictionaries
    vacation_list = [
        {
            "vacation_id": vacation.vacation_id,
            "place": vacation.place,
            "air_cost": float(vacation.air_cost),
            "days": vacation.days,
            "budget_range": vacation.budget_range,
            "time_range": vacation.time_range,
        }
        for vacation in vacations
    ]

    return jsonify(vacation_list), 200

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

@app.route('/mutualfunds', methods=['GET', 'POST'])
def get_mutual_funds():
    funds = MutualFund.query.all()
    return jsonify([fund.to_dict() for fund in funds])

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files or 'text' not in request.form:
        return jsonify({"error": "Must upload a file and select the bank name"}), 400

    file = request.files['file']
    input_text = request.form['text']

    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    # Save the file temporarily
    file_path = os.path.join("uploads", file.filename)
    file.save(file_path)

    # Process the DOCX file
    combined_df, recommend = read_and_concat_tables(file_path, input_text.lower())
    os.remove(file_path)  # Clean up the file

    recommend_message = recommend['overall_recommendations'][0]  # Extract the message string
    recommend_df = recommend['monthly_recommendations']
    combined_df = combined_df.applymap(lambda x: str(x) if isinstance(x, pd.Period) else x)
    recommend_df = recommend_df.applymap(lambda x: str(x) if isinstance(x, pd.Period) else x)
    
    # Convert DataFrame to JSON and return
    data_json = combined_df.to_dict(orient="records")
    recommend_data = recommend_df.to_dict(orient="records")

    total_credit_values = [entry.get('total_credit', 0) for entry in recommend_data if isinstance(entry.get('total_credit', None), (int, float))]
    average_total_credit = sum(total_credit_values) / len(total_credit_values) if total_credit_values else 0

    return jsonify(data=data_json, recommend_message=recommend_message, recommend_data=recommend_data, average_total_credit=average_total_credit) # if monthly analysis too needed give--> return jsonify(data=data_json, recommend_message=recommend_message, recommend_data=recommend_data)

@app.route('/calculate_return', methods=['POST'])
def calculate_return():
    data = request.json
    symbol = data.get('stockName')
    investment_amount = float(data.get('investmentAmount', 0))
    duration = data.get('period', '3mo')  # default 3mo

    # Get the date range based on duration
    end_date = datetime.now().date()
    if duration == '1wk':
        start_date = end_date - timedelta(weeks=1)
    elif duration == '1mo':
        start_date = end_date - timedelta(days=30)
    elif duration == '3mo':
        start_date = end_date - timedelta(days=90)
    elif duration == '6mo':
        start_date = end_date - timedelta(days=180)
    elif duration == '1yr':
        start_date = end_date - timedelta(days=365)
    else:
        return jsonify({'error': 'Invalid duration'}), 400

    # Fetch historical data for the stock
    stock = yf.Ticker(symbol)
    hist = stock.history(start=start_date, end=end_date)

    # Calculate the return
    if hist.empty:
        return jsonify({'error': 'No data available for the given period'}), 400

    initial_price = hist['Close'].iloc[0]
    final_price = hist['Close'].iloc[-1]
    absolute_return = (final_price - initial_price) / initial_price * 100
    final_investment_value = investment_amount * (1 + absolute_return / 100)

    # Fetch nifty (e.g., NIFTY 50) data for comparison
    nifty_symbol = "^NSEI"  # Example for NIFTY 50
    nifty = yf.Ticker(nifty_symbol)
    nifty_hist = nifty.history(start=start_date, end=end_date)
    if nifty_hist.empty:
        nifty_return = None
    else:
        nifty_initial_price = nifty_hist['Close'].iloc[0]
        nifty_final_price = nifty_hist['Close'].iloc[-1]
        nifty_return = (nifty_final_price - nifty_initial_price) / nifty_initial_price * 100

    # Prepare response
    result = {
        'investment_amount': investment_amount,
        'final_investment_value': final_investment_value,
        'absolute_return': absolute_return,
        'stock_value': final_investment_value,
        'nifty_value': investment_amount * (1 + (nifty_return or 0) / 100)
    }

    return jsonify(result)

@app.route('/calculate_tax', methods=['POST'])
def calculate_tax_route():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    try:
        tax_details = calculate_tax(data)
        return jsonify(tax_details)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/recommend_budgets/<int:total_credit>', methods=['POST'])
def get_recommendations(total_credit):
    #data = request.json
    
    # Get total_credit from the request JSON, default to 5000 if not provided
    #total_credit = data.get('total_credit', 5000)
    
    # Get budget recommendations based on total_credit
    recommendations = recommend_budgets(total_credit)
    
    return jsonify(recommendations)

@app.route('/add_budget/<int:serial_id>', methods=['POST'])
def add_budget(serial_id):
    data = request.get_json()

    # Extract the category and limit from the request
    category = data.get('category')
    recommended_limit = data.get('recommended_limit')

    if not category or recommended_limit is None:
        return jsonify({"message": "Invalid input: category and recommended_limit are required"}), 400

    limit = Decimal(recommended_limit)

    # Calculate total spent amount for this category
    total_spent = db.session.query(func.sum(Record.amount)).filter(
        and_(Record.serial_id == serial_id, Record.category == category, Record.transaction_type == 'Expense')
    ).scalar() or Decimal('0')

    # Calculate remaining amount
    remaining = limit - total_spent

    # Create or update the budget entry
    budget = Budget.query.filter_by(serial_id=serial_id, category=category).first()
    if budget:
        # Update existing budget
        budget.budget_limit = limit
        budget.spent = total_spent
        budget.remaining = remaining
    else:
        # Create a new budget entry
        budget = Budget(
            serial_id=serial_id,
            category=category,
            budget_limit=limit,
            spent=total_spent,
            remaining=remaining
        )
        db.session.add(budget)

    db.session.commit()

    return jsonify({
        "message": "Budget added successfully"})
@app.route('/analyse_stock', methods=['POST'])
def analyse_stock():
    try:
        data = request.get_json()
        stock_symbol = data.get('stock_name')
        start_date = data.get('start_date')
        end_date = data.get('end_date')
        
        if not all([stock_symbol, start_date, end_date]):
            return jsonify({
                'status': 'error',
                'error': 'Missing required parameters: stock_name, start_date, end_date'
            }), 400

        # Fetch stock data
        stock = yf.Ticker(stock_symbol)
        
        # Get stock info
        try:
            stock_info = stock.info
        except:
            stock_info = {}
        
        # Get historical data
        hist_data = stock.history(start=start_date, end=end_date)
        
        if hist_data.empty:
            return jsonify({
                'status': 'error',
                'error': 'No data available for the given date range and stock symbol'
            }), 400

        # Get actual prices
        actual_prices = hist_data['Close'].values.tolist()
        
        # Simple moving average prediction (lightweight alternative to LSTM)
        if len(actual_prices) >= 20:
            predicted_prices = []
            for i in range(10, len(actual_prices)):
                # Simple moving average prediction
                avg = sum(actual_prices[i-10:i]) / 10
                predicted_prices.append(avg)
            model_trained = True
        else:
            predicted_prices = []
            model_trained = False

        # Prepare response
        response_data = {
            'status': 'success',
            'model_trained': model_trained,
            'actual_stock_price': actual_prices,
            'predicted_stock_price': predicted_prices,
            'stock_info': {
                'longName': stock_info.get('longName', 'N/A'),
                'sector': stock_info.get('sector', 'N/A'),
                'industry': stock_info.get('industry', 'N/A'),
                'marketCap': stock_info.get('marketCap', 0),
                'priceToEarningsRatio': stock_info.get('forwardPE', 0),
                'returnOnEquity': stock_info.get('returnOnEquity', 0) or 0,
                'dividendYield': stock_info.get('dividendYield', 0) or 0
            }
        }
        
        return jsonify(response_data)
        
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': f'An error occurred during analysis: {str(e)}'
        }), 500


if __name__ == "__main__":
    #app.run(debug=True, port=5000, ssl_context=('cert.pem', 'key.pem'))
    app.run(debug=True,host="0.0.0.0", port=5000)

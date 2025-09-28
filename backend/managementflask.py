from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import func
from sqlalchemy import and_
from decimal import Decimal
from datetime import datetime
import os
import binascii
from flask_cors import CORS
import bcrypt

app = Flask(__name__)
CORS(app)
app.config['SECRET_KEY'] = binascii.hexlify(os.urandom(24)).decode()  # Securely generate a secret key
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:anirudhh@localhost:5432/Archons'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Define the database models
class Customer(db.Model):
    __tablename__ = 'customer'
    serial_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(20), unique=True, nullable=False)
    password = db.Column(db.String(128), nullable=False)

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
    remaining = db.Column(db.Numeric(15,2))

    # Foreign key relationship with the Customer model
    customer = db.relationship("Customer", backref=db.backref("budgets", cascade="all, delete-orphan"))


# Create database tables
with app.app_context():
    db.create_all()

# Endpoints
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data['username']
    password = data['password']
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    new_user = Customer(username=username, password=hashed_password)
    db.session.add(new_user)
    db.session.commit()
    return jsonify({"message": "User registered successfully", "serial_id": new_user.serial_id}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data['username']
    password = data['password']
    user = Customer.query.filter_by(username=username).first()
    if user and bcrypt.checkpw(password.encode('utf-8'), user.password.encode('utf-8')):
        return jsonify({"message": "Login successful", "serial_id": user.serial_id}), 200
    else:
        return jsonify({"message": "Invalid credentials"}), 401

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

    # Get current date in "Fri, 01 Nov 2024" format
    transaction_date = datetime.now().strftime('%a, %d %b %Y')

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


if __name__ == '__main__':
   app.run(debug=True, host='0.0.0.0', port=5004)

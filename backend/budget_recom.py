from flask import Flask, request, jsonify
import joblib
import random
from flask_cors import CORS
import pandas as pd
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import func
from sqlalchemy import and_
from decimal import Decimal
import binascii
import os

app = Flask(__name__)
CORS(app)
# Load the trained model
model = joblib.load(r'C:\Users\Lenovo\Desktop\fintech\FinTech\backend\models\budget_recommendation_model.pkl')


app.config['SECRET_KEY'] = binascii.hexlify(os.urandom(24)).decode()  # Securely generate a secret key
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:anirudhh@localhost:5432/Archons'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Define the database models
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
    remaining = db.Column(db.Numeric(15,2))

with app.app_context():
    db.create_all()

# Function to recommend budgets based on remaining total_credit
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

# API endpoint to get budget recommendations
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

    budget_limit = Decimal(recommended_limit)

    # Calculate total spent amount for this category
    total_spent = db.session.query(func.sum(Record.amount)).filter(
        and_(Record.serial_id == serial_id, Record.category == category, Record.transaction_type == 'Expense')
    ).scalar() or Decimal('0')

    # Calculate remaining amount
    remaining = budget_limit - total_spent

    # Create or update the budget entry
    budget = Budget.query.filter_by(serial_id=serial_id, category=category).first()
    if budget:
        # Update existing budget
        budget.budget_limit = budget_limit
        budget.spent = total_spent
        budget.remaining = remaining
    else:
        # Create a new budget entry
        budget = Budget(
            serial_id=serial_id,
            category=category,
            limit=budget_limit,
            spent=total_spent,
            remaining=remaining
        )
        db.session.add(budget)

    db.session.commit()

    return jsonify({
        "message": "Budget added successfully"})

if __name__ == '__main__':
    app.run(debug=True)

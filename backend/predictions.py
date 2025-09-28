from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from decimal import Decimal
from datetime import datetime, timedelta
from flask_cors import CORS
import os
import binascii
import pandas as pd
import numpy as np
from savings import save_model

app = Flask(__name__)
CORS(app)

# Configuration
app.config['SECRET_KEY'] = binascii.hexlify(os.urandom(24)).decode()
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:anirudhh@localhost:5432/Archons'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Models
class Customer(db.Model):
    __tablename__ = 'customer'
    serial_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(20), unique=True, nullable=False)
    password = db.Column(db.String(10), nullable=False)  # Use hashing in production!

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
    limit = db.Column(db.Numeric(15, 2), nullable=False)
    spent = db.Column(db.Numeric(15, 2), default=0)
    remaining = db.Column(db.Numeric(15, 2))

class Vacation(db.Model):
    __tablename__ = 'vacation'
    vacation_id = db.Column(db.Integer, primary_key=True)
    serial_id = db.Column(db.Integer, db.ForeignKey('customer.serial_id', ondelete='CASCADE'), nullable=False)
    place = db.Column(db.String(100), nullable=False)
    air_cost = db.Column(db.Numeric(15, 2), nullable=False)
    days = db.Column(db.Integer, nullable=False)
    budget_range = db.Column(db.String(50), nullable=False)
    time_range = db.Column(db.String(50), nullable=False)

# Initialize models
with app.app_context():
    db.create_all()

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

    # Encode place and time using the respective LabelEncoders
    place_encoded = le_place.transform([place])[0]
    time_encoded = le_time.transform([time_of_year])[0]

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


if __name__ == '__main__':
    app.run(debug=True, port=5009)

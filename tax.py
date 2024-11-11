from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

def calculate_tax(data):
    # Extract inputs
    financial_year = data.get('financial_year')
    basic_income = data.get('basic_income')
    special_income = data.get('special_income')
    hra_received = data.get('hra_received')
    deductions = data.get('deductions', {})
    capital_gains = data.get('capital_gains', {})

    # Calculate gross salary and other inputs
    gross_salary = basic_income + special_income + hra_received
    total_deductions = (
        deductions.get('deduction80C') + 
        deductions.get('deduction80D') + 
        deductions.get('deduction80E') + 
        deductions.get('deduction80G')
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
    if financial_year == '2024-25' and taxable_income <= 715000:
        excess_income = taxable_income - 700000
        tax_without_rebate = income_tax
        rebate = max(0, tax_without_rebate - excess_income)

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

if __name__ == '__main__':
    app.run(debug=True)
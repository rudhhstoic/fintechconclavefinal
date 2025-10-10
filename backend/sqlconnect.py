from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:Archana@localhost:5432/Archons'
db = SQLAlchemy(app)

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

@app.route('/mutualfunds', methods=['GET', 'POST'])
def get_mutual_funds():
    funds = MutualFund.query.all()
    return jsonify([fund.to_dict() for fund in funds])

if __name__ == "__main__":
   app.run(debug=True, host="0.0.0.0", port=5006)

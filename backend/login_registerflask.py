from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
import bcrypt

app = Flask(__name__)
CORS(app)

app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:anirudhh@localhost:5432/Archons'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

class Customer(db.Model):
    __tablename__ = 'customer'
    serial_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(20), unique=True, nullable=False)
    password = db.Column(db.String(128), nullable=False)

with app.app_context():
    db.create_all()

@app.route('/',methods=['GET'])
def home():
    return "LoginPage"

# User registration route
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    # Ensure both username and password are provided
    if not username or not password:
        return jsonify({'message': 'Username and password are required'}), 400

    # Hash the password
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    try:
        new_user = Customer(username=username, password=hashed_password)
        db.session.add(new_user)
        db.session.commit()
        serial_id = new_user.serial_id
        name = ''.join(filter(lambda z: not z.isdigit(), username.split('@')[0]))
        return jsonify({'message': 'User registered successfully', 'serial_id': serial_id, "name" : name.title()}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': 'Username already exists'}), 409

# User login route
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    # Ensure both username and password are provided
    if not username or not password:
        return jsonify({'message': 'Username and password are required'}), 400

    user = Customer.query.filter_by(username=username).first()
    name = ''.join(filter(lambda z: not z.isdigit(), username.split('@')[0]))
    if user and bcrypt.checkpw(password.encode('utf-8'), user.password.encode('utf-8')):
        return jsonify({'message': 'Login successful', 'serial_id': user.serial_id, "name": name.title()}), 200
    else:
        return jsonify({'message': 'Invalid credentials'}), 401

# Dashboard route
@app.route('/dashboard', methods=['GET'])
def dashboard():
    return "HomePage"

if __name__ == '__main__':
    app.run(debug=True)
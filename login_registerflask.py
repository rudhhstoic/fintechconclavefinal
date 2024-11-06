from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
import bcrypt

app = Flask(__name__)
CORS(app)

# Connect to PostgreSQL
def get_db_connection():
    try:
        conn = psycopg2.connect(
            host="localhost",
            port="5432",
            database="Archons",  # Replace with your database name
            user="first_username",  # Replace with your PostgreSQL username
            password="Archana"  # Replace with your PostgreSQL password
        )
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        return None

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
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

    conn = get_db_connection()
    if conn is None:
        return jsonify({'message': 'Database connection failed'}), 500

    cur = conn.cursor()

    try:
        # Insert the username and hashed password into the database
        cur.execute("INSERT INTO customer (username, password) VALUES (%s, %s) RETURNING serial_id", 
                    (username, hashed_password.decode('utf-8')))
        serial_id = cur.fetchone()[0]
        conn.commit()
        return jsonify({'message': 'User registered successfully', 'serial_id' : serial_id}), 201
    except psycopg2.IntegrityError:
        conn.rollback()  # In case of username conflict or error
        return jsonify({'message': 'Username already exists'}), 409
    finally:
        cur.close()
        conn.close()

# User login route
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    # Ensure both username and password are provided
    if not username or not password:
        return jsonify({'message': 'Username and password are required'}), 400

    # Connect to PostgreSQL to get the stored hashed password
    conn = get_db_connection()
    if conn is None:
        return jsonify({'message': 'Database connection failed'}), 500

    cursor = conn.cursor()

    try:
        cursor.execute("SELECT password FROM customer WHERE username = %s", (username,))
        result = cursor.fetchone()
        cursor.execute("SELECT serial_id FROM customer WHERE username = %s", (username,))
        serial_id = cursor.fetchone()[0]

        if result:
            stored_hashed_password = result[0]

            # Verify the entered password against the stored hashed password
            if bcrypt.checkpw(password.encode('utf-8'), stored_hashed_password.encode('utf-8')):
                return jsonify({'message': 'Login successful','serial_id' : serial_id}), 200
            else:
                return jsonify({'message': 'Invalid credentials'}), 401
        else:
            return jsonify({'message': 'Invalid credentials'}), 401
    finally:
        cursor.close()
        conn.close()

# Dashboard route
@app.route('/dashboard', methods=['GET'])
def dashboard():
    return "HomePage"

if __name__ == '__main__':
    app.run(debug=True)
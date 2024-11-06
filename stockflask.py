from flask import Flask, request, jsonify
from stock import Stock  # Make sure to replace with the actual module name
from datetime import datetime
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Initialize the stock analysis class
stock_analyzer = Stock()

@app.route('/analyze_stock', methods=['POST'])
def analyze_stock():
    try:
        # Get data from the request
        data = request.json
        stock_name = data.get('stock_name')
        start_date = data.get('start_date')
        end_date = data.get('end_date')

        # Check if all necessary data is provided
        if not all([stock_name, start_date, end_date]):
            return jsonify({'error': 'Missing required parameters'}), 400

        # Convert dates from mm/dd/yyyy to yyyy-mm-dd
        try:
            start_date = datetime.strptime(start_date, '%m/%d/%Y').strftime('%Y-%m-%d')
            end_date = datetime.strptime(end_date, '%m/%d/%Y').strftime('%Y-%m-%d')
        except ValueError:
            return jsonify({'error': 'Invalid date format. Use mm/dd/yyyy.'}), 400


        # Call the analyze function
        result = stock_analyzer.analyse(stock_name, start_date, end_date)
        # Return the result as JSON
        return jsonify(result), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

#if __name__ == '__main__':
#    app.run(debug=True,host='0.0.0.0',port=5002)

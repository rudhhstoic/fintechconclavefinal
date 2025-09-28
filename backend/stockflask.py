from flask import Flask, request, jsonify
from stock import StockPredictor  # Make sure to replace with the actual module name
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Initialize the stock analysis class
stock_analyzer = StockPredictor()

@app.route('/analyse_stock', methods=['POST'])
def analyse_stock():
    try:
        # Get data from the request
        data = request.json
        stock_name = data.get('stock_name')
        start_date = data.get('start_date')
        end_date = data.get('end_date')

        # Check if all necessary data is provided
        if not all([stock_name, start_date, end_date]):
            return jsonify({'error': 'Missing required parameters'}), 400

        # Dates are already in yyyy-MM-dd format from Flutter

        # Call the analyse function
        result = stock_analyzer.analyse(stock_name, start_date, end_date)
        # Return the result as JSON
        return jsonify(result), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

#if __name__ == '__main__':
#    app.run(debug=True,host='0.0.0.0',port=5002)

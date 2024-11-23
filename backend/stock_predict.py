
from flask import Flask, request, jsonify
import yfinance as yf
from datetime import datetime, timedelta
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

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

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5002)

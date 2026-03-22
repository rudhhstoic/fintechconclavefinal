from flask import Flask, jsonify, request
from flask_cors import CORS
import pandas as pd
import os
import json
import logging
from setu_aa.client import SetuAAClient
from setu_aa.parser import parse_transactions, get_summary
from recommend import FinancialAnalyzer

# In this project's architecture, each service is a separate Flask app.
# The user requested additions to app.py, but app.py is a process runner for multiple files.
# Thus, we create aa_flask.py which will be added to the apps list in app.py.

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

aa_client = SetuAAClient()
analyzer = FinancialAnalyzer()

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

@app.route('/api/aa/initiate', methods=['POST'])
def initiate_aa():
    """
    Takes user_id and mobile_number
    Calls create_consent_request
    Returns consent_handle and redirect_url
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "No JSON payload provided"}), 400
        
    user_id = data.get('user_id')
    mobile_number = data.get('mobile_number')
    
    if not user_id or not mobile_number:
        return jsonify({"error": "user_id and mobile_number are required"}), 400
    
    result = aa_client.create_consent_request(user_id, mobile_number)
    return jsonify(result)

@app.route('/api/aa/status/<consent_handle>', methods=['GET'])
def check_aa_status(consent_handle):
    """
    Returns consent status
    """
    result = aa_client.get_consent_status(consent_handle)
    return jsonify(result)

@app.route('/api/aa/fetch', methods=['POST'])
def fetch_aa_data():
    """
    Takes consent_handle
    Fetches and parses all transactions
    Runs K-Means clustering
    Stores result in a simple JSON file data/{user_id}_transactions.json
    Returns parsed summary + clusters
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "No JSON payload provided"}), 400
        
    consent_handle = data.get('consent_handle')
    user_id = data.get('user_id')
    
    if not consent_handle or not user_id:
        return jsonify({"error": "consent_handle and user_id are required"}), 400
        
    # Fetch raw FI data
    fetch_result = aa_client.fetch_fi_data(consent_handle)
    if fetch_result['status'] == 'error':
        return jsonify(fetch_result), 500
        
    raw_fi_data = fetch_result['raw_fi_data']
    
    # Parse and categorize transactions
    transactions = parse_transactions(raw_fi_data)
    
    # Generate summary
    summary = get_summary(transactions)
    
    # Prepare data for K-Means (FinancialAnalyzer)
    # The analyzer expects a DataFrame with Date, Debit, Credit, Balance
    if transactions:
        df = pd.DataFrame(transactions)
        # Ensure correct column names for FinancialAnalyzer
        # Amount + Type (DEBIT/CREDIT) -> Debit/Credit
        df['Debit'] = df.apply(lambda x: x['Amount'] if x['Type'] == 'DEBIT' else 0, axis=1)
        df['Credit'] = df.apply(lambda x: x['Amount'] if x['Type'] == 'CREDIT' else 0, axis=1)
        # Keep Date and Balance as they are
        
        # Run clustering
        try:
            clustering_results = analyzer.analyse(df)
            
            # Format results for JSON storage
            # FinancialAnalyzer.analyse returns {overall_recommendations, monthly_recommendations}
            # where monthly_recommendations is a DataFrame with 'Cluster' and 'Recommendation'
            
            # Convert Periods to string if any (as seen in statementflask.py)
            monthly_rec_df = clustering_results['monthly_recommendations']
            monthly_rec_df = monthly_rec_df.applymap(lambda x: str(x) if isinstance(x, pd.Period) else x)
            
            result_to_store = {
                "user_id": user_id,
                "transactions": transactions,
                "summary": summary,
                "overall_recommendations": clustering_results['overall_recommendations'],
                "monthly_analysis": monthly_rec_df.to_dict(orient="records")
            }
            
            # Store in JSON file
            file_path = os.path.join(DATA_DIR, f"{user_id}_transactions.json")
            with open(file_path, "w") as f:
                json.dump(result_to_store, f, indent=4)
                
            return jsonify({
                "status": "success",
                "summary": summary,
                "overall_recommendations": clustering_results['overall_recommendations'],
                "monthly_analysis": result_to_store["monthly_analysis"]
            })
            
        except Exception as e:
            logger.error(f"Error during analysis or storage: {str(e)}")
            return jsonify({"status": "error", "message": f"Analysis failed: {str(e)}"}), 500
    else:
        return jsonify({"status": "success", "message": "No transactions found", "summary": summary})

if __name__ == '__main__':
    # Defaulting to 5012 to avoid collision with existing services
    app.run(debug=True, host='0.0.0.0', port=5012)

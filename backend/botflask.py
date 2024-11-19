from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import os
from bot import FinanceChatbotModel  # Import your model class

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Load environment variables from .env file
load_dotenv()

# Access the API key
api_key = os.getenv("GEMINI_API_KEY")

# Initialize the chatbot model with your API key
chatbot = FinanceChatbotModel(api_key)

@app.route("/chatbot", methods=["POST"])
def chatbot_interaction():
    data = request.get_json()  # Get the JSON data from Flutter
    user_message = data.get("message", "")  # Get user input from the JSON

    if not user_message:
        return jsonify({"error": "No message provided"})

    # Get the response from the chatbot
    bot_response = chatbot.get_response(user_message)

    # Return the bot's response as JSON
    return jsonify({"response": bot_response})

#if __name__ == "__main__":
#    app.run(debug=True, host='0.0.0.0',port=5000)

import os
from google import genai

class FinanceChatbotModel:
    def __init__(self, api_key):
        # Initialize client with API key
        self.client = genai.Client(api_key=api_key)

        # Generation config (same as before)
        self.generation_config = {
            "temperature": 1,
            "top_p": 0.95,
            "top_k": 39,
            "max_output_tokens": 5000,
        }

        # Store conversation history
        self.history = []

    def get_response(self, user_input):
        """Handles a conversation with the user."""
        try:
            # Add user input to history
            self.history.append({
                "role": "user",
                "parts": [{"text": user_input}]
            })

            # Generate response
            response = self.client.models.generate_content(
                model="gemini-2.0-flash",
                contents=self.history,
                config=self.generation_config
            )

            model_response = response.text

            # Add model response to history
            self.update_history(model_response)

            return model_response

        except Exception as e:
            return f"Error: {str(e)}"

    def update_history(self, model_response):
        """Maintains conversation history"""
        self.history.append({
            "role": "model",
            "parts": [{"text": model_response}]
        })
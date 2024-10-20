import os
import google.generativeai as genai

class FinanceChatbotModel:
    def __init__(self, api_key):
        # Set up the environment for the Gemini API key
        os.environ["GEMINI_API_KEY"] = api_key
        genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

        # Create the generative model with the configuration
        self.generation_config = {
            "temperature": 1,
            "top_p": 0.95,
            "top_k": 64,
            "max_output_tokens": 5000,
            "response_mime_type": "text/plain",
        }
        self.model = genai.GenerativeModel(
            model_name="gemini-1.5-flash",
            generation_config=self.generation_config,
        )
        
        self.history = []

    def get_response(self, user_input):
        """Handles a conversation with the user."""
        chat_session = self.model.start_chat(history=self.history)
        response = chat_session.send_message(user_input)
        
        # Extract and return model's response
        model_response = response.text
        self.update_history(user_input, model_response)
        
        return model_response

    def update_history(self, user_input, model_response):
        """Maintains conversation history for context in the chatbot."""
        self.history.append({'role': 'user', 'parts': [user_input]})
        self.history.append({'role': 'model', 'parts': [model_response]})

# Usage Example
if __name__ == "__main__":
    api_key = "AIzaSyBA2eQI5SxOpsZlwTybTluQ8F4h-JT90co"  # Replace with your actual API key
    chatbot = FinanceChatbotModel(api_key)

    chatbot.start_session()

    while True:
        user_input = input("You: ")
        response = chatbot.get_response(user_input)
        print(f"Bot: {response}")

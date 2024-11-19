from flask import Flask, jsonify
from flask_cors import CORS


import requests

app = Flask(__name__)
CORS(app)

# Your News API key
NEWS_API_KEY = '2d81a14081ae4493892bbcf8a2526c47'

@app.route('/get_articles', methods=['GET'])
def get_articles():
    # API endpoint with your API key
    url = f'https://newsapi.org/v2/everything?q=finance management&apiKey={NEWS_API_KEY}'
    try:
        response = requests.get(url)
        data = response.json()

        # Check if the response contains articles
        if 'articles' in data:
            articles = data['articles'][:1000]  # Limit to 10 articles
            formatted_articles = [
                {
                    "title": article['title'],
                    "description": article['description'],
                    "url": article['url'],
                    "source": article['source']['name']
                }
                for article in articles
            ]
            return jsonify(formatted_articles), 200
        else:
            return jsonify({"error": "No articles found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

#if __name__ == '__main__':
#    app.run(debug=True)

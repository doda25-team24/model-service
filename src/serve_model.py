"""
Flask API of the SMS Spam detection model model.
F10: Loads model from volume mount or downloads if not provided.

"""
import os
import joblib
from flask import Flask, jsonify, request
from flasgger import Swagger
import pandas as pd

from text_preprocessing import prepare, _extract_message_len, _text_process

app = Flask(__name__)
swagger = Swagger(app)

MODEL_DIR = os.getenv('MODEL_DIR', '/model-service/output')
MODEL_PATH = os.path.join(MODEL_DIR, 'model.joblib')
MODEL_URL = os.getenv('MODEL_URL', '/model-service/output/model.joblib')
model = None

def load_or_download_model():
    """
    Load the model from MODEL_DIR. If no model exists, download from MODEL_URL if provided.
    """
    global model

    os.makedirs(MODEL_DIR, exist_ok=True)
    
    if os.path.exists(MODEL_PATH):
        print(f"Loading model from {MODEL_PATH}")
        model = joblib.load(MODEL_PATH)
        return
    
    if MODEL_URL:
        print(f"No model found at {MODEL_PATH}")
        print(f"Downloading model from {MODEL_URL}...")
        download_model(MODEL_URL, MODEL_PATH)
        model = joblib.load(MODEL_PATH)
        return
    
    raise FileNotFoundError(
        f"No model found at {MODEL_PATH} and no MODEL_URL provided. "
        "Please mount a model volume or set MODEL_URL environment variable."
    )


def download_model(url, destination):
    """
    fallback for not found model: download from URL
    """
    import urllib.request
    try:
        urllib.request.urlretrieve(url, destination)
        print(f"Model downloaded successfully to {destination}")
    except Exception as e:
        raise RuntimeError(f"Failed to download model from {url}: {str(e)}")


@app.route('/predict', methods=['POST'])
def predict():
    """
    Predict whether an SMS is Spam.
    ---
    consumes:
      - application/json
    parameters:
        - name: input_data
          in: body
          description: message to be classified.
          required: True
          schema:
            type: object
            required: sms
            properties:
                sms:
                    type: string
                    example: This is an example of an SMS.
    responses:
      200:
        description: "The result of the classification: 'spam' or 'ham'."
    """
    input_data = request.get_json()
    sms = input_data.get('sms')
    processed_sms = prepare(sms)
    global model 
    prediction = model.predict(processed_sms)[0]
    
    res = {
        "result": prediction,
        "classifier": "decision tree",
        "sms": sms
    }
    print(res)
    return jsonify(res)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    try:
        # Check if model is loaded
        model_loaded = model is not None
        
        if model_loaded:
            return jsonify({
                'status': 'healthy',
                'model_loaded': True
            }), 200
        else:
            return jsonify({
                'status': 'unhealthy',
                'model_loaded': False,
                'error': 'Model not loaded'
            }), 503
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e)
        }), 503


if __name__ == '__main__':
    load_or_download_model()
    # Read port from environment, default 8081
    port = int(os.getenv("MODEL_PORT", "8081"))
    print(f"Starting Flask on port {port}")
    app.run(host="0.0.0.0", port=port, debug=True)

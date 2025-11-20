# --- STAGE 1: Model Training ---
# Use a base image of Python 3.12.9 (as recommended in the README) for training.
FROM python:3.12.9-slim AS trainer

# Set the working directory inside the container
WORKDIR /model-service

# Copy the necessary files for training (source code and requirements)
COPY requirements.txt .
COPY src /model-service/src
COPY smsspamcollection /model-service/smsspamcollection

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Run the model training.
# 1. Create the 'output' folder
# 2. Execute the read_data, preprocessing, and classification scripts.
# The trained models (.joblib) will be saved in /model-service/output
RUN mkdir output && \
    python src/read_data.py && \
    python src/text_preprocessing.py && \
    python src/text_classification.py


# ----------------------------------------------------------------------

# --- STAGE 2: Model Serving (Production) ---
# Use a cleaner base image for serving the application.
FROM python:3.12.9-slim AS production

# Set the working directory
WORKDIR /model-service

# Copy essential files from the 'trainer' stage and the local directory:
# 1. The trained model (.joblib) from 'trainer'
# 2. requirements.txt
# 3. The entire source code directory 'src' (CRITICAL FIX for ModuleNotFoundError)
COPY --from=trainer /model-service/output /model-service/output
COPY requirements.txt .

# *** CRITICAL CORRECTION LINE: Copy the entire 'src' folder ***
# This ensures that 'serve_model.py' can import 'text_preprocessing.py'
COPY src /model-service/src/

# Install ONLY the necessary dependencies (those in requirements.txt)
RUN pip install --no-cache-dir -r requirements.txt

ENV MODEL_PORT=8081

# Expose the service port (8081 as per README)
EXPOSE 8081

# Command to start the REST service
CMD ["python", "src/serve_model.py"]
# --- STAGE 1: Model Training ---
FROM python:3.12.9-slim AS trainer

WORKDIR /model-service

# Copy source and DATA
COPY requirements.txt .
COPY src /model-service/src
COPY smsspamcollection /model-service/smsspamcollection

RUN pip install --no-cache-dir -r requirements.txt

# Train the model
# (Fixed the command syntax error by adding '&&')
RUN mkdir -p output && \
    python src/read_data.py && \
    python src/text_preprocessing.py && \
    python src/text_classification.py

# --- STAGE 2: Model Serving (Production) ---
FROM python:3.12.9-slim AS production

WORKDIR /model-service

COPY requirements.txt .
COPY src /model-service/src/

# --- CRITICAL FIX: Copy the "Brain" from Stage 1 ---
#COPY --from=trainer /model-service/output /model-service/output
# --------------------------------------------------

RUN pip install --no-cache-dir -r requirements.txt

# Align port to 8080 (matches your manual fix)
ENV MODEL_PORT=8080
ENV MODEL_DIR=/model-service/output

EXPOSE 8080

CMD ["python", "src/serve_model.py"]

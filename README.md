# Model Service - SMS Spam Detection

Containerized microservice providing SMS spam classification using machine learning.

**Team:** doda2025-team24  
**Repository:** https://github.com/doda2025-team24/model-service

## Architecture Overview

- Runtime: Python 3.12.9
- Web Framework: Flask with Swagger UI
- Machine Learning: scikit-learn, NLTK, Decision Tree classifier
- Containerization: Docker (supports amd64 and arm64)

Model files are downloaded at runtime from GitHub Releases rather than being embedded in the Docker image. This design allows for model updates without requiring container rebuilds. Models can also be provided via volume mounts for faster initialization.

## Installation and Deployment

### Standard Deployment

Pull the container image and start the service:

**Windows PowerShell:**
```powershell
docker pull ghcr.io/doda2025-team24/model-service:latest

docker run -d -p 8081:8081 `
  -e GITHUB_REPO=doda2025-team24/model-service `
  --name model-service `
  ghcr.io/doda2025-team24/model-service:latest

# Allow 30-60 seconds for model download, then verify
Invoke-RestMethod http://localhost:8081/health
```

**Linux/Mac:**
```bash
docker pull ghcr.io/doda2025-team24/model-service:latest

docker run -d -p 8081:8081 \
  -e GITHUB_REPO=doda2025-team24/model-service \
  --name model-service \
  ghcr.io/doda2025-team24/model-service:latest

curl http://localhost:8081/health
```

### Using Local Model Files

For faster startup when model files are available locally:

```powershell
# Windows
docker run -d -p 8081:8081 -v ${PWD}/output:/app/models --name model-service ghcr.io/doda2025-team24/model-service:latest

# Linux/Mac
docker run -d -p 8081:8081 -v ./output:/app/models --name model-service ghcr.io/doda2025-team24/model-service:latest
```

### Persistent Model Cache

Create a persistent volume to avoid re-downloading models:

```powershell
docker volume create model-cache
docker run -d -p 8081:8081 -v model-cache:/app/models -e GITHUB_REPO=doda2025-team24/model-service --name model-service ghcr.io/doda2025-team24/model-service:latest
```

## API Reference

### Health Check Endpoint

```powershell
# Windows
Invoke-RestMethod http://localhost:8081/health

# Linux/Mac
curl http://localhost:8081/health
```

### Spam Classification Endpoint

**Windows PowerShell:**
```powershell
$body = @{ sms = "WIN FREE PRIZE NOW!" } | ConvertTo-Json
Invoke-RestMethod -Uri http://localhost:8081/predict -Method POST -ContentType "application/json" -Body $body
```

**Linux/Mac:**
```bash
curl -X POST http://localhost:8081/predict \
  -H "Content-Type: application/json" \
  -d '{"sms": "WIN FREE PRIZE NOW!"}'
```

**Expected Response:**
```json
{
  "result": "spam",
  "classifier": "decision tree",
  "confidence": 0.92,
  "sms": "WIN FREE PRIZE NOW!"
}
```

Interactive API documentation is available at: http://localhost:8081/apidocs

## Configuration Options

| Environment Variable | Default Value | Description |
|---------------------|---------------|-------------|
| MODEL_SERVICE_PORT | 8081 | Port number for the service |
| MODEL_DIR | /app/models | Directory where models are stored |
| MODEL_VERSION | latest | Version tag from GitHub releases |
| GITHUB_REPO | doda2025-team24/model-service | Repository for model downloads |

**Configuration Examples:**

```powershell
# Custom port configuration
docker run -d -p 9000:9000 -e MODEL_SERVICE_PORT=9000 -e GITHUB_REPO=doda2025-team24/model-service --name model-service ghcr.io/doda2025-team24/model-service:latest

# Specific model version
docker run -d -p 8081:8081 -e MODEL_VERSION=v1.0.0 -e GITHUB_REPO=doda2025-team24/model-service --name model-service ghcr.io/doda2025-team24/model-service:latest
```

## Model Training Process

Models are trained through automated GitHub Actions workflows:

1. Navigate to: https://github.com/doda2025-team24/model-service/actions
2. Execute the "Train, Build and Release (Automated)" workflow
3. Provide a version identifier (example: v1.0.0) and release notes
4. The workflow trains the model and publishes it as a GitHub release
5. Deploy the new model version using: `docker run -e MODEL_VERSION=v1.0.0 ...`

View all available model releases at: https://github.com/doda2025-team24/model-service/releases

## Development Setup

Building and running locally:

```powershell
# Build local image
docker build -t model-service:local .

# Run with local model files
docker run -d -p 8081:8081 -v ${PWD}/output:/app/models --name test model-service:local

# Test the service
Invoke-RestMethod http://localhost:8081/health

# Cleanup
docker stop test && docker rm test
```

## Container Operations

```powershell
# View container logs
docker logs -f model-service

# Stop the service
docker stop model-service

# Remove the container
docker rm model-service

# Stop and remove in one command
docker rm -f model-service
```

## Troubleshooting Guide

**Container fails to start:**
```powershell
docker logs model-service  # Examine error messages
```

**Model files not loading:**
```powershell
docker exec model-service ls -lh /app/models/  # Check if models are present
```

**Force model re-download:**
```powershell
docker rm -f model-service
docker volume rm model-cache  # If using persistent cache
# Restart the container
```
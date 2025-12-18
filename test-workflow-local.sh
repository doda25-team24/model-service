#!/bin/bash
set -e

echo "=== Starting Local Workflow Test ==="

# 1. Calculate version
echo "Step 1: Calculate Version"
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
CURRENT_VERSION=${LAST_TAG#v}
MAJOR=$(echo "$CURRENT_VERSION" | cut -d . -f 1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d . -f 2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d . -f 3)
NEW_PATCH=$((PATCH + 1))
NEW_TAG="v$MAJOR.$MINOR.$NEW_PATCH"
echo "New Version: $NEW_TAG"

# 2. Install dependencies
echo "Step 2: Install Dependencies"
pip install --no-cache-dir -r requirements.txt

# 3. Train model
echo "Step 3: Train Model"
mkdir -p output
python src/read_data.py
python src/text_preprocessing.py
python src/text_classification.py

# 4. Verify model
echo "Step 4: Verify Model"
if [ ! -f output/model.joblib ]; then
  echo "ERROR: Model file not generated"
  exit 1
fi
echo "Model verified!"

# 5. Build Docker image
echo "Step 5: Build Docker Image"
docker build -t test-model-service:$NEW_TAG .

# 6. Test Docker image
echo "Step 6: Test Docker Image"
docker run -d -p 8081:8081 \
  -e GITHUB_REPO=test/repo \
  --name test-container \
  test-model-service:$NEW_TAG

echo "Waiting for service to start..."
sleep 45

echo "Testing health endpoint..."
curl -f http://localhost:8081/health || exit 1

echo "Testing prediction endpoint..."
curl -f -X POST http://localhost:8081/predict \
  -H "Content-Type: application/json" \
  -d '{"sms": "test message"}' || exit 1

echo "All tests passed!"

# 7. Cleanup
docker stop test-container
docker rm test-container

echo "=== Local Workflow Test Complete ==="
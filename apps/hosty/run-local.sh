#!/bin/bash
set -e

echo "=== Starting Hosty locally ==="

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "ERROR: uv is not installed"
    echo "Install it with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# Install dependencies
echo "Installing dependencies..."
uv pip install -e .

# Run the app
echo "Starting FastAPI server on http://localhost:8000"
echo "Endpoints:"
echo "  - http://localhost:8000/       - Get host header"
echo "  - http://localhost:8000/health - Health check"
echo "  - http://localhost:8000/docs   - API documentation"
echo ""

uv run uvicorn main:app --host 0.0.0.0 --port 8000 --reload
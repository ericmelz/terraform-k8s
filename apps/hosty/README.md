# Hosty

A simple FastAPI application that returns the host header from the incoming request.

## Features

- **GET /** - Returns the host header from the request
- **GET /health** - Health check endpoint
- **GET /docs** - Interactive API documentation (Swagger UI)

## Response Format

```json
{
  "host": "example.com",
  "message": "I'm being hit from example.com!"
}
```

## Local Development

### Prerequisites

- Python 3.11+
- [uv](https://github.com/astral-sh/uv) package manager

### Install uv

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Run Locally

```bash
cd apps/hosty
./run-local.sh
```

The app will be available at:
- http://localhost:8000 - Main endpoint
- http://localhost:8000/health - Health check
- http://localhost:8000/docs - API documentation

### Test the Endpoint

```bash
# Test with default host
curl http://localhost:8000

# Test with custom host header
curl -H "Host: weighter.net" http://localhost:8000
```

## Docker

### Build the Image

```bash
cd apps/hosty
docker build -t hosty:latest .
```

### Run with Docker

```bash
docker run -p 8000:8000 hosty:latest
```

### Test the Docker Container

```bash
curl http://localhost:8000
```

## GitHub Container Registry

Images are automatically built and pushed to GitHub Container Registry when changes are committed to `apps/hosty/`:

```bash
docker pull ghcr.io/ericmelz/hosty:latest
docker run -p 8000:8000 ghcr.io/ericmelz/hosty:latest
```

## Deployment

See the main project README for deploying to Kubernetes with Helm and GitOps.

## Development

### Project Structure

```
apps/hosty/
├── main.py              # FastAPI application
├── pyproject.toml       # uv/pip dependencies
├── Dockerfile           # Container image
├── .dockerignore        # Docker build exclusions
├── run-local.sh         # Local development script
└── README.md            # This file
```

### Adding Dependencies

```bash
# Add a new dependency
uv pip install <package>

# Update pyproject.toml
# Add the package to dependencies list
```

### Running Tests

```bash
# Install dev dependencies
uv pip install pytest httpx

# Run tests (when added)
uv run pytest
```
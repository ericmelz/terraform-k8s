import os
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI(
    title="Hosty",
    description="Returns the host header from the request",
    version="0.1.0",
)


@app.get("/")
async def get_host(request: Request):
    """Return the host header from the request."""
    host = request.headers.get("host", "unknown")

    # Read configuration from environment variables
    non_secret_env_var = os.getenv("NON_SECRET_ENV_VAR", "default-value")
    secret_env_var = os.getenv("SECRET_ENV_VAR", "default-secret")

    return JSONResponse(
        content={
            "host": host,
            "message": f"I'm being hit from {host}!",
            "nonSecretEnvVar": non_secret_env_var,
            "secretEnvVar": secret_env_var,
        }
    )


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}
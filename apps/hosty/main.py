import os
from pathlib import Path
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI(
    title="Hosty",
    description="Returns the host header from the request",
    version="0.1.0",
)

# Load configuration from file if it exists
CONFIG_FILE = Path("/app/config/.env")
config_from_file = {}

if CONFIG_FILE.exists():
    with open(CONFIG_FILE) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                config_from_file[key] = value


@app.get("/")
async def get_host(request: Request):
    """Return the host header from the request."""
    host = request.headers.get("host", "unknown")

    # Read configuration from environment variables
    non_secret_env_var = os.getenv("NON_SECRET_ENV_VAR", "default-value")
    secret_env_var = os.getenv("SECRET_ENV_VAR", "default-secret")

    # Read configuration from file
    non_secret_conf_file_var = config_from_file.get(
        "NON_SECRET_CONF_FILE_VAR", "default-conf-value"
    )
    secret_conf_file_var = config_from_file.get(
        "SECRET_CONF_FILE_VAR", "default-conf-secret"
    )

    return JSONResponse(
        content={
            "host": host,
            "message": f"I'm being hit from {host}!",
            "nonSecretEnvVar": non_secret_env_var,
            "secretEnvVar": secret_env_var,
            "nonSecretConfFileVar": non_secret_conf_file_var,
            "secretConfFileVar": secret_conf_file_var,
        }
    )


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}
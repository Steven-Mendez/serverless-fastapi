# Stage 1: Base
FROM python:3.13-slim as base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    # UV Environment settings
    UV_PROJECT_ENVIRONMENT="/opt/venv" \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    # Update PATH to include the venv
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# Stage 2: Builder
FROM base as builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml uv.lock ./

# Install dependencies into /opt/venv
RUN uv sync --frozen --no-dev --no-install-project

# Stage 3: Development
FROM base as dev

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
COPY --from=builder /opt/venv /opt/venv

# Install system dependencies for dev tools if needed
# (None currently needed but good practice to keep the layer)

COPY pyproject.toml uv.lock ./

# Install dev dependencies
RUN uv sync --frozen --no-install-project

# Install dev tools (if not in pyproject.toml dev group, otherwise uv sync handles them)
# Note: debugpy is in the dev group in pyproject.toml
# RUN pip install debugpy watchfiles pytest httpx # Removed as uv sync handles dev dependencies

COPY . .

# Default dev command (optimized for debugging)
CMD ["python", "-Xfrozen_modules=off", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# Stage 4: Production
FROM base as prod

# Install Tini for signal handling
RUN apt-get update && apt-get install -y --no-install-recommends tini \
    && rm -rf /var/lib/apt/lists/*

# Lambda Adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/lambda-adapter

COPY --from=builder /opt/venv /opt/venv

COPY . .

# Secure non-root user setup
RUN addgroup --system appgroup && adduser --system --group appuser
RUN chown -R appuser:appgroup /app

USER appuser

ENTRYPOINT ["/usr/bin/tini", "--"]

ENV PORT=8080
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]

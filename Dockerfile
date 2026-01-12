# Stage 1: Base
FROM python:3.13-slim as base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on

WORKDIR /app

# Stage 2: Builder
FROM base as builder

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml uv.lock ./

# Export requirements and build wheels
RUN uv export --frozen --no-dev --format requirements-txt > requirements.txt
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Stage 3: Development
FROM base as dev

COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/*

# Install dev tools
RUN pip install debugpy watchfiles pytest httpx

COPY . .

# Default dev command (can be overridden by compose)
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# Stage 4: Production
FROM base as prod

# Install Tini for signal handling
RUN apt-get update && apt-get install -y --no-install-recommends tini \
    && rm -rf /var/lib/apt/lists/*

# Lambda Adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/lambda-adapter

COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/*

COPY . .

# Secure non-root user setup
RUN addgroup --system appgroup && adduser --system --group appuser
RUN chown -R appuser:appgroup /app

USER appuser

ENTRYPOINT ["/usr/bin/tini", "--"]

ENV PORT=8080
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]

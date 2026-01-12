# Serverless FastAPI

A FastAPI project configured for AWS Lambda (via Web Adapter) with Docker-based dev/prod parity.

## Prerequisites

Ensure you have the following installed:

- **Python 3.13+**
- **[uv](https://github.com/astral-sh/uv)** (Python package manager)
- **Docker** & **Docker Compose**

## Quickstart

Choose one of the following methods to get started.

### Option 1: Docker (Preferred)

Run the application with Docker.

1. **Start the application**:
   ```bash
   docker compose up --build
   ```
   *The API will be available at `http://localhost:8000` (and a Postgres DB).*

2. **Stop the application**:
   ```bash
   docker compose down
   ```

### Option 2: Native

Run the application directly on your machine.

1. **Install dependencies**:
   ```bash
   uv sync
   ```

2. **Run the API**:
   ```bash
   fastapi dev main.py
   ```
   *The API will be available at `http://localhost:8000`.*

## Development

### Managing Dependencies

This project uses `uv` for dependency management.

- **Add a dependency**:
  ```bash
  uv add <package_name>
  ```
  *Example: `uv add requests`*

- **Add a dev dependency**:
  ```bash
  uv add --dev <package_name>
  ```
  *Example: `uv add --dev pytest`*

- **Sync dependencies** (after pulling changes):
  ```bash
  uv sync
  ```

### Debugging

We provide two pre-configured launch options in `.vscode/launch.json`:

1.  **Local: Run & Debug** _(Default)_
    - Runs `fastapi dev` locally on your machine.
    - Best for quick iteration and simple logic.

2.  **Docker: Build, Run & Debug**
    - Automates the process of building the container, running `docker compose up`, and attaching the debugger.
    - Ensures you are debugging in an environment identical to production.
    - *Note: This task waits for the debugger to be ready before attaching.*

### VS Code Tasks

We have configured standard VS Code tasks for convenience:

- **docker-build-run-debug**: Used by the Docker launch config.
- **docker-compose-down**: Runs `docker compose down`.

Access them via `Terminal -> Run Task...`.

**Note**: All configurations use port **8000** for consistency.

### Code Quality

Ensure code quality before committing changes:

```bash
pre-commit run --all-files
```
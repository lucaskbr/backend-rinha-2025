
FROM python:3.12-slim AS builder

# Install uv
# The installer requires curl (and certificates) to download the release archive
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates

# Download the latest installer
ADD https://astral.sh/uv/install.sh /uv-installer.sh

# Run the installer then remove it
RUN sh /uv-installer.sh && rm /uv-installer.sh

# Ensure the installed binary is on the `PATH`
ENV PATH="/root/.local/bin/:$PATH"

# Change the working directory to the `app` directory
WORKDIR /app

COPY pyproject.toml ./
COPY uv.lock ./

ENV UV_COMPILE_BYTECODE=1

# Install dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-editable

FROM python:3.12-slim

WORKDIR /app

# Copy the environment, from builder
COPY --from=builder /app/.venv /app/.venv

# Copy the source code
COPY src /app/src

# Set the Python path to use the virtual environment
ENV PATH="/app/.venv/bin:$PATH"
ENV VIRTUAL_ENV="/app/.venv"

# CMD ["tail", "-f", "/dev/null"]

CMD ["uvicorn", "src.main:app", "--port", "80", "--host", "0.0.0.0"]
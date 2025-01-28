# Use official Python image
FROM python:3.10-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Install dependencies
COPY requirements.txt .
RUN uv pip install --no-cache-dir -r requirements.txt --system

# Copy application code
COPY main.py .

# Run the script
CMD ["python", "main.py"]
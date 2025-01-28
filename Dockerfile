# Use official Python image
FROM python:3.10-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Install dependencies
COPY requirements.txt .
RUN uv pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY simulate.py .

# Run the script
CMD ["python", "simulate.py"]
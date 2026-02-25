FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY embedding_server.py .

# Create non-root user
RUN useradd -m -u 1000 embeddings && chown -R embeddings:embeddings /app
USER embeddings

# Expose port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# Run the application
CMD ["python", "embedding_server.py"]


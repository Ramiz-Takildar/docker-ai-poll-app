# Dockerfile for AI Poll Voting Application
# Uses Python 3.11 slim image optimized for production

FROM python:3.11-slim

# Set metadata labels
LABEL maintainer="DevOps Team"
LABEL description="AI Poll Voting Application using Flask and PostgreSQL"
LABEL version="1.0"

# Set environment variables
# PYTHONUNBUFFERED=1: Output Python logs immediately (important for Docker)
# PYTHONDONTWRITEBYTECODE=1: Prevents creation of .pyc files
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Set working directory inside container
WORKDIR /app

# Create non-root user for security
# Running as root inside containers is a security risk
# This creates a user 'appuser' with UID 1000
RUN useradd -m -u 1000 appuser

# Copy requirements first (for better layer caching)
# Docker caches layers, so if requirements don't change, 
# this layer is reused and dependencies aren't reinstalled
COPY app/requirements.txt .

# Install Python dependencies
# --no-cache-dir: Doesn't cache pip packages (reduces image size)
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
# This is done after requirements to take advantage of Docker's layer caching
COPY app/ .

# Change ownership of application files to appuser
# Ensures the non-root user can access and modify files if needed
RUN chown -R appuser:appuser /app

# Switch to non-root user
# All subsequent commands and the container process will run as 'appuser'
USER appuser

# Expose port 5000
# Informs Docker that the application listens on port 5000
# This doesn't actually publish the port; that happens at runtime with -p
EXPOSE 5000

# Healthcheck configuration
# Checks if application is running and responding
# --interval=30s: Check every 30 seconds
# --timeout=10s: Timeout after 10 seconds
# --start-period=10s: Wait 10 seconds before starting checks
# --retries=3: Mark unhealthy after 3 failed checks
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health', timeout=5)" || exit 1

# Run the Flask application
# Uses the main app module to start the application
# 0.0.0.0 ensures the app listens on all network interfaces (required for Docker)
CMD ["python", "app.py"]

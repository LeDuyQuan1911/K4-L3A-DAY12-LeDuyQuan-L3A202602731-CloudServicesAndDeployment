# ═══════════════════════════════════════════════════════════════════
# CP2 — Containerization
#
# Production-ready Dockerfile: multi-stage build, slim base image,
# non-root user, health check, dynamic port from env.
#
# Kiểm tra:  pytest tests/test_cp2.py -v
# Build thử: docker build -t day12-agent:prod .
#            docker images day12-agent:prod     # xem dung lượng
# ═══════════════════════════════════════════════════════════════════

# ── Stage 1: builder ──────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: runtime ─────────────────────────────────────────────
FROM python:3.11-slim AS runtime

WORKDIR /app

# Copy installed dependencies from builder
COPY --from=builder /install /usr/local

# Copy application source code
COPY app/ ./app/
COPY utils/ ./utils/

# Create non-root user
RUN useradd --no-create-home --shell /bin/false --uid 10001 appuser
USER appuser

# Port from environment variable (cloud platforms set PORT)
ENV PORT=8000
EXPOSE ${PORT}

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:${PORT}/health')" || exit 1

# Start the application
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT}

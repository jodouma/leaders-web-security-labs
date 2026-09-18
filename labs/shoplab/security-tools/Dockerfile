FROM python:3.13-slim

RUN pip install --no-cache-dir \
        bandit==1.9.4 \
        pip-audit==2.10.1 \
        pytest==9.1.1 \
        fastapi==0.141.1 \
        prometheus-client==0.22.1 \
        'psycopg[binary]==3.2.10' \
        uvicorn==0.35.0 \
    && useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin analyst
USER analyst
CMD ["sleep", "infinity"]

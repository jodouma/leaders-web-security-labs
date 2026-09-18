FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt \
    && groupadd --system websec \
    && useradd --system --gid websec --home-dir /nonexistent --shell /usr/sbin/nologin websec

COPY main.py /app/main.py
COPY sample-public /app/sample-public
COPY sample-training-vault /app/sample-training-vault
RUN mkdir -p /var/log/websec \
    && chown -R websec:websec /app /var/log/websec

USER websec
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

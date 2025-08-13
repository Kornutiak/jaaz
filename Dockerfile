# ===== 1) FRONTEND (React/Vite) =====
FROM node:18-bullseye AS frontend
WORKDIR /app

RUN apt-get update && apt-get install -y python3 make g++ pkg-config \
  && rm -rf /var/lib/apt/lists/*

# копируем ВЕСЬ репозиторий (чтобы точно попали react/index.html и vite.config.ts)
COPY . /app

# билд фронта строго из папки react
WORKDIR /app/react
RUN npm ci --legacy-peer-deps
RUN test -f index.html || (echo "index.html not found in /app/react" && ls -la && exit 1)
RUN npm run build

# ===== 2) BACKEND (Python 3.12) =====
FROM python:3.12-slim AS backend
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl \
  && rm -rf /var/lib/apt/lists/*

COPY server/requirements.txt /app/server/requirements.txt
RUN pip install --no-cache-dir -r /app/server/requirements.txt

COPY server/ /app/server/
COPY --from=frontend /app/react/dist /app/server/react-dist

# чтоб не зависеть от Variables — порт зашит здесь
ENV PORT=8000
ENV PYTHONUNBUFFERED=1

EXPOSE 8000
WORKDIR /app/server
CMD ["python", "main.py"]

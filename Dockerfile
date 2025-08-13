# ===== 1) FRONTEND BUILD (React/Vite) =====
FROM node:18-bullseye AS frontend
WORKDIR /app

# Инструменты для node-gyp на всякий случай
RUN apt-get update && apt-get install -y python3 make g++ pkg-config \
  && rm -rf /var/lib/apt/lists/*

# КОПИРУЕМ ВЕСЬ РЕПОЗИТОРИЙ (чтобы точно попал react/index.html)
COPY . /app

# Переходим в папку фронта
WORKDIR /app/react

# Ставим зависимости и запускаем ИМЕННО скрипт сборки проекта
# (если у тебя нет скрипта build — скажи, посмотрим package.json)
RUN npm ci --legacy-peer-deps
RUN npm run build

# ===== 2) BACKEND (Python 3.12) =====
FROM python:3.12-slim AS backend
WORKDIR /app

# Базовые системные пакеты
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl \
  && rm -rf /var/lib/apt/lists/*

# Python-зависимости
COPY server/requirements.txt /app/server/requirements.txt
RUN pip install --no-cache-dir -r /app/server/requirements.txt

# Код сервера
COPY server/ /app/server/

# Готовый фронт кладём рядом с сервером
COPY --from=frontend /app/react/dist /app/server/react-dist

# Порт (если у тебя другой — скажи)
ENV PORT=8000
ENV PYTHONUNBUFFERED=1

EXPOSE 8000
WORKDIR /app/server

# Точка входа (как в README)
CMD ["python", "main.py"]

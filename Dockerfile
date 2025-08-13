# ===== 1) FRONTEND (React/Vite) =====
FROM node:18-bullseye AS frontend
WORKDIR /app

# инструменты на случай native-зависимостей у npm-пакетов
RUN apt-get update && apt-get install -y python3 make g++ pkg-config \
  && rm -rf /var/lib/apt/lists/*

# Копируем ВЕСЬ репозиторий (чтобы точно попали react/index.html и vite.config.ts)
COPY . /app

# Переходим в папку фронта
WORKDIR /app/react

# Устанавливаем зависимости и СТРОГО запускаем скрипт сборки из package.json
RUN npm ci --legacy-peer-deps
# (для наглядности проверим, что index.html на месте)
RUN test -f index.html || (echo "index.html not found in /app/react" && ls -la && exit 1)
RUN npm run build

# ===== 2) BACKEND (Python 3.12) =====
FROM python:3.12-slim AS backend
WORKDIR /app

# системные пакеты (компилятор и т.п.)
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

# Порт (если в main.py другой — скажи, поменяем)
ENV PORT=8000
ENV PYTHONUNBUFFERED=1

EXPOSE 8000
WORKDIR /app/server

# Точка входа (как в README)
CMD ["python", "main.py"]

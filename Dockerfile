# ===== 1) FRONTEND (React/Vite без строгого tsc) =====
FROM node:18-bullseye AS frontend
WORKDIR /app

# Инструменты на случай native-зависимостей у npm-пакетов
RUN apt-get update && apt-get install -y python3 make g++ pkg-config \
  && rm -rf /var/lib/apt/lists/*

# Копируем весь репозиторий (чтобы точно попали react/index.html и vite.config.ts)
COPY . /app

# Переходим в папку фронта, ставим зависимости, собираем ЧЕРЕЗ Vite
WORKDIR /app/react
RUN npm ci --legacy-peer-deps
# Проверим наличие index.html (если нет — сразу покажем в логе)
RUN test -f index.html || (echo "index.html not found in /app/react" && ls -la && exit 1)
# КЛЮЧЕВАЯ строка: без tsc, только Vite
RUN npx vite build

# ===== 2) BACKEND (Python 3.12) =====
FROM python:3.12-slim AS backend
WORKDIR /app

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
ENV UI_DIST_DIR=/app/server/react-dist

# Порт жёстко задаём внутри образа (переменные Railway не требуются)
ENV PORT=8000
ENV PYTHONUNBUFFERED=1

EXPOSE 8000
WORKDIR /app/server

# Как в README
CMD ["python", "main.py"]

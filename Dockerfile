# ===== 1) Сборка фронта (React/Vite) =====
FROM node:18-bullseye AS frontend
WORKDIR /app

# инструменты (на случай native-зависимостей у npm-пакетов)
RUN apt-get update && apt-get install -y python3 make g++ pkg-config \
  && rm -rf /var/lib/apt/lists/*

# 1. зависимости
COPY react/package*.json ./react/
WORKDIR /app/react
RUN npm ci --legacy-peer-deps

# 2. КОД ФРОНТА (вот этого как раз не хватало)
COPY react/ ./

# 3. билд
RUN npx vite build

# ===== 2) Сервер (Python 3.12) + статические файлы фронта =====
FROM python:3.12-slim AS backend
WORKDIR /app

# базовые системные пакеты
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl \
  && rm -rf /var/lib/apt/lists/*

# зависимости сервера
COPY server/requirements.txt /app/server/requirements.txt
RUN pip install --no-cache-dir -r /app/server/requirements.txt

# код сервера
COPY server/ /app/server/

# статические файлы фронта (Vite кладёт в react/dist)
COPY --from=frontend /app/react/dist /app/server/react-dist

# порт; если у тебя другой — поменяй здесь и в Railway Variables
ENV PORT=8000
ENV PYTHONUNBUFFERED=1

EXPOSE 8000
WORKDIR /app/server

# если точка входа другая — скажи, поправлю
CMD ["python", "main.py"]

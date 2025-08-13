# ===== 1) Сборка фронта (React/Vite) =====
FROM node:18-bullseye AS frontend
WORKDIR /app
# инструменты на случай native-зависимостей
RUN apt-get update && apt-get install -y python3 make g++ pkg-config \
  && rm -rf /var/lib/apt/lists/*

# ставим зависимости и собираем фронт
COPY react/package*.json ./react/
WORKDIR /app/react
RUN npm install --force
RUN npx vite build

# ===== 2) Сервер (Python 3.12) + статические файлы фронта =====
FROM python:3.12-slim AS backend
WORKDIR /app

# системные пакеты (компилятор и т.п., на всякий случай)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl \
  && rm -rf /var/lib/apt/lists/*

# Python-зависимости
COPY server/requirements.txt /app/server/requirements.txt
RUN pip install --no-cache-dir -r /app/server/requirements.txt

# код сервера
COPY server/ /app/server/

# собранный фронт (Vite кладет в react/dist)
COPY --from=frontend /app/react/dist /app/server/react-dist

# порт, который будет слушать сервер
ENV PORT=8000
ENV PYTHONUNBUFFERED=1

EXPOSE 8000
WORKDIR /app/server

# Запускаем сервер (как в README: python main.py)
# Если у тебя точка входа другая — скажи, поправлю.
CMD ["python", "main.py"]

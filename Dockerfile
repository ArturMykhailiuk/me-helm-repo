# Використовуємо офіційний образ Python
FROM python:3.9-slim

# Встановлюємо робочу директорію
WORKDIR /app

# Встановлюємо системні залежності
RUN apt-get update && apt-get install -y \
    postgresql-client \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Копіюємо файл залежностей
COPY requirements.txt .

# Встановлюємо Python залежності
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо код проєкту
COPY . .

# Створюємо директорію для статичних файлів
RUN mkdir -p staticfiles

# Копіюємо та налаштовуємо entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Відкриваємо порт
EXPOSE 8000

# Встановлюємо entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Команда для запуску Django сервера
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "myproject.wsgi:application"]

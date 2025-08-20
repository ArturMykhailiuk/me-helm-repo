#!/bin/bash

# Скрипт для ініціалізації Django проєкту в Docker

echo "🚀 Ініціалізація Django проєкту..."

# Перевірка чи встановлено Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не встановлено. Спочатку запустіть ./install_dev_tools.sh"
    exit 1
fi

# Перевірка чи встановлено Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose не встановлено"
    exit 1
fi

echo "✅ Docker та Docker Compose знайдено"

# Збірка та запуск контейнерів
echo "🔨 Збірка Docker образів..."
docker-compose build

echo "🗄️ Запуск бази даних..."
docker-compose up -d db

echo "⏳ Очікування готовності PostgreSQL..."
sleep 10

echo "🔧 Виконання міграцій Django..."
docker-compose run --rm web python manage.py migrate

echo "👤 Створення суперкористувача (admin/admin)..."
docker-compose run --rm web python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin')
    print('Суперкористувача створено: admin/admin')
else:
    print('Суперкористувач вже існує')
"

echo "📦 Збір статичних файлів..."
docker-compose run --rm web python manage.py collectstatic --noinput

echo "🚀 Запуск всіх сервісів..."
docker-compose up -d

echo ""
echo "✅ Проєкт успішно запущено!"
echo ""
echo "🌐 Доступні адреси:"
echo "   Django додаток: http://localhost"
echo "   Адмін панель: http://localhost/admin"
echo "   Логін: admin / Пароль: admin"
echo ""
echo "📊 Перевірка статусу:"
echo "   docker-compose ps"
echo ""
echo "📝 Перегляд логів:"
echo "   docker-compose logs -f"
echo ""
echo "🛑 Зупинка:"
echo "   docker-compose down"

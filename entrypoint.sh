#!/bin/bash

echo "🔧 Очікування бази даних..."
while ! nc -z db 5432; do
  sleep 1
done

echo "✅ База даних готова!"

echo "🔧 Виконання міграцій..."
python manage.py migrate --noinput

echo "📦 Збір статичних файлів..."
python manage.py collectstatic --noinput

echo "👤 Створення суперкористувача..."
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', '123Django123')
    print('✅ Суперкористувач створено: admin/123Django123')
else:
    print('ℹ️ Суперкористувач вже існує')
"

echo "🚀 Запуск Django сервера..."
exec "$@"

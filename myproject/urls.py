"""
URL configuration for myproject project.
"""

from django.contrib import admin
from django.urls import path, include
from django.http import HttpResponse


def home_view(request):
    return HttpResponse(
        """
    <h1>🚀 Django з Docker працює! Чудово! Test push</h1>
    <p>Вітаємо! Ваш Django проєкт успішно запущений в Docker контейнері.</p>
    <hr>
    <p><strong>Конфігурація:</strong></p>
    <ul>
        <li>Django + PostgreSQL + Nginx</li>
        <li>Docker Compose</li>
        <li>Gunicorn як WSGI сервер</li>
    </ul>
    <p><a href="/admin/">Адмін панель</a></p>
    """
    )


urlpatterns = [
    path("admin/", admin.site.urls),
    path("", home_view, name="home"),
]

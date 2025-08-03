#!/bin/bash

# Скрипт для тестирования сети в Docker контейнере

echo "🧪 Тестирование Docker сети"
echo "=========================="

# Проверяем базовую сеть с простым Ubuntu контейнером
echo ""
echo "1️⃣ Тест базовой сети Ubuntu:"
docker run --rm ubuntu:22.04 bash -c "
    echo 'Проверка DNS...'
    cat /etc/resolv.conf
    echo ''
    echo 'Проверка доступности серверов...'
    apt-get update -qq && echo '✅ apt update работает' || echo '❌ apt update не работает'
" 2>/dev/null || echo "❌ Ошибка запуска базового контейнера"

echo ""
echo "2️⃣ Тест с кастомным DNS:"
docker run --rm --dns=8.8.8.8 --dns=8.8.4.4 ubuntu:22.04 bash -c "
    echo 'DNS настройки:'
    cat /etc/resolv.conf
    echo ''
    echo 'Проверка ping...'
    apt-get update -qq && apt-get install -y iputils-ping -qq
    ping -c 1 8.8.8.8 && echo '✅ ping работает' || echo '❌ ping не работает'
    apt-get update -qq && echo '✅ apt update работает' || echo '❌ apt update не работает'
" 2>/dev/null || echo "❌ Ошибка теста с кастомным DNS"

echo ""
echo "3️⃣ Тест с хост-сетью:"
docker run --rm --network=host ubuntu:22.04 bash -c "
    echo 'DNS настройки (хост-сеть):'
    cat /etc/resolv.conf
    echo ''
    apt-get update -qq && echo '✅ apt update работает' || echo '❌ apt update не работает'
" 2>/dev/null || echo "❌ Ошибка теста с хост-сетью"

echo ""
echo "4️⃣ Тест российских зеркал:"
docker run --rm ubuntu:22.04 bash -c "
    echo 'Переключение на российские зеркала...'
    echo 'deb http://mirror.yandex.ru/ubuntu/ jammy main restricted universe multiverse' > /etc/apt/sources.list
    echo 'deb http://mirror.yandex.ru/ubuntu/ jammy-updates main restricted universe multiverse' >> /etc/apt/sources.list
    echo 'deb http://mirror.yandex.ru/ubuntu/ jammy-security main restricted universe multiverse' >> /etc/apt/sources.list
    apt-get update -qq && echo '✅ Российские зеркала работают' || echo '❌ Российские зеркала не работают'
" 2>/dev/null || echo "❌ Ошибка теста российских зеркал"

echo ""
echo "📊 Результаты тестирования завершены"
echo ""
echo "🛠️ Рекомендации:"
echo "- Если тест 1 прошел: используйте стандартный Dockerfile"
echo "- Если прошел только тест 2: добавьте DNS настройки в docker-compose"
echo "- Если прошел только тест 3: используйте --network=host"
echo "- Если прошел тест 4: используйте российские зеркала"

# Проверяем какие Docker сети доступны
echo ""
echo "🔌 Доступные Docker сети:"
docker network ls

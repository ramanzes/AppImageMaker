#!/bin/bash

# Скрипт для диагностики сетевых проблем Docker

echo "🔍 Диагностика сетевых проблем Docker"
echo "====================================="

# Проверяем DNS настройки хоста
echo ""
echo "📡 DNS настройки хоста:"
cat /etc/resolv.conf

# Проверяем доступность основных серверов
echo ""
echo "🌐 Проверка доступности серверов:"
for host in archive.ubuntu.com security.ubuntu.com mirror.yandex.ru 8.8.8.8; do
    echo -n "  $host: "
    if ping -c 1 -W 3 "$host" >/dev/null 2>&1; then
        echo "✅ доступен"
    else
        echo "❌ недоступен"
    fi
done

# Проверяем Docker daemon
echo ""
echo "🐳 Статус Docker:"
if systemctl is-active --quiet docker; then
    echo "  ✅ Docker daemon запущен"
else
    echo "  ❌ Docker daemon не запущен"
    echo "  Попробуйте: sudo systemctl start docker"
fi

# Проверяем Docker сеть
echo ""
echo "🔌 Docker сети:"
docker network ls 2>/dev/null || echo "  ❌ Не удалось получить список сетей"

# Предлагаем решения
echo ""
echo "🛠️ Возможные решения:"
echo ""
echo "1. Перезапуск Docker daemon:"
echo "   sudo systemctl restart docker"
echo ""
echo "2. Очистка Docker кэша:"
echo "   docker system prune -f"
echo ""
echo "3. Проверка настроек прокси (если используется):"
echo "   docker info | grep -i proxy"
echo ""
echo "4. Использование альтернативного Dockerfile:"
echo "   mv Dockerfile Dockerfile.original"
echo "   mv Dockerfile.alternative Dockerfile"
echo "   docker-compose build --no-cache"
echo ""
echo "5. Ручная сборка с отладкой:"
echo "   docker build --network=host --progress=plain ."
echo ""
echo "6. Использование хост-сети:"
echo "   docker run --network=host ubuntu:22.04 apt update"

# Тест простой сборки
echo ""
echo "🧪 Тест простой сборки Ubuntu:"
echo "docker run --rm ubuntu:22.04 bash -c 'apt update && echo \"Тест успешен\"'"

# Создаем минимальный тестовый Dockerfile
cat > Dockerfile.test << 'EOF'
FROM ubuntu:22.04
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf
RUN apt update
EOF

echo ""
echo "📝 Создан тестовый Dockerfile.test"
echo "Запустите: docker build -f Dockerfile.test ."

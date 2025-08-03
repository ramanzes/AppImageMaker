#!/bin/bash

# Скрипт для запуска AppImage Builder

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверяем наличие Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker не установлен. Установите Docker и попробуйте снова."
    exit 1
fi

# Проверяем наличие docker-compose
if ! command -v docker-compose &> /dev/null; then
    log_error "docker-compose не установлен. Установите docker-compose и попробуйте снова."
    exit 1
fi

log_info "🐳 AppImage Builder Docker"
echo "=========================="

# Создаем необходимые директории
mkdir -p ./itdid

# Проверяем наличие файла todo
if [[ ! -f "./todo" ]]; then
    log_warning "Файл todo не найден. Создаем пример..."
    cat > ./todo << 'EOF'
# Список программ для создания AppImage
# Каждая строка = одна программа

krusader
htop
mc
gedit
EOF
    log_info "📝 Создан файл todo с примерами программ"
    log_info "Отредактируйте файл todo и запустите скрипт снова"
    exit 0
fi

log_info "📝 Найден файл todo:"
cat ./todo | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*' | while read app; do
    echo "  • $app"
done

# Проверяем сетевое подключение
log_info ""
log_info "🌐 Проверка сетевого подключения..."
if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    log_warning "⚠️ Проблемы с сетевым подключением обнаружены"
    log_info "Запустите скрипт диагностики: chmod +x debug-network.sh && ./debug-network.sh"
fi

# Проверяем статус Docker
if ! systemctl is-active --quiet docker 2>/dev/null; then
    log_warning "⚠️ Docker daemon может быть не запущен"
    log_info "Попробуйте: sudo systemctl start docker"
fi

log_info ""
log_info "🏗️ Запуск сборки AppImage файлов..."
log_info "📁 Готовые файлы будут сохранены в ./itdid/"

# Функция для повторных попыток сборки
build_with_retry() {
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Попытка сборки $attempt из $max_attempts..."
        
        if docker-compose build --no-cache; then
            log_success "✅ Сборка образа успешна!"
            break
        else
            log_warning "❌ Сборка образа неудачна (попытка $attempt)"
            
            if [[ $attempt -eq $max_attempts ]]; then
                log_error "Все попытки сборки исчерпаны"
                log_info ""
                log_info "🛠️ Возможные решения:"
                log_info "1. Проверьте интернет-соединение"
                log_info "2. Запустите диагностику: ./debug-network.sh"
                log_info "3. Попробуйте альтернативный Dockerfile:"
                log_info "   mv Dockerfile Dockerfile.original"
                log_info "   mv Dockerfile.alternative Dockerfile"
                log_info "   ./build.sh"
                log_info "4. Используйте хост-сеть:"
                log_info "   docker build --network=host ."
                return 1
            fi
            
            ((attempt++))
            log_info "Ожидание 10 секунд перед следующей попыткой..."
            sleep 10
        fi
    done
    
    return 0
}

# Собираем Docker образ с повторными попытками
if ! build_with_retry; then
    exit 1
fi

# Запускаем контейнер
log_info "🚀 Запуск контейнера для сборки AppImage..."
if docker-compose run --rm appimage-builder; then
    log_success "🎉 Готово!"
else
    log_error "❌ Ошибка при выполнении сборки"
    log_info "Попробуйте запустить контейнер в интерактивном режиме для отладки:"
    log_info "docker-compose run --rm appimage-builder bash"
    exit 1
fi

log_info "📁 Проверьте директорию ./itdid/ для готовых AppImage файлов"

# Показываем созданные файлы
if ls ./itdid/*.AppImage 1> /dev/null 2>&1; then
    log_info ""
    log_success "📦 Созданные AppImage файлы:"
    ls -la ./itdid/*.AppImage
    
    log_info ""
    log_info "🚀 Для запуска AppImage:"
    echo "  chmod +x ./itdid/название.AppImage"
    echo "  ./itdid/название.AppImage"
else
    log_warning "❌ AppImage файлы не были созданы"
    log_info "Проверьте логи выше для диагностики проблем"
fi

#!/bin/bash

# Продвинутый скрипт запуска AppImage Builder с множественными стратегиями

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

show_usage() {
    echo "🐳 AppImage Builder - Продвинутый запуск"
    echo "========================================"
    echo ""
    echo "Использование: $0 [опция]"
    echo ""
    echo "Опции:"
    echo "  auto     - Автоматический выбор стратегии (по умолчанию)"
    echo "  simple   - Использовать простой Dockerfile"
    echo "  host     - Использовать хост-сеть"
    echo "  mirror   - Использовать российские зеркала"
    echo "  test     - Протестировать сеть"
    echo "  clean    - Очистить Docker кэш и перестроить"
    echo "  help     - Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0              # Автоматический режим"
    echo "  $0 test         # Тестирование сети"
    echo "  $0 simple       # Простая сборка"
    echo "  $0 clean        # Очистка и пересборка"
}

# Проверяем аргументы
MODE=${1:-auto}

case "$MODE" in
    help|-h|--help)
        show_usage
        exit 0
        ;;
esac

# Проверяем зависимости
if ! command -v docker &> /dev/null; then
    log_error "Docker не установлен"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    log_error "docker-compose не установлен"
    exit 1
fi

# Создаем необходимые директории
mkdir -p ./itdid

# Проверяем файл todo
if [[ ! -f "./todo" ]]; then
    log_warning "Файл todo не найден. Создаем пример..."
    cat > ./todo << 'EOF'
# Список программ для создания AppImage
krusader
htop
mc
gedit
EOF
    log_info "📝 Создан файл todo с примерами"
    log_info "Отредактируйте файл todo и запустите скрипт снова"
    exit 0
fi

# Функция тестирования сети
test_network() {
    log_info "🧪 Тестирование Docker сети..."
    chmod +x test-docker-network.sh
    ./test-docker-network.sh
}

# Функция очистки
clean_docker() {
    log_info "🧹 Очистка Docker кэша..."
    docker system prune -f
    docker-compose down --volumes --remove-orphans 2>/dev/null || true
    log_success "Очистка завершена"
}

# Функция сборки с простым Dockerfile
build_simple() {
    log_info "🔧 Сборка с простым Dockerfile..."
    cp Dockerfile.simple Dockerfile.current
    docker build -f Dockerfile.current -t appimage-builder:simple .
    docker run --rm -v $(pwd):/workspace --privileged appimage-builder:simple
}

# Функция сборки с хост-сетью
build_host_network() {
    log_info "🌐 Сборка с хост-сетью..."
    docker build --network=host -t appimage-builder:host .
    docker run --rm -v --network=host -v $(pwd):/workspace --privileged appimage-builder:host
}

# Функция сборки с российскими зеркалами
build_with_mirrors() {
    log_info "🇷🇺 Сборка с российскими зеркалами..."
    cp Dockerfile.alternative Dockerfile.current
    docker build -f Dockerfile.current -t appimage-builder:mirror .
    docker run --rm -v $(pwd):/workspace --privileged appimage-builder:mirror
}

# Функция автоматического выбора стратегии
build_auto() {
    log_info "🤖 Автоматический выбор стратегии сборки..."
    
    # Стратегия 1: Пробуем стандартную сборку
    log_info "Попытка 1: Стандартная сборка..."
    if docker-compose build --no-cache 2>/dev/null && docker-compose run --rm appimage-builder 2>/dev/null; then
        log_success "✅ Стандартная сборка успешна!"
        return 0
    fi
    log_warning "❌ Стандартная сборка не удалась"
    
    # Стратегия 2: Простой Dockerfile
    log_info "Попытка 2: Простая сборка..."
    if build_simple 2>/dev/null; then
        log_success "✅ Простая сборка успешна!"
        return 0
    fi
    log_warning "❌ Простая сборка не удалась"
    
    # Стратегия 3: Хост-сеть
    log_info "Попытка 3: Сборка с хост-сетью..."
    if build_host_network 2>/dev/null; then
        log_success "✅ Сборка с хост-сетью успешна!"
        return 0
    fi
    log_warning "❌ Сборка с хост-сетью не удалась"
    
    # Стратегия 4: Российские зеркала
    log_info "Попытка 4: Российские зеркала..."
    if build_with_mirrors 2>/dev/null; then
        log_success "✅ Сборка с российскими зеркалами успешна!"
        return 0
    fi
    log_warning "❌ Все стратегии не удались"
    
    log_error "Не удалось собрать AppImage ни одним способом"
    log_info "Запустите '$0 test' для диагностики сети"
    return 1
}

# Основная логика
case "$MODE" in
    test)
        test_network
        ;;
    clean)
        clean_docker
        ;;
    simple)
        build_simple
        ;;
    host)
        build_host_network
        ;;
    mirror)
        build_with_mirrors
        ;;
    auto)
        build_auto
        ;;
    *)
        log_error "Неизвестная опция: $MODE"
        show_usage
        exit 1
        ;;
esac

# Проверяем результаты
if [[ "$MODE" != "test" && "$MODE" != "clean" ]]; then
    log_info ""
    log_info "📁 Проверка результатов..."
    
    if ls ./itdid/*.AppImage 1> /dev/null 2>&1; then
        log_success "📦 Созданные AppImage файлы:"
        ls -la ./itdid/*.AppImage
        
        log_info ""
        log_info "🚀 Для запуска AppImage:"
        echo "  chmod +x ./itdid/название.AppImage"
        echo "  ./itdid/название.AppImage"
    else
        log_warning "❌ AppImage файлы не были созданы"
        if [[ "$MODE" == "auto" ]]; then
            log_info "Попробуйте: $0 test"
        fi
    fi
fi

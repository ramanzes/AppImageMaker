#!/bin/bash
# AppImage Builder Script
# Читает файл todo и создает AppImage для каждого приложения
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для цветного вывода
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Директории
TODO_FILE="/workspace/todo"
OUTPUT_DIR="/workspace/itdid"
WORK_DIR="/tmp/appimage_build"

# Создаем выходную директорию
mkdir -p "$OUTPUT_DIR"
mkdir -p "$WORK_DIR"

log_info "🚀 Запуск AppImage Builder"
log_info "📝 TODO файл: $TODO_FILE"
log_info "📁 Выходная директория: $OUTPUT_DIR"

# Проверяем наличие файла todo
if [[ ! -f "$TODO_FILE" ]]; then
    log_error "Файл todo не найден: $TODO_FILE"
    log_info "Создайте файл todo со списком программ для сборки AppImage"
    log_info "Пример содержимого:"
    echo "krusader"
    echo "firefox"
    echo "vlc"
    exit 1
fi

# Функция для установки пакета
install_package() {
    local package="$1"
    log_info "📦 Установка пакета: $package"
    
    # Обновляем список пакетов если нужно
    if [[ ! -f /tmp/apt_updated ]]; then
        apt-get update
        touch /tmp/apt_updated
    fi
    
    # Пытаемся установить пакет
    if apt-get install -y "$package" 2>/dev/null; then
        return 0
    else
        log_warning "Не удалось установить $package, пытаемся найти альтернативы"
        # Ищем пакеты с похожими именами
        local alternatives=$(apt-cache search "^$package" | head -5 | cut -d' ' -f1)
        if [[ -n "$alternatives" ]]; then
            for alt in $alternatives; do
                log_info "Пробуем альтернативу: $alt"
                if apt-get install -y "$alt" 2>/dev/null; then
                    return 0
                fi
            done
        fi
        return 1
    fi
}

# Функция для получения зависимостей
get_dependencies() {
    local binary="$1"
    local lib_dir="$2"
    
    log_info "🔍 Собираем зависимости для $binary"
    
    # Создаем директорию для библиотек
    mkdir -p "$lib_dir"
    
    # Получаем список зависимостей
    local deps=$(ldd "$binary" 2>/dev/null | grep "=> /" | awk '{print $3}' | grep -v "^/lib64" | grep -v "^/lib/x86_64" | sort -u)
    
    for lib in $deps; do
        if [[ -f "$lib" ]]; then
            local lib_name=$(basename "$lib")
            if [[ ! -f "$lib_dir/$lib_name" ]]; then
                cp "$lib" "$lib_dir/" 2>/dev/null || true
                log_info "  📚 Скопирована библиотека: $lib_name"
            fi
        fi
    done
}

# Функция для поиска иконки
find_icon() {
    local app_name="$1"
    local app_dir="$2"
    
    # Возможные расположения иконок
    local icon_paths=(
        "/usr/share/icons/hicolor/256x256/apps/${app_name}.png"
        "/usr/share/icons/hicolor/128x128/apps/${app_name}.png"
        "/usr/share/icons/hicolor/64x64/apps/${app_name}.png"
        "/usr/share/icons/hicolor/48x48/apps/${app_name}.png"
        "/usr/share/pixmaps/${app_name}.png"
        "/usr/share/pixmaps/${app_name}.xpm"
        "/usr/share/icons/${app_name}.png"
    )
    
    for icon_path in "${icon_paths[@]}"; do
        if [[ -f "$icon_path" ]]; then
            cp "$icon_path" "$app_dir/${app_name}.png"
            log_info "  🎨 Найдена иконка: $icon_path"
            return 0
        fi
    done
    
    # Ищем любую иконку с именем приложения
    local found_icon=$(find /usr/share -name "${app_name}*" -type f \( -name "*.png" -o -name "*.svg" -o -name "*.xpm" \) 2>/dev/null | head -1)
    if [[ -n "$found_icon" ]]; then
        cp "$found_icon" "$app_dir/${app_name}.png"
        log_info "  🎨 Найдена иконка: $found_icon"
        return 0
    fi
    
    log_warning "Иконка для $app_name не найдена, создаем заглушку"
    # Создаем простую заглушку
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==" | base64 -d > "$app_dir/${app_name}.png"
    return 0
}

# Функция для поиска desktop файла
find_desktop_file() {
    local app_name="$1"
    
    # Возможные расположения desktop файлов
    local desktop_paths=(
        "/usr/share/applications/${app_name}.desktop"
        "/usr/share/applications/kde4/${app_name}.desktop"
        "/usr/local/share/applications/${app_name}.desktop"
    )
    
    for desktop_path in "${desktop_paths[@]}"; do
        if [[ -f "$desktop_path" ]]; then
            echo "$desktop_path"
            return 0
        fi
    done
    
    # Ищем desktop файл с именем приложения
    local found_desktop=$(find /usr/share/applications -name "*${app_name}*" -type f -name "*.desktop" 2>/dev/null | head -1)
    if [[ -n "$found_desktop" ]]; then
        echo "$found_desktop"
        return 0
    fi
    
    return 1
}

# Функция для создания desktop файла
create_desktop_file() {
    local app_name="$1"
    local app_dir="$2"
    local executable="$3"
    
    log_info "🖥 Создание desktop файла для $app_name..."
    
    # Пытаемся найти существующий desktop файл
    local existing_desktop=$(find_desktop_file "$app_name")
    
    if [[ -n "$existing_desktop" ]]; then
        log_info "📋 Найден существующий desktop файл: $existing_desktop"
        # Копируем и модифицируем существующий
        cp "$existing_desktop" "$app_dir/${app_name}.desktop"
        # Исправляем Exec= строку
        sed -i "s|Exec=.*|Exec=AppRun|g" "$app_dir/${app_name}.desktop"
        sed -i "s|Icon=.*|Icon=${app_name}|g" "$app_dir/${app_name}.desktop"
    else
        log_info "📝 Создание нового desktop файла..."
        # Получаем информацию о приложении
        local app_comment="Application"
        local app_categories="Application;"
        
        # Пытаемся определить категорию
        case "$app_name" in
            *krusader*|*nautilus*|*dolphin*|*thunar*)
                app_categories="System;FileTools;FileManager;"
                app_comment="File Manager"
                ;;
            *firefox*|*chromium*|*chrome*)
                app_categories="Network;WebBrowser;"
                app_comment="Web Browser"
                ;;
            *vlc*|*mplayer*)
                app_categories="AudioVideo;Video;Player;"
                app_comment="Media Player"
                ;;
            *gimp*|*inkscape*)
                app_categories="Graphics;Photography;"
                app_comment="Graphics Editor"
                ;;
            *kate*|*gedit*|*mousepad*)
                app_categories="Development;TextEditor;"
                app_comment="Text Editor"
                ;;
            *htop*|*mc*)
                app_categories="System;Monitor;"
                app_comment="System Monitor"
                ;;
        esac
        
        # Создаем новый desktop файл
        cat > "$app_dir/${app_name}.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${app_name^}
Comment=${app_comment}
Exec=AppRun
Icon=${app_name}
Terminal=false
Categories=${app_categories}
StartupNotify=true
EOF
    fi
    
    # Проверяем валидность desktop файла
    if command -v desktop-file-validate >/dev/null 2>&1; then
        if desktop-file-validate "$app_dir/${app_name}.desktop" 2>/dev/null; then
            log_success "✅ Desktop файл валиден"
        else
            log_warning "⚠ Desktop файл может содержать ошибки"
        fi
    fi
    
    # ВАЖНО: Создаем главный desktop файл в корне AppDir
    cp "$app_dir/${app_name}.desktop" "$app_dir/$(basename "$app_dir").desktop"
    log_info "📋 Создан главный desktop файл: $(basename "$app_dir").desktop"
}

# Функция для создания AppRun скрипта
create_apprun() {
    local app_dir="$1"
    local app_name="$2"
    
    log_info "⚙ Создание AppRun скрипта для $app_name..."
    
    cat > "$app_dir/AppRun" << EOF
#!/bin/bash
# AppRun скрипт для портативного запуска приложения

HERE="\$(dirname "\$(readlink -f "\${0}")")"

# Экспорт переменных окружения для поиска библиотек
export LD_LIBRARY_PATH="\${HERE}/usr/lib:\${HERE}/usr/lib/x86_64-linux-gnu:\${LD_LIBRARY_PATH}"
export PATH="\${HERE}/usr/bin:\${PATH}"

# Qt переменные окружения
export QT_PLUGIN_PATH="\${HERE}/usr/lib/qt5/plugins:\${HERE}/usr/lib/plugins:\${QT_PLUGIN_PATH}"
export QML2_IMPORT_PATH="\${HERE}/usr/lib/qt5/qml:\${QML2_IMPORT_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="\${HERE}/usr/lib/qt5/plugins/platforms"

# GTK переменные окружения
export GTK_PATH="\${HERE}/usr/lib/gtk-2.0:\${HERE}/usr/lib/gtk-3.0:\${GTK_PATH}"
export GTK_THEME_PATH="\${HERE}/usr/share/themes:\${GTK_THEME_PATH}"
export GTK_MODULE_PATH="\${HERE}/usr/lib/gtk-3.0/modules:\${GTK_MODULE_PATH}"

# XDG переменные окружения
export XDG_DATA_DIRS="\${HERE}/usr/share:\${XDG_DATA_DIRS}"
export XDG_CONFIG_DIRS="\${HERE}/usr/etc/xdg:\${XDG_CONFIG_DIRS}"

# KDE/Qt переменные
export KDEDIRS="\${HERE}/usr:\${KDEDIRS}"

# Переменные для поиска ресурсов
export APPDIR="\${HERE}"

# Установка локали
export LC_NUMERIC=C

# Переходим в директорию приложения для корректной работы
cd "\${HERE}"

# Проверяем существование исполняемого файла
if [[ ! -f "\${HERE}/usr/bin/$app_name" ]]; then
    echo "Ошибка: исполняемый файл не найден: \${HERE}/usr/bin/$app_name"
    exit 1
fi

# Запускаем приложение с переданными аргументами
exec "\${HERE}/usr/bin/$app_name" "\$@"
EOF
    
    chmod +x "$app_dir/AppRun"
    log_success "✅ AppRun скрипт создан"
}

# Функция для создания AppImage
build_appimage() {
    local app_name="$1"
    local build_dir="$WORK_DIR/$app_name"
    
    log_info "🏗 Начинаем сборку AppImage для: $app_name"
    
    # Проверяем, не создан ли уже AppImage
    if [[ -f "$OUTPUT_DIR/${app_name}.AppImage" ]]; then
        log_warning "AppImage для $app_name уже существует, пропускаем"
        return 0
    fi
    
    # Очищаем рабочую директорию
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    # Устанавливаем пакет
    if ! install_package "$app_name"; then
        log_error "Не удалось установить $app_name"
        return 1
    fi
    
    # Проверяем, что исполняемый файл существует
    local executable=$(which "$app_name" 2>/dev/null)
    if [[ -z "$executable" ]]; then
        # Ищем в стандартных местах
        for path in /usr/bin /usr/local/bin /bin; do
            if [[ -f "$path/$app_name" ]]; then
                executable="$path/$app_name"
                break
            fi
        done
    fi
    
    if [[ -z "$executable" ]]; then
        log_error "Исполняемый файл для $app_name не найден"
        return 1
    fi
    
    log_info "📍 Найден исполняемый файл: $executable"
    
    # Создаем AppDir структуру
    local app_dir="${app_name^}AppDir"
    mkdir -p "$app_dir/usr/bin"
    mkdir -p "$app_dir/usr/lib"
    mkdir -p "$app_dir/usr/share"
    
    # Копируем исполняемый файл
    cp "$executable" "$app_dir/usr/bin/"
    log_info "📁 Скопирован исполняемый файл"
    
    # Собираем зависимости
    get_dependencies "$executable" "$app_dir/usr/lib"
    
    # Копируем ресурсы приложения
    for share_dir in /usr/share/"$app_name" /usr/share/applications /usr/share/icons; do
        if [[ -d "$share_dir" ]]; then
            cp -r "$share_dir" "$app_dir/usr/share/" 2>/dev/null || true
        fi
    done
    
    # Ищем и копируем иконку
    find_icon "$app_name" "$app_dir"
    
    # Создаем desktop файл
    create_desktop_file "$app_name" "$app_dir" "$executable"
    
    # Создаем AppRun скрипт
    create_apprun "$app_dir" "$app_name"
    
    # Проверяем структуру AppDir
    log_info "🔍 Проверка AppDir структуры..."
    log_info "📁 Содержимое AppDir:"
    ls -la "$app_dir/" | while read line; do
        log_info "  $line"
    done
    
    # Проверяем наличие обязательных файлов
    local required_files=("AppRun" "$(basename "$app_dir").desktop")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$app_dir/$file" ]]; then
            log_error "Отсутствует обязательный файл: $file"
            return 1
        else
            log_success "✅ Найден: $file"
        fi
    done
    
    # Создаем AppImage
    log_info "📦 Создание AppImage..."
    
    # Устанавливаем переменные окружения для appimagetool
    export APPIMAGE_EXTRACT_AND_RUN=1
    
    # Запускаем appimagetool с более подробным выводом
    if appimagetool --verbose --no-appstream "$app_dir" "${app_name}.AppImage"; then
        # Проверяем, что файл действительно создался
        if [[ -f "${app_name}.AppImage" ]]; then
            # Перемещаем готовый AppImage в выходную директорию
            mv "${app_name}.AppImage" "$OUTPUT_DIR/"
            log_success "✅ AppImage для $app_name создан успешно!"
            
            # Показываем информацию о файле
            local size=$(du -h "$OUTPUT_DIR/${app_name}.AppImage" 2>/dev/null | cut -f1)
            log_info "📊 Размер: $size"
            
            # Делаем файл исполняемым
            chmod +x "$OUTPUT_DIR/${app_name}.AppImage"
            
            return 0
        else
            log_error "❌ AppImage файл не был создан"
            return 1
        fi
    else
        log_error "❌ Ошибка при создании AppImage для $app_name"
        return 1
    fi
}

# Основная логика
main() {
    log_info "📖 Чтение файла todo..."
    
    local total_apps=0
    local successful_apps=0
    local failed_apps=()
    
    # Читаем файл todo построчно
    while IFS= read -r app_name || [[ -n "$app_name" ]]; do
        # Пропускаем пустые строки и комментарии
        if [[ -z "$app_name" ]] || [[ "$app_name" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Убираем пробелы в начале и конце
        app_name=$(echo "$app_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [[ -n "$app_name" ]]; then
            total_apps+=1
            log_info "🎯 Обработка: $app_name"
            
            if build_appimage "$app_name"; then
                successful_apps+=1
            else
                failed_apps+=("$app_name")
            fi
            
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        fi
    done < "$TODO_FILE"
    
    # Выводим итоговую статистику
    echo ""
    log_info "📈 ИТОГОВАЯ СТАТИСТИКА"
    log_info "────────────────────────"
    log_info "Всего приложений: $(printf "%02d" $total_apps)"
    log_success "Успешно собрано: $(printf "%02d" $successful_apps)"
    
    if [[ ${#failed_apps[@]} -gt 0 ]]; then
        log_error "Не удалось собрать: ${#failed_apps[@]}"
        for failed_app in "${failed_apps[@]}"; do
            log_error "  ❌ $failed_app"
        done
    fi
    
    log_info ""
    log_info "📁 Готовые AppImage файлы находятся в: $OUTPUT_DIR"
    log_info "📋 Список созданных файлов:"
    
    # Проверяем результаты
    if ls "$OUTPUT_DIR"/*.AppImage >/dev/null 2>&1; then
        ls -la "$OUTPUT_DIR"/*.AppImage | while read line; do
            log_success "  ✅ $line"
        done
    else
        log_warning "❌ AppImage файлы не были созданы"
    fi
}

# Проверяем, что мы запущены в контейнере
if [[ ! -f /.dockerenv ]]; then
    log_warning "Скрипт предназначен для запуска в Docker контейнере"
fi

# Запускаем основную функцию
main

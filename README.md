# AppImageMaker 📦

Автоматизированная система для создания AppImage пакетов из Ubuntu репозиториев с использованием Docker.

## 🎯 Описание

AppImageMaker - это продвинутая Docker-система для автоматического создания переносимых AppImage файлов из Ubuntu репозиториев. 

### 🌟 Ключевые особенности:

- **🤖 Автоматические стратегии сборки** - система пробует разные подходы до успешного результата
- **🔍 Встроенная диагностика** - автоматическое определение и решение проблем
- **🌐 Множественные источники** - поддержка разных репозиториев и зеркал
- **📋 Простое управление** - один файл `todo` со списком приложений
- **🛠 Отказоустойчивость** - автоматическое переключение между стратегиями при ошибках

Система читает список приложений из файла `todo` и автоматически:

- Устанавливает пакеты из Ubuntu репозиториев
- Собирает зависимости
- Создает правильную структуру AppDir
- Генерирует AppImage файлы
- Диагностирует и решает проблемы автоматически

## 🚀 Быстрый старт

### Предварительные требования

- Docker
- Docker Compose  
- Linux хост-система
- Права администратора (для FUSE)

### Автоматическая установка

```bash
# Клонирование проекта
git clone <your-repo> AppImageMaker
cd AppImageMaker

# Или создание с нуля
mkdir AppImageMaker && cd AppImageMaker

# Автоматическое создание файла todo (если отсутствует)
chmod +x build-advanced.sh
./build-advanced.sh auto
```

При первом запуске система автоматически:
- Создаст пример файла `todo` если он отсутствует
- Проведет диагностику сети
- Выберет оптимальную стратегию сборки

### Установка и запуск

1. **Клонируйте или создайте проект:**
```bash
mkdir AppImageMaker
cd AppImageMaker
```

2. **Создайте файл со списком приложений:**
```bash
echo "krusader" > todo
echo "vlc" >> todo
echo "gimp" >> todo
```

3. **Запустите сборку (рекомендуемый способ):**
```bash
# Автоматический режим с множественными стратегиями
chmod +x build-advanced.sh
./build-advanced.sh auto
```

**Альтернативные способы запуска:**
```bash
# Стандартный Docker Compose
docker-compose up

# Простая сборка
./build-advanced.sh simple

# Сборка с российскими зеркалами
./build-advanced.sh mirror

# Диагностика сети
./build-advanced.sh test
```

Готовые AppImage файлы будут созданы в директории `itdid/`.

## 📁 Структура проекта

```
AppImageMaker/
├── Dockerfile              # Основной образ для сборки
├── Dockerfile.alternative  # Альтернативный Dockerfile с российскими зеркалами
├── Dockerfile.simple       # Упрощенный Dockerfile для отладки
├── Dockerfile.test         # Минимальный тестовый Dockerfile
├── docker-compose.yaml     # Конфигурация Docker Compose
├── build_appimages.sh      # Основной скрипт сборки
├── build-advanced.sh       # Продвинутый скрипт запуска с множественными стратегиями
├── debug-network.sh        # Скрипт диагностики сетевых проблем
├── test-docker-network.sh  # Тестирование Docker сети
├── todo                    # Список приложений для сборки
├── itdid/                  # Директория с готовыми AppImage
└── README.md              # Этот файл
```

## 📋 Формат файла todo

Файл `todo` содержит список приложений для сборки, по одному на строку:

```
# Файловые менеджеры
krusader
nautilus
dolphin

# Медиа плееры
vlc
mplayer

# Графические редакторы
gimp
inkscape

# Браузеры
firefox
chromium-browser

# Текстовые редакторы
kate
gedit
```

### Поддерживаемые форматы:
- Обычные строки с именами пакетов
- Комментарии (строки, начинающиеся с `#`)
- Пустые строки (игнорируются)

## 🛠 Конфигурация

### Docker Compose настройки

```yaml
version: '3.8'
services:
  appimage-builder:
    build: .
    container_name: appimage-builder
    volumes:
      - ./:/workspace           # Монтирование рабочей директории
      - appimage-cache:/var/cache/apt  # Кэш пакетов
      - appimage-lib:/var/lib/apt      # Библиотеки пакетов
    environment:
      - DEBIAN_FRONTEND=noninteractive
      - LC_ALL=C.UTF-8
      - LANG=C.UTF-8
    dns:
      - 8.8.8.8                # Надежные DNS серверы
      - 8.8.4.4
      - 1.1.1.1
    privileged: true           # Для работы FUSE
    working_dir: /workspace
    network_mode: bridge
```

### Переменные окружения

- `DEBIAN_FRONTEND=noninteractive` - неинтерактивная установка пакетов
- `APPIMAGE_EXTRACT_AND_RUN=1` - запуск AppImage без FUSE
- `LC_ALL=C.UTF-8` - локализация

## 📊 Процесс сборки

### Автоматический режим

Продвинутый скрипт использует интеллектуальный подход:

```bash
./build-advanced.sh auto
```

**Стратегии сборки (в порядке приоритета):**

1. **Стандартная сборка** - основной Dockerfile с полными настройками
2. **Простая сборка** - минимальный Dockerfile для проблемных сред  
3. **Хост-сеть** - использование сети хоста для обхода ограничений
4. **Альтернативные зеркала** - российские репозитории Ubuntu

### Диагностический режим

```bash
./build-advanced.sh test
```

Проверяет:
- Доступность Docker daemon
- DNS настройки
- Доступность репозиториев Ubuntu
- Сетевые настройки Docker

### Ручная сборка

Для каждого приложения система выполняет:

1. **Установка пакета** из Ubuntu репозитория
2. **Поиск исполняемого файла** в стандартных директориях
3. **Сбор зависимостей** с помощью `ldd`
4. **Создание AppDir структуры:**
   ```
   AppName/
   ├── AppRun                 # Скрипт запуска
   ├── AppName.desktop        # Desktop файл приложения
   ├── AppName.png           # Иконка приложения
   └── usr/
       ├── bin/              # Исполняемые файлы
       ├── lib/              # Библиотеки
       └── share/            # Ресурсы приложения
   ```
5. **Генерация AppImage** с помощью `appimagetool`

## 🎨 Особенности

### Автоматическое определение категорий

Система автоматически определяет категории приложений:

- **Файловые менеджеры:** krusader, nautilus, dolphin, thunar
- **Браузеры:** firefox, chromium, chrome
- **Медиа плееры:** vlc, mplayer
- **Графические редакторы:** gimp, inkscape
- **Текстовые редакторы:** kate, gedit, mousepad
- **Системные утилиты:** htop, mc

### Автоматический поиск ресурсов

- **Иконки:** поиск в `/usr/share/icons/`, `/usr/share/pixmaps/`
- **Desktop файлы:** поиск в `/usr/share/applications/`
- **Библиотеки:** автоматический сбор зависимостей

### Совместимость

- Исключение системных библиотек для лучшей совместимости
- Настройка переменных окружения для Qt и GTK приложений
- Поддержка KDE/Qt и GNOME/GTK приложений

## 🔧 Команды управления

### Продвинутый скрипт (рекомендуемый)

```bash
# Показать справку
./build-advanced.sh help

# Автоматический выбор стратегии сборки
./build-advanced.sh auto

# Диагностика сетевых проблем
./build-advanced.sh test

# Простая сборка
./build-advanced.sh simple

# Сборка с хост-сетью
./build-advanced.sh host

# Сборка с российскими зеркалами
./build-advanced.sh mirror

# Очистка Docker кэша
./build-advanced.sh clean
```

### Основные команды Docker Compose

```bash
# Сборка всех приложений из todo
docker-compose up

# Пересборка с очисткой кэша
docker-compose build --no-cache
docker-compose up

# Остановка и очистка
docker-compose down
docker system prune -a
```

### Отладка

```bash
# Диагностика сетевых проблем
chmod +x debug-network.sh
./debug-network.sh

# Запуск контейнера в интерактивном режиме
docker-compose run --rm appimage-builder bash

# Просмотр логов
docker-compose logs -f appimage-builder

# Проверка созданных файлов
ls -la itdid/
```

## 📈 Статистика сборки

После завершения система выводит:

```
📈 ИТОГОВАЯ СТАТИСТИКА
────────────────────────
Всего приложений: 03
✅ Успешно собрано: 03

📁 Готовые AppImage файлы находятся в: /workspace/itdid
📋 Список созданных файлов:
  ✅ -rwxr-xr-x 1 root root 45M Aug  3 15:30 krusader.AppImage
  ✅ -rwxr-xr-x 1 root root 67M Aug  3 15:35 vlc.AppImage
  ✅ -rwxr-xr-x 1 root root 89M Aug  3 15:42 gimp.AppImage
```

## 🐛 Решение проблем

### Автоматическая диагностика

Система включает мощные инструменты диагностики:

```bash
# Комплексная диагностика
./build-advanced.sh test

# Детальная диагностика сети
./debug-network.sh
```

### Множественные стратегии сборки

Продвинутый скрипт автоматически пробует разные стратегии:

1. **Стандартная сборка** - используется основной Dockerfile
2. **Простая сборка** - упрощенный Dockerfile без дополнительных настроек
3. **Хост-сеть** - использование сети хоста для обхода проблем NAT
4. **Российские зеркала** - альтернативные репозитории

```bash
# Автоматический выбор стратегии
./build-advanced.sh auto
```

### Распространенные ошибки

**Ошибка DNS разрешения:**
```bash
# Автоматическая диагностика
./debug-network.sh

# Ручное решение: проверьте DNS настройки в docker-compose.yaml
dns:
  - 8.8.8.8
  - 8.8.4.4
```

**Ошибка доступа к репозиториям:**
```bash
# Используйте альтернативные зеркала
./build-advanced.sh mirror

# Или проверьте доступность серверов
ping archive.ubuntu.com
ping mirror.yandex.ru
```

**Ошибка "Desktop file not found":**
```bash
# Проверьте создание desktop файла в AppDir
ls AppNameAppDir/*.desktop

# Обычно исправляется автоматически в новой версии скрипта
```

**Ошибка FUSE:**
```bash
# Автоматически используется APPIMAGE_EXTRACT_AND_RUN=1
export APPIMAGE_EXTRACT_AND_RUN=1

# Или запустите с правами администратора
sudo ./build-advanced.sh auto
```

**Docker daemon не запущен:**
```bash
# Запуск Docker
sudo systemctl start docker
sudo systemctl enable docker

# Проверка статуса
./debug-network.sh
```

### Логирование

Система использует цветное логирование:
- 🔵 **INFO** - информационные сообщения
- 🟢 **SUCCESS** - успешные операции  
- 🟡 **WARNING** - предупреждения
- 🔴 **ERROR** - ошибки

## 🔒 Безопасность

- Контейнер запускается в привилегированном режиме для работы FUSE
- Используются официальные Ubuntu репозитории
- Автоматическая проверка целостности пакетов

## 📝 Лицензия

Этот проект распространяется под лицензией GPL.

## 🤝 Вклад в проект

Приветствуются:
- Сообщения об ошибках
- Предложения улучшений
- Pull requests
- Тестирование на разных приложениях

## 📞 Поддержка

### При возникновении проблем:

1. **Автоматическая диагностика:**
   ```bash
   ./build-advanced.sh test
   ./debug-network.sh
   ```

2. **Проверьте файл `todo` на корректность**

3. **Попробуйте альтернативные стратегии:**
   ```bash
   ./build-advanced.sh mirror  # Российские зеркала
   ./build-advanced.sh simple  # Простая сборка
   ./build-advanced.sh host    # Хост-сеть
   ```

4. **Очистите Docker кэш:**
   ```bash
   ./build-advanced.sh clean
   ```

5. **Проверьте логи:** 
   ```bash
   docker-compose logs -f
   ```

## 🔗 Полезные ссылки

- [AppImage документация](https://appimage.org/)
- [Docker документация](https://docs.docker.com/)
- [Ubuntu пакеты](https://packages.ubuntu.com/)

---

**Создано с ❤️ для сообщества Linux**

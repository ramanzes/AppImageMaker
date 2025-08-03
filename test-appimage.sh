#!/bin/bash

# Скрипт для тестирования appimagetool в контейнере

echo "🧪 Тестирование appimagetool"
echo "============================"

# Запускаем контейнер в интерактивном режиме для отладки
docker-compose run --rm appimage-builder bash -c "
echo '🔍 Проверка appimagetool...'
which appimagetool
echo ''

echo '📋 Версия appimagetool:'
appimagetool --version 2>/dev/null || echo 'Не удалось получить версию'
echo ''

echo '🔧 Проверка FUSE:'
fusermount -V 2>/dev/null || echo 'FUSE может не работать'
echo ''

echo '📁 Создание тестового AppDir...'
mkdir -p TestAppDir/usr/bin
echo '#!/bin/bash' > TestAppDir/usr/bin/test
echo 'echo \"Hello from AppImage!\"' >> TestAppDir/usr/bin/test
chmod +x TestAppDir/usr/bin/test

echo '[Desktop Entry]' > TestAppDir/test.desktop
echo 'Name=Test' >> TestAppDir/test.desktop
echo 'Exec=AppRun' >> TestAppDir/test.desktop
echo 'Type=Application' >> TestAppDir/test.desktop
echo 'Categories=Utility;' >> TestAppDir/test.desktop

echo '#!/bin/bash' > TestAppDir/AppRun
echo 'HERE=\"\$(dirname \"\$(readlink -f \"\${0}\")\")\"' >> TestAppDir/AppRun
echo 'exec \"\${HERE}/usr/bin/test\" \"\$@\"' >> TestAppDir/AppRun
chmod +x TestAppDir/AppRun

echo ''
echo '📦 Тестирование создания AppImage...'
if APPIMAGE_EXTRACT_AND_RUN=1 appimagetool --no-appstream TestAppDir Test.AppImage 2>&1; then
    echo '✅ Тестовый AppImage создан успешно!'
    ls -la Test.AppImage
    echo ''
    echo '🧪 Тестирование запуска...'
    chmod +x Test.AppImage
    ./Test.AppImage
else
    echo '❌ Ошибка создания тестового AppImage'
fi

echo ''
echo '🗂️ Содержимое TestAppDir:'
find TestAppDir -type f -exec ls -la {} \;
"

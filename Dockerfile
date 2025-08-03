# AppImage builder Container
FROM ubuntu:22.04

# Устанавливаем переменные окружения
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Настраиваем надежные репозитории Ubuntu
RUN echo "deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list

# Обновляем списки пакетов и устанавливаем базовые пакеты
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
    wget \
    curl \
    git \
    build-essential \
    cmake \
    pkg-config \
    file \
    desktop-file-utils \
    fuse \
    libfuse2 \
    python3 \
    python3-pip \
    squashfs-tools \
    zsync \
    patchelf \
    libglib2.0-dev \
    libc6-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем appimagetool и linuxdeploy
RUN wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O /usr/local/bin/appimagetool && \
    chmod +x /usr/local/bin/appimagetool

RUN wget -q https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage -O /usr/local/bin/linuxdeploy && \
    chmod +x /usr/local/bin/linuxdeploy

# Настраиваем FUSE для работы в контейнере
RUN echo 'user_allow_other' >> /etc/fuse.conf

# Устанавливаем переменную окружения для AppImage
ENV APPIMAGE_EXTRACT_AND_RUN=1

# Создаем рабочую директорию
WORKDIR /workspace

# Копируем скрипт сборщика
COPY build_appimages.sh /usr/local/bin/build_appimages.sh
RUN chmod +x /usr/local/bin/build_appimages.sh

# Устанавливаем точку входа
ENTRYPOINT ["/usr/local/bin/build_appimages.sh"]

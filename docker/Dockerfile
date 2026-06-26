# ============================================
# Docker-контейнер для тестирования установки
# KiloCode CLI на Linux Mint
# ============================================
# Сборка:
#   docker build -t kilo-test .
# Запуск:
#   docker run --rm -it kilo-test
# Тестирование установки:
#   docker run --rm kilo-test bash -c "
#     cd /opt/kilo && make check && make install && make verify
#   "

FROM linuxmintd/mint22-amd64:latest

# Предотвращение интерактивных запросов
ENV DEBIAN_FRONTEND=noninteractive
ENV INSTALL_DRY_RUN=0

# Установка базовых зависимостей
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    git \
    curl \
    wget \
    ca-certificates \
    build-essential \
    python3 \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Установка uv (замена pip/venv)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/tester/.local/bin:${PATH}"

# Создание пользователя для тестирования
RUN useradd -m -s /bin/bash tester && echo "tester ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Копирование проекта
WORKDIR /opt/kilo
COPY . .

# Настройка прав
RUN chown -R tester:tester /opt/kilo

# Переключение на пользователя
USER tester

# Установка shellcheck и bats для тестов
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Установка bats
RUN git clone https://github.com/bats-core/bats-core.git /tmp/bats \
    && cd /tmp/bats \
    && sudo ./install.sh /usr/local \
    && rm -rf /tmp/bats

# Установка Python-инструментов через uv
RUN /home/tester/.local/bin/uv sync --frozen 2>&1 || true

# Точка входа по умолчанию
CMD ["/bin/bash"]

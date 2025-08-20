#!/bin/bash

# Скрипт для автоматичного встановлення інструментів розробки на Linux
# Встановлює: Docker, Docker Compose, Python 3.9+, Django
# Підтримує: Ubuntu/Debian, CentOS/RHEL/Fedora, Arch Linux

set -e  # Зупинити виконання при помилці

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функції для виводу повідомлень
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Функція для визначення дистрибутива Linux
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        DISTRO="centos"
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    else
        DISTRO="unknown"
    fi
    
    print_info "Виявлено дистрибутив: $DISTRO $VERSION"
}

# Функція для перевірки інтернет з'єднання
check_internet() {
    print_info "Перевірка інтернет з'єднання..."
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        print_error "Немає інтернет з'єднання!"
        exit 1
    fi
    print_success "Інтернет з'єднання доступне"
}

# Функція перевірки версії Python
check_python_version() {
    if command -v python3 &> /dev/null; then
        local version=$(python3 --version 2>&1 | cut -d " " -f 2)
        local major=$(echo $version | cut -d. -f1)
        local minor=$(echo $version | cut -d. -f2)
        
        if [[ $major -eq 3 ]] && [[ $minor -ge 9 ]]; then
            return 0
        fi
    fi
    return 1
}

# Функція встановлення Docker
install_docker() {
    print_info "Перевірка наявності Docker..."
    
    if command -v docker &> /dev/null; then
        print_success "Docker вже встановлено. Версія: $(docker --version)"
        return 0
    fi
    
    # Спеціальна обробка для WSL 2
    if [[ "$WSL_ENV" == true ]]; then
        print_warning "Виявлено WSL 2. Рекомендується використовувати Docker Desktop для Windows."
        print_info "Інструкції для налаштування Docker в WSL 2:"
        echo "1. Встановіть Docker Desktop для Windows"
        echo "2. Увімкніть WSL 2 інтеграцію в налаштуваннях Docker Desktop:"
        echo "   Settings → Resources → WSL Integration → Enable integration with additional distros"
        echo "3. Перезапустіть WSL: wsl --shutdown (в PowerShell)"
        echo ""
        read -p "Продовжити встановлення Docker в WSL? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Пропускаємо встановлення Docker"
            return 0
        fi
    fi
    
    print_info "Встановлення Docker..."
    
    case "$DISTRO" in
        ubuntu|debian)
            # Встановлення залежностей
            sudo apt-get update -y
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            
            # Додавання GPG ключа Docker
            curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # Додавання репозиторію Docker
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Оновлення та встановлення Docker
            sudo apt-get update -y
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
            
        centos|rhel|fedora)
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
            
        arch|manjaro)
            sudo pacman -S docker docker-compose --noconfirm
            ;;
            
        *)
            print_error "Непідтримуваний дистрибутив для автоматичного встановлення Docker"
            return 1
            ;;
    esac
    
    # Запуск Docker сервісу
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Додавання користувача до групи docker
    sudo usermod -aG docker $USER
    
    print_success "Docker успішно встановлено!"
    print_warning "Перезайдіть в систему або виконайте 'newgrp docker' для використання Docker без sudo"
}

# Функція встановлення Docker Compose (якщо не встановлено з Docker)
install_docker_compose() {
    print_info "Перевірка наявності Docker Compose..."
    
    # Перевірка Docker Compose v2 (інтегрований з Docker)
    if docker compose version &> /dev/null 2>&1; then
        print_success "Docker Compose (v2) вже встановлено. Версія: $(docker compose version --short)"
        return 0
    fi
    
    # Перевірка standalone Docker Compose
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose вже встановлено. Версія: $(docker-compose --version)"
        return 0
    fi
    
    # Спеціальна обробка для WSL 2
    if [[ "$WSL_ENV" == true ]]; then
        print_warning "У WSL 2 з Docker Desktop, Docker Compose зазвичай вже включений."
        print_info "Спробуйте використовувати: docker compose (замість docker-compose)"
        print_info "Якщо це не працює, перевірте інтеграцію WSL в Docker Desktop"
        
        # Перевірка чи Docker працює через Docker Desktop
        if docker info &> /dev/null; then
            print_info "Docker працює через Docker Desktop. Створюємо аліас для docker-compose..."
            echo 'alias docker-compose="docker compose"' >> ~/.bashrc
            source ~/.bashrc 2>/dev/null || true
            print_success "Створено аліас docker-compose → docker compose"
            return 0
        fi
    fi
    
    print_info "Встановлення Docker Compose..."
    
    # Отримання останньої версії Docker Compose
    local latest_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    if [[ -z "$latest_version" ]]; then
        print_warning "Не вдалося отримати останню версію Docker Compose. Використовуємо v2.24.0"
        latest_version="v2.24.0"
    fi
    
    # Завантаження та встановлення Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/${latest_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Створення symbolic link
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    print_success "Docker Compose успішно встановлено! Версія: $(docker-compose --version)"
}

# Функція встановлення Python
install_python() {
    print_info "Перевірка наявності Python 3.9+..."
    
    if check_python_version; then
        print_success "Python 3.9+ вже встановлено. Версія: $(python3 --version)"
        return 0
    fi
    
    print_info "Встановлення Python 3.9+..."
    
    case "$DISTRO" in
        ubuntu|debian)
            sudo apt-get update -y
            sudo apt-get install -y software-properties-common
            sudo add-apt-repository ppa:deadsnakes/ppa -y
            sudo apt-get update -y
            sudo apt-get install -y python3.9 python3.9-pip python3.9-dev python3.9-venv python3.9-distutils
            
            # Створення symbolic links якщо потрібно
            if ! check_python_version; then
                sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
            fi
            ;;
            
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                sudo dnf install -y python39 python39-pip python39-devel
            else
                sudo yum install -y python39 python39-pip python39-devel
            fi
            ;;
            
        arch|manjaro)
            sudo pacman -S python python-pip --noconfirm
            ;;
            
        *)
            print_error "Непідтримуваний дистрибутив для автоматичного встановлення Python"
            return 1
            ;;
    esac
    
    if check_python_version; then
        print_success "Python 3.9+ успішно встановлено!"
    else
        print_error "Помилка встановлення Python 3.9+"
        return 1
    fi
}

# Функція встановлення pip (якщо не встановлено)
install_pip() {
    print_info "Перевірка наявності pip..."
    
    if command -v pip3 &> /dev/null || command -v pip &> /dev/null; then
        print_success "pip вже встановлено"
        return 0
    fi
    
    print_info "Встановлення pip..."
    
    # Завантаження та встановлення pip
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python3 get-pip.py --user
    rm get-pip.py
    
    # Додавання pip до PATH
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    
    print_success "pip успішно встановлено!"
}

# Функція встановлення Django
install_django() {
    print_info "Перевірка наявності Django..."
    
    if python3 -c "import django; print('Django версія:', django.get_version())" 2>/dev/null; then
        print_success "Django вже встановлено"
        return 0
    fi
    
    print_info "Встановлення Django..."
    
    # Встановлення Django через pip
    if command -v pip3 &> /dev/null; then
        pip3 install Django --user
    elif command -v pip &> /dev/null; then
        pip install Django --user
    else
        python3 -m pip install Django --user
    fi
    
    # Перевірка встановлення
    if python3 -c "import django; print('Django версія:', django.get_version())" 2>/dev/null; then
        print_success "Django успішно встановлено!"
    else
        print_error "Помилка встановлення Django"
        return 1
    fi
}

# Функція для налаштування WSL інтеграції
setup_wsl_integration() {
    if [[ "$WSL_ENV" == true ]]; then
        print_info "Налаштування WSL інтеграції..."
        
        # Перевірка Docker Desktop інтеграції
        if docker info &> /dev/null 2>&1; then
            print_success "Docker Desktop інтеграція працює!"
            
            # Створення аліасів для зручності
            if ! grep -q "docker-compose" ~/.bashrc; then
                echo '' >> ~/.bashrc
                echo '# Docker Compose аліаси для WSL' >> ~/.bashrc
                echo 'alias docker-compose="docker compose"' >> ~/.bashrc
                print_success "Додано аліас docker-compose"
            fi
            
        else
            print_warning "Docker Desktop інтеграція не налаштована."
            echo ""
            print_info "Для налаштування Docker Desktop в WSL 2:"
            echo "1. Відкрийте Docker Desktop"
            echo "2. Перейдіть в Settings → Resources → WSL Integration"
            echo "3. Увімкніть 'Enable integration with my default WSL distro'"
            echo "4. Увімкніть інтеграцію для вашого дистрибутива"
            echo "5. Натисніть 'Apply & Restart'"
            echo "6. Перезапустіть WSL: wsl --shutdown (в PowerShell)"
            echo ""
        fi
    fi
}

# Функція виводу інформації про встановлені інструменти
show_installed_versions() {
    echo ""
    print_info "=== Інформація про встановлені інструменти ==="
    
    if command -v docker &> /dev/null; then
        echo "Docker: $(docker --version)"
    fi
    
    if command -v docker-compose &> /dev/null; then
        echo "Docker Compose: $(docker-compose --version)"
    elif docker compose version &> /dev/null 2>&1; then
        echo "Docker Compose: $(docker compose version --short)"
    else
        echo "Docker Compose: Не встановлено (використовуйте Docker Desktop в WSL)"
    fi
    
    if command -v python3 &> /dev/null; then
        echo "Python: $(python3 --version)"
    fi
    
    if python3 -c "import django; print('Django версія:', django.get_version())" 2>/dev/null; then
        python3 -c "import django; print('Django:', django.get_version())"
    fi
    
    echo ""
}

# Основна функція
main() {
    echo ""
    print_info "=== Скрипт встановлення інструментів розробки для Linux ==="
    print_info "Встановлення: Docker, Docker Compose, Python 3.9+, Django"
    echo ""
    
    # Перевірка що запущено на Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "Цей скрипт призначений тільки для Linux систем!"
        exit 1
    fi
    
    # Перевірка WSL 2
    if grep -qi microsoft /proc/version; then
        print_info "Виявлено WSL 2 середовище"
        WSL_ENV=true
    else
        WSL_ENV=false
    fi
    
    # Перевірка прав root
    if [[ $EUID -eq 0 ]]; then
        print_warning "Скрипт запущено з правами root. Рекомендується запускати від звичайного користувача."
    fi
    
    # Виявлення дистрибутива
    detect_distro
    
    # Перевірка інтернету
    check_internet
    
    # Встановлення інструментів
    install_docker
    install_docker_compose
    install_python
    install_pip
    install_django
    
    # Налаштування WSL інтеграції
    setup_wsl_integration
    
    # Виведення інформації
    show_installed_versions
    
    print_success "=== Встановлення завершено! ==="
    
    # Додаткові поради
    echo ""
    print_info "=== Додаткові поради ==="
    if [[ "$WSL_ENV" == true ]]; then
        echo "WSL 2 специфічні поради:"
        echo "1. Для Docker: Використовуйте Docker Desktop з WSL інтеграцією"
        echo "2. Для Docker Compose: Використовуйте 'docker compose' замість 'docker-compose'"
        echo "3. Перезавантажте WSL після налаштування: wsl --shutdown"
        echo "4. Файли Windows доступні в /mnt/c/"
        echo ""
    fi
    echo "Загальні поради:"
    echo "1. Перезайдіть в систему або виконайте 'newgrp docker' для використання Docker без sudo"
    echo "2. Для створення Django проекту: django-admin startproject myproject"
    echo "3. Для перевірки Docker: docker run hello-world"
    echo "4. Для активації Python venv: python3 -m venv myenv && source myenv/bin/activate"
    echo ""
}

# Запуск основної функції
main "$@"
#!/bin/bash
set -e

# Deteksi sistem operasi dan set path Nginx yang sesuai
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (Homebrew)
    NGINX_DIR="/usr/local/etc/nginx/servers"
    NGINX_SITES_ENABLED=""
    OS_TYPE="macos"
    echo "🍎 Terdeteksi macOS - menggunakan Homebrew Nginx"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux (Ubuntu/Debian)
    NGINX_DIR="/etc/nginx/sites-available"
    NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
    OS_TYPE="linux"
    echo "🐧 Terdeteksi Linux - menggunakan sites-available/sites-enabled"
else
    echo "❌ Sistem operasi tidak didukung: $OSTYPE"
    exit 1
fi

# Direktori untuk menyimpan sertifikat SSL lokal
SSL_CERTS_DIR="$HOME/.local/ssl-certs"

# Pastikan direktori Nginx ada
echo "🔍 Memeriksa direktori Nginx..."
if [[ ! -d "$NGINX_DIR" ]]; then
    echo "📁 Membuat direktori Nginx: $NGINX_DIR"
    sudo mkdir -p "$NGINX_DIR"
fi

# Untuk Linux, pastikan sites-enabled juga ada
if [[ "$OS_TYPE" == "linux" && ! -d "$NGINX_SITES_ENABLED" ]]; then
    echo "📁 Membuat direktori sites-enabled: $NGINX_SITES_ENABLED"
    sudo mkdir -p "$NGINX_SITES_ENABLED"
fi

# Fungsi untuk mendeteksi versi PHP yang tersedia
detect_php_versions() {
    echo "🔍 Mendeteksi versi PHP yang tersedia..."
    
    # Array untuk menyimpan versi PHP yang ditemukan
    PHP_VERSIONS=()
    PHP_FPM_PATHS=()
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        # macOS (Homebrew) - cek di /usr/local/bin dan /opt/homebrew/bin
        for php_path in /usr/local/bin/php* /opt/homebrew/bin/php*; do
            if [[ -x "$php_path" && "$php_path" =~ php[0-9]+\.[0-9]+ ]]; then
                # Ekstrak versi dari nama file (contoh: php8.1 -> 8.1)
                version=$(basename "$php_path" | sed 's/php//')
                if [[ "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
                    # Cek apakah PHP-FPM tersedia untuk versi ini
                    fpm_socket="/usr/local/var/run/php-fpm-${version}.sock"
                    fpm_port="127.0.0.1:90$(echo $version | tr -d '.')"  # 8.1 -> 9081, 8.2 -> 9082
                    
                    # Cek socket atau port yang tersedia
                    if [[ -S "$fpm_socket" ]] || pgrep -f "php-fpm.*${version}" > /dev/null; then
                        PHP_VERSIONS+=("$version")
                        # Prioritaskan socket jika ada, fallback ke port
                        if [[ -S "$fpm_socket" ]]; then
                            PHP_FPM_PATHS+=("unix:$fpm_socket")
                        else
                            # Fallback ke port
                            fpm_port="127.0.0.1:90$(echo $version | tr -d '.')"
                            PHP_FPM_PATHS+=("$fpm_port")
                        fi
                    fi
                fi
            fi
        done
        
        # Cek juga PHP default
        if command -v php &> /dev/null; then
            default_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
            # Cek apakah versi default belum ada di list
            if [[ ! " ${PHP_VERSIONS[@]} " =~ " ${default_version} " ]]; then
                # Untuk PHP default, gunakan port 9000
                PHP_VERSIONS+=("$default_version (default)")
                PHP_FPM_PATHS+=("127.0.0.1:9000")
            fi
        fi
        
    elif [[ "$OS_TYPE" == "linux" ]]; then
        # Linux - cek di /usr/bin dan service php-fpm
        for php_path in /usr/bin/php*; do
            if [[ -x "$php_path" && "$php_path" =~ php[0-9]+\.[0-9]+ ]]; then
                # Ekstrak versi dari nama file
                version=$(basename "$php_path" | sed 's/php//')
                if [[ "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
                    # Cek apakah service PHP-FPM berjalan untuk versi ini
                    service_name="php${version}-fpm"
                    if systemctl is-active --quiet "$service_name" 2>/dev/null || service "$service_name" status &>/dev/null; then
                        PHP_VERSIONS+=("$version")
                        # Linux biasanya menggunakan socket
                        fpm_socket="/run/php/php${version}-fpm.sock"
                        if [[ -S "$fpm_socket" ]]; then
                            PHP_FPM_PATHS+=("unix:$fmp_socket")
                        else
                            # Fallback ke port
                            fmp_port="127.0.0.1:90$(echo $version | tr -d '.')"
                            PHP_FPM_PATHS+=("$fpm_port")
                        fi
                    fi
                fi
            fi
        done
        
        # Cek juga PHP default
        if command -v php &> /dev/null; then
            default_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
            if [[ ! " ${PHP_VERSIONS[@]} " =~ " ${default_version} " ]]; then
                PHP_VERSIONS+=("$default_version (default)")
                PHP_FPM_PATHS+=("127.0.0.1:9000")
            fi
        fi
    fi
    
    # Jika tidak ada PHP yang ditemukan
    if [[ ${#PHP_VERSIONS[@]} -eq 0 ]]; then
        echo "⚠️  Tidak ada PHP yang terdeteksi di sistem!"
        echo "💡 Silakan install PHP terlebih dahulu:"
        if [[ "$OS_TYPE" == "macos" ]]; then
            echo "   brew install php"
        else
            echo "   sudo apt install php-fpm"
        fi
        exit 1
    fi
    
    echo "✅ Ditemukan ${#PHP_VERSIONS[@]} versi PHP"
}

# Fungsi untuk memilih versi PHP
select_php_version() {
    if [[ ${#PHP_VERSIONS[@]} -eq 1 ]]; then
        # Jika hanya ada satu versi, gunakan otomatis
        SELECTED_PHP_VERSION="${PHP_VERSIONS[0]}"
        SELECTED_PHP_FPM="${PHP_FPM_PATHS[0]}"
        echo "🐘 Menggunakan PHP ${SELECTED_PHP_VERSION} (otomatis)"
    else
        # Jika ada beberapa versi, biarkan user memilih
        echo ""
        echo "🐘 Pilih versi PHP yang ingin digunakan:"
        for i in "${!PHP_VERSIONS[@]}"; do
            echo "$((i+1))) PHP ${PHP_VERSIONS[$i]}"
        done
        
        while true; do
            read -p "Masukkan pilihan (1-${#PHP_VERSIONS[@]}): " php_choice
            if [[ "$php_choice" =~ ^[0-9]+$ ]] && [[ "$php_choice" -ge 1 ]] && [[ "$php_choice" -le ${#PHP_VERSIONS[@]} ]]; then
                index=$((php_choice-1))
                SELECTED_PHP_VERSION="${PHP_VERSIONS[$index]}"
                SELECTED_PHP_FPM="${PHP_FPM_PATHS[$index]}"
                echo "✅ Dipilih: PHP ${SELECTED_PHP_VERSION}"
                break
            else
                echo "❌ Pilihan tidak valid! Masukkan angka 1-${#PHP_VERSIONS[@]}"
            fi
        done
    fi
}

echo "=== ⚙️  Setup / Hapus Proyek Web ==="
echo "1) Buat konfigurasi baru"
echo "2) Hapus konfigurasi yang sudah ada"
read -p "Masukkan pilihan (1/2): " main_choice

# === MODE HAPUS ===
if [[ "$main_choice" == "2" ]]; then
    read -p "Masukkan domain yang ingin dihapus: " domain
    CONF_FILE="$NGINX_DIR/$domain.conf"

    if [[ ! -f "$CONF_FILE" ]]; then
        echo "❌ Konfigurasi untuk $domain tidak ditemukan!"
        exit 1
    fi

    echo "🕵️  Mendeteksi sertifikat SSL yang digunakan..."
    CERT_FILE=$(grep "ssl_certificate " "$CONF_FILE" | awk '{print $2}' | tr -d ';')
    KEY_FILE=$(grep "ssl_certificate_key " "$CONF_FILE" | awk '{print $2}' | tr -d ';')

    echo "🧹 Menghapus konfigurasi Nginx untuk $domain..."
    sudo rm -f "$CONF_FILE"
    
    # Hapus symlink jika menggunakan Linux
    if [[ "$OS_TYPE" == "linux" ]]; then
        SYMLINK_FILE="$NGINX_SITES_ENABLED/$domain.conf"
        if [[ -L "$SYMLINK_FILE" ]]; then
            echo "🔗 Menghapus symlink dari sites-enabled..."
            sudo rm -f "$SYMLINK_FILE"
        fi
    fi

    if [[ -n "$CERT_FILE" && -n "$KEY_FILE" ]]; then
        if [[ "$CERT_FILE" == *"/usr/local/etc/nginx/certs/"* ]]; then
            echo "🧽 Menghapus sertifikat Let's Encrypt..."
            sudo certbot delete --cert-name "$domain" || true
        else
            echo "🧽 Menghapus sertifikat lokal (mkcert)..."
            rm -f "$CERT_FILE" "$KEY_FILE"
        fi
    fi

    echo "🧾 Menghapus entri dari /etc/hosts..."
    if [[ "$OS_TYPE" == "macos" ]]; then
        sudo sed -i '' "/$domain/d" /etc/hosts
    else
        sudo sed -i "/$domain/d" /etc/hosts
    fi

    echo "🔁 Reloading Nginx..."
    sudo nginx -t && sudo nginx -s reload

    echo "✅ Semua bersih untuk domain $domain!"
    exit 0
fi


# === MODE SETUP BARU ===
echo "=== 🚀 Setup Proyek Web Baru ==="
echo "Pilih jenis proyek:"
echo "1) Laravel"
echo "2) WordPress"
echo "3) Node.js"
read -p "Masukkan pilihan (1/2/3): " project_type

case $project_type in
  1)
    TYPE="laravel"
    read -p "Masukkan path folder proyek Laravel (misal: /Users/afif/Projects/myapp): " project_path
    ROOT_PATH="$project_path/public"
    ;;
  2)
    TYPE="wordpress"
    read -p "Masukkan path folder proyek WordPress (misal: /Users/afif/Projects/wpstore): " project_path
    ROOT_PATH="$project_path"
    ;;
  3)
    TYPE="nodejs"
    read -p "Masukkan port proyek Node.js (misal: 3000): " node_port
    ;;
  *)
    echo "Pilihan tidak valid!"
    exit 1
    ;;
esac

# Deteksi dan pilih versi PHP untuk proyek Laravel dan WordPress
if [[ "$TYPE" == "laravel" || "$TYPE" == "wordpress" ]]; then
    detect_php_versions
    select_php_version
fi

read -p "Masukkan domain yang ingin digunakan (contoh: wpstore.local): " domain
read -p "Apakah ini proyek lokal? (y/n): " is_local

if [[ "$is_local" == "y" ]]; then
  IP="127.0.0.1"
  echo "$IP $domain" | sudo tee -a /etc/hosts > /dev/null
else
  read -p "Masukkan IP server publik Anda: " IP
fi

read -p "Apakah Anda ingin menambahkan SSL? (y/n): " use_ssl

CONF_FILE="$NGINX_DIR/$domain.conf"

echo "🧩 Membuat konfigurasi Nginx di $CONF_FILE ..."

if [[ "$TYPE" == "nodejs" ]]; then
cat <<EOF | sudo tee "$CONF_FILE" > /dev/null
server {
    listen 80;
    server_name $domain;

    location / {
        proxy_pass http://127.0.0.1:$node_port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
else
cat <<EOF | sudo tee "$CONF_FILE" > /dev/null
server {
    listen 80;
    server_name $domain;
    root $ROOT_PATH;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass $SELECTED_PHP_FPM;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi.conf;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
fi

# === SSL Handling ===
if [[ "$use_ssl" == "y" ]]; then
    if [[ "$is_local" == "y" ]]; then
        echo "🔒 Membuat sertifikat lokal menggunakan mkcert..."
        
        # Membuat direktori SSL jika belum ada
        DOMAIN_SSL_DIR="$SSL_CERTS_DIR/$domain"
        mkdir -p "$DOMAIN_SSL_DIR"
        
        # Path sertifikat di direktori khusus SSL
        CERT_FILE="$DOMAIN_SSL_DIR/$domain.pem"
        KEY_FILE="$DOMAIN_SSL_DIR/$domain-key.pem"

        # Membuat sertifikat dengan mkcert (tanpa sudo agar CA dikenali browser)
        mkcert -cert-file "$CERT_FILE" -key-file "$KEY_FILE" "$domain"

        # Update konfigurasi Nginx untuk menggunakan SSL
        if [[ "$OS_TYPE" == "macos" ]]; then
            # macOS menggunakan sed dengan -i ''
            sudo sed -i '' "s|listen 80;|listen 443 ssl;\n    ssl_certificate $CERT_FILE;\n    ssl_certificate_key $KEY_FILE;|" "$CONF_FILE"
        else
            # Linux menggunakan sed dengan -i tanpa ''
            sudo sed -i "s|listen 80;|listen 443 ssl;\n    ssl_certificate $CERT_FILE;\n    ssl_certificate_key $KEY_FILE;|" "$CONF_FILE"
        fi
        echo "✅ Sertifikat lokal disimpan di $DOMAIN_SSL_DIR"
    else
        echo "🌍 Menggunakan Let's Encrypt (certbot)..."
        sudo certbot --nginx -d "$domain"
    fi
fi

# Buat symlink untuk Linux (sites-available -> sites-enabled)
if [[ "$OS_TYPE" == "linux" ]]; then
    SYMLINK_FILE="$NGINX_SITES_ENABLED/$domain.conf"
    if [[ ! -L "$SYMLINK_FILE" ]]; then
        echo "🔗 Membuat symlink ke sites-enabled..."
        sudo ln -s "$CONF_FILE" "$SYMLINK_FILE"
        echo "✅ Symlink dibuat: $SYMLINK_FILE"
    fi
fi

echo "🔁 Reloading Nginx..."
sudo nginx -t && sudo nginx -s reload

echo "✅ Selesai!"
echo "Akses situs kamu di: http${use_ssl:+s}://$domain"

# Tampilkan informasi PHP yang digunakan untuk proyek Laravel/WordPress
if [[ "$TYPE" == "laravel" || "$TYPE" == "wordpress" ]]; then
    echo "🐘 PHP yang digunakan: $SELECTED_PHP_VERSION"
    echo "📡 PHP-FPM endpoint: $SELECTED_PHP_FPM"
fi


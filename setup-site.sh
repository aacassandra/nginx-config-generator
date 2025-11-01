#!/bin/bash
set -e

# Direktori konfigurasi Nginx
NGINX_DIR="/usr/local/etc/nginx/servers"
# Direktori untuk menyimpan sertifikat SSL lokal
SSL_CERTS_DIR="$HOME/.local/ssl-certs"

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
    sudo sed -i '' "/$domain/d" /etc/hosts

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
        fastcgi_pass 127.0.0.1:9000;
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
        sudo sed -i '' "s|listen 80;|listen 443 ssl;\n    ssl_certificate $CERT_FILE;\n    ssl_certificate_key $KEY_FILE;|" "$CONF_FILE"
        echo "✅ Sertifikat lokal disimpan di $DOMAIN_SSL_DIR"
    else
        echo "🌍 Menggunakan Let's Encrypt (certbot)..."
        sudo certbot --nginx -d "$domain"
    fi
fi

echo "🔁 Reloading Nginx..."
sudo nginx -t && sudo nginx -s reload

echo "✅ Selesai!"
echo "Akses situs kamu di: http${use_ssl:+s}://$domain"


# 🧩 setup-site — Nginx Config Generator for Laravel, WordPress, Node.js

A simple bash script to easily **setup and remove Nginx configurations** automatically for **Laravel**, **WordPress**, and **Node.js** projects, including **local SSL** support using [`mkcert`](https://github.com/FiloSottile/mkcert).

**🌍 Multi-OS Support**: Works seamlessly on both **macOS** (Homebrew) and **Linux** (Ubuntu/Debian) with automatic OS detection and appropriate configuration paths.

---

## ⚙️ Key Features

- 🔧 Auto-generate Nginx configurations for:
  - Laravel
  - WordPress
  - Symfony
  - HTML/SPA (React, Vue, Angular)
  - Node.js
- 🌍 **Cross-platform compatibility** (macOS & Linux)
- 🔒 Local SSL support via `mkcert`
- 🧹 Easy uninstall configurations including SSL certificates
- ⚡ Run from anywhere with a single `setup-site` command
- 📁 Organized SSL certificate storage in `~/.local/ssl-certs/`
- 🔗 **Smart symlink management** for Linux (sites-available ↔ sites-enabled)

---

## 🧱 Requirements

### macOS
- **Homebrew**
- **Nginx** (`brew install nginx`)
- **mkcert** (`brew install mkcert`)
- **nss** (for Firefox trust store, `brew install nss`)

### Linux (Ubuntu/Debian)
- **Nginx**
  ```bash
  sudo apt install nginx -y
  ```

- **mkcert**
  ```bash
  sudo apt install libnss3-tools -y
  wget https://github.com/FiloSottile/mkcert/releases/latest/download/mkcert-v1.4.4-linux-amd64
  sudo mv mkcert-v1.4.4-linux-amd64 /usr/local/bin/mkcert
  sudo chmod +x /usr/local/bin/mkcert
  mkcert -install
  ```

---

## 📂 Nginx Configuration Paths

The script automatically detects your operating system and uses the appropriate Nginx configuration paths:

| OS | Folder Config | Include Default | Notes |
|---|---|---|---|
| **macOS (Homebrew)** | `/usr/local/etc/nginx/servers/` | `include servers/*;` | Direct configuration files |
| **Linux (Ubuntu/Debian)** | `/etc/nginx/sites-available/` & `/etc/nginx/sites-enabled/` | `include /etc/nginx/sites-enabled/*;` | Uses symlinks from sites-available to sites-enabled |

### 🔗 Linux Symlink Management
- Configuration files are created in `/etc/nginx/sites-available/`
- Symlinks are automatically created in `/etc/nginx/sites-enabled/`
- When removing configurations, both the original file and symlink are deleted

---

## 📦 Script Installation

1. **Save the `setup-site.sh` file to your home directory:**

   ```bash
   # Move script to home directory
   mv setup-site.sh ~/setup-site.sh
   ```

2. **Grant execution permissions:**

   ```bash
   # Give permission to execute the script
   chmod +x ~/setup-site.sh
   ```

3. **Add to global PATH for access from anywhere:**

   ```bash
   # Create symbolic link to /usr/local/bin for global access
   sudo ln -sf ~/setup-site.sh /usr/local/bin/setup-site
   ```

4. **Verify installation:**

   ```bash
   # Test if script can be run from anywhere
   setup-site
   ```

   If you see the menu:
   ```diff
   === ⚙️  Setup / Remove Web Project ===
   1) Create new configuration
   2) Remove existing configuration
   ```

   Installation successful! 🎉

---

## 🚀 Usage Guide

### 📋 Creating New Configuration

```bash
# Run the setup-site script
setup-site
```

Select option `1) Create new configuration`, then enter:

• **Project type** (Laravel / WordPress / Symfony / HTML / Node.js)
• **Project folder path** (absolute path)
  - For HTML projects: Additional question about SPA (React/Vue/Angular) or static HTML
• **Local domain** (example: `project.local`)
• **Is this a local project** (`y/n`)
• **Add SSL support** (`y/n`)

The script will:

• Create Nginx configuration file in `/usr/local/etc/nginx/servers/`
• Create SSL certificates in `~/.local/ssl-certs/$domain/` (for local projects)
• Automatically reload Nginx

### 🗑️ Removing Existing Configuration

```bash
# Run the setup-site script
setup-site
```

Select option `2) Remove existing configuration`, then enter:

• **Domain of the project to remove** (example: `project.local`)

The script will:

• Remove Nginx configuration file for that domain
• Remove SSL certificates (if any) by reading paths from Nginx config
• Remove domain entry from `/etc/hosts`
• Reload Nginx

---

## 📁 Default Directory Structure

| File Type | Location |
|-----------|----------|
| Nginx Configuration | `/usr/local/etc/nginx/servers/` |
| SSL Certificates (Local) | `~/.local/ssl-certs/$domain/` |
| SSL Certificates (Production) | `/etc/letsencrypt/live/$domain/` |

### 🔒 SSL Certificate Organization

For local development, SSL certificates are organized as follows:

```
~/.local/ssl-certs/
├── myapp.local/
│   ├── myapp.local.pem
│   └── myapp.local-key.pem
├── wpstore.local/
│   ├── wpstore.local.pem
│   └── wpstore.local-key.pem
└── api.local/
    ├── api.local.pem
    └── api.local-key.pem
```

> If the `servers` directory doesn't exist, the script will automatically create it.

---

## 🐘 Dynamic PHP Version Detection

For **Laravel**, **WordPress**, and **Symfony** projects, the script automatically detects available PHP versions and lets you choose:

### 🔍 **Auto-Detection Process**

1. **Scans for PHP versions** in system paths:
   - **macOS**: `/usr/local/bin/php*` and `/opt/homebrew/bin/php*`
   - **Linux**: `/usr/bin/php*`

2. **Checks PHP-FMP availability** for each version:
   - **macOS**: Looks for sockets in `/usr/local/var/run/` or running processes
   - **Linux**: Checks systemd services (`php8.1-fpm`, `php8.2-fpm`, etc.)

3. **Presents available options** to user:
   ```
   🐘 Choose PHP version to use:
   1) PHP 8.1
   2) PHP 8.2 (default)
   3) PHP 8.3
   ```

### 📡 **Smart PHP-FPM Configuration**

The script automatically configures the appropriate PHP-FPM endpoint:

| OS | PHP Version | Preferred Method | Fallback |
|----|-------------|------------------|----------|
| **macOS** | 8.1 | `unix:/usr/local/var/run/php-fpm-8.1.sock` | `127.0.0.1:9081` |
| **macOS** | 8.2 | `unix:/usr/local/var/run/php-fpm-8.2.sock` | `127.0.0.1:9082` |
| **Linux** | 8.1 | `unix:/run/php/php8.1-fpm.sock` | `127.0.0.1:9081` |
| **Linux** | 8.2 | `unix:/run/php/php8.2-fpm.sock` | `127.0.0.1:9082` |

### 💡 **Benefits**

- ✅ **No more hardcoded PHP-FPM ports**
- ✅ **Automatic version detection**
- ✅ **Cross-platform compatibility**
- ✅ **Socket prioritization for better performance**
- ✅ **Fallback to ports if sockets unavailable**
- ✅ **SPA support with proper routing** (for React, Vue, Angular)
- ✅ **Static HTML optimization** with caching and gzip

---

## 🎨 HTML & SPA Project Support

The script now supports static HTML and Single Page Application (SPA) projects with optimized Nginx configurations.

### 📋 **Project Types Supported**

1. **Static HTML**: Traditional multi-page websites
2. **SPA (Single Page Applications)**: React, Vue, Angular applications

### 🔧 **Configuration Features**

#### For Static HTML:
- Standard file serving with `try_files $uri $uri/ =404`
- Returns 404 for non-existent files
- Optimized for traditional multi-page websites

#### For SPA Applications:
- Automatic fallback to `index.html` for all routes
- Enables client-side routing (React Router, Vue Router, Angular Router)
- Configuration: `try_files $uri $uri/ /index.html`

### ⚡ **Performance Optimizations**

Both HTML and SPA configurations include:

- **Gzip Compression**: Reduces file sizes for faster loading
  ```nginx
  gzip on;
  gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;
  ```

- **Static Asset Caching**: 1-year cache for images, fonts, and styles
  ```nginx
  location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
      expires 1y;
      add_header Cache-Control "public, immutable";
  }
  ```

- **Security Headers**: Protection against common vulnerabilities
  ```nginx
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-XSS-Protection "1; mode=block" always;
  ```

### 📝 **Usage Example**

```bash
setup-site

# Choose: 4) HTML
# Enter project path: /Users/john/Projects/my-react-app
# Enter domain: myapp.local
# Is this a SPA (React/Vue/Angular)? y  ← Important for client-side routing
# Local project? y
# Add SSL? y
```

---

## 🎼 Symfony Framework Support

Full support for Symfony projects with proper directory structure and PHP-FPM integration.

### 📂 **Directory Structure**

Symfony projects use the `web/` directory as document root:
```
/path/to/symfony-project/
├── app/
├── src/
├── web/              ← Document Root
│   ├── index.php
│   └── app.php
├── vendor/
└── composer.json
```

### 🔧 **Automatic Configuration**

The script automatically:
1. Sets document root to `{project_path}/web`
2. Configures PHP-FPM with selected PHP version
3. Sets up proper routing for Symfony controllers
4. Enables `.htaccess` protection

### 🐘 **PHP Version Selection**

Like Laravel and WordPress, Symfony projects benefit from:
- Automatic PHP version detection
- Interactive PHP version selection
- Smart PHP-FPM socket/port configuration
- Multi-version PHP support (7.4, 8.0, 8.1, 8.2, 8.3+)

### 📝 **Usage Example**

```bash
setup-site

# Choose: 3) Symfony
# Enter project path: /Users/john/Projects/symfony-blog
# Choose PHP version: 2) PHP 8.2
# Enter domain: symfony.local
# Local project? y
# Add SSL? y
```

### ⚙️ **Generated Nginx Configuration**

```nginx
server {
    listen 443 ssl;
    server_name symfony.local;
    root /Users/john/Projects/symfony-blog/web;
    index index.php index.html;

    ssl_certificate ~/.local/ssl-certs/symfony.local/symfony.local.pem;
    ssl_certificate_key ~/.local/ssl-certs/symfony.local/symfony.local-key.pem;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/usr/local/var/run/php-fpm-8.2.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        include fastcgi.conf;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

---

## ⚠️ Important Notes

• Run the script with a user that has access to Nginx directories.
• If `nginx -t` fails, ensure SSL paths and project folders are correct.
• **For Symfony projects**: The script uses `web/` as document root (Symfony 2/3). If using Symfony 4+, manually edit the config to use `public/` instead.
• **For SPA projects**: Make sure to answer 'y' when asked "Is this a SPA?" to enable proper client-side routing.
• **For static HTML**: Answer 'n' to SPA question if you have traditional multi-page website.
• For Firefox, run:

  ```bash
  # Install mkcert for Firefox to trust local certificates
  mkcert -install
  ```

  to trust local certificates.

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| Permission denied when creating SSL | Ensure you have write access to `~/.local/ssl-certs/` |
| Nginx fails to reload | Check `nginx -t` to ensure no configuration errors |
| Domain not recognized | Add domain to `/etc/hosts`, example: `127.0.0.1 myapp.local` |
| Firefox doesn't recognize local SSL | Run `mkcert -install` again |
| SSL certificates not found during removal | Script reads paths from Nginx config, ensure config file exists |
| No PHP versions detected | Install PHP: `brew install php` (macOS) or `sudo apt install php-fpm` (Linux) |
| PHP-FPM not running | Start service: `brew services start php` (macOS) or `sudo systemctl start php8.2-fpm` (Linux) |
| Socket connection failed | Check if PHP-FPM socket exists or use port fallback |
| SPA routing not working | Ensure you answered 'y' when asked "Is this a SPA?" during setup |
| Static assets not cached | Check nginx config has proper `location ~*` block for static files |
| Symfony 404 errors | Verify project uses `web/` directory (older Symfony) or `public/` directory (Symfony 4+) |

---

## 💡 Local Domain Examples

| Domain | Project Type | Project Path |
|--------|--------------|-------------|
| `laravel.test` | Laravel | `/Users/john/Projects/laravel-app` |
| `wpstore.local` | WordPress | `/Users/john/Projects/wordpress` |
| `symfony.local` | Symfony | `/Users/john/Projects/symfony-app` |
| `myapp.local` | HTML/SPA | `/Users/john/Projects/react-app` |
| `nodeapi.local` | Node.js | Port 3000 |

---

## 🆕 Recent Updates

- ✅ **Multi-OS Support**: Automatic detection and support for macOS and Linux
- ✅ **Smart Path Detection**: Uses appropriate Nginx paths for each OS
- ✅ **Linux Symlink Management**: Automatic symlink creation/deletion for sites-available/sites-enabled
- ✅ **Cross-Platform Commands**: Compatible sed commands for both macOS and Linux
- ✅ **Directory Auto-Creation**: Creates necessary Nginx directories if they don't exist
- ✅ **Organized SSL Storage**: SSL certificates now stored in `~/.local/ssl-certs/$domain/`
- ✅ **Fixed Node.js SSL Bug**: Node.js projects can now use SSL without project path dependency
- ✅ **Smart Certificate Removal**: Reads actual certificate paths from Nginx config for safe removal
- ✅ **Auto Directory Creation**: Automatically creates SSL certificate directories
- ✅ **Clean Directory Management**: Removes empty directories after certificate deletion
- ✅ **Dynamic PHP Detection**: Automatically detects available PHP versions and lets you choose
- ✅ **Smart PHP-FPM Configuration**: Uses appropriate socket/port based on PHP version and OS
- ✅ **Multi-Version PHP Support**: Supports multiple PHP versions (7.4, 8.0, 8.1, 8.2, 8.3+)
- ✅ **Symfony Support**: Full support for Symfony framework with proper web directory configuration
- ✅ **HTML/SPA Support**: Optimized configurations for static HTML and Single Page Applications
- ✅ **SPA Routing**: Automatic fallback to index.html for React, Vue, and Angular applications
- ✅ **Static Asset Optimization**: Cache headers and gzip compression for HTML projects

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### MIT License Summary
- ✅ Commercial use allowed
- ✅ Modification allowed
- ✅ Distribution allowed
- ✅ Private use allowed
- ❌ No warranty provided
- ❌ No liability assumed

---

## 👨‍💻 Contributors

Made with ❤️ by **Afif Saja**

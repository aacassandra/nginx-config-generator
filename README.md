# 🧩 setup-site — Nginx Config Generator for Laravel, WordPress, Node.js

A simple bash script to easily **setup and remove Nginx configurations** automatically for **Laravel**, **WordPress**, and **Node.js** projects, including **local SSL** support using [`mkcert`](https://github.com/FiloSottile/mkcert).

**🌍 Multi-OS Support**: Works seamlessly on both **macOS** (Homebrew) and **Linux** (Ubuntu/Debian) with automatic OS detection and appropriate configuration paths.

---

## ⚙️ Key Features

- 🔧 Auto-generate Nginx configurations for:
  - Laravel
  - WordPress
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

• **Project type** (Laravel / WordPress / Node.js)
• **Project folder path** (absolute path)
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

For **Laravel** and **WordPress** projects, the script automatically detects available PHP versions and lets you choose:

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

---

## ⚠️ Important Notes

• Run the script with a user that has access to Nginx directories.
• If `nginx -t` fails, ensure SSL paths and project folders are correct.
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

---

## 💡 Local Domain Examples

| Domain | Project Type | Project Path |
|--------|--------------|-------------|
| `laravel.test` | Laravel | `/Users/john/Projects/laravel-app` |
| `wpstore.local` | WordPress | `/Users/john/Projects/wordpress` |
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

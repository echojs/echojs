# EchoJS VPS Provisioning Guide

This guide covers provisioning a fresh Debian 13 VPS to run EchoJS with Nginx, Puma, Sinatra, and Redis. It also covers migrating your existing Redis database and SSL certificates from the old server.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Base System Setup](#1-base-system-setup)
3. [Application Deployment](#2-application-deployment)
4. [Email Setup (Mailgun)](#3-email-setup-mailgun)
5. [Puma Configuration](#4-puma-configuration)
6. [SSL Certificates](#5-ssl-certificates)
7. [Nginx Reverse Proxy](#6-nginx-reverse-proxy)
8. [Redis Data Migration](#7-redis-data-migration)
9. [Maintenance](#8-maintenance)
10. [Validation](#validation)
11. [Troubleshooting](#troubleshooting)
12. [DNS Configuration](#dns-configuration)
13. [Notes and Risks](#notes-and-risks)

---

## Prerequisites

Before you begin, gather the following:

- A new **Debian 13** VPS with root SSH access
- A **Mailgun** account (free tier) — verified sending domain with API key
- From your old server:
  - `dump.rdb` (Redis database export)
  - Existing SSL files:
    - `/etc/nginx/ssl/fullchain.cer`
    - `/etc/nginx/ssl/echojs.com.key`
  - `/etc/ssl/dhparam.pem` (or generate a new one during setup)

---

## 1. Base System Setup

Update the system and install required packages:

```bash
apt-get update && apt-get upgrade -y
apt-get install -y build-essential nginx redis-server ruby ruby-dev git curl \
  ufw unattended-upgrades certbot python3-certbot-nginx
```

Create the application user:

```bash
adduser --disabled-password --gecos "" echojs
```

Configure the firewall:

```bash
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw enable
```

---

## 2. Application Deployment

Switch to the application user and clone the repository:

```bash
su - echojs
git clone https://github.com/echojs/echojs.git
cd echojs
```

Install Ruby dependencies. If `gem` installs to your user directory and complains about PATH, add the gem bin directory to your PATH:

```bash
gem install bundler puma
export PATH="$PATH:/home/echojs/.local/share/gem/ruby/3.3.0/bin"
```

Then configure Bundler to install gems inside the project directory and install:

```bash
bundle config set --local path 'vendor/bundle'
bundle install
```

Create required directories:

```bash
mkdir -p log tmp/pids tmp/sockets
touch tmp/pids/puma.pid
exit
```

---

## 3. Email Setup (Mailgun)

EchoJS uses password recovery emails. To set up Mailgun:

1. Create a free Mailgun account at [mailgun.com](https://www.mailgun.com/).
2. Add and verify your sending domain in the Mailgun dashboard.
3. Copy your **API key** (not the SMTP credentials) and your **sending domain**.

You will need these values in the next step when creating the Puma systemd service file.

### API Integration

EchoJS uses the Mailgun HTTP API (`/v3/YOUR_DOMAIN/messages`) with basic auth (`api:YOUR_API_KEY`). This is built into `mail.rb` and requires no additional patching — just set `MAILGUN_API_KEY` and `MAILGUN_DOMAIN` in the Puma systemd service.

### SMTP Fallback

If the Mailgun API is unavailable, you can use an SMTP relay by setting `MAIL_RELAY` in the Puma systemd service. Note that the built-in SMTP fallback does not support authenticated SMTP — use an unauthenticated local relay or configure your SMTP server to allow relay from the VPS IP.

---

## 4. Puma Configuration

Before creating the systemd service file below, **replace the Mailgun placeholders** with your actual Mailgun API key and domain:

- `YOUR_MAILGUN_API_KEY` → your Mailgun API key
- `YOUR_MAILGUN_DOMAIN` → your Mailgun sending domain

If you don't replace them, the file will contain invalid placeholders and emails won't work.

Create a systemd service file at `/etc/systemd/system/puma.service` (as root):

```bash
cat > /etc/systemd/system/puma.service << 'EOF'
[Unit]
Description=Puma web server for EchoJS
After=network.target redis.service
Requires=redis.service

[Service]
Type=simple
User=echojs
WorkingDirectory=/home/echojs/echojs
Environment=SITE_URL=https://www.echojs.com
Environment=REDIS_URL=redis://127.0.0.1:6379
Environment=MAILGUN_API_KEY=YOUR_MAILGUN_API_KEY
Environment=MAILGUN_DOMAIN=YOUR_MAILGUN_DOMAIN
Environment=MAIL_FROM=robot@echojs.com
ExecStart=/home/echojs/.local/share/gem/ruby/3.3.0/bin/puma -C config/puma.rb -e production
PIDFile=/home/echojs/echojs/tmp/pids/puma.pid
ExecStop=/bin/kill -QUIT $MAINPID
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start Puma:

```bash
systemctl daemon-reload
systemctl enable puma
systemctl start puma
systemctl status puma
```

The `config/puma.rb` file is already included in the repository, so no manual creation is needed. If you need to customize worker or thread counts, edit the file directly as the `echojs` user:

```bash
su - echojs
cd ~/echojs
nano config/puma.rb
exit
```

Then restart Puma to apply changes:

```bash
systemctl daemon-reload
systemctl restart puma
```

---

## 5. SSL Certificates

### On the old server

Before migrating, stop Redis and create a tarball of the files you need:

```bash
systemctl stop redis-server
tar czf /tmp/echojs-migration.tar.gz \
  /etc/nginx/ssl/fullchain.cer \
  /etc/nginx/ssl/echojs.com.key \
  /etc/ssl/dhparam.pem \
  /var/lib/redis/dump.rdb
```

### On your local Mac

Download the archive from the old server (replace `OLD_SERVER_IP`):

```bash
scp -i ~/.ssh/YOUR_SSH_KEY_NAME root@OLD_SERVER_IP:/tmp/echojs-migration.tar.gz ~/Downloads/
tar xzf ~/Downloads/echojs-migration.tar.gz -C ~/Downloads/
```

### On the new server

Upload files to `/tmp/` first, then move them into place with SSH:

```bash
scp -i ~/.ssh/YOUR_SSH_KEY_NAME ~/Downloads/fullchain.cer root@VPS_IP_ADDRESS:/tmp/
scp -i ~/.ssh/YOUR_SSH_KEY_NAME ~/Downloads/echojs.com.key root@VPS_IP_ADDRESS:/tmp/
scp -i ~/.ssh/YOUR_SSH_KEY_NAME ~/Downloads/dhparam.pem root@VPS_IP_ADDRESS:/tmp/
```

Move the files and set permissions:

```bash
ssh -i ~/.ssh/YOUR_SSH_KEY_NAME root@VPS_IP_ADDRESS "mkdir -p /etc/nginx/ssl && mv /tmp/fullchain.cer /etc/nginx/ssl/ && mv /tmp/echojs.com.key /etc/nginx/ssl/ && mv /tmp/dhparam.pem /etc/ssl/ && chmod 600 /etc/nginx/ssl/echojs.com.key"
```

If you do not have the old `dhparam.pem`, generate a new one on the new server instead:

```bash
openssl dhparam -out /etc/ssl/dhparam.pem 4096
```

---

## 6. Nginx Reverse Proxy

Switch back to root (if still in the echojs user shell):

```bash
exit
```

Create the site configuration using a heredoc (as root):

```bash
cat > /etc/nginx/sites-available/www.echojs.com << 'EOF'
upstream puma_server {
    server unix:/home/echojs/echojs/tmp/sockets/puma.sock fail_timeout=0;
}

server {
    listen 80;
    listen [::]:80;
    server_name echojs.com echojs.net echojs.org www.echojs.net www.echojs.org;
    return 301 https://www.echojs.com\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name www.echojs.com;

    ssl_certificate /etc/nginx/ssl/fullchain.cer;
    ssl_certificate_key /etc/nginx/ssl/echojs.com.key;
    ssl_dhparam /etc/ssl/dhparam.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/echojs.access.log;
    error_log  /var/log/nginx/echojs.error.log;

    location / {
        root /home/echojs/echojs/public;
        try_files \$uri @app;
    }

    location @app {
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_redirect off;
        proxy_pass http://puma_server;
    }
}
EOF
```

Enable the site:

If the default Nginx site is still enabled, it will take precedence and show the default welcome page. Remove it first if present:

```bash
rm -f /etc/nginx/sites-enabled/default
```

Then enable the EchoJS site:

```bash
ln -s /etc/nginx/sites-available/www.echojs.com /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

---

## 7. Redis Data Migration

Upload the RDB dump to `/tmp/` first, then move it into place:

```bash
scp -i ~/.ssh/YOUR_SSH_KEY_NAME ~/Downloads/dump.rdb root@VPS_IP_ADDRESS:/tmp/
ssh -i ~/.ssh/YOUR_SSH_KEY_NAME root@VPS_IP_ADDRESS "systemctl stop redis-server && mv /tmp/dump.rdb /var/lib/redis/dump.rdb && chown redis:redis /var/lib/redis/dump.rdb && systemctl start redis-server && redis-cli dbsize"
```

The `dbsize` output should reflect the number of keys in your database.

---

## 8. Maintenance

Run as root.

### AWS CLI Setup

Install and configure the AWS CLI following the official instructions:

[Back up files to Amazon S3 using the AWS CLI](https://docs.aws.amazon.com/hands-on/latest/backup-to-s3-cli/backup-to-s3-cli.html)

You will need:

- AWS Access Key ID
- AWS Secret Access Key
- Default region name (e.g. `us-east-1`)
- Default output format (`json`)

Create the S3 bucket beforehand (e.g. `echojs-backup`) and ensure the IAM user has `s3:PutObject` permissions on it.

### Automated Redis Backups

Create a nightly backup of the Redis database, compress it, upload to S3, and keep only the most recent local copy:

```bash
mkdir -p /home/echojs/backups
(crontab -l ; echo "0 2 * * * tar cfz /home/echojs/echojs-\$(date +\%Y\%m\%d-\%H\%M).tar.gz /var/lib/redis/dump.rdb && aws s3 cp \$(ls -t /home/echojs/echojs-* | head -1) s3://echojs-backup --storage-class ONEZONE_IA && ls -t /home/echojs/echojs-* | tail -n +3 | xargs rm -f") | crontab -
```

This creates a timestamped tarball, uploads the newest one to S3, and keeps the 2 most recent local copies while removing older ones to prevent disk saturation.

### Security Updates

Enable unattended security upgrades:

```bash
dpkg-reconfigure -plow unattended-upgrades
```

---

## Validation

After completing the setup, verify that everything works:

- `curl -I http://VPS_IP_ADDRESS` returns HTTP 200 (site is running on the raw IP)
- The homepage renders with the news list at `http://VPS_IP_ADDRESS`
- User registration, login, and logout work
- A password-reset email is sent and received
- `redis-cli dbsize` returns a non-zero key count
- Nginx access and error logs show no 502 Bad Gateway errors
- `systemctl status puma` shows the service as `active (running)`
- `openssl s_client -connect www.echojs.com:443 -servername www.echojs.com` shows a valid SSL certificate
- `ufw status` shows OpenSSH and Nginx are allowed

### Testing without DNS

To test the full Nginx → Puma stack before DNS is configured, spoof the Host header:

```bash
curl -H "Host: www.echojs.com" http://VPS_IP_ADDRESS/
```

To test Puma directly (bypasses Nginx):

```bash
curl --unix-socket /home/echojs/echojs/tmp/sockets/puma.sock http://localhost/
```

Once the IP-based checks pass, proceed to [DNS Configuration](#dns-configuration) to point your domain to this server.

## 9. DNS Configuration

Point your domain to the new VPS. At your domain registrar or DNS provider, update the A records:

| Host  | Value            | TTL  |
| ----- | ---------------- | ---- |
| `@`   | `VPS_IP_ADDRESS` | Auto |
| `www` | `VPS_IP_ADDRESS` | Auto |

If you also use `echojs.net`, `echojs.org`, etc., point them to the same IP.

DNS propagation can take a few minutes to a few hours. Verify it's working:

```bash
dig +short www.echojs.com
```

It should return your new VPS IP address.

---

## Notes and Risks

- **Mailgun API**: When `MAILGUN_API_KEY` and `MAILGUN_DOMAIN` are set, EchoJS uses the Mailgun HTTP API via `mail.rb`. When they are unset, it falls back to SMTP using `MAIL_RELAY`. Both paths are handled in the committed code — no manual patching required.
- **Certificate expiration**: Track certificate expiry and renew manually or via certbot before the certificates expire. For manual renewal, upload the new certificate files and reload Nginx.
- **Puma workers**: The configuration uses 2 workers with 1 thread each to match the previous Unicorn process model and avoid Redis thread-safety issues. Puma runs as `Type=simple` under systemd (no daemonization).

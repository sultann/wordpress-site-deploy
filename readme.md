# WordPress Site Deploy Action

GitHub Action to deploy the `wp-content` directory of a WordPress site to a remote server using SSH and `rsync`. This is ideal for deploying themes, plugins, and other customizations directly from GitHub.

---

## 🔐 Requirements

1. **Generate SSH Key on your local machine:**

   Run the following command in your terminal (on your local development machine):

   ```bash
   ssh-keygen -t rsa -b 4096 -C "deploy@yourdomain.com"
   ```

   When prompted, press Enter to use the default path. This generates two files:

  - `~/.ssh/id_rsa` (private key — never share this)
  - `~/.ssh/id_rsa.pub` (public key)

2. **Copy Public Key to the Remote Server:**

   Use the following command to append your public key to the server's authorized keys:

   ```bash
   ssh-copy-id -i ~/.ssh/id_rsa.pub your-user@your-server-ip
   ```

   Replace `your-user` and `your-server-ip` with your actual SSH username and IP address of the server.

3. **Add the following secrets in your GitHub repository:**

   Go to **Settings > Secrets and Variables > Actions** and add:

   | Secret Name     | Description                                  |
   | --------------- | -------------------------------------------- |
   | `DEPLOY_HOST`   | The IP address or hostname of your server    |
   | `DEPLOY_KEY`    | The private SSH key (contents of `id_rsa`)   |
   | `SLACK_WEBHOOK` | *(Optional)* Slack webhook for notifications |

---

## 📂 Project Structure

Your GitHub repository should look like this:

```
wp-content/
├── plugins/
│   ├── my-plugin/
│   └── another-plugin/
├── themes/
│   └── my-theme/
├── mu-plugins/
├── uploads/               ← excluded from deploy
├── vendor/                ← excluded from deploy
├── composer.json
├── .distignore            ← used for custom exclusions
└── .github/
    └── workflows/
        └── deploy.yml
```

---

## ✍️ Inputs

| Input           | Required | Default                               | Description                                        |
| --------------- | -------- | ------------------------------------- | -------------------------------------------------- |
| `ssh_host`      | Yes      | –                                     | The IP/host of the server                          |
| `ssh_user`      | Yes      | –                                     | The SSH username to connect as                     |
| `ssh_key`       | Yes      | –                                     | The private key content (from `id_rsa`)            |
| `deploy_path`   | Yes      | –                                     | Full path to the `wp-content` folder on the server |
| `site_url`      | No       | `${{ github.event.repository.name }}` | Used for Slack notification message                |
| `slack_webhook` | No       | –                                     | Slack webhook URL                                  |
| `slack_message` | No       | –                                     | Custom Slack message. Auto-generated if not set.   |

---

## 🔧 Outputs

None explicitly, but it provides:

- Slack notification with status
- Cache flush via WP-CLI if available

---

## 📦 Sample `.distignore`

The `.distignore` file allows you to explicitly define which files and folders should be excluded from deployment via `rsync`. This is useful to prevent unnecessary or sensitive files (like dev tools, cache, logs, or personal editor configs) from being pushed to your production server.

Even without `.distignore`, this action already excludes many common development and system folders by default, such as:

- `.git/`
- `.github/`
- `node_modules/`
- `vendor/`
- `uploads/`, `cache/`, `backups/`, etc.

The `.distignore` file gives you fine control to customize or expand those exclusions as needed.

```text
# Git
/.git
/.github

# Node/npm
node_modules/
yarn.lock
npm-debug.log

# PHP/Composer
/vendor/
composer.lock

# Media / Cache
uploads/
upgrade/
backups/
cache/

# WordPress drop-ins
advanced-cache.php
object-cache.php
db.php

# Editor/OS junk
.idea/
.vscode/
.DS_Store
Thumbs.db

# Misc
*.log
*.sql
*.tar.gz
*.zip
*.bak
*.sh
```

---

## 🚀 Usage

```yaml
- name: Deploy site
  uses: sultann/wordpress-site-deploy@v1
  with:
    ssh_host: ${{ secrets.DEPLOY_HOST }}
    ssh_user: deploy
    ssh_key: ${{ secrets.DEPLOY_KEY }}
    deploy_path: /var/www/example.com/wp-content
    slack_webhook: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 🛠️ Example Workflow

```yaml
name: Build & Deploy – My WordPress Site

on:
  push:
    branches:
      - master

jobs:
  deploy:
    name: Deploy to Server
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          tools: composer

      - name: Install Composer Dependencies
        run: composer install --no-dev --optimize-autoloader

      - name: Deploy using WordPress Site Deploy
        uses: sultann/wordpress-site-deploy@v1
        with:
          ssh_host: ${{ secrets.DEPLOY_HOST }}
          ssh_user: deploy
          ssh_key: ${{ secrets.DEPLOY_KEY }}
          deploy_path: /var/www/example.com/wp-content
          slack_webhook: ${{ secrets.SLACK_WEBHOOK }}
```

---

## ✅ What Gets Deployed

Everything tracked by Git, **except**:
- Files/folders matched in `.distignore`
- Common dev junk and build artifacts (see sample above)

If a file is removed from Git and not excluded, it **will be deleted from the server**.

---

## 📣 Slack Notifications

When the deploy finishes:
- A Slack message is sent if `slack_webhook` is set
- Auto-includes the `site_url` and commit hash
- You can override the message with `slack_message`

---

## 🧪 Want to Test First?

Run this locally to simulate the deploy:

```bash
rsync -avzn --delete --exclude-from=.distignore ./ user@server:/var/www/example.com/wp-content
```

---

## License

MIT © Sultan Nasir Uddin


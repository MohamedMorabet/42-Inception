# Working on Inception

## Fresh setup

Use a Linux VM with Docker Engine running, modern Docker Compose (`docker compose`), Git, Make, and OpenSSL. Internet access is needed for image builds and the first WordPress/plugin download. The commands below assume the VM user is `mel-mora` and can run Docker.

```bash
docker --version
docker compose version
git clone https://github.com/MohamedMorabet/42-Inception.git ~/inception
cd ~/inception
```

Create `srcs/.env` with the following starting configuration. Replace the example emails with your own and set `FTP_PASV_ADDRESS` to the VM IP reachable from your FTP client (`hostname -I` helps identify it).

```dotenv
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
DOMAIN_NAME=mel-mora.42.fr
WP_TITLE="Inception by mel-mora"
WP_OWNER_USER=mel-mora
WP_OWNER_EMAIL=owner@example.com
WP_USER=reader
WP_USER_EMAIL=reader@example.com
FTP_USER=mel-mora
FTP_PASV_ADDRESS=127.0.0.1
```

`127.0.0.1` works for an FTP client inside the VM only. The WordPress owner name must not contain `admin`, regardless of case, and the two WordPress usernames must differ. Database names and usernames accept letters, digits, and underscores.

Create the six passwords once on a fresh installation. This command preserves any nonempty files already present:

```bash
mkdir -p secrets
chmod 700 secrets
(
    umask 077
    for name in db_password db_root_password wp_owner_password wp_user_password ftp_password monitor_password; do
        if [ ! -s "secrets/$name.txt" ]; then
            openssl rand -hex 24 > "secrets/$name.txt"
        fi
    done
)
```

Compose mounts these files under `/run/secrets/` without the `.txt` suffix. Hex passwords also satisfy Monit's letters-and-numbers restriction. Keep `.env` and `secrets/` out of Git:

```bash
git check-ignore srcs/.env secrets/db_password.txt
```

On the machine used for browsing, add a hosts entry mapping `mel-mora.42.fr` to the VM's reachable IP. For a browser inside the VM, use `127.0.0.1 mel-mora.42.fr`. Editing `/etc/hosts` requires administrator rights. With VirtualBox NAT, configure port forwarding or use a VM network reachable from the client. FTP needs its passive port range as well as port 21.

The domain is also written in the NGINX configuration and certificate-generation script. Changing only `DOMAIN_NAME` will not change those files.

## Build and launch

```bash
make
make ps
```

`make` creates the two data directories and runs:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

Compose reads `srcs/.env` alongside its configuration. You can validate the configuration without starting services:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml config --quiet
```

All eight images are built from `debian:bookworm`. MariaDB initializes an empty data directory and creates the database account. WordPress waits for a successful database connection, installs the site when needed, creates the subscriber, and enables Redis Object Cache. NGINX generates a self-signed certificate at startup if none exists in its container.

## Files to edit

| Location | Purpose |
| --- | --- |
| `Makefile` | Build, start, stop, and cleanup commands |
| `srcs/docker-compose.yml` | Services, network, volumes, ports, and secrets |
| `srcs/requirements/mariadb/` | Database image, server configuration, initialization |
| `srcs/requirements/wordpress/` | PHP-FPM image, pool configuration, WordPress setup |
| `srcs/requirements/nginx/` | HTTPS, certificate generation, request routing |
| `srcs/requirements/bonus/` | Redis, FTP, static-site, Adminer, and Monit sources |

Dockerfiles install software; `conf/` holds service settings; `tools/` holds startup scripts where needed. The portfolio source is in `srcs/requirements/bonus/static-site/html/`.

## Useful commands

| Command | Effect |
| --- | --- |
| `make build` | Build images |
| `make up` | Build and start the full stack |
| `make down` | Remove containers and the Compose network |
| `make clean` | Same cleanup, including orphan containers |
| `make fclean` | Also remove service images and named volume objects |
| `make re` | Run `fclean`, then build and start again |
| `make ps` / `make logs` | Status / recent logs |

`fclean` and `re` do **not** erase the host data directories. They are not a fresh database reset. Back up data before any deliberate deletion of those directories.

After editing an image's files, rebuild its service. For example:

```bash
docker compose -f srcs/docker-compose.yml up -d --build wordpress
```

For a simple process restart or a shell:

```bash
docker compose -f srcs/docker-compose.yml restart wordpress
docker compose -f srcs/docker-compose.yml exec wordpress sh
```

If an upstream container gets a different IP after recreation and NGINX returns 502, restart NGINX so it resolves the service again.

## Storage and persistence

| Named volume | Container path | VM directory |
| --- | --- | --- |
| `mariadb_data` | `/var/lib/mysql` | `/home/mel-mora/data/mariadb` |
| `wordpress_data` | `/var/www/html` | `/home/mel-mora/data/wordpress` |

The local volume driver uses `type: none`, `o: bind`, and a host `device` path. Services still reference named volumes. WordPress and FTP share the website volume; NGINX mounts it read-only. The database and uploads survive container recreation because their files remain on the VM.

```bash
docker volume ls
docker volume inspect srcs_mariadb_data srcs_wordpress_data
```

The `srcs_` prefix is Compose's default project name here; use the names from `docker volume ls` if you override it. Redis has no persistent volume: cache loss is expected. Monit state and the generated TLS certificate are also container-local.

For a simple backup, stop the stack with `make down`, copy both data directories while preserving ownership and permissions, and keep a separate private copy of `.env` and `secrets/`. Start again with `make`. Restore both data directories together; Git stores the project source, not the live website.

Existing MariaDB initialization is tracked by `.inception_initialized`. WordPress keeps its existing `wp-config.php` and accounts. Editing environment variables or password files does not automatically migrate an initialized site or rotate its database credentials.

## Checks after changes

```bash
make ps
curl -k --resolve mel-mora.42.fr:443:127.0.0.1 -I https://mel-mora.42.fr/
docker compose -f srcs/docker-compose.yml exec wordpress wp user list --allow-root --fields=ID,user_login,roles
docker compose -f srcs/docker-compose.yml exec wordpress wp redis status --allow-root
docker compose -f srcs/docker-compose.yml exec monit monit -c /etc/monit/monitrc summary
```

`curl -k` accepts the local self-signed certificate for this test. Also check the portfolio and Adminer pages, FTP upload/download, and the Monit dashboard listed in [USER_DOC.md](USER_DOC.md). After `make down` followed by `make`, existing posts, users, and uploads should still be present.

Monit checks network endpoints every ten seconds. Its configuration reports failures; it does not restart the other containers or configure email delivery. Docker's `unless-stopped` policy handles unexpected container exits.

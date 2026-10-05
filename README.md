*This project has been created as part of the 42 curriculum by mel-mora.*

# Inception

Eight services. One VM. Built from Debian.

## Description

Inception is my Docker infrastructure project at 1337. The goal is to run a WordPress website with HTTPS, a separate database, and data that survives container recreation.

NGINX handles incoming web requests, PHP-FPM runs WordPress, and MariaDB stores its data. The bonus adds Redis, FTP, a static portfolio, Adminer, and Monit.

| Service | What it does |
| --- | --- |
| NGINX | HTTPS entry point with TLS 1.2 and 1.3 |
| WordPress + PHP-FPM | Website and administration panel |
| MariaDB | WordPress database |
| Redis | WordPress object cache |
| FTP | Access to the WordPress files through vsftpd |
| Static site | HTML/CSS portfolio served by its own NGINX container |
| Adminer | Database management in the browser |
| Monit | Checks service availability and shows a monitoring dashboard |

## Project description

Each service has its own Dockerfile based on `debian:bookworm`. Compose builds the images locally, connects the containers through the `inception` bridge network, and applies `restart: unless-stopped`.

The source is kept in `srcs/`: Compose configuration, Dockerfiles, service configuration, startup scripts, and the portfolio files. The Makefile at the root provides the everyday commands. WordPress and its Redis plugin are downloaded during initial setup; WP-CLI is installed while building the WordPress image.

The website uses port **443**. The bonus adds **8443** for Monit and **21 / 21100–21110** for passive FTP. MariaDB, PHP-FPM, Redis, Adminer, and the portfolio have no directly published host ports.

### Main choices

| Comparison | Choice in this project |
| --- | --- |
| Virtual machines vs Docker | A VM runs its own kernel; containers share their host's kernel. Debian is the VM, and Docker separates the services inside it. |
| Secrets vs environment variables | Environment variables hold settings such as the domain and usernames. Passwords are local files mounted through Compose secrets under `/run/secrets`. Both `.env` and `secrets/` are ignored by Git. |
| Docker network vs host network | The bridge network gives containers their own network space and service-name lookup. Host networking would share the VM's network directly; it is not used. |
| Docker volumes vs bind mounts | A named volume is a Docker storage object; a direct bind mount maps a host path into a container. Here, services use two named volumes whose local driver binds them to specific folders under `/home/mel-mora/data`. |

NGINX mounts the WordPress files read-only. FTP shares the same files with write access. Redis is disposable cache, so its contents do not need persistent storage. Monit checks availability; Docker handles container restarts.

## Instructions

Run the project inside a Linux VM with Docker Engine, the `docker compose` plugin, Git, and Make installed.

For a fresh machine, follow [DEV_DOC.md](DEV_DOC.md) to create `srcs/.env`, the six secret files, and the domain mapping. Then, from the repository root:

```bash
make
make ps
```

Open [mel-mora.42.fr](https://mel-mora.42.fr). The local certificate is self-signed, so the browser initially displays a certificate warning.

```bash
make down   # Stop and remove containers; keep stored data
make logs   # Show the last 100 log lines per service
```

[USER_DOC.md](USER_DOC.md) covers access, credentials, and daily use. [DEV_DOC.md](DEV_DOC.md) covers setup, storage, and maintenance. The current Compose file starts mandatory and bonus services together.

## Resources

- [Docker documentation](https://docs.docker.com/) — images, Compose, networks, volumes, and secrets.
- [NGINX documentation](https://nginx.org/en/docs/) — TLS, FastCGI, and reverse proxy configuration.
- [MariaDB documentation](https://mariadb.com/docs/) — database initialization, users, and permissions.
- [WP-CLI handbook](https://make.wordpress.org/cli/handbook/) — automated WordPress setup.
- [Redis Object Cache](https://wordpress.org/plugins/redis-cache/) — WordPress cache integration.
- [Monit manual](https://mmonit.com/monit/documentation/monit.html) — service checks and dashboard configuration.

### AI use

I used ChatGPT to help draft Dockerfiles, startup scripts, service configurations, test commands, and these documents. I also used it to troubleshoot build and connection errors while running the project in my VM. The code and configuration are part of my submission, and I am responsible for checking and explaining them.

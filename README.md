cat > README.md <<'EOF'
*This project has been created as part of the 42 curriculum by mel-mora.*

# Inception

## Description

Inception builds a small web infrastructure inside a virtual machine using
Docker Compose. Three separate containers provide NGINX, WordPress with PHP-FPM,
and MariaDB.

NGINX is the only public entrypoint, exposing port 443 with TLS 1.2 and TLS 1.3.
WordPress communicates with MariaDB through a private Docker bridge network.
Two named volumes preserve the database and website files.

## Project description

Each service has its own Dockerfile based on Debian Bookworm. The images are
built locally rather than using ready-made application images.

The repository includes:
- `Makefile`: builds and manages the stack.
- `srcs/docker-compose.yml`: defines services, networking, secrets and volumes.
- `srcs/requirements/`: Dockerfiles, configuration and startup scripts.
- `USER_DOC.md`: instructions for users and administrators.
- `DEV_DOC.md`: environment setup and developer commands.

Local configuration is stored in `srcs/.env`. Password files are stored in
`secrets/`. Both are excluded from Git.

### Virtual Machines vs Docker

A virtual machine runs its own kernel and operating system. Docker containers
share the host kernel and isolate application processes. This project runs
Docker inside a Debian virtual machine.

### Secrets vs Environment Variables

Environment variables provide configuration such as the domain and database
name. Docker secrets provide password files mounted under `/run/secrets`.
Local Compose secrets rely on the protection of their source files; they are
not an encrypted secret store.

### Docker Network vs Host Network

A Docker bridge network isolates the stack and allows services to communicate
using service names. Host networking shares the host's network namespace.
This project uses a bridge network and publishes only NGINX port 443.

### Docker Volumes vs Bind Mounts

Named volumes are managed through Docker and referenced by name. Direct bind
mounts attach host paths directly to containers. This project uses two named
volumes with local driver options pointing to `/home/mel-mora/data/mariadb`
and `/home/mel-mora/data/wordpress`.

## Instructions

Install Docker Engine, the Docker Compose plugin, Make and Python 3 inside
the virtual machine. Configure `srcs/.env`, create the local secret files,
and map `mel-mora.42.fr` to the virtual machine IP on the browsing machine.

Start the stack:

```sh
make
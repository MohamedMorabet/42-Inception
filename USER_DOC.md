# Using Inception

Run terminal commands from `~/inception` inside the Debian VM. First-time setup is in [DEV_DOC.md](DEV_DOC.md).

## Start, stop, check

```bash
make        # Build and start all services
make ps     # Show running containers
make logs   # Show recent logs
make down   # Stop the stack and remove its containers
```

Starting again with `make` reuses the existing database and WordPress files. Allow a little time for WordPress initialization and Monit's first checks.

## Where to go

The device running your browser must resolve `mel-mora.42.fr` to the VM's reachable IP address.

| Page | Address |
| --- | --- |
| WordPress | https://mel-mora.42.fr/ |
| WordPress dashboard | https://mel-mora.42.fr/wp-admin/ |
| Static portfolio | https://mel-mora.42.fr/portfolio/ |
| Adminer | https://mel-mora.42.fr/adminer/ |
| Monit | https://mel-mora.42.fr:8443/ |

HTTPS uses a self-signed certificate for this local project. A browser warning is expected; confirm that you are connecting to your own VM before continuing.

WordPress provides the website and its admin panel. MariaDB stores content and accounts. Redis caches WordPress objects. The portfolio is a separate static site, Adminer manages the database, and Monit shows service availability.

## Credentials

Usernames and general settings are in `srcs/.env`. Passwords are in these local files:

| Account | Username | Password file under `secrets/` |
| --- | --- | --- |
| WordPress owner | `WP_OWNER_USER` | `wp_owner_password.txt` |
| WordPress subscriber | `WP_USER` | `wp_user_password.txt` |
| Database user | `MYSQL_USER` | `db_password.txt` |
| Database root | `root` | `db_root_password.txt` |
| FTP | `FTP_USER` | `ftp_password.txt` |
| Monit | `observer` | `monitor_password.txt` |

For Adminer, select **MySQL**, enter **mariadb** as the server, and use `MYSQL_USER`, its database password, and `MYSQL_DATABASE`. These are database credentials, not WordPress login details.

Keep these files local. Do not commit passwords or share them in screenshots.

Change WordPress passwords from the dashboard and update the matching local secret for future installations. Changing a secret file alone does not change an existing WordPress or MariaDB account. Database password changes also require updating the database account and WordPress connection settings. FTP and Monit read their passwords at startup; after changing their secret files, recreate those containers:

```bash
docker compose -f srcs/docker-compose.yml up -d --force-recreate ftp monit
```

The Monit password must contain only letters and numbers.

## FTP access

Use an FTP client with the VM's reachable IP, port **21**, the `FTP_USER` username, and the password in `ftp_password.txt`. Select **passive mode**. This setup uses plain FTP, not SFTP or FTPS, so use it only on the trusted project network.

The FTP root is the WordPress files. Uploading or deleting files changes the live website. Passive transfers also need ports **21100–21110** reachable and `FTP_PASV_ADDRESS` set to the correct VM address.

## Quick health check

```bash
make ps
docker compose -f srcs/docker-compose.yml exec wordpress wp redis status --allow-root
docker compose -f srcs/docker-compose.yml exec monit monit -c /etc/monit/monitrc summary
```

All eight services should be running. Redis should report healthy in Compose and connected in WordPress. Monit should report the monitored services as OK after its checks run.

If the website does not open, check that the VM is running and the domain points to its current IP. For a service error, inspect its logs, for example:

```bash
docker compose -f srcs/docker-compose.yml logs --tail=50 wordpress
```

Posts and accounts live in `/home/mel-mora/data/mariadb`; website files and uploads live in `/home/mel-mora/data/wordpress`. Keep both directories when moving or backing up the project. A Git clone alone does not contain this data or your secrets.

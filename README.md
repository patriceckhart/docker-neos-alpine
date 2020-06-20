## patriceckhart/docker-neos-alpine ##
Neos CMS docker image based on Alpine linux with nginx + php-fpm 7.4 🚀, packing everything needed for development and production usage of Neos.

#### The image does a few things: ####
Automatically install and provision a Neos CMS website or a Neos Flow application, based on environment vars documented below
Pack a few useful things like git, automated update mechanism + a simple ci-pipeline, etc.

### Usage ###
This image supports following environment variable for automatically configuring Neos at container startup:

#### Required env vars ####

| Docker env var | Description |
|---------|-------------|
|REPOSITORY_URL|Link to Neos CMS website distribution|
|GITHUB_USERNAME|Will pull authorized keys allowed to connect to the container via ssh|

#### Optional env vars ####

| Docker env var | Description |
|---------|-------------|
|GITHUB_TOKEN|Github Token for clone private repositories|
|DB_DATABASE|Database name, defaults to `neos`|
|DB_USER|Database user, defaults to `admin`|
|DB_PASS|Database password, defaults to `pass`|
|DB_HOST|Database host, defaults to `mariadb`|
|SITE_PACKAGE|Neos CMS website package with exported website data to be imported|
|ADMIN_PASSWORD|If set, would create a Neos CMS `admin` user with such password|
|EDITOR_USERNAME|If set, would create a Neos CMS `editor` user|
|EDITOR_PASSWORD|Password for the editor user if defined|
|EDITOR_FIRSTNAME|Firstname of editor user|
|EDITOR_LASTNAME|Lastname of editor user|
|EDITOR_ROLE|Individual user group/role for the editor user|
|CONTAINERNAME|Container name for different processes around the container|
|VIRTUAL_HOST|Virtual host if a Nginx proxy is used|
|UPDATEPACKAGES|`daily`, `weekly`, `monthly` Auto-Update Neos installation including all packages with composer update|

### Example docker-compose.yml configuration ###

```
web:
  image: patriceckhart/docker-neos-alpine
  ports:
    - '80'
    - '22:22'
  links:
    - mariadb:mariadb
  volumes:
    - /data
  environment:
    # If you use a GITHUB_TOKEN, just enter YourGitRepo.git as GITHUB_REPOSITORY
    - GITHUB_REPOSITORY=https://github.com/yourgitaccount/YourGitRepo
    # - GITHUB_REPOSITORY=YourGitRepo.git
    #- GITHUB_TOKEN=9a72f0aca3c52463b17464k2277833x58037ff68
    - GITHUB_USERNAME=yourgitusername
    # When using the following ENV, a database and a privileged user must already be created, otherwise the container will crash
    - DB_DATABASE=neos
    - DB_USER=admin
    - DB_PASS=pass
    - DB_HOST=mariadb
    # Neos CMS site import
    - SITE_PACKAGE=Your.Site
    # Neos CMS User
    - ADMIN_PASSWORD=password
    #- CONTAINERNAME=yourneos
    #- VIRTUAL_HOST=dev.neos.local

mariadb:
  image: mariadb:latest
  expose:
    - 3306
  volumes:
    - /var/lib/data
  environment:
    MYSQL_DATABASE: 'neos'
    MYSQL_USER: 'admin'
    MYSQL_PASSWORD: 'pass'
    MYSQL_ROOT_PASSWORD: 'root'
  ports:
    - '3306:3306'
  command: mysqld --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
```

### Helpful cli scripts ###

| CLI command | Description |
|---------|-------------|
|updateneos|Update Neos installation including all packages with composer-update|
|setfilepermissions|Adjust file permissions for CLI and web server access|
|flushcache|Flush all development and production caches|
|flushcachedev|Flush all development caches|
|flushcacheprod|Flush all production caches|

#### For development (only works with docker exec ... or kubectl exec ...) ####

| CLI command | Description |
|---------|-------------|
|pullapp|Pulls latest code from git repository|
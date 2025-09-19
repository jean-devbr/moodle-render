# BancoDados — Moodle + MariaDB (Docker)

Este repositório traz uma configuração Docker Compose para executar o Moodle (aplicação web de ensino) com um banco de dados MariaDB.

Resumo
- Serviços:
  - `mariadb`: servidor MariaDB que armazena os dados do Moodle.
  - `moodle`: container Bitnami do Moodle (PHP + Apache) que provê a interface web em HTTP/HTTPS.
- Portas expostas:
  - Moodle HTTP: `8080` (host) -> `8080` (container)
  - (Se presente) Moodle HTTPS: `8443` (host) -> `8443` (container)
- Volumes importantes:
  - `mariadb_data`: dados persistidos do MariaDB.
  - `moodle_data`: arquivos da aplicação Moodle persistidos (conteúdo de `/bitnami/moodle`).
  - `moodledata_data`: dataroot do Moodle (arquivos carregados pelos usuários) — normalmente mapeado para `/bitnami/moodledata`.

Pré-requisitos
- Docker e Docker Compose instalados na sua máquina.
- Espaço em disco suficiente para volumes (vários centenas de MBs a alguns GBs, dependendo do conteúdo).

Como rodar (passo-a-passo) exemplo
1. Abrir o diretório do projeto:

```bash
cd /home/jean/projects/bancoDados
```

2. Subir os serviços em background:

```bash
docker compose up -d
```

3. Verificar se os containers estão rodando:

```bash
docker ps
```

Procure por `bancodados-mariadb-1` e `bancodados-moodle-1` (ou nomes equivalentes) e verifique portas e status.

4. Acessar o Moodle no navegador:

- Abra: `http://localhost:8080`
- Use as credenciais de administrador definidas no `docker-compose.yml` (ex.: `MOODLE_USERNAME` / `MOODLE_PASSWORD`) durante a instalação automática.

Como acessar o banco de dados MariaDB
- A forma mais simples e segura é executar comandos diretamente no container MariaDB:

```bash
# Acessa o cliente mariadb como root
docker exec -it bancodados-mariadb-1 mariadb -uroot -prootpass
```

- Comando único sem entrar interativo:

```bash
docker exec bancodados-mariadb-1 mariadb -uroot -prootpass -e "SHOW DATABASES;"
```

- Se preferir GUI, rode o Adminer temporariamente (conecta-se à rede do compose):

```bash
docker run --rm -d --name adminer --network $(docker compose ps -q | head -n1 | xargs docker inspect --format '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}') -p 8081:8080 adminer
```

Depois acesse `http://localhost:8081` e conecte com:
- Host: `mariadb` (nome do serviço dentro da rede)
- Usuário/senha: conforme `docker-compose.yml` (ex.: `bn_moodle` / `moodlepass`) ou `root`/`rootpass`

Principais variáveis no `docker-compose.yml`
- `MARIADB_ROOT_PASSWORD` — senha do root do MariaDB.
- `MARIADB_DATABASE` — nome do banco criado para o Moodle (ex.: `bitnami_moodle`).
- `MARIADB_USER` / `MARIADB_PASSWORD` — usuário usado pela aplicação Moodle.
- `MOODLE_DATABASE_HOST` / `MOODLE_DATABASE_USER` / `MOODLE_DATABASE_PASSWORD` — correspondem às configurações de conexão do Moodle.
- `MOODLE_USERNAME` / `MOODLE_PASSWORD` — credenciais do admin Moodle (se a instalação é automatizada).

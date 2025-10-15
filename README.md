# Moodle no Render (Dockerfile + PostgreSQL)

Infra simples para rodar Moodle no Render:
- Web Service (este repo, Dockerfile + Apache + PHP 8.2)
- PostgreSQL gerenciado do Render

O entrypoint:
- Define o APACHE_DOCUMENT_ROOT no Apache.
- Gera config.php a partir das variáveis de ambiente.
- Força SSL ao Postgres (PGSSLMODE=require).
- Instala o Moodle via CLI na primeira execução ou executa upgrade nas próximas.
- Faz purge de cache após instalar/atualizar.

Requisitos
- Conta no Render.
- Um serviço PostgreSQL no Render (recomendado usar o host do External Database URL).
- Repositório conectado ao Render.

Variáveis de ambiente (Render > Web Service > Environment)
- DB_TYPE=pgsql
- DB_HOST=dpg-...oregon-postgres.render.com  (copie do External Database URL/PSQL Command)
- DB_PORT=5432
- DB_NAME=<nome do banco>
- DB_USER=<usuário>
- DB_PASS=<senha do banco>
- PGSSLMODE=require
- DB_PREFIX=mdl_  (altere se já houver tabelas: ex. mdl2_)
- MOODLE_WWWROOT=https://<seu-servico>.onrender.com
- MOODLE_DATAROOT=/tmp/moodledata  (ephemeral no Free)
- FORCE_CONFIG=1
- ADMIN_USER=admin
- ADMIN_PASS=Adm!n2025_R3nd3r#  (ajuste)
- ADMIN_EMAIL=admin@seu-dominio.com
- SITE_FULLNAME=Moodle Render
- SITE_SHORTNAME=Moodle

Deploy
1) Conecte o repo ao Render e crie um Web Service (Docker).
2) Adicione as variáveis acima e “Save, rebuild, and deploy”.
3) Nos logs procure:
   - “[dbcheck] OK”
   - “Running first install” (primeiro deploy) ou “Running upgrade” (seguintes)
4) Acesse o domínio e conclua as telas iniciais (nome do site, fuso etc.).

Atualizações
- A cada novo deploy o entrypoint executa o upgrade do Moodle via CLI e limpa os caches.

Resolução de problemas
- Database connection failed:
  - Verifique DB_HOST/DB_NAME/DB_USER/DB_PASS e PGSSLMODE=require.
  - Teste do seu computador (Linux):
    PGPASSWORD='<SENHA>' PGSSLMODE=require psql -h <HOST> -p 5432 -U <USUARIO> -d <DB> -c 'select now();'
- “Reverse proxy enabled…”:
  - Já resolvido no config (reverseproxy=false, sslproxy=true).
- “relation ‘mdl_…’ already exists” durante instalação:
  - Limpe o banco (apaga TUDO):
    PGPASSWORD='<SENHA>' PGSSLMODE=require psql -h <HOST> -p 5432 -U <USUARIO> -d <DB> <<'SQL'
    BEGIN;
    DROP SCHEMA public CASCADE;
    CREATE SCHEMA public AUTHORIZATION <USUARIO>;
    GRANT ALL ON SCHEMA public TO public;
    COMMIT;
    SQL
  - Ou mude DB_PREFIX para outro valor (ex. mdl2_) e redeploy.

Notas
- Plano Free do Render tem filesystem efêmero; por isso o dataroot está em /tmp. Para produção, use um volume persistente/serviço com disco.
- Nunca commit secrets. Use o painel de Environment do Render.
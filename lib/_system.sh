#!/bin/bash
# 
# system management

#######################################
# creates user
# Arguments:
#   None
#######################################
system_create_user() {
  print_banner
  printf "${WHITE} 💻 Agora, vamos criar o usuário para a instancia...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
    sudo useradd -m -s /bin/bash -G sudo deploy

  ENCRYPTED_PASS=deploybotmal

  echo "deploy:${ENCRYPTED_PASS}" | sudo chpasswd
EOF

  sleep 2
}

#######################################
# clones repositories using licensing gateway
# Arguments:
#   None
#######################################
system_git_clone() {
  # URL da API de licenciamento — atualize após o deploy do Cloudflare Worker
  AUTHCHAT_API_URL="https://authchat-gateway.authcom.workers.dev"

  print_banner
  printf "${WHITE} 💻 Validando licença e fazendo download do Authchat...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # ── Etapa 1: Validar chave e obter token de download ──────────────────────
  printf "${WHITE} 🔐 Conectando ao servidor de licenças...${GRAY_LIGHT}\n\n"

  RESPOSTA=$(curl -s --max-time 30 \
    -X POST "${AUTHCHAT_API_URL}/ativar" \
    -H "Content-Type: application/json" \
    -d "{\"chave\": \"${chave_ativacao}\"}")

  if [ -z "$RESPOSTA" ]; then
    printf "${RED} ❌ Erro: servidor de licenças inacessível. Verifique sua conexão.${NC}\n\n"
    exit 1
  fi

  # Extrai campo "erro" da resposta usando node (já instalado neste ponto)
  ERRO=$(echo "$RESPOSTA" | node -e "
    let d = '';
    process.stdin.on('data', c => d += c);
    process.stdin.on('end', () => {
      try { console.log(JSON.parse(d).erro || ''); }
      catch(e) { console.log('Resposta inválida do servidor de licenças'); }
    });
  " 2>/dev/null)

  if [ -n "$ERRO" ]; then
    printf "${RED} ❌ Licença inválida: %s${NC}\n\n" "$ERRO"
    exit 1
  fi

  DL_TOKEN=$(echo "$RESPOSTA" | node -e "
    let d = '';
    process.stdin.on('data', c => d += c);
    process.stdin.on('end', () => {
      try { console.log(JSON.parse(d).dl_token || ''); }
      catch(e) { console.log(''); }
    });
  " 2>/dev/null)

  MENSAGEM=$(echo "$RESPOSTA" | node -e "
    let d = '';
    process.stdin.on('data', c => d += c);
    process.stdin.on('end', () => {
      try { console.log(JSON.parse(d).mensagem || ''); }
      catch(e) { console.log(''); }
    });
  " 2>/dev/null)

  if [ -z "$DL_TOKEN" ]; then
    printf "${RED} ❌ Erro inesperado ao validar licença.${NC}\n\n"
    exit 1
  fi

  printf "${GREEN} ✅ %s${NC}\n\n" "$MENSAGEM"
  sleep 1

  # ── Etapa 2: Baixar o código fonte ────────────────────────────────────────
  printf "${WHITE} 📦 Baixando código fonte...${GRAY_LIGHT}\n\n"

  curl -L --progress-bar \
    -o /tmp/authchat-install.zip \
    "${AUTHCHAT_API_URL}/baixar?token=${DL_TOKEN}"

  if [ $? -ne 0 ] || [ ! -s /tmp/authchat-install.zip ]; then
    printf "${RED} ❌ Falha ao baixar o código fonte. Tente novamente.${NC}\n\n"
    exit 1
  fi

  # ── Etapa 3: Extrair e posicionar o código ────────────────────────────────
  printf "${WHITE} 📂 Extraindo e instalando código fonte...${GRAY_LIGHT}\n\n"

  rm -rf /tmp/authchat-extract
  mkdir -p /tmp/authchat-extract

  unzip -q /tmp/authchat-install.zip -d /tmp/authchat-extract/ || {
    printf "${RED} ❌ Falha ao extrair o pacote baixado. Tente novamente.${NC}\n\n"
    exit 1
  }

  # O ZIP do GitHub cria um diretório com o formato: owner-repo-sha/
  EXTRACTED_DIR=$(ls /tmp/authchat-extract/ | head -1)

  if [ -z "$EXTRACTED_DIR" ]; then
    printf "${RED} ❌ Extração resultou em diretório vazio. Contate o suporte.${NC}\n\n"
    exit 1
  fi

  EXTRACTED_APP="/tmp/authchat-extract/${EXTRACTED_DIR}/codatendechat-mainatualizado"

  if [ ! -d "$EXTRACTED_APP" ]; then
    printf "${RED} ❌ Estrutura do pacote inválida (codatendechat-mainatualizado não encontrado).${NC}\n\n"
    exit 1
  fi

  # Remove instalação anterior e move o código para o destino final
  # mv é mais confiável que cp -r: atômico e falha visivelmente se o source não existe
  rm -rf "/home/deploy/${instancia_add}"
  mv "$EXTRACTED_APP" "/home/deploy/${instancia_add}"

  # Valida que backend e frontend estão presentes antes de continuar
  if [ ! -d "/home/deploy/${instancia_add}/backend" ]; then
    printf "${RED} ❌ Diretório backend não encontrado em /home/deploy/${instancia_add}/. Abortando.${NC}\n\n"
    exit 1
  fi

  if [ ! -d "/home/deploy/${instancia_add}/frontend" ]; then
    printf "${RED} ❌ Diretório frontend não encontrado em /home/deploy/${instancia_add}/. Abortando.${NC}\n\n"
    exit 1
  fi

  chown -R deploy:deploy "/home/deploy/${instancia_add}"
  rm -rf /tmp/authchat-install.zip /tmp/authchat-extract

  printf "${GREEN} ✅ Código instalado em /home/deploy/${instancia_add}${NC}\n\n"

  sleep 2
}

#######################################
# updates system
# Arguments:
#   None
#######################################
system_update() {
  print_banner
  printf "${WHITE} 💻 Vamos atualizar o sistema do Authchat...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt -y update
  sudo apt-get install -y libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
EOF

  sleep 2
}



#######################################
# delete system
# Arguments:
#   None
#######################################
deletar_tudo() {
  print_banner
  printf "${WHITE} 💻 Vamos deletar o Authchat...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  docker container rm redis-${empresa_delete} --force
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_delete}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_delete}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa_delete}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa_delete}-backend
  
  sleep 2

  sudo su - postgres
  dropuser ${empresa_delete}
  dropdb ${empresa_delete}
  exit
EOF

sleep 2

sudo su - deploy <<EOF
 rm -rf /home/deploy/${empresa_delete}
 pm2 delete ${empresa_delete}-frontend ${empresa_delete}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Remoção da Instancia/Empresa ${empresa_delete} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"


  sleep 2

}

#######################################
# bloquear system
# Arguments:
#   None
#######################################
configurar_bloqueio() {
  print_banner
  printf "${WHITE} 💻 Vamos bloquear o Authchat...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
 pm2 stop ${empresa_bloquear}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Bloqueio da Instancia/Empresa ${empresa_bloquear} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}


#######################################
# desbloquear system
# Arguments:
#   None
#######################################
configurar_desbloqueio() {
  print_banner
  printf "${WHITE} 💻 Vamos Desbloquear o Authchat...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
 pm2 start ${empresa_bloquear}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Desbloqueio da Instancia/Empresa ${empresa_desbloquear} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# alter dominio system
# Arguments:
#   None
#######################################
configurar_dominio() {
  print_banner
  printf "${WHITE} 💻 Vamos Alterar os Dominios do Authchat...${GRAY_LIGHT}"
  printf "\n\n"

sleep 2

  sudo su - root <<EOF
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_dominio}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_dominio}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa_dominio}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa_dominio}-backend
EOF

sleep 2

  sudo su - deploy <<EOF
  cd && cd /home/deploy/${empresa_dominio}/frontend
  sed -i "1c\REACT_APP_BACKEND_URL=https://${alter_backend_url}" .env
  cd && cd /home/deploy/${empresa_dominio}/backend
  sed -i "2c\BACKEND_URL=https://${alter_backend_url}" .env
  sed -i "3c\FRONTEND_URL=https://${alter_frontend_url}" .env 
EOF

sleep 2
   
   backend_hostname=$(echo "${alter_backend_url/https:\/\/}")

 sudo su - root <<EOF
  cat > /etc/nginx/sites-available/${empresa_dominio}-backend << 'END'
server {
  server_name $backend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${alter_backend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${empresa_dominio}-backend /etc/nginx/sites-enabled
EOF

sleep 2

frontend_hostname=$(echo "${alter_frontend_url/https:\/\/}")

sudo su - root << EOF
cat > /etc/nginx/sites-available/${empresa_dominio}-frontend << 'END'
server {
  server_name $frontend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${alter_frontend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${empresa_dominio}-frontend /etc/nginx/sites-enabled
EOF

 sleep 2

 sudo su - root <<EOF
  service nginx restart
EOF

  sleep 2

  backend_domain=$(echo "${backend_url/https:\/\/}")
  frontend_domain=$(echo "${frontend_url/https:\/\/}")

  sudo su - root <<EOF
  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Alteração de dominio da Instancia/Empresa ${empresa_dominio} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# installs node
# Arguments:
#   None
#######################################
system_node_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nodejs...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  apt-get install -y nodejs
  sleep 2
  npm install -g npm@latest
  sleep 2
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update -y && sudo apt-get -y install postgresql
  sleep 2
  sudo timedatectl set-timezone America/Sao_Paulo
  sudo npm install -g pm2
  
EOF

  sleep 2
}
#######################################
# installs docker
# Arguments:
#   None
#######################################
system_docker_install() {
  print_banner
  printf "${WHITE} 💻 Instalando docker...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt install -y apt-transport-https \
                 ca-certificates curl \
                 software-properties-common

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

  apt install -y docker-ce
EOF

  sleep 2
}

#######################################
# Ask for file location containing
# multiple URL for streaming.
# Globals:
#   WHITE
#   GRAY_LIGHT
#   BATCH_DIR
#   PROJECT_ROOT
# Arguments:
#   None
#######################################
system_puppeteer_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando puppeteer dependencies...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt-get install -y libxshmfence-dev \
                      libgbm-dev \
                      wget \
                      unzip \
                      fontconfig \
                      locales \
                      gconf-service \
                      libasound2 \
                      libatk1.0-0 \
                      libc6 \
                      libcairo2 \
                      libcups2 \
                      libdbus-1-3 \
                      libexpat1 \
                      libfontconfig1 \
                      libgcc1 \
                      libgconf-2-4 \
                      libgdk-pixbuf2.0-0 \
                      libglib2.0-0 \
                      libgtk-3-0 \
                      libnspr4 \
                      libpango-1.0-0 \
                      libpangocairo-1.0-0 \
                      libstdc++6 \
                      libx11-6 \
                      libx11-xcb1 \
                      libxcb1 \
                      libxcomposite1 \
                      libxcursor1 \
                      libxdamage1 \
                      libxext6 \
                      libxfixes3 \
                      libxi6 \
                      libxrandr2 \
                      libxrender1 \
                      libxss1 \
                      libxtst6 \
                      ca-certificates \
                      fonts-liberation \
                      libappindicator1 \
                      libnss3 \
                      lsb-release \
                      xdg-utils
EOF

  sleep 2
}

#######################################
# installs pm2
# Arguments:
#   None
#######################################
system_pm2_install() {
  print_banner
  printf "${WHITE} 💻 Instalando pm2...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  
  npm install -g pm2

  sleep 2
}

#######################################
# installs snapd
# Arguments:
#   None
#######################################
system_snapd_install() {
  print_banner
  printf "${WHITE} 💻 Instalando snapd...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt install -y snapd
  snap install core
  snap refresh core
EOF

  sleep 2
}

#######################################
# installs certbot
# Arguments:
#   None
#######################################
system_certbot_install() {
  print_banner
  printf "${WHITE} 💻 Instalando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt-get remove certbot
  snap install --classic certbot
  ln -s /snap/bin/certbot /usr/bin/certbot
EOF

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt install -y nginx
  rm /etc/nginx/sites-enabled/default
EOF

  sleep 2
}

#######################################
# restarts nginx
# Arguments:
#   None
#######################################
system_nginx_restart() {
  print_banner
  printf "${WHITE} 💻 reiniciando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  service nginx restart
EOF

  sleep 2
}

#######################################
# setup for nginx.conf
# Arguments:
#   None
#######################################
system_nginx_conf() {
  print_banner
  printf "${WHITE} 💻 configurando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - root << EOF

cat > /etc/nginx/conf.d/deploy.conf << 'END'
client_max_body_size 100M;
END

EOF

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_certbot_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  backend_domain=$(echo "${backend_url/https:\/\/}")
  frontend_domain=$(echo "${frontend_url/https:\/\/}")

  sudo su - root <<EOF
  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain

EOF

  sleep 2
}


#!/usr/bin/env bash
set -euo pipefail

# ===============================
#  Linux Post-Install Script
#  Uso: ./menu.sh [opciones]
#  Opciones:
#    -h, --help   Muestra esta ayuda y sale
#  Dependencias: curl, wget
# ===============================

# === limpieza de temporales ante error o salida ===
function cleanup_temp() {
  rm -f /tmp/get_helm.sh get-docker.sh kubectl minikube-linux-amd64 awscliv2.zip packages.microsoft.gpg 2>/dev/null || true
}
trap cleanup_temp EXIT

# Mensajes globales
TITULO="💬 Comprobando si \$app esta instalado ..."
NOEXISTE="🚨 \$app no esta instalado. 🚀 Instalando \$app ..."
INSTALADO="✅ \$app se ha instalado correctamente."
EXISTE="✅ \$app Ya esta instalado."

# === Codigos de color ANSI (unificados) ===
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color


# === Chequeo de dependencias (sugerindo por IA)===
function check_dependencies() {
  local missing=()
  
  # 1. Verificar qué dependencias faltan
  for dep in curl wget; do
    if ! command -v "$dep" &>/dev/null; then
      missing+=("$dep")
    fi
  done

  # 2. Si falta alguna, intentar instalarla
  if (( ${#missing[@]} )); then
    echo -e "${YELLOW}⚠️ Faltan las siguientes dependencias: ${missing[*]}${NC}"
    echo -e "${YELLOW}📦 Intentando instalar automáticamente...${NC}"

    # Actualizar la lista de paquetes
    echo -e "${YELLOW}🔄 Actualizando lista de paquetes (apt update)...${NC}"
    sudo apt-get update -y &>/dev/null

    # Instalar las dependencias faltantes
    if sudo apt-get install -y "${missing[@]}"; then
      echo -e "${GREEN}✅ Dependencias instaladas correctamente: ${missing[*]}${NC}"
    else
      echo -e "${RED}❌ Error al instalar las dependencias: ${missing[*]}. Por favor, instálalas manualmente.${NC}"
      exit 1
    fi
  else
    echo -e "${GREEN}✅ Todas las dependencias están instaladas.${NC}"
  fi
}

## === TESTING ===
function test_func() {
  app="FakeApp"
  echo -e "${GREEN}Funcion de test. No hace nada.${NC}"
  ## test: titulo  
  echo -e "${BLUE}${TITULO//\$app/$app}${NC}" && sleep 3
  ## test: no existe
  echo -e "${RED}${NOEXISTE//\$app/$app}${NC}" && sleep 3
  ## test: instalado
  echo -e "${GREEN}${INSTALADO//\$app/$app}${NC}" && sleep 3
  ## test: ya existe
  echo -e "${GREEN}${EXISTE//\$app/$app}${NC}" && sleep 3
  ## test:
  echo -e "${YELLOW}${EXISTE}${NC}" && sleep 3
}

## === Func Aplicaciones === 
function inst_docker() {
	app="Docker"
  echo -e "💬${BLUE}${TITULO//\$app/$app}${NC}"
  if ! command -v docker &> /dev/null; then
    echo -e "🚨 ${RED}${NOEXISTE//\$app/$app}${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    echo -e "✅ ${GREEN}${INSTALADO//\$app/$app}${NC}"
    rm -f get-docker.sh
  else
    version=$(docker version --format '{{.Server.Version}}')
    echo -e "✅ ${GREEN}${EXISTE//\$app/$app $version}${NC}"
  fi
  # Verifica si el usuario esta en el grupo docker
  if ! groups "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    echo -e "✅ ${YELLOW}Se agrego al usuario $USER al grupo docker. reiniciar sesion.${NC}"
  else
    echo -e "✅ ${GREEN}Tu usuario ya pertenece al grupo docker.${NC}"
  fi
}
function inst_kube() {
  echo -e "💬 ${BLUE}## Verificando Kubernetes ##${NC}"
  if ! command -v kubectl &> /dev/null; then
    echo -e "🚨 ${RED}kubectl no esta instalado${NC}"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
    echo -e "✅ ${GREEN}kubectl se instalo satisfactoriamente${NC}"
  else
    version=$(kubectl version --client=true | head -n 1 | awk '{print $3}')
    echo -e "✅ ${GREEN}kubectl $version ya esta instalado${NC}"
  fi
}
function inst_terra() {
  echo -e "💬 ${BLUE}## Verificando Terraform ##${NC}"
  if ! command -v terraform &> /dev/null; then
    echo -e "🚨 ${RED}terraform no está instalado${NC}"
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform -y
    echo -e "✅ ${GREEN} Terraform se instaló satisfactoriamente${NC}"
  else
    version=$(terraform -v | head -n 1 | awk '{print $2}')
    echo -e "✅ ${GREEN}Terraform $version ya está instalado${NC}"
  fi
}
function inst_minikube() {
  echo -e "💬 ${BLUE}## Verificando Minikube ##${NC}"
  if ! command -v minikube &> /dev/null; then
    echo -e "🚨 ${BLUE}Minikube no esta instalado${NC}"
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    echo -e "✅ ${GREEN} Minikube se instalo satisfactoriamente${NC}"
    rm -f minikube-linux-amd64
  else
    version=$(minikube version --short)
    echo -e "✅ ${GREEN}Minikube $version ya esta instalado${NC}"
  fi
}
function inst_argo() {
  echo -e "💬 ${BLUE}## Verificando ArgoCD ##${NC}"
  if ! command -v argo &> /dev/null; then
    echo -e "🚨 ${BLUE}ArgoCD no esta instalado${NC}"
    curl -sLO https://github.com/argoproj/argo/releases/latest/download/argo-linux-amd64.gz
    gunzip -f argo-linux-amd64.gz
    sudo mv argo-linux-amd64 /usr/local/bin/argo
    sudo chmod +x /usr/local/bin/argo
    echo -e "✅ ${GREEN} ArgoCD se instalo satisfactoriamente${NC}"
  else
    version=$(argo version --short | awk '{print $2}')
    echo -e "✅ ${GREEN}ArgoCD $version ya esta instalado${NC}"
  fi
}
function inst_helm() {
  echo -e "💬 ${BLUE}## Verificando Helm ##${NC}"
  if ! command -v helm &> /dev/null; then
    echo -e "🚨 ${RED}helm no esta instalado${NC}"
    local helm_script="/tmp/get_helm.sh"
    curl -fsSL -o "$helm_script" https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 "$helm_script"
    sudo "$helm_script"
    rm -f "$helm_script"
    echo -e "✅ ${GREEN}helm se instalo satisfactoriamente${NC}"
  else
    version=$(helm version --short)
    echo -e "✅ ${GREEN}Helm $version ya esta instalado${NC}"
  fi
}
function inst_azure() {
  echo -e "💬 ${BLUE}## Verificando Azure CLI ##${NC}"
  if ! command -v az &> /dev/null; then
    echo -e "🚨 ${RED}Azure CLI no esta instalado${NC}"
    sudo mkdir -p /etc/apt/keyrings
    curl -sLS https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg
    sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ jammy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list > /dev/null
    sudo apt update && sudo apt install -f azure-cli -y
    echo -e "✅ ${BLUE}Instalando kubelogin${NC}"
    sudo az aks install-cli
    echo -e "✅ ${GREEN}Azure CLI se instalo satisfactoriamente${NC}"
  else
    echo -e "✅ ${GREEN}Azure CLI ya esta instalado${NC}"
  fi
}
function inst_ghcli() {  
  echo -e "${BLUE}## Verificando GitHub CLI ##${NC}"
  if ! command -v gh &> /dev/null; then
    echo -e "🔴 ${RED}GitHub CLI no está instalado${NC}"
    out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg
    cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update && sudo apt install gh -y
    echo -e "🚀 ${GREEN}GitHub CLI se instaló satisfactoriamente${NC}"
  else
    version=$(gh version | head -n 1 | awk '{print $3}')
    echo -e "📣 ${GREEN}GitHub CLI $version ya está instalado${NC}"
  fi
}
function inst_awscli() {
  app="awscli"
  version=$(aws --version | awk '{print $1}')
  echo -e "${BLUE}${TITULO//\$app/$app}${NC}"
  if ! command -v aws &> /dev/null; then
    echo -e "${RED}${NOEXISTE//\$app/$app}${NC}"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip && sudo ./aws/install
    rm -rf ./aws && rm -f awscliv2.zip
    echo -e "${GREEN}${INSTALADO//\$app/$app}${NC}"
  else
    echo -e "${GREEN}${EXISTE//\$app/$app $version}${NC}"
  fi
}
function inst_lens() {
  app="Lens Desktop"
  echo -e "${BLUE}${TITULO//\$app/$app}${NC}"
  if ! type lens-desktop &> /dev/null; then
    echo -e "🔴 ${RED}${NOEXISTE//\$app/$app}${NC}"
    curl -fsSL https://downloads.k8slens.dev/keys/gpg | sudo gpg --dearmor -o /usr/share/keyrings/lens-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/lens-archive-keyring.gpg] https://downloads.k8slens.dev/apt/debian stable main" | sudo tee /etc/apt/sources.list.d/lens.list > /dev/null
    sudo apt update && sudo apt install lens -y
    echo -e "🚀 ${GREEN}${INSTALADO//\$app/$app}${NC}"
  else
    version=$(apt show lens 2>/dev/null | grep '^Version:' | awk '{print $2}')
    echo -e "📣 ${GREEN}${EXISTE//\$app/$app $version}${NC}"
  fi
}
function inst_code() {
  app="VSCode"
  version=$(code --version | head -1)
  echo -e "${BLUE}${TITULO//\$app/$app}${NC}"
  if command -v code &> /dev/null; then
    echo -e "${GREEN}${EXISTE//\$app/$app $version}${NC}"
  else
    echo -e "${RED}${NOEXISTE//\$app/$app}${NC}"
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg
    sudo apt update && sudo apt install code -y
    echo -e "${GREEN}${INSTALADO//\$app/$app}${NC}"
  fi
}
function inst_flatpak() {
  app="flatpak"
  echo -e "${BLUE}${TITULO//\$app/$app}${NC}"
  if command -v flatpak &> /dev/null; then
    version=$(flatpak --version)
    echo -e "${GREEN}${EXISTE//\$app/$app $version}${NC}"
  else
    echo -e "${RED}${NOEXISTE//\$app/$app}${NC}"
    sudo apt install flatpak -y
    sleep 5
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    echo -e "${GREEN}${INSTALADO//\$app/$app}${NC}"
  fi
}
function inst_eza() {
  app="eza"
  version=$(eza -v)
  echo -e "${BLUE}${TITULO//\$app/$app}${NC}"
  if command -v eza &> /dev/null; then
    echo -e "${GREEN}${EXISTE//\$app/$app $version}${NC}"
  else
    echo -e "${RED}${NOEXISTE//\$app/$app}${NC}"
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update && sudo apt install eza -y
    echo -e "${GREEN}${INSTALADO//\$app/$app}${NC}"
  fi
}

## === Func Instalacion aplicaciones base ===
function inst_coreapps() {
  echo -e "${GREEN}####${BLUE} Preparando el listado de aplicaciones CORE ${GREEN}####${NC}"
  sleep 2
  local file_path=""
  if command -v kwin &> /dev/null || command -v plasmashell &> /dev/null; then
    echo -e "${BLUE}Entorno de escritorio en uso es: ${GREEN}KDE${NC}"
    file_path="$PWD/source/k-programs_core.src"
  else
    echo -e "${RED}No se pudo detectar un entorno de escritorio compatible con este script.${NC}"
    return 0
  fi
  install_programs "$file_path"
}

## === func inst aplicaciones ===
function inst_apps() {
  echo -e "${GREEN}#### ${BLUE}Preparando el listado de aplicaciones${GREEN} ####${NC}"
  sleep 2
  local file_path=""
  if command -v kwin &> /dev/null || command -v plasmashell &> /dev/null; then
    echo -e "${BLUE}Entorno de escritorio en uso es: ${GREEN}KDE${NC}"
    file_path="$PWD/source/k-programs.src"
  else
    echo -e "${RED}No se pudo detectar un entorno de escritorio compatible con este script.${NC}"
    return 0
  fi
  install_programs "$file_path"
}

# === Instala programas desde un archivo (reutilizable) ===
function install_programs() {
  local file_path="$1"
  if [[ ! -f "$file_path" ]]; then
    echo -e "${RED}Archivo de programas no encontrado: $file_path${NC}"
    return 0
  fi
  echo -e "${YELLOW}Leyendo lista de programas de: $file_path${NC}"
  sleep 1
  local programs=()
  while IFS= read -r program || [[ -n "$program" ]]; do
    [[ -z "$program" || "$program" =~ ^# ]] && continue
    programs+=("$program")
  done < "$file_path"
  for program in "${programs[@]}"; do
    if dpkg -s "$program" &> /dev/null; then
      echo -e "${BLUE}El programa '$program' ya está instalado${NC}"
    else
      echo -e "${YELLOW}Instalando '$program'...${NC}"
      sudo apt-get install -y "$program"
      echo -e "${GREEN}'$program' se instaló satisfactoriamente${NC}"
    fi
  done
}
## === func inst aplicaciones para Server ===
function inst_server() {
  echo -e "${GREEN}### ${BLUE}Instalando SNAP Apps ${GREEN}###${NC}"
  local script_dir="$(dirname "$0")"
  local file_path="$script_dir/source/server.src"
  sleep 2
  programs=($(cat "$file_path"))
  for program in "${programs[@]}"; do
    if dpkg -s "$program" &> /dev/null; then
      echo -e "${BLUE}El programa '$program' ya esta instalado${NC}"
    else
        sudo apt install -y "$program"
        if [ $? -ne 0 ]; then
          echo -e "${RED}Error al instalar '$program'.${NC}"
          return 0
        fi
        echo -e "${GREEN}'$program' Se instalo satisfactoriamente${NC}"
    fi
  done
}

## === clean & update ===
function os_update_clean() {
  echo -e "${GREEN}### 🚀${BLUE}Actualizando Debian ${GREEN} 🚀 ###${NC}"
  sleep 3
  sudo apt-get -y update && sudo apt-get install --fix-missing -y && sudo apt -y upgrade

  echo -e "${GREEN}### ♻️ ${BLUE}Limpiando Debian ${GREEN} ♻️ ###${NC}"
  sleep 3
  sudo apt-get install -f && sudo apt-get autoremove -y && sudo apt-get autoclean && sudo apt-get clean
}

function inst_antigen() {
  if [ ! -f "$HOME/.oh-my-zsh/antigen.zsh" ]; then
    echo -e "${BLUE}Instalando Antigen...${NC}"
    curl -L git.io/antigen > "$HOME/.oh-my-zsh/antigen.zsh"
    echo -e "${GREEN}Antigen instalado correctamente...${NC}"
  else
    echo -e "${GREEN}Antigen ya esta instalado.${NC}"
  fi
}
function inst_ohmyzsh() {
  app="OhMyZSH"
  version="N/A"
  echo -e "${BLUE}## Verificando $app${NC}"
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo -e "${RED}${NOEXISTE//\$app/$app}${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
      echo -e "${GREEN}${INSTALADO//\$app/$app}${NC}"
    else
      echo -e "${RED}Error critico: No se pudo instalar $app. Revisa tu conexion a internet o instala manualmente.${NC}"
      exit 2
    fi
  else
    echo -e "${GREEN} $app ya esta instalado ${NC}"
  fi
}

## funciones agurpadas ##
function func_inst_devops() {
  inst_kube
  inst_minikube
  inst_terra
  inst_helm
  inst_azure
  inst_argo
  inst_ghcli
  inst_lens
  # Agregar mas funciones
}
function func_inst_desktop() {
  inst_flatpak
  inst_apps
  inst_code
  inst_docker
  # Agregar mas funciones
}

## === MENU PRINCIPAL ===
function print_menu() {
  echo -e "${BLUE}### Seleccione una opcion: ${NC}"
  echo -e "${GREEN}1) Instalar OhMyZSH ${NC}"
  echo -e "${GREEN}2) Instalar aplicacion BASE ${NC}"
  echo -e "${GREEN}3) Instalar aplicaciones Devops ${NC}"
  echo -e "${GREEN}4) Instalar aplicaciones Desktop ${NC}"
  echo -e "${GREEN}5) Test ${NC}"
  echo -e "${GREEN}0) Salir ${NC}"
}

function handle_option() {
  local option="$1"
  case $option in
    1) inst_ohmyzsh ;;
    2) inst_coreapps ; os_update_clean ;;
    3) func_inst_devops ; os_update_clean ;;
    4) func_inst_desktop ; os_update_clean ;;
    5) test_func ;;
    0) echo -e "${YELLOW}Finalizando...${NC}"; exit 0 ;;
    *) echo -e "${RED} Opcion no valida, intenta de nuevo ${NC}" ;;
  esac
}

function show_menu() {
  # Ayuda rapida
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    grep '^#' "$0" | head -20 | sed 's/^# //;s/^#//'
    exit 0
  fi
  check_dependencies
  local option
  while true; do
    clear
    print_menu
    read -p "Elige una opcion [0-7]: " option
    handle_option "$option"
    sleep 1
  done
}


# Call menu function
show_menu

#!/bin/bash
#
# Print banner art.

#######################################
# Print a board. 
# Globals:
#   BG_BROWN
#   NC
#   WHITE
#   CYAN_LIGHT
#   RED
#   GREEN
#   YELLOW
# Arguments:
#   None
#######################################
print_banner() {
  clear


printf "${GREEN}";
printf "######   ######   ######   ##  ##   #####    ######   ######   ##  ##   ######   ######\n";
printf "##  ##     ##     ##       ### ##   ##  ##   ##       ##  ##   ##  ##   ##  ##     ##\n";
printf "##  ##     ##     ####     ######   ##  ##   ####     ##       ######   ##  ##     ##\n";
printf "######     ##     ##       ## ###   ##  ##   ##       ##       ##  ##   ######     ##\n";
printf "##  ##     ##     ##       ##  ##   ##  ##   ##       ##  ##   ##  ##   ##  ##     ##\n";
printf "##  ##     ##     ######   ##  ##   #####    ######   ######   ##  ##   ##  ##     ##\n";

printf "\n"

printf "Solicite suporte: https://github.com/authcomtecnologia/authchat\n"
printf "Contrate nossos servidores: https://github.com/authcomtecnologia/authchat\n"
printf "2025 @ Todos os direitos reservados a https://github.com/authcomtecnologia/authchat\n"



  printf "${NC}";

  printf "\n"
}

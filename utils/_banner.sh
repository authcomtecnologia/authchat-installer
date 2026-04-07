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

printf "${CYAN_LIGHT}";
printf " ###    ##  ##  ######  ##  ##   ####   ##  ##   ###    ######\n";
printf "##  ##  ##  ##    ##    ##  ##  ##  ##  ##  ##  ##  ##    ##  \n";
printf "##  ##  ##  ##    ##    ######  ##      ######  ##  ##    ##  \n";
printf "######  ##  ##    ##    ##  ##  ##      ##  ##  ######    ##  \n";
printf "##  ##  ##  ##    ##    ##  ##  ##  ##  ##  ##  ##  ##    ##  \n";
printf "##  ##   ####     ##    ##  ##   ####   ##  ##  ##  ##    ##  \n";

printf "\n"

printf "Solicite suporte: https://suporte.authcom.com.br\n"
printf "Contrate nossos servidores: https://authcom.com.br\n"
printf "2025 @ Todos os direitos reservados a https://authcom.com.br\n"

  printf "${NC}";

  printf "\n"
}

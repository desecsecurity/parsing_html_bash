#!/usr/bin/env bash

################################################################################
# Titulo    : Parsing_HTML_Bash                                                #
# Versao    : 1.5                                                              #
# Data      : 16/10/2019                                                       #
# Homepage  : https://www.desecsecurity.com                                    #
# Tested on : macOS/Linux                                                      #
################################################################################

# ==============================================================================
# Constantes
# ==============================================================================

# Constantes para facilitar a utilização das cores.
RED='\033[31;1m'
GREEN='\033[32;1m'
BLUE='\033[34;1m'
YELLOW='\033[33;1m'
END='\033[m'

# Constantes criadas utilizando os valores dos argumentos
# passados, para evitando a perda dos valores.
ARG01=$1
ARG02=$2

# Constante utilizada para guadar a versão do programa.
VERSION='1.5'

# ==============================================================================
# Banner do programa
# ==============================================================================

__Banner__() {
    echo
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}#                                                                              #${END}"
    echo -e "${YELLOW}#                             PARSING HTML                                     #${END}"
    echo -e "${YELLOW}#                   Desec Security - Ricardo Longatto                          #${END}"
    echo -e "${YELLOW}#                             Version $VERSION                                      #${END}"
    echo -e "${YELLOW}#                                                                              #${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo
    echo -e "Usage   : ${GREEN}$0${END} [OPTION] [URL]"
    echo -e "Example : ${GREEN}$0${END} www.site.com"
    echo
    echo -e "Try ${GREEN}$0 -h${END} for more options."
    echo
}

# ==============================================================================
# Menu de ajuda
# ==============================================================================

__Help__() {
    printf "\
    \nNAME\n \
    \t$0 - Software para procura de links em páginas web.\n \
    \nSYNOPSIS\n \
    \t$0 [Options] [URL]\n \
    \nDESCRIPTION\n \
    \tO $0 é usado para procurar links em páginas web e verificar se existem \n \
    \thosts vivos.\n \
    \nOPTIONS\n \
    \t-h, --help\n \
    \t\tMostra o menu de ajuda.\n\n \
    \t-v, --version\n \
    \t\tMostra a versão do programa.\n\n \
    \t-f, --file\n \
    \t\tProcura links no arquivo informado.\n\n \
    \t\tEx: $0 -f file.txt\n\n"
}

# ==============================================================================
# Verificando dependências
# ==============================================================================

__Verification__() {
    # Verificando as dependências.
    if ! [[ -e /usr/bin/wget ]]; then
        printf "\nFaltando programa ${RED}wget${END} para funcionar.\n"
        exit 1
    elif ! [[ -e /usr/bin/host ]]; then
        printf "\nFaltando programa ${RED}host${END} para funcionar.\n"
        exit 1
    fi

    # Verificando se não foi passado argumentos.
    if [[ "$ARG01" == "" ]]; then
        __Banner__
        exit 1
    fi
}

# ==============================================================================
# Limpando arquivos temporários
# ==============================================================================

__Clear__() {
    rm -rf /tmp/1 &>/dev/null
}

# ==============================================================================
# Fazendo download da página
# ==============================================================================

__Download__() {
    # É criado e utilizado um diretório em /tmp, para não sujar o sistema do
    # usuário.
    __Clear__
    mkdir /tmp/1 && cd /tmp/1

    printf "\n${GREEN}[+] Download do site...${END}\n\n"
    if wget -q -c --show-progress $ARG01 -O FILE; then
        printf "\n${GREEN}[+] Download completo!${END}\n\n"
    else
        printf "\n${RED}[+] Falha no download!${END}\n\n"
        exit 1
    fi
}

# ==============================================================================
# Copiando arquivo para diretório temporario.
# ==============================================================================

__OpenFile__() {
    __Clear__
    mkdir /tmp/1
    cp $ARG02 /tmp/1/FILE
    cd /tmp/1
}

# ==============================================================================
# Filtrando links
# ==============================================================================

__FindLinks__() {
    # Quebranco as linhas para melhorar a seleção dos links, onde
    # se encontram as palavras 'href' e 'action'.
    sed -i "s/ /\n/g" FILE
    grep -E "(href=|action=)" FILE > .tmp1

    # Capturando o conteudo entre aspas e apostrofos.
    grep -oh '"[^"]*"' .tmp1 > .tmp2
    grep -oh "'[^']*'" .tmp1 >> .tmp2

    # Removendo as aspas e apostrofos.
    sed -i 's/"//g' .tmp2
    sed -i "s/'//g" .tmp2

    # Captura apenas as linhas que contenham pontos, e remove as
    # semelhantes.
    grep "\." .tmp2 | sort -u > links
}

# ==============================================================================
# Filtrando hosts
# ==============================================================================

__FindHosts__() {
    # Quebrando as URLs para facilitar a procurar de links no corpo da URL.
    cp links links2
    sed -i "s/?/\n/g
            s/\/\/\//\n\/\//g" links2

    # Utilizando expressões regulares para procurar os links simples.
    grep -oh "//[^/]*/" links2 > .tmp10
    grep -oh "//[^/]*" links2 >> .tmp10
    grep -oh "www.*\.br" links2 >> .tmp10
    grep -oh "www.*\.net" links2 >> .tmp10
    grep -oh "www.*\.org[^\.br]" links2 >> .tmp10
    grep -oh "www.*\.com[^\.br]" links2 >> .tmp10

    # Removendo as barras e filtrando as linhas com pontos.
    sed -i "s/\///g" .tmp10
    grep "\." .tmp10 | sort -u > hosts
}

# ==============================================================================
# Verificando e mostrando Hosts ativos
# ==============================================================================

__LiveHosts__() {
    echo
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}#                            Hosts ativos                                      #${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo

    # Como será a uma das ultimas funções executadas, seu resultado será
    # mostrado na tela ao mesmo tempo.
     while read linha; do
        host $linha 2>/dev/null | grep "has address" | awk '{print $4 "\t\t" $1}'
     done < hosts
}

# ==============================================================================
# Mostrando links encontrados
# ==============================================================================

__ShowLinks__() {
    echo
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}#                         Links encontrados.                                   #${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo
    while read linha; do
        echo $linha
    done < links
}

# ==============================================================================
# Mostrando Hosts encontrados
# ==============================================================================

__ShowHosts__() {
    echo
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}#                         Hosts encontrados.                                   #${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo
    while read linha; do
        echo $linha
    done < hosts
}

# ==============================================================================
# Mostrando quantidade de links e Hosts encontrados.
# ==============================================================================

__ShowResume__() {
    printf "\n${YELLOW}================================================================================${END}\n\n"
    printf "Found :\t" ; wc -l links
    printf "\t" ; wc -l hosts
}

# ==============================================================================
# Função principal do programa
# ==============================================================================

__Main__() {
    __Verification__

    case $ARG01 in
        "-v"|"--version") printf "\nVersion: $VERSION\n"
              exit 0
        ;;
        "-h"|"--help") __Help__
              exit 0
        ;;
        "-f"|"--file") __OpenFile__
              __FindLinks__
              __ShowLinks__
              __FindHosts__
              __ShowHosts__
              __LiveHosts__
              __ShowResume__
              __Clear__
        ;;
        *) __Download__
           __FindLinks__
           __ShowLinks__
           __FindHosts__
           __ShowHosts__
           __LiveHosts__
           __ShowResume__
           __Clear__
        ;;
    esac
}

# ==============================================================================
# Inicio do programa
# ==============================================================================

__Main__

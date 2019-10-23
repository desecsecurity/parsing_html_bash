#!/usr/bin/env bash

################################################################################
# Titulo    : Parsing_HTML_Bash                                                #
# Versao    : 1.2                                                              #
# Data      : 16/10/2019                                                       #
# Homepage  : https://www.desecsecurity.com                                    #
# Tested on : macOS/Linux                                                      #
################################################################################

# ==============================================================================
# Constantes
# ==============================================================================

RED='\033[31;1m'
GREEN='\033[32;1m'
BLUE='\033[34;1m'
YELLOW='\033[33;1m'
END='\033[m'

ARG01=$1
ARG02=$2

VERSION='1.2'

# ==============================================================================
# Banner do programa
# ==============================================================================

__Banner__() {
    echo
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}|->                                                                          <-|${END}"
    echo -e "${YELLOW}|->                           PARSING HTML                                   <-|${END}"
    echo -e "${YELLOW}|->                 Desec Security - Ricardo Longatto                        <-|${END}"
    echo -e "${YELLOW}|->                                                                          <-|${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo
    echo "Usage: $0 [OPTION] [URL]"
    echo "Ex: $0 www.site.com"
    echo
    echo "Try $0 -h for more options."
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
    \t-h) - Mostra o menu de ajuda.\n\n \
    \t-v) - Mostra a versão do programa.\n\n \
    \t-l) - Mostra apenas os links encontrados.\n\n \
    \t-o) - Procura links em um arquivo.\n\n"
}

# ==============================================================================
# Verificando dependências
# ==============================================================================

__Verification__() {
    # Verificando as dependências.
    if ! [[ -e /usr/bin/wget ]]; then
        printf "\nFaltando programa ${RED}wget${END} para funcionar.\n"
        exit 1
    elif ! [[ -e /usr/bin/curl ]]; then
        printf "\nFaltando programa ${RED}curl${END} para funcionar.\n"
        exit 1
    fi

    # Verificando se não foi passado argumentos.
    if [ "$ARG01" == "" ]; then
        __Banner__
        exit 1
    fi
}

# ==============================================================================
# Fazendo download da página
# ==============================================================================

__Download__() {
    rm -rf /tmp/1 &>/dev/null
    mkdir /tmp/1 && cd /tmp/1
    wget -q -c --show-progress $ARG01
    mv index.html $ARG01.html
}

# ==============================================================================
# Filtrando links
# ==============================================================================

__FindLinks__() {
    grep "href" $ARG01.html | cut -d "/" -f 3 | grep "\." | cut -d '"' -f 1 | grep -v "<l" \
    | grep -v "www." | sort -u > $ARG01.hosts

}

# ==============================================================================
# Mostrando hosts encontrados
# ==============================================================================

__FindHosts__() {
    echo
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}|->                       Buscando Hosts...                                  <-|${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo

    # Para cada HOST encontrado, checa o status code de retorno
    for i in $(cat "$ARG01.hosts")
    do
        status_code=$(curl -m 2 -o /dev/null -s -w "%{http_code}\n" $i)   # -m 2 = timeout (2 segundos)
        echo -e "$i [CODE : ${status_code}]"
    done
}

# ==============================================================================
# Verificando Hosts ativos
# ==============================================================================

__LiveHosts__() {
    echo
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}|->                       Resolvendo Hosts...                                <-|${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo

    for h in $(cat "$ARG01.hosts");do host $h;done | grep "has address" > $ARG01.ip
    cat $ARG01.ip
}

__Main__() {
    __Verification__

    case $ARG01 in
        "-v") printf "\nVersion: $VERSION\n"
              exit 0
        ;;
        "-h") __Help__
              exit 0
        ;;
        "-l") printf "\nEm construção :)\n"
              exit 0
        ;;
        *) __Download__
           __FindLinks__
           __FindHosts__
           __LiveHosts__
        ;;
    esac
}


__Main__

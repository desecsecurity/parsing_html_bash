#!/usr/bin/env bash

################################################################################
# Titulo    : Parsing_HTML_Bash                                                #
# Versao    : 1.3                                                              #
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
VERSION='1.3'

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
    \t-v) - Mostra a versão do programa.\n\n"
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
    if [ "$ARG01" == "" ]; then
        __Banner__
        exit 1
    fi
}

# ==============================================================================
# Fazendo download da página
# ==============================================================================

__Download__() {
    # É criado e utilizado um diretório em /tmp, para não sujar o sistema do
    # usuário.
    rm -rf /tmp/1 &>/dev/null
    mkdir /tmp/1 && cd /tmp/1

    printf "\n${GREEN}[+] Download do site...${END}\n\n"
    wget -q -c --show-progress $ARG01 || \
    printf "\n${RED}[+] Erro no download do site${END}\n\n"
}

# ==============================================================================
# Filtrando links
# ==============================================================================

__FindLinks__() {
    printf "\n${RED}[+] Filtrando Links...${END}\n"

    # Quebranco as linhas para melhorar a seleção dos links, onde
    # se encontram as palavras 'href' e 'action'.
    sed -i "s/ /\n/g" index.html
    grep -E "(href=|action=)" index.html > .tmp1

    # Capturando o conteudo entre aspas e apostrofos.
    grep -oh '"[^"]*"' .tmp1 > .tmp2
    grep -oh "'[^']*'" .tmp1 >> .tmp2

    # Removendo as aspas e apostrofos.
    sed -i 's/"//g' .tmp2
    sed -i "s/'//g" .tmp2

    # Captura apeas as linhas que contenham pontos, e remove as
    # semelhantes.
    grep "\." .tmp2 | sort | uniq > links
}

# ==============================================================================
# Filtrando hosts
# ==============================================================================

__FindHosts__() {
    printf "\n${RED}[+] Filtrando Hosts...${END}\n"

    # Quebrando as URLs para facilitar a procurar links no corpo da URL.
    cp links links2
    sed -i "s/?/\n/g" links2

    # Utilizando expressões regulares para utilizar os links simples.
    grep -oh "//[^/]*/" links2 > .tmp10
    grep -oh "//[^/]*" links2 >> .tmp10
    grep -oh "www.*\.br" links2 >> .tmp10
    grep -oh "www.*\.net" links2 >> .tmp10
    grep -oh "www.*\.org[^\.br]" links2 >> .tmp10
    grep -oh "www.*\.com[^\.br]" links2 >> .tmp10

    # Removendo as barras e filtrando as linhas com pontos.
    sed -i "s/\///g" .tmp10
    grep "\." .tmp10 | sort | uniq > hosts
}

# ==============================================================================
# Verificando Hosts ativos
# ==============================================================================

__LiveHosts__() {
     printf "\n${RED}[+] Procurando Hosts ativos...${END}\n"

     while read linha; do
        host $linha 2>/dev/null | grep "has address" | sed "s/has address/ ----------------- /g" >> live-hosts
     done < hosts
}

# ==============================================================================
# Mostrando links encontrados
# ==============================================================================

__ShowLinks__() {
    echo
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}|->                       Links encontrados.                                 <-|${END}"
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
    echo -e "${YELLOW}|->                       Hosts encontrados.                                 <-|${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo
    while read linha; do
        echo $linha
    done < hosts
}

# ==============================================================================
# Mostrando Hosts ativos
# ==============================================================================

__ShowLiveHosts__() {
    echo
    echo -e "${YELLOW}################################################################################${END}"
    echo -e "${YELLOW}|->                          Hosts ativos                                     <-|${END}"
    echo -e "${YELLOW}################################################################################${END}"
    echo
    while read linha; do
        echo $linha
    done < live-hosts
}

# ==============================================================================
# Função principal do programa
# ==============================================================================

__Main__() {
    __Verification__

    case $ARG01 in
        "-v") printf "\nVersion: $VERSION\n"
              exit 0
        ;;
        "-h") __Help__
              exit 0
        ;;
        *) __Download__
           __FindLinks__
           __FindHosts__
           __LiveHosts__
           __ShowLinks__
           __ShowHosts__
           __ShowLiveHosts__
        ;;
    esac
}

# ==============================================================================
# Inicio do programa
# ==============================================================================

__Main__

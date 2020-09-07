#!/usr/bin/env bash

################################################################################
# Titulo    : Parsing HTML                                                     #
# Versao    : 1.9                                                              #
# Data      : 16/10/2019                                                       #
# Homepage  : https://www.desecsecurity.com                                    #
# Tested on : MacOS/Linux                                                      #
# -----------------------------------------------------------------------------#
# Descrição:                                                                   #
#   Esse programa tem a função de procurar todos os links que podem ser        #
#   considerados uteis para analise, e verificar quais deles estão ativos.     #
#                                                                              #
################################################################################

# ==============================================================================
# Constantes
# ==============================================================================

# Constantes para facilitar a utilização das cores.
RED='\033[31;1m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
RED_BLINK='\033[31;5;1m'
END='\033[m'

# Constantes criadas utilizando os valores dos argumentos
# passados, para evitando a perda dos valores.
ARG01="${1}"
ARG02="${2}"

# Constante utilizada para guadar a versão do programa.
VERSION='1.9'

# Função chamada quando cancelar o programa com [Ctrl]+[c]
trap __Ctrl_c__ INT

# ==============================================================================
# Função chamada ao pressionar as teclas Ctrl+c
# ==============================================================================

__Ctrl_c__() {
    __Clear__
    echo -e "\n${RED_BLINK}!!! Ação abortada !!!${END}\n\n"
    exit 1
}

# ==============================================================================
#                           Banner do programa
# ------------------------------------------------------------------------------
# Função responsável por apenas mostrar o banner do programa junto com algumas
# opções básicas.
# ==============================================================================

__Banner__() {
    echo -e "
        ${YELLOW}
        ################################################################################
        #                                                                              #
        #                             PARSING HTML                                     #
        #                            Desec Security                                    #
        #                             Version ${VERSION}                                      #
        #                                                                              #
        ################################################################################
        ${END}

        Usage   : ${GREEN}${0}${END} [OPTION] [URL]
        Example : ${GREEN}${0}${END} www.site.com

        Try ${GREEN}${0} -h${END} for more options."
}

# ==============================================================================
#                                Menu de ajuda
# ------------------------------------------------------------------------------
# Função responsável por explicar para o usuário o propósito do programa e como
# ele funciona, mostrando todas as suas opções.
# ==============================================================================

__Help__() {
    echo -e "
    NAME
        ${0} - Software para procura de links em páginas web.

    SYNOPSIS
        ${0} [Options] [URL]

    DESCRIPTION
        O ${0} é usado para procurar links em páginas web e verificar se existem
        hosts vivos.

    OPTIONS
        -h, --help
            Mostra o menu de ajuda.

        -v, --version
            Mostra a versão do programa.

        -f, --file
            Procura links no arquivo informado.
                Ex: ${0} -f file.txt"
}

# ==============================================================================
#                           Verificação básica
# ------------------------------------------------------------------------------
# Função responsável por verificar todos os requisitos básicos, para o
# funcionamento do programa, como verificando se os programas e scripts de
# terceiros estão instalados e se os argumentos foram passados corretamente.
# ==============================================================================

__Verification__() {
    # Verificando as dependências.
    if ! [[ -e /usr/bin/wget ]]; then
        echo -e "\nFaltando programa ${RED}wget${END} para funcionar.\n"
        exit 1
    elif ! [[ -e /usr/bin/host ]]; then
        echo -e "\nFaltando programa ${RED}host${END} para funcionar.\n"
        exit 1
    fi

    # Verificando se não foi passado argumentos.
    if [[ "${ARG01}" == "" ]]; then
        __Banner__
        exit 1
    fi
}

# ==============================================================================
#                       Limpando arquivos temporários
# ------------------------------------------------------------------------------
# Função para apagar todos os arquivos temporários criados durante a execução
# do programa.
# ==============================================================================

__Clear__() {
    rm -rf /tmp/"${ARG01}" &>/dev/null
    rm -rf /tmp/tempfile &>/dev/null
}

# ==============================================================================
#                           Download da página
# ------------------------------------------------------------------------------
# Função responsável por criar o diretório para amazenar o download da página
# index do site, e arquivos que serão criados posteriomente.
# ==============================================================================

__Download__() {
    # É criado e utilizado um diretório em /tmp, para não sujar o sistema do
    # usuário.
    __Clear__

    mkdir /tmp/"${ARG01}" && cd /tmp/"${ARG01}"

    echo -e "\n${GREEN}[+] Download do site...${END}\n\n"
    if wget -q -c --show-progress "${ARG01}" -O FILE;then
        echo -e "\n${GREEN}[+] Download completo!${END}\n\n"
    else
        echo -e "\n${RED}[+] Falha no download!${END}\n\n"
        exit 1
    fi
}

# ==============================================================================
#                       Copiando arquivo da opção -f
# ------------------------------------------------------------------------------
# Função responsável por verificar se o nome do arquivo foi informado e se ele
# existe, caso exista será criado um diretório temporário em /tmp e copiar o
# arquivo para lá, mudando o seu nome para FILE.
# ==============================================================================

__OpenFile__() {
    if [[ "${ARG02}" == "" ]]; then
        echo -e "\n${RED}!!! Necessário informar nome do arquivo !!!${END}\n"
        exit 1
    elif ! [[ -e "${ARG02}" ]]; then
        echo -e "\n${RED}!!! Arquivo não encontrado !!!${END}\n"
        exit 1
    fi

    __Clear__

    mkdir /tmp/tempfile
    cp "${ARG02}" /tmp/tempfile/FILE
    cd /tmp/tempfile
}

# ==============================================================================
#                               Filtrando links
# ------------------------------------------------------------------------------
# Função responsável por capturar todos os links completos contidos na página
# informada e salvalos no arquivo "links"
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
#                            Filtrando hosts
# ------------------------------------------------------------------------------
# Função responsável por criar uma cópia do arquivo "links" gerado pela função
# __FindLinks__, para quebrar as urls e selecionando todos os links simples
# contidos no arquivo.
# ==============================================================================

__FindHosts__() {
    # Quebrando as URLs para facilitar a procurar de links no corpo da URL.
    cp links links2
    sed -i "s/?/\n/g
            s/\/\/\//\n\/\//g" links2

    # Utilizando expressões regulares para procurar os links simples.
    grep -oh "//[^/]*/" links2 > .tmp10
    grep -oh "//[^/]*" links2 >> .tmp10
    grep -oh "ww.*\.br" links2 >> .tmp10
    grep -oh "ww.*\.net" links2 >> .tmp10
    grep -oh "ww.*\.gov" links2 >> .tmp10
    grep -oh "ww.*\.org[^.]" links2 >> .tmp10
    grep -oh "ww.*\.com[^.]" links2 >> .tmp10

    # Removendo as barras e filtrando as linhas com pontos.
    sed -i "s/\///g" .tmp10
    grep "\." .tmp10 | sort -u > hosts
}

# ==============================================================================
# Verificando e mostrando Hosts ativos
# ==============================================================================

__LiveHosts__() {
    echo -e "${YELLOW}
################################################################################
#                            Hosts ativos                                      #
################################################################################
${END}"

    # Como será uma das ultimas funções executadas, seu resultado será
    # mostrado na tela ao mesmo tempo.
     while read -r linha; do
        host "${linha}" 2>/dev/null | grep "has address" | awk '{print $4 "\t\t" $1}'
     done < hosts
}

# ==============================================================================
# Mostrando links encontrados
# ==============================================================================

__ShowLinks__() {
    echo -e "${YELLOW}
################################################################################
#                         Links encontrados.                                   #
################################################################################
${END}"

    while read -r linha; do
        echo "${linha}"
    done < links
}

# ==============================================================================
# Mostrando Hosts encontrados
# ==============================================================================

__ShowHosts__() {
    echo -e "${YELLOW}
################################################################################
#                         Hosts encontrados.                                   #
################################################################################
${END}"

    while read -r linha; do
        echo "${linha}"
    done < hosts
}

# ==============================================================================
# Mostrando quantidade de links e Hosts encontrados.
# ==============================================================================

__ShowResume__() {
    echo -e "
${YELLOW}================================================================================${END}
Found :
        $(wc -l links)
        $(wc -l hosts)
${YELLOW}================================================================================${END}"
}

# ==============================================================================
# Função principal do programa
# ==============================================================================

__Main__() {
    __Verification__

    case "${ARG01}" in
        "-v"|"--version")
              echo -e "\nVersion: ${VERSION}\n"
              exit 0
        ;;
        "-h"|"--help")
              __Help__
              exit 0
        ;;
        "-f"|"--file")
              __OpenFile__
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

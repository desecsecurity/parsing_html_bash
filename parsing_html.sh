#!/bin/bash
# Titulo: Parsing_HTML_Bash 
# Versao: 1.0 
# Data: 14/10/2019 
# Homepage: https://www.desecsecurity.com
# Tested on: macOS/Linux

if [ "$1" == "" ]
then
echo -e "\033[1;33m#########################################\033[0m"
echo -e "\033[40;1;33m|->           PARSING HTML            <-|\033[0m"
echo -e "\033[40;1;33m|-> Desec Security - Ricardo Longatto <-|\033[0m"
echo -e "\033[40;1;33m|-> $0 www.alvo.com.br <-|\033[0m"
echo -e "\033[1;33m#########################################\033[0m"
else
wget -q $1
mv index.html $1.html
grep "href" $1.html | cut -d "/" -f 3 | grep "\." | cut -d '"' -f 1 | grep -v "<l" | grep -v "www." | sort -u > $1.hosts
for h in $(cat "$1.hosts");do host $h;done | grep "has address" > $1.ip
echo -e "\033[1;33m#############################################################\033[0m"
echo -e "\033[40;1;33m|->                 Buscando Hosts...                     <-|\033[0m"
echo -e "\033[1;33m#############################################################\033[0m"
cat $1.hosts
echo -e "\033[1;33m#############################################################\033[0m"
echo -e "\033[40;1;33m|->                 Resolvendo Hosts...                   <-|\033[0m"
echo -e "\033[1;33m#############################################################\033[0m"
cat $1.ip
fi

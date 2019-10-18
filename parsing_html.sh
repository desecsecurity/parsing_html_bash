#!/bin/bash
# Titulo: Parsing_HTML_Bash 
# Versao: 1.1 
# Data: 14/10/2019 
# Atualizado: 17/10/2019
# Homepage: https://www.desecsecurity.com
# Git: https://github.com/desecsecurity/parsing_html_bash
# Tested on: macOS/Linux

OKBLUE='\033[94m'
OKRED='\033[91m'
OKGREEN='\033[92m'
OKORANGE='\033[93m'
RESET='\e[0m'

if [ "$1" == "" ]
then
	echo -e "\033[1;33m#########################################\033[0m"
	echo -e "\033[40;1;33m|->           PARSING HTML            <-|\033[0m"
	echo -e "\033[40;1;33m|-> Desec Security - Ricardo Longatto <-|\033[0m"
	echo -e "\033[40;1;33m|-> $0 www.alvo.com.br <-|\033[0m"
	echo -e "\033[1;33m#########################################\033[0m"
	exit 1
else
	# banner
	echo ""
    echo -e "$OKRED    ____  ___    ____  _____ _____   ________   __  __________  _____$RESET ";
	echo -e "$OKRED   / __ \/   |  / __ \/ ___//  _/ | / / ____/  / / / /_  __/  |/  / / $RESET";
	echo -e "$OKRED  / /_/ / /| | / /_/ /\__ \ / //  |/ / / __   / /_/ / / / / /|_/ / /  $RESET";
	echo -e "$OKRED / ____/ ___ |/ _, _/___/ // // /|  / /_/ /  / __  / / / / /  / / /___$RESET";
	echo -e "$OKRED/_/   /_/  |_/_/ |_|/____/___/_/ |_/\____/  /_/ /_/ /_/ /_/  /_/_____/$RESET";
	echo -e "$OKRED                                                                      $RESET";
	echo -e "$RESET"
	echo -e "$OKORANGE + -- --=[https://www.desecsecurity.com$RESET"
	echo ""
	wget -q $1
	mv index.html $1.html
	#grep "href" $1.html | cut -d "/" -f 3 | grep "\." | cut -d '"' -f 1 | grep -v "<l" | grep -v "www." | sort -u > $1.hosts
	grep "href" $1.html | grep -oE '(http|https)://(.*).' | cut -d "/" -f 3 | grep "\." | cut -d '"' -f 1 | grep -v "<l" | grep -v "www." | grep -v ":" | sort -u > $1.hosts
	#for h in $(cat "$1.hosts");do host $h;done | grep "has address" > $1.ip
	echo -e "\033[1;33m#############################################################\033[0m"
	echo -e "\033[40;1;33m|->                 Buscando Hosts...                     <-|\033[0m"
	echo -e "\033[1;33m#############################################################\033[0m"
	cat $1.hosts
	echo -e "\033[1;33m#############################################################\033[0m"
	echo -e "\033[40;1;33m|->                 Resolvendo Hosts...                   <-|\033[0m"
	echo -e "\033[1;33m#############################################################\033[0m"
	#cat $1.ip
	n="1"
    for h in $(cat "$1.hosts")
    do
        # salva retorno do comando hosts em arquivo temporario
        host -t A -W 3 $h > $$.tmp
        # verifica se o arquivo tem mais de uma linha
        if [ $(cat $$.tmp | wc -l) -gt 1 ]; then
        	# entra se tiver mais de uma linha
            if [ $(cat $$.tmp| grep alias | wc -l) -ge 1 ]; then
        		# mais de uma linha e com alias
				ip=$(tail -1 $$.tmp | cut -f4 -d" ")
				alias=$(head -1 $$.tmp | cut -f6 -d" ")
				url=$(head -1 $$.tmp | cut -f1 -d" ")
        		echo "[$n] $url é um alias para $alias - $ip"    		
           		#echo "[$n]" $h " - " $(echo $ip | cut -d" " -f4)
           		n=$[$n+1]  	
           	else
           		# mais de uma linha e nao tem alias
           		# laço para imprimir os outros ips
           		#echo "mais de uma linha e nao tem alias"
           		ip=" "
       			for count in $(seq 1 $(cat $$.tmp | wc -l)); do
                	linha=$(sed "$count!d" $$.tmp)
                	#echo "linha= " $linha
                    ip[$count]=$(echo $linha| cut -f4 -d" ")
                done
                url=$(head -1 $$.tmp | cut -f1 -d" ")
                echo -n "[$n] $url - " ; echo ${ip[*]}
                n=$[$n+1]
           	fi
        else
           	#echo "so tem uma linha"
    		ip=$(tail -1 $$.tmp | cut -f4 -d" ")
			url=$(tail -1 $$.tmp | cut -f1 -d" ")
	        echo "[$n] $url - $ip"
           	n=$[$n+1]
        fi
    done
	echo -e "\033[1;33m#############################################################\033[0m"
fi
rm $$.tmp
exit 0
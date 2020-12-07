#!/bin/bash

# Trabalho realizado por:
#   João António Assis Reis, 98474, P1
#   Ricardo Manuel Batista Rodriguez, 98388, P1

cd /proc

declare -a processID                                    # declaração de arrays 
declare -a infoProcess  
declare -a allRchar
declare -a allWchar

numProcess="null"
reverse=0                                               # reverse está "desativado", caso o utilizador "ative" (-r), esta variável passa a ter o valor '1'
order=1                                                 # por default, a tabela irá ser ordenada pela primeira coluna, ou seja, alfabeticamente
comm=".*"                                               # caso o utilizador não coloque nenhum argumento do tipo "-c", irá guardar todos (.*) o processos
user="*"                                                # caso o utilizador não coloque nenhum argumento do tipo "-u", irá guardar todos o processos independemente dos users
sDate=0                                                 
eDate=$(date +"%s")
sleepTime=${@: -1}                                      # sleepTime = último argumento 
total=0

while getopts ":s:e:c:u:p:mtdwr" opt; do                                                            # while que percorre todos os argumentos
    case $opt in
        p)                                                                                          # caso -p 
            numProcess=$OPTARG                                                                          # o nº de processos a imprimir é atualizado
            if ! [[ "$numProcess" =~ ^[0-9]+$ ]]; then                                                  # se o numProcess não for um inteiro positivo, irá dar erro
                echo "Error: Invalid options (number of -p must be a positive integer)"
                exit 1
            fi;;

        u)                                                                                          
            user=$OPTARG;;                                                                             

        c)
            comm=$OPTARG;;

        s)
            startingDate=$OPTARG
            
            if date -d "$startingDate" >/dev/null 2>&1; then                                       
                sDate=$(date --date="$startingDate" +"%s")                                        # se a data inserida for válida, será guardada, caso contrário, dá erro
            else 
                echo "Error: Invalid starting date"
                exit 1
            fi;;

        e)
            endingDate=$OPTARG                                                                    # a mesma situação da starting date
            if date -d "$endingDate" >/dev/null 2>&1; then
                eDate=$(date --date="$endingDate" +"%s")
            else 
                echo "Error: Invalid ending date"
                exit 1
            fi;;

        m)  
            ((total++))
            order=4;;                                                                             # ordenar pela 4 coluna
        
        t)
            ((total++))
            order=5;;

        d)
            ((total++))
            order=8;;

        w)
            ((total++))
            order=9;;
        
        r)
            reverse=1;;                                                                           # reverse é "ativado" caso haja opção -r

        *)                                                                                        # caso for inserido um argumento que não está entre os disponíveis, dá erro também
            echo "Error: command not found"          
            exit 1;;
    esac
done
shift $((OPTIND - 1))

if [[ $eDate -le $sDate ]]; then                                                                  # caso a eDate for menor que a sDate, dá erro
    echo "Error: Invalid options (ending date smaller or equal than the starting date)"
    exit 1 
fi

if [[ $total -gt 1 ]]; then                                                                       # a variavel total guarda quantas vezes foram inseridos comandos incompativeis
    echo "Error: incompatible commands"                                                           # caso total seja maior que 1, dá erro
    exit 1 
fi

if ! [[ "$sleepTime" =~ ^[0-9]+$ && $sleepTime != 0 ]]; then                                      # sleep time tem que ser um numero inteiro positivo ou diferente de 0, senão também dá erro
    echo "Error: Invalid options (sleep time is not a positive integer or don't exist)"
    exit 1 
fi 

index=0
for k in $(ls -a | grep -Eo '[0-9]{1,5}'); do                                                                               # vai agrupar só os números no comando ls e ir um a um no for
    if [[ -f "$k/status" && -f "$k/io" && -f "$k/comm" ]]; then                                                             # -f irá validar se o ficheiro que queremos aceder existe, em caso negativo avança para o próximo processo
        if [[ -r "$k/status" && -r "$k/io" && -r "$k/comm" ]]; then                                                         # -r confirma se temos permissão para ler os ficheiros
            if $(cat $k/status | grep -q 'VmSize\|VmRSS') && $(cat $k/io | grep -q 'rchar\|wchar') ; then                   # verificar se existe a informação VmSize,VmRSS,rchar e wchar

                pComm=$(cat $k/comm)                                                                                        # pComm = nome do processo em questão

                pUser=$(ps -o user= -p $k)                                                                                  # pUser = utilizador do processo
                
                LANG=en_us_8859_1
                startDate=$(ps -o lstart= -p $k)                                                                            # vai buscar a data de começo do processo em questão
                startDate=$(date +"%b %d %H:%M" -d "$startDate")                                                            # formata a data
                dateTS=$(date --date="$startDate" +"%s")       

                if [[ ($pComm =~ $comm) && ($pUser == $user) && ($dateTS -gt $sDate) && ($dateTS -lt $eDate) ]]; then 
                    if ! [[ "${processID[@]}" =~ "$k" ]]; then                                                              # verificar de o PID já existe em processID => quando faço sudo "./procstat.sh 10" aparecem processos repetidos, portanto este passo é para evitar essa situação 
                        processID[index]=$k                                                                                 # PID é um dos pretendidos, ou seja, será guardado em processID 
                        ((index++))
                    fi
                fi
            fi
        fi
    fi
done

index=0
for PID in ${processID[@]}; do                                      # para cada processo vamos guardar todos os rchars e wchars
    var1=$(cat $PID/io | grep 'rchar')
    var2=$(cat $PID/io | grep 'wchar')
    rchar=${var1//[!0-9]/} 
    wchar=${var2//[!0-9]/}
                            
    allRchar[$index]=$rchar                                         # guarda todos os rchars
    allWchar[$index]=$wchar                                         # guarda todos os wchars
                            
    ((index++))
done

sleep $sleepTime

index=0
for PID in ${processID[@]}; do

    ############### VmSize / VmRSS ###############

    var1=$(cat $PID/status | grep 'VmSize')
    var2=$(cat $PID/status | grep 'VmRSS')
    VmSize=${var1//[!0-9]/} 
    VmRSS=${var2//[!0-9]/}

    ################ RCHAR / WCHAR ###############

    rchar=${allRchar[$index]}
    wchar=${allWchar[$index]}

    ((index++))

    ################ RATER / RATEW ###############

    var1=$(cat $PID/io | grep 'rchar')
    var2=$(cat $PID/io | grep 'wchar')
    rchar2=${var1//[!0-9]/} 
    wchar2=${var2//[!0-9]/}

    sub=$(($rchar2-$rchar))
    rater=$( echo "scale=2; $sub/$sleepTime"| bc -l)                        # por exemplo, rater = .33
    rater=${rater/#./0.}                                                    #              rater = 0.33  => acrescenta o zero (uma questão de estética)

    sub=$(($wchar2-$wchar))
    ratew=$( echo "scale=2; $sub/$sleepTime"| bc -l)                        
    ratew=${ratew/#./0.}

    #################### COMM ####################

    comm=$(cat $PID/comm | tr " " "_" )    
                                     

    #################### DATE ####################

    LANG=en_us_8859_1 
    startDate=$(ps -o lstart= -p $PID)                                     # vai buscar a data de inicio de processo em questão
    date=$(date +"%b %d %H:%M" -d "$startDate")                            # formata a data

    #################### USER ####################

    user=$(ps -o user= -p $PID)

    ##############################################

    infoProcess+=($comm $user $PID $VmSize $VmRSS $rchar $wchar $rater $ratew $date)            # guarda as informações recolhidas em infoProcess

done

if [[ $numProcess -gt ${#processID[@]} ]]; then                                                 # caso o nº de processos a serem imprimidos for superior à quantidade de PID, dá erro
    echo "Error: You selected a greater number of processes than the available ones"
    exit 1
elif [[ "$numProcess" == "null" ]]; then                                                        # caso numProcess ainda não tiver sido atualizado, este será o número total de PID's
    numProcess=${#processID[@]}
fi

#################### PRINT ##################

if [[ $numProcess != 0 ]]; then                                                                                                                             
    printf "%-30s %-20s %5s %15s %15s %15s %15s %15s %15s %17s \n" "COMM" "USER" "PID" "MEM" "RSS" "READB" "WRITEB" "RATER" "RATEW" "DATE"
else
    echo "Warning: No valid processes found"                                                    # caso não haja PID's para imprimir, aparecerá um warning a avisar que não há processos
    exit 1
fi

if [[ $order -ne 1 && $reverse -eq 0 ]]; then
    printf "%-30s %-20s %5s %15s %15s %15s %15s %15s %15s %8s %-1s %-1s \n" ${infoProcess[@]} | sort -k${order}rn | head -n ${numProcess}
elif [[ $order -ne 1 && $reverse -eq 1 ]]; then
    printf "%-30s %-20s %5s %15s %15s %15s %15s %15s %15s %8s %-1s %-1s \n" ${infoProcess[@]} | sort -k${order}n | head -n ${numProcess}
elif [[ $order -eq 1 && $reverse -eq 1 ]]; then
    printf "%-30s %-20s %5s %15s %15s %15s %15s %15s %15s %8s %-1s %-1s \n" ${infoProcess[@]} | sort -k${order} -f -r| head -n ${numProcess}
else
    printf "%-30s %-20s %5s %15s %15s %15s %15s %15s %15s %8s %-1s %-1s \n" ${infoProcess[@]} | sort -k${order} -f | head -n ${numProcess}
fi

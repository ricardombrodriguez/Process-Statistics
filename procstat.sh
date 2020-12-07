#!/bin/bash

# Trabalho realizado por:
#   João António Assis Reis, 98474, P1
#   Ricardo Manuel Batista Rodriguez, 98388, P1

cd /proc

declare -a processID
declare -a infoProcess  
declare -a allRchar
declare -a allWchar

numProcess="null"
reverse=0
order=1
comm=".*"
user="*"
sDate=0
eDate=$(date +"%s")
sleepTime=${@: -1}
total=0

while getopts ":s:e:c:u:p:mtdwr" opt; do
    case $opt in
        p)
            numProcess=$OPTARG
            if ! [[ "$numProcess" =~ ^[0-9]+$ ]]; then
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
                sDate=$(date --date="$startingDate" +"%s")
            else 
                echo "Error: Invalid starting date"
                exit 1
            fi;;

        e)
            endingDate=$OPTARG
            if date -d "$endingDate" >/dev/null 2>&1; then
                eDate=$(date --date="$endingDate" +"%s")
            else 
                echo "Error: Invalid ending date"
                exit 1
            fi;;

        m)  
            ((total++))
            order=4;;
        
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
            reverse=1;;

        *)
            echo "Error: command not found\n"          
            exit 1;;
    esac
done
shift $((OPTIND - 1))

if [[ $eDate -le $sDate ]]; then
    echo "Error: Invalid options (ending date smaller or equal than the starting date)"
    exit 1 
fi

if [[ $total -gt 1 ]]; then 
    echo "Error: incompatible commands"
    exit 1 
fi

if ! [[ "$sleepTime" =~ ^[0-9]+$ && $sleepTime != 0 ]]; then
    echo "Error: Invalid options (sleep time is not a positive integer or don't exist)"
    exit 1 
fi 

index=0
for k in $(ls -a | grep -Eo '[0-9]{1,5}'); do
    if [[ -f "$k/status" ]]; then                    
        if [[ -f "$k/io" ]]; then                      
            if [[ -f "$k/comm" ]]; then
                if [[ -r "$k/io" ]]; then
                    pComm=$(cat $k/comm)
                    if [[ $pComm =~ $comm ]]; then
                        pUser=$(ps -o user= -p $k)
                        if [[ $pUser == $user ]]; then
                            LANG=en_us_8859_1
                            startDate=$(ps -o lstart= -p $k)
                            startDate=$(date +"%b %d %H:%M" -d "$startDate")
                            dateTS=$(date --date="$startDate" +"%s")
                            if [[ $dateTS -gt $sDate && $dateTS -lt $eDate ]]; then
                                processID[index]=$k
                                ((index++))
                            fi
                        fi
                    fi
                fi
            fi
        fi
    fi
done

index=0
for PID in ${processID[@]}; do
    var1=$(cat $PID/io | grep 'rchar')
    var2=$(cat $PID/io | grep 'wchar')
    rchar=${var1//[!0-9]/} 
    wchar=${var2//[!0-9]/}
                            
    allRchar[$index]=$rchar
    allWchar[$index]=$wchar
                            
    ((index++))
done

sleep $sleepTime

index=0
validProcess=0
for PID in ${processID[@]}; do

    ((validProcess++))

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
    rater=$( echo "scale=2; $sub/$sleepTime"| bc -l)      
    rater=${rater/#./0.}                                    

    sub=$(($wchar2-$wchar))
    ratew=$( echo "scale=2; $sub/$sleepTime"| bc -l)
    ratew=${ratew/#./0.}

    #################### COMM ####################

    comm=$(cat $PID/comm | tr " " "_")

    #################### DATE ####################

    LANG=en_us_8859_1
    startDate=$(ps -o lstart= -p $PID)
    date=$(date +"%b %d %H:%M" -d "$startDate")

    #################### USER ####################

    user=$(ps -o user= -p $PID)

    ##############################################

    infoProcess+=($comm $user $PID $VmSize $VmRSS $rchar $wchar $rater $ratew $date)

done

if [[ $numProcess -gt $validProcess ]]; then
    echo "Error: You selected a greater number of processes than the available ones"
    exit 1
elif [[ "$numProcess" == "null" ]]; then
    numProcess=$validProcess
fi

#################### PRINT ##################

if [[ $numProcess != 0 ]]; then
    printf "%-20s %-10s %5s %15s %15s %15s %15s %15s %15s %17s \n" "COMM" "USER" "PID" "MEM" "RSS" "READB" "WRITEB" "RATER" "RATEW" "DATE"
else
    echo "Warning: No valid processes found"
    exit 1
fi

if [[ $order -ne 1 && $reverse -eq 0 ]]; then
    printf "%-20s %-10s %5s %15s %15s %15s %15s %15s %15s %8s %-1s %-1s \n" ${infoProcess[@]} | sort -k${order}rn | head -n ${numProcess}
elif [[ $order -ne 1 && $reverse -eq 1 ]]; then
    printf "%-20s %-10s %5s %15s %15s %15s %15s %15s %15s %8s %-1s %-1s \n" ${infoProcess[@]} | sort -k${order}n | head -n ${numProcess}
elif [[ $order -eq 1 && $reverse -eq 1 ]]; then
    printf "%-20s %-10s %5s %15s %15s %15s %15s %15s %15s %8s %-1s %-1s \n" ${infoProcess[@]} | sort -k${order} -f -r| head -n ${numProcess}
else
    printf "%-20s %-10s %5s %15s %15s %15s %15s %15s %15s %8s %-1s %-1s \n" ${infoProcess[@]} | sort -k${order} -f | head -n ${numProcess}
fi

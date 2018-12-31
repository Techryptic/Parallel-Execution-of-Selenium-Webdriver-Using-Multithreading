#! /bin/bash

NetworkAdapter="eno1"
List="Nmap-InputFile"
OutputFile="bannergrabber.csv"
LogsFile="logs.txt"
Script_LogsFile="script_logs.txt"
Set_Exit_Time="no"

echo "" > $Script_LogsFile
echo "" > $LogsFile

#BURP
#gnome-terminal -e 'sh -c  "echo STARTING BURP HEADLESS; java -jar -Xmx1g -Djava.awt.headless=true /usr/local/BurpSuitePro/burpsuite_pro.jar --project-file='$BurpProjectFile'"'

#Logger
gnome-terminal -e 'sh -c  "echo STARTING LOGGER; less +F '$Script_LogsFile'"'

CurrentTime=$(date | awk '{print $4}' | cut -d ':' -f1)
OriSizeOutputFileSize=$(cat $OutputFile | wc -l)
ExitHour=23
SECONDS=0
sleep 5

Cyan='\033[1;36m'
Red='\033[1;31m'
Green='\033[1;32m'
none='\e[0m'
#echo -e ell ${Cyan} hello ${none}

while sleep 15;
do echo "" &&
if [ $Set_Exit_Time == yes ]; then
#if (( $CurrentTime >= $ExitHour )); then
    echo "EXECUTION TIME"
    echo "EXITING, Logger, Script.....................$(date)"
    echo "EXITING, Logger, Script.....................$(date)" >> $LogsFile
    pkill less
    pkill ruby
    exit
else
    echo "---------------------------------"
    echo "Currently Running: TitleGrabber.rb"
    Scriptlogs=$(cat $Script_LogsFile | wc -l)
    ListSize=$(cat $List | wc -l)
    OutputFileSize=$(cat $OutputFile | wc -l)

    #Lastmachine Details
    lastbox=$(tail -1 $OutputFile | head -1 | cut -d ',' -f10) #http://ip:port #tail -1 bannergrabber.csv | head -1 | cut-d '.' -f10

    areyouhere=$(grep -n $lastbox $List >> /dev/null 2>&1 && echo yes || echo no)
    if [ $areyouhere == no ]; then
        lastboxfull=$(tail -1 $OutputFile)
        echo $lastboxfull >> $List
    fi

    whichline=$(grep -n $lastbox $List | head -n 1 | cut -d: -f1) #grep -n http://ip:port nmap-output.csv | head -n 1 | cut -d: -f1
    newline=$(jq -n $whichline+0)
    ListSplit=$List"_SPLIT"
    NewListFile=$(head -n $newline $List  > $ListSplit)
    CurrentlyLeft=$(wc -l < $ListSplit)

    #Real Percent based off script_log.txt
    #echo -e "Completed: "${Cyan}$Scriptlogs${none}, out of ${Red}$ListSize${none}

    #Real Calc based off completed:
    RealNumb=$(jq -n $ListSize-$CurrentlyLeft)
    echo -e "Completed: "${Cyan}$RealNumb${none}, out of ${Red}$ListSize${none}

    #Dec=$(echo 5k $Scriptlogs $ListSize /p | dc)
    RealPerc=$(jq -n $RealNumb/$ListSize)
    Percent=$(jq -n $RealPerc*100)
    echo -e "Percent Completed: "${Cyan}$Percent"%"${none}

    duration=$SECONDS
    echo -e "Completed ${Cyan}$Scriptlogs${none} in $(($duration / 3600)):$(($duration / 60)):$(($duration % 60))"

    #Threads (Beta)
    Threads=$(xwininfo -tree -root | grep "Chromium" | awk '{print $1}' | xargs -n1 xwininfo -all -id | grep "Process id" | sort | uniq -c | cut -d "P" -f 1 | xargs)
    T=$(jq -n $Threads-2)
    echo -e "Current Threads Running: "${Cyan}$T${none}

    #Last Machine Worked on (fixing long skip dups)
    echo -e "Last Box: ${Red}$lastbox${none}, Split List: ${Cyan}$ListSplit${none}, Currently Left: ${Cyan}$CurrentlyLeft${none}"

    currentuptime=$(uptime)
    echo Uptime:$currentuptime

    CurrentTime=$(date | awk '{print $4}' | cut -d ':' -f1)
    let countdown=$ExitHour-$CurrentTime
    echo "Set to EXIT in "$countdown" hours!"

    RESULTS=$(ps ax | grep -v grep | grep ruby | wc -l)
    if [ $RESULTS == 2 ]; then
        echo -e ${Green}"Running Great...."${none}
        echo "---------------------------------"
        echo ""
        echo "Running Great... $(date)" >> $LogsFile
    fi

    if [ $RESULTS == 0 ]; then
        echo -e ${Red}"Restarting TitleGrabber.rb..."${none}
        echo "---------------------------------"
        echo "Checking if completed.."

        #CheckScriptLogs=$(cat $Script_LogsFile | wc -l)
        if (( $CurrentlyLeft <= 5 )); then
            echo "Completed: ALL FINISHED"
            pkill less
            pkill ruby
            exit
        fi

        echo "Continuing.."
        echo "Restarting TitleGrabber.rb...: $(date)" >> $LogsFile
        echo "" > $Script_LogsFile
        pkill less
        gnome-terminal -e 'sh -c  "echo STARTING LOGGER; less +F '$Script_LogsFile'"'

        #Split or no
        ToSplit=$(ls $ListSplit >> /dev/null 2>&1 && echo yes || echo no)
        echo $ToSplit
        if [ $ToSplit == yes ]; then
            gnome-terminal --geometry=80x10 -e 'sh -c  "echo STARTING Main Script; ruby TitleGrabber.rb -l '$ListSplit' >> '$Script_LogsFile'"'
        fi
        if [ $ToSplit == no ]; then
            gnome-terminal --geometry=80x10 -e 'sh -c  "echo STARTING Main Script; ruby TitleGrabber.rb -l '$List' >> '$Script_LogsFile'"'
        fi
    fi
    
    NetworkOutage=$(ifconfig ${NetworkAdapter} | grep "inet addr" | wc -l)
    if [ $NetworkOutage == 0 ]; then
        echo "Network Disconnected!"
        echo "Network Disconnected: EXIT: Logger, Script.....................$(date)"
        echo "Network Disconnected: EXIT: Logger, Script.....................$(date)" >> $LogsFile
        pkill less
        pkill ruby
        exit
    fi
fi
done

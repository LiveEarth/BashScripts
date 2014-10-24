#!/bin/bash
##################################################################################
#   To use the script, you must start with the first parameter hostname or ip.   #
#   For example: $ PingScript.sh 127.0.0.1                                       #
#                $ PingScript.sh localhost                                       #
#                                                              G. Uzunov, 2014   #
##################################################################################

_IP=$1                                      # Destination IP address
_MAXtime="1"                                # Max time in milisecons to record
_SNDtime="1"                                # number of seconds for each ping
_SNDErrTime="5"                             # Retry on failed connection new ping request (5=10sec)
_PINGlocate="/bin/ping"                     # Where the PING app
_MAILreport="uzunov.g@scon-bg.com"          # Mail report log file (Must have a valid configuration of the mail application, that can send e-mails)
_LOGfile="/var/log/logping-$1.txt"          # Log file of the process
_start_time=$(date '+%Y-%m-%d %H:%M:%S')    # Variable containing value: time that the process is running
_TIMEdisplay=$((_SNDErrTime * 2))           # Variable containing the value: message on the screen "Retry on failed connection new ping request"

###########################################################
# FUNCTIONS
#
function float_cond()
{
        local cond=0
        if [[ $# -gt 0 ]]; then
                cond=$(echo "$*" | bc -q 2>/dev/null)
                if [[ -z "$cond" ]]; then cond=0; fi
                if [[ "$cond" != 0  &&  "$cond" != 1 ]]; then cond=0; fi
        fi
        local stat=$((cond == 0))
        return $stat
}
function exit_sig ()
{
        mail -s "Ping test result for ${_IP} from ${_start_time}" ${_MAILreport} < ${_LOGfile}
        echo "### User stop test: `date '+%Y-%m-%d %H:%M:%S'` ##############################" | tee -a ${_LOGfile}
        exit 0
}
###########################################################
clear
echo "--------------- Test begin at ${_start_time} --------------------"      | tee -a ${_LOGfile}
echo "> Maximum allow ping response time:            ${_MAXtime} ms"          | tee -a ${_LOGfile}
echo "> Seconds for each new ping request:           ${_SNDtime} s"           | tee -a ${_LOGfile}
echo "> Retry on failed connection new ping request: ${_TIMEdisplay} s"       | tee -a ${_LOGfile}
echo "> Mail report to: ${_MAILreport}"                                       | tee -a ${_LOGfile}
echo "> Log file: ${_LOGfile}"                                                | tee -a ${_LOGfile}
echo "----------------------------------------------------------------------" | tee -a ${_LOGfile}
while true
do
  ${_PINGlocate} -c1 -W2 ${_IP} > /dev/null
    if [ "$?" = "0" ]; then
      echo "Yes! Host is Alive! $?" > /dev/null
    else
      echo ""["`date '+%Y-%m-%d %H:%M:%S'`"]": No connection to ${_IP} !" | tee -a ${_LOGfile}
      trap exit_sig 9 1 2 3 15
      sleep ${_SNDErrTime}
      trap exit_sig 9 1 2 3 15
    fi
    RET=`${_PINGlocate} -c1 -W2 ${_IP} | grep 'time=' | awk '{print $7}' | cut -d '=' -f 2`
    if float_cond "${RET} > ${_MAXtime}"; then
      echo "["`date '+%Y-%m-%d %H:%M:%S'`"]: echo reply from ${_IP} time=${RET} ms" | tee -a ${_LOGfile}
    fi
    trap exit_sig 9 1 2 3 15
    sleep ${_SNDtime}
    trap exit_sig 9 1 2 3 15
done

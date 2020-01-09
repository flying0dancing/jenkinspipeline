#!/bin/bash


if [ X$1 == X-h -o X$1 == X-help -o X$1 == Xhelp ];then
  echo "--------------------------------------------------------------------------------------------------------"
  echo "It checks provided AgileREPORTER or product version, compare with installed, return need install or not"
  echo "                               "
  echo "Parameter introduction-- "
  echo "  1 installfolder: like /home/test/PIPEAR4FED "
  echo "  2 provide installer name: like HKMA_v5.30.0-b78.zip, CE_DPB_v5.30.0-b78_sign.lrm"
  echo ""
  echo "  check provided AgileREPORTER install or not:"
  echo "   Usage: installfolder installerName"
  echo "   this.sh /home/test/PIPEAR4FED AgileREPORTER-19.3.0-b207.jar"
  echo "  check provided product install or not:"
  echo "   Usage: installfolder installerName"
  echo "   this.sh /home/test/PIPEAR4FED HKMA_v5.30.0-b78.zip"
  echo ""
  echo "  return 0 for need to install, return 1 for no need"
  echo "----------------------------------------------------------------------------------------------------------"
  exit
fi


curdatetime=`date "+%Y_%m_%d_%H_%M_%S"`
installfolder=$1
fileName=$2
installedVersion=
installedProduct=
providedProduct=
providedVersion=
providedAR=${fileName:0:13}
providedARFlag=1

logfile=${0%.*}.tmp
resultFlag=0

if [ $providedAR == "AgileREPORTER" ];then
    providedARFlag=0
    providedProduct=AgileREPORTER
    temp=${fileName:14}
    providedVersion=${temp%%\.jar}
else
    providedProduct=${fileName%%_v*}
    temp=${fileName##*_v}
    temp1=${temp%%\.lrm}
    temp2=${temp1%%\.zip}
    providedVersion=${temp2%%_*}
fi
echo "version: provided($providedVersion)"


if [ -f "${installfolder}/${logfile}" ];then
    echo "delete file ${installfolder}/${logfile}"
    rm "${installfolder}/${logfile}"
fi

if [ "${installfolder}" = "None" ];then
    echo "error, installfolder is null"
    echo "installation is interrupted, because installfolder is null.">$logfile
else
    if [ -d "${installfolder}" ];then
	    
        cd "${installfolder}"
        bar=
        if [ $providedARFlag == 0 ];then
            bar=`./bin/config.sh -l | grep ^version: `
        else
            bar=`./bin/config.sh -l | grep ^"${providedProduct} " `
        fi
        echo "$bar"
        if [ -n "${bar}" ];then
            installedVersion=`echo ${bar}| awk -F ' ' '{print $2}'`
            echo "version: provided($providedVersion) vs installed($installedVersion)"
            if [ ${providedVersion} == ${installedVersion} ];then
                echo "no need install, same version"
                resultFlag=1
            else
                providedMainVer=${providedVersion%-b*}
                providedBuildNum=${providedVersion#*-b}
                installedMainVer=${installedVersion%-b*}
                installedBuildNum=${installedVersion#*-b}
                if [ ${providedMainVer} == ${installedMainVer} ];then
                    echo "build number: provided(${providedBuildNum}) vs installed(${installedBuildNum})"
                    if [ ${providedBuildNum} -gt ${installedBuildNum} ];then
                        echo "need install, provided build number is bigger"
                        resultFlag=0
                    else
                        echo "no need install, provided build number is lower"
                        resultFlag=1
                    fi
                else
                    echo "compare main version"
                    i=1
                    while((1==1))
                    do
                        providedSplit=`echo ${providedMainVer}|cut -d "." -f$i`
                        installedSplit=`echo ${installedMainVer}|cut -d "." -f$i`
                        echo "split version(at index $i): provided($providedSplit) vs installed($installedSplit)"
                        
                        if [ "$providedSplit" != ""  -a "$installedSplit" != "" ];then
                            
                            if [ $providedSplit -gt $installedSplit ];then
                                echo "need install, provided version(at index $i) is bigger"
                                resultFlag=0
                                break
                            elif [ $providedSplit -lt $installedSplit ];then
                                echo "no need install, provided version(at index $i) is lower"
                                resultFlag=1
                                break
                            else
                                echo "version(at index $i) is same"
                                resultFlag=1
                            fi
                            ((i++))
                        else
                            echo "need install, different version"
                            resultFlag=0
                            break
                        fi

                    done

                fi

            fi
        else
            echo "need install, no installed product"
            resultFlag=0
        fi

    fi
fi
exit $resultFlag


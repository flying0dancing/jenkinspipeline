#!/bin/bash


if [ X$1 == X-h -o X$1 == X-help -o X$1 == Xhelp ];then
  echo "--------------------------------------------------------------------------------------------------------"
  echo "this script can installing agile reporter or installing product package or config DID"
  echo "                               "
  echo "Parameter introduction-- "
  echo "  1 installfolder: like /home/test/PIPEAR4FED "
  echo "  2 type: choose 0 or 1 or 2; 0 means install agile reporter, 1 means install product package or config DID, 2 meas config REPORTER metadata"
  echo ""
  echo "  install agile reporter:"
  echo "   Usage: installfolder type appFile[Full]Name propertiesFile[Full]Name"
  echo "   this.sh /home/test/PIPEAR4FED 0 /home/test/repository/AgileREPORTER/1.16.0/AgileREPORTER-1.16.0-b71.jar /home/test/repository/AgileREPORTER/1.16.0/ocelot.properties"
  echo ""
  echo "  install product package:"
  echo "   Usage: installfolder type appFile[Full]Name"
  echo "   this.sh /home/test/PIPEAR4FED 1 /home/test/repository/ARProduct/fed/candidate-release/1.16.0.6/AR_FED_Package_v1_16_0_6.zip(or .lrm)"
  echo ""
  echo "  install config DID:"
  echo "   Usage: installfolder type propertiesFileName DIDprefix DIDimplementationVersion DIDaliasNames"
  echo "   this.sh /home/test/PIPEAR4FED 1 MASoracleSystemaliasinfo.properties MAS 2.23.1.7 \"STB Work:STB System:STB System MAS\""
  echo ""
  echo "  install config ALIAS for REPORTER metadata:"
  echo "   Usage: installfolder type propertiesFileName DIDprefix DIDimplementationVersion DIDaliasNames"
  echo "   this.sh /home/test/PIPEAR4FED 2 MASoracleSystemaliasinfo.properties MAS 2.23.1.7 \"STB Work:STB System:STB System MAS\""
  echo ""
  echo " Notes: if app or properties are already in installfolder, only type their FileName;"
  echo "        if installfolder does not exist, this.sh will create a new one."
  echo "        product's propertiesFileName must under bin folder"
  echo "----------------------------------------------------------------------------------------------------------"
  exit
fi


curdatetime=`date "+%Y_%m_%d_%H_%M_%S"`
installfolder=$1
type=$2
logfile=${0%.*}_$2.tmp
detaillog=${0%.*}_$2_$curdatetime.log
app=
properties=
DIDprefix=
DIDimplementationVersion=
DIDaliasName=

port=None

eaFlag=-ea

if [ -f "${installfolder}/${logfile}" ];then
    echo "delete file ${installfolder}/${logfile}"
    rm "${installfolder}/${logfile}"
fi

if [ -f "${installfolder}/${detaillog}" ];then
    echo "delete file ${installfolder}/${detaillog}"
    rm "${installfolder}/${detaillog}"
fi

if [ "${installfolder}" = "None" ];then
    echo "error, installfolder is null"
    echo "installation is interrupted, because installfolder is null.">$logfile
else
    if [ -f "${installfolder}/bin/run.lock" ];then
        echo "stopping service"
        cd "${installfolder}"
        bash bin/stop.sh
        bash bin/cleanup.sh
        rm -f bin/run.lock
        rm -f bin/stop.lock
        rm -f bin/stop.error
        cd ~
    fi
    if [ "${type}" = "0" ];then
        if [ ! -d "${installfolder}" ];then
	        echo "create folder(if not existed): ${installfolder}"
            mkdir "${installfolder}"
        fi
		app=$3
		properties=$4
        cd "${installfolder}"
		sed -i "s#^ocelot.install.path=.*#ocelot.install.path=${installfolder}#g" "${properties}"
        port_base=`awk -F '=' /^host.port[^.]/'{print $2}' "${properties}"`
        port_offset=`awk -F '=' /^host.port.offset/'{print $2}' "${properties}"`
        port_zookeeper=`awk -F '=' /^zookeeper.port/'{print $2}' "${properties}"`
        
        if [ -n "${port_offset}" ];then
            let port=${port_base}+${port_offset}
        else
            port=${port_base}
        fi
        echo "port_base:${port_base},port_offset:${port_offset}"
        echo "port:${port}, port_zookeeper:${port_zookeeper}"
        netstat -atunlp | grep ${port}
        if [ "$?" = "0" ]; then
            echo "killing progress port:${port}"
            netstat -atunlp | awk '/${port}/{print substr($7,1,index($7,"/")-1)}' | sort | uniq | xargs kill -9
        fi
        netstat -atunlp | grep ${port_zookeeper}
        if [ "$?" = "0" ]; then
            echo "killing progress port_zookeeper:${port_zookeeper}"
            netstat -atunlp | awk '/${port_zookeeper}/{print substr($7,1,index($7,"/")-1)}' | sort | uniq | xargs kill -9
        fi
        cd "${installfolder}"
	echo "java -jar ${app} -options ${properties} 2>&1 |tee $detaillog"
        java -jar "${app}" -options "${properties}" 2>&1 | tee $detaillog
        tail -5 $detaillog | grep -i "AgileREPORTER has been installed"
        if [ "$?" = "0" ]; then
            echo "${app} install or upgrade successfully."
            echo "install ${app} pass">$logfile
            if [ -n "${port_offset}" ];then
                cd wildfly*/standalone/configuration
                sed -i "s/port-offset:[0-9]/port-offset:${port_offset}/g" standalone.xml
            fi
        else
            echo "${app} install or upgrade fail, please check."
            echo "install ${app} fail">$logfile
			exit 1
        fi
        
    elif [ "${type}" = "1" -o "${type}" = "2" ];then
	    if [ ! -d "${installfolder}" ];then
	        echo "folder does Not exist: ${installfolder}"
			exit 1
        fi
        cd "${installfolder}"
		if [ $# -eq 3 ];then
		  app=$3
		fi
		if [ $# -eq 6 ];then
		  properties=$3
		  DIDprefix=$4
		  DIDimplementationVersion=$5
		  DIDaliasName=$6
		fi
		if [ $# -eq 7 ];then
		  app=$3
		  properties=$4
		  DIDprefix=$5
		  DIDimplementationVersion=$6
		  DIDaliasName=$7
		fi
        
        if [ -n "${app}" ];then
            echo "================================================================================"
            echo "./bin/config.sh -a ${app}" >$detaillog
            echo "================================================================================" >>$detaillog
            ./bin/config.sh -a "${app}"  2>&1 | tee -a $detaillog
            tail -5 $detaillog | grep -i "successfully"
            if [ "$?" = "0" ]; then
                echo "${app} install or upgrade successfully."
                echo "install ${app} pass">$logfile
            else
                echo "${app} install or upgrade fail, please check."
                echo "install ${app} fail">$logfile
				exit 1
            fi
        fi
        if [ -n "${properties}" ];then 
            i=1
            while((1==1))
            do
               echo "================================================================================"
               split=`echo ${DIDaliasName}|cut -d ":" -f$i`
                if [ "$split" != ""  -a "$split" != "${DIDaliasName}" ];then
                    ((i++))
                    if [ "${type}" = "2" ];then
                        eaFlag=-aa
                        ./bin/config.sh -da "${DIDprefix}" -iv "${DIDimplementationVersion}" -alias "${split}"
                    fi
                    echo "${split}"
                    echo "./bin/config.sh ${eaFlag} ${DIDprefix} -iv ${DIDimplementationVersion} -alias \"${split}\" -aif \"${properties}\"" >>$detaillog
                    echo "================================================================================" >>$detaillog
                    ./bin/config.sh ${eaFlag} "${DIDprefix}" -iv "${DIDimplementationVersion}" -alias "${split}" -aif "${properties}"  2>&1 | tee -a $detaillog
                    tail -5 $detaillog | grep -i "successfully"
                    if [ "$?" = "0" ]; then
                        echo "${split} configuration successfully."
                        echo "configure ${split} pass">>$logfile
                    else
                        echo "${split} configuration fail, please check."
                        echo "configure ${split} fail">>$logfile
                    fi
                elif [ "$split" != "" -a "$split" = "${DIDaliasName}" ];then
                    if [ "${type}" = "2" ];then
                        eaFlag=-aa
                        ./bin/config.sh -da "${DIDprefix}" -iv "${DIDimplementationVersion}" -alias "${split}"
                    fi
                    echo "${split}"
                    echo "./bin/config.sh ${eaFlag} ${DIDprefix} -iv ${DIDimplementationVersion} -alias \"${split}\" -aif \"${properties}\"" >>$detaillog
                    echo "================================================================================" >>$detaillog
                    ./bin/config.sh ${eaFlag} "${DIDprefix}" -iv "${DIDimplementationVersion}" -alias "${split}" -aif "${properties}" 2>&1 | tee -a $detaillog
                    tail -5 $detaillog | grep -i "successfully"
                    if [ "$?" = "0" ]; then
                        echo "${split} configuration successfully."
                        echo "configure ${split} pass">>$logfile
                    else
                        echo "${split} configuration fail, please check."
                        echo "configure ${split} fail">>$logfile
                    fi
                    break
                else
                    break
                fi 
            done
        fi
    else
        echo "type is wrong."
        echo "configure type fail">$logfile
		exit 1
    fi
fi

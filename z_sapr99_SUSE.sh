#!/bin/sh
# https://github.com/cdavisnz/saprouter_suse
# Version:
# 1.0 04/11/2016 @cdavis.nz
# 1.1 28/06/2017 @cdavis.nz Logging Path
#
# /etc/init.d/z_sapr99
# chkconfig: 345 90 10
# description: Start SAProuter R99

### BEGIN INIT INFO
# Provides: z_sapr99
# Required-Start: $network $syslog $remote_fs $time
# X-UnitedLinux-Should-Start:
# Required-Stop:
# Default-Start: 3 5
# Default-Stop: 0 1 2 6
# Short-Description: Start the SAProuter R99
# Description: Start the SAProuter R99
### END INIT INFO

RETVAL=0

# Source function library.
. /etc/rc.status
rc_reset

SAPSYSTEMNAME=R99
SAPUSER=r99adm
SAPBASE=/usr/sap/${SAPSYSTEMNAME}/saprouter
SAPEXEC=${SAPBASE}/exe/saprouter
SAPHOST=`hostname --ip-address`
SAPPORT=3299

SECUDIR=${SAPBASE}/sec; export SECUDIR
SNC_LIB=${SAPBASE}/exe/libsapcrypto.so; export SNC_LIB
SAPSNCP=""

LOCKFILE=${SAPBASE}/tmp/z_sap${SAPUSER}-`whoami`.tmp
LOGFILE=${SAPBASE}/tmp/saprouter-`whoami`.log
PATH=${PATH}:$SAPBASE/exe; export PATH
LIBPATH=$SAPBASE/exe; export LIBPATH

stop()
{
    echo -n $"Shutdown SAPRouter ${SAPSYSTEMNAME}: "

    if [ -d ${SAPBASE}/exe ]; then
        ${SAPEXEC} -s -H ${SAPHOST} -S ${SAPPORT} > ${LOGFILE} 2>&1
        RETVAL=$?
    else
        RETVAL=1
    fi

    if [ ${RETVAL} -eq 0 ]; then
        rm -f ${LOCKFILE}
        rc_status -v
    else
        rc_status -v
    fi
    return ${RETVAL}
}

start()
{
    echo -n $"Startup SAPRouter ${SAPSYSTEMNAME}: "

    if [ -d ${SAPBASE}/exe ]; then

        START="-u `id -u ${SAPUSER}` ${SAPEXEC} -r -H ${SAPHOST} -I ${SAPHOST} -S ${SAPPORT} -Z -D -E -J 1048576 -W 60000"
        LOGGING="-G ${SAPBASE}/log/dev_saprouter -T ${SAPBASE}/log/dev_rout"

        case "$SAPSNCP" in
            CN=*)
            /sbin/startproc ${START} -R ${SAPBASE}/saprouttab -K p:\"$SAPSNCP\" ${LOGGING} > ${LOGFILE} 2>&1 &;;
            *)
            /sbin/startproc ${START} -R ${SAPBASE}/saprouttab ${LOGGING} > ${LOGFILE} 2>&1 &;;
        esac

        sleep 5
        /sbin/checkproc ${SAPEXEC} 2>&1
        RETVAL=$?
    else
        RETVAL=1
    fi

    if [ ${RETVAL} -eq 0 ]; then
        touch ${LOCKFILE}
        rc_status -v
    else
        rc_status -v
    fi
    return ${RETVAL}
}

reload()
{
    echo -n $"Reload SAPRouter ${SAPSYSTEMNAME}: "

    if [ -d ${SAPBASE}/exe ]; then
        ${SAPEXEC} -n -H ${SAPHOST} -S ${SAPPORT} > ${LOGFILE} 2>&1
        RETVAL=$?
    else
        RETVAL=1
    fi

    if [ ${RETVAL} -eq 0 ]; then
        touch ${LOCKFILE}
        rc_status -v
    else
        rc_status -v
    fi
    return ${RETVAL}
}

status()
{
    echo -n $"Status SAPRouter ${SAPSYSTEMNAME}: "

    if [ -d ${SAPBASE}/exe ]; then
        ${SAPEXEC} -l -H ${SAPHOST} -S ${SAPPORT} > ${LOGFILE} 2>&1
        RETVAL=$?
    else
        RETVAL=1
    fi

    if [ ${RETVAL} -eq 0 ]; then
        touch ${LOCKFILE}
        rc_status -v
    else
        rc_status -v
    fi
    return ${RETVAL}
}

case $1 in
    stop)
        stop
    ;;
    start)
        start
    ;;
    restart)
        stop   
        start
    ;;
    reload)
        reload
    ;;
    status)
        status
    ;;
    *)
        echo "Usage $0 (start|stop|restart|reload|status)"
        exit 1;
    ;;
esac
rc_exit
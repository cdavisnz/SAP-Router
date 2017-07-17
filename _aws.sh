#!/bin/sh
# https://github.com/cdavisnz/SAP-Router
# Version:
# 1.0 04/11/2016 @cdavis.nz
# 1.1 28/06/2017 @cdavis.nz Logging Path
# 1.2 08/07/2017 @cdavis.nz Sync from S3
#
# built on: Linux Amzn1.x86_64
# description: SAProuter on AWS

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 \$SAPSYSTEMNAME \$SAPBASE \$SAPUSER \$AWSREPO"
    exit 1
fi

SAPSYSTEMNAME=$1
SAPBASE=$2
SAPUSER=$3
AWSREPO=$4

if [ ! -d ${SAPBASE} ]; then
    echo "ERROR! Directory '${SAPBASE}' doesn't exist (\$SAPBASE)"
    exit 1
fi

if [ ! `id -u ${SAPUSER} 2>/dev/null || echo -1` -ge 0 ]; then
    echo "ERROR! User '${SAPUSER}' doesn't exist (\$SAPUSER)"
    exit 1
fi

## Functions

function init_security {

    # Initialisation 'security'

    if [ -d ${SAPBASE} ]; then

        if [ -f ${SAPBASE}/saprouttab ]; then
            chown -f ${SAPUSER}:sapsys ${SAPBASE}/saprouttab
            chmod -f 600 ${SAPBASE}/saprouttab
        fi
    fi
}

function init_tmp {

    # Initialisation 'tmp'

    if [ -d ${SAPBASE}/tmp ]; then

        if [ ! -d ${SAPBASE}/tmp ]; then
            mkdir ${SAPBASE}/tmp
            chmod -f 755 ${SAPBASE}/tmp
        fi
    fi
}

function init_log {

    # Initialisation 'log'

    if [ -d ${SAPBASE}/log ]; then

        if [ ! -d ${SAPBASE}/log ]; then
            mkdir ${SAPBASE}/log
            chmod -f 755 ${SAPBASE}/log
        fi

        x=`ls ${SAPBASE}/log/dev_saprouter* 2>/dev/null | wc -l`

        if [ $x -gt 100 ];then
            find ${SAPBASE}/log/ -type f -mtime +90 -name "dev_saprouter*" -exec rm -f {} \;
        fi

        if [ -f ${SAPBASE}/log/dev_rout ]; then
            mv ${SAPBASE}/log/dev_rout ${SAPBASE}/log/dev_rout.old
        fi
    fi
}

function upgrading_lock {

    # Create upgrading file

    if [ -x "/usr/bin/aws" ]; then

        if [ -f ${SAPBASE}/exe/.upgrading ]; then
            rm -f ${SAPBASE}/exe/.upgrading
        fi

        /usr/bin/aws s3 cp ${AWSREPO}/.upgrading ${SAPBASE}/exe --quiet

    else
        echo "ERROR! Executable '/usr/bin/aws' doesn't exist"
        exit 1
    fi
}

function upgrading_unlock {

    # Remove upgrading file

    if [ -f ${SAPBASE}/exe/.upgrading ]; then
        rm -f ${SAPBASE}/exe/.upgrading
    fi
}

function sync_exe {

    # Synchronise executables

    touch ${SAPBASE}/tmp/aws.log

    if [ -f ${SAPBASE}/exe/.upgrading ]; then

        if [ -d ${SAPBASE}/exe ]; then
            rm -fr `ls -d ${SAPBASE}/exe/* | grep -v '_aws.sh'`
            /usr/bin/aws s3 sync ${AWSREPO} ${SAPBASE}/exe --exclude '${AWSREPO}/.upgrading' --quiet
            chown -f ${SAPUSER}:sapsys ${SAPBASE}/exe/*
            chmod -fR 755 ${SAPBASE}/exe*
        fi

    else
        echo "ERROR! File '.upgrading' doesn't exist (\$SAPBASE/exe/.upgrading)"
        exit 1
    fi
}

## Run

init_security
init_log
init_tmp
upgrading_lock
sync_exe
upgrading_unlock

exit 0
# 1. SAP Router
> Introduction

The [SAP Router](https://support.sap.com/en/tools/connectivity-tools/saprouter.html) is an SAP program that acts as an intermediate station (proxy) in a network connection between SAP Systems, or between SAP Systems and external networks. SAP Router controls the access to your network (application level gateway), and, as such, is a useful enhancement to an existing firewall system (port filter).

The following provides my recommended installation process for LINUX and includes an /etc/init.d scripts. The documentation below is based on SUSE Linux.
 
# 2. Documentation
> Installation Guide
###### 2.1 Parameters:
The parameter `$_SAPINST` is a temporary variable for the install identifying the system, it just allows us to install multiple sSAP Routers on the one host and gives the appearance that the install looks like a standard SAP application layout. For this example 'R' for router followed by the SAP port number '99' i.e. 3299, i.e. SAP System ID of 'R99'.
```shell
# sudo su - root
# bash
# _SAPINST=R99; export SAPINST
```
###### 2.2 User Account:
Create the \<sapsid\>adm user account and group that the SAP router process will run under, provide the groupid \<GID\> and userid \<UID\> as required.
```
# groupadd -g <GID> sapsys
# useradd -u <UID> -g sapsys -c "SAP Router" ${_SAPINST,,}adm -m -s /bin/csh
# passwd ${_SAPINST,,}adm
```
###### 2.3 Software:
Ensure the SAPCAR executable is downloaded and available for use.
```
# cp SAPCAR_<VERSION>.EXE /usr/sbin/SAPCAR
# chown root:sapsys /usr/sbin/SAPCAR
# chmod 755 /usr/sbin/SAPCAR
```
###### 2.4 Direcorties:
Create the following direcorty structure for the SAP router installation.
```
# mkdir -p /usr/sap/${_SAPINST}/saprouter/exe
# mkdir /usr/sap/${_SAPINST}/saprouter/tmp
# mkdir /usr/sap/${_SAPINST}/saprouter/sec
# mkdir /usr/sap/${_SAPINST}/saprouter/log
```
###### 2.5 Permission Tables:
The following just creates a sample 'saprouttab' file with all connections denied. The SAP router needs this file to start, please amended as per your own requirements [Route Permission Table](https://uacp2.hana.ondemand.com/viewer/e245703406684d8a81812f4c6334eb2f/7.51.0/en-US/486c7a3fc1504e6ce10000000a421937.html).
```
# echo "D * * *" > /usr/sap/${_SAPINST}/saprouter/saprouttab
# chmod 600 /usr/sap/${_SAPINST}/saprouter/saprouttab
```
###### 2.6 Software:
Extract the SAP software for the SAP router and SAP crypto library to the executable directory.
```
# SAPCAR -xvf saprouter_<VERSION>.SAR -R /usr/sap/${_SAPINST}/saprouter/exe/
# SAPCAR -xvf SAPCRYPTOLIBP_<VERSION>.SAR -R /usr/sap/${_SAPINST}/saprouter/exe/
# chown root:sapsys /usr/sap/
# chown -R ${_SAPINST,,}adm:sapsys /usr/sap/${_SAPINST}/
# chmod -r 755 /usr/sap/${_SAPINST}/
```
###### 2.7 Start-up Scripts:
Download the init.d script `z_sapr99_<os_type>` from this repository.
```
# cd /etc/init.d
# wget https://raw.githubusercontent.com/cdavisnz/SAP-Router/master/z_sapr99_<os_type>
# mv z_sapr99_<os_type> z_sap${_SAPINST,,}
# chown root:sapsys z_sap${_SAPINST,,}
# chmod 750 z_sap${_SAPINST,,}
```
Adjust the values for `$SAPSYSTEMNAME`, `$SAPUSER`, and `$SAPPORT` as required. If your SAP router is to be SNC enabled, please provide the Common Name within the parameter `SAPSNCP` i.e. SAPSNCP="CN=\<Name\>, OU=\<Customer Number\>, OU=SAProuter, O=SAP, C=DE". To disable, leave the parameter as is.  
```
# vi  z_sap${_SAPINST,,}
:set fileformat=unix
...
SAPSYSTEMNAME=R99
SAPUSER=r99adm
SAPBASE=/usr/sap/${SAPSYSTEMNAME}/saprouter
SAPEXEC=${SAPBASE}/exe/saprouter
SAPHOST=`hostname --ip-address`
SAPPORT=3299
SAPSYNC=Off
AWSREPO=s3://software/SAPROUTER_LINUX/exe

SECUDIR=${SAPBASE}/sec; export SECUDIR
SNC_LIB=${SAPBASE}/exe/libsapcrypto.so; export SNC_LIB
SAPSNCP=""
...
:wq!
```
Add and enable the script to execute on start-up.
```
# systemctl daemon-reload
# chkconfig -a z_sap${_SAPINST,,}
# chkconfig z_sap${_SAPINST,,} on
```
###### 2.8 Access:
Via sudo allow the \<sapsid\>adm rights to access the init.d script, edit the sudoers.d file as required.
```shell-script
# visudo
```
Add the following content and save the file , modify if required to reflect the correct SAP System ID.
```
...
# SAP Router Commands
r99adm ALL = (root) NOPASSWD: /bin/systemctl start z_sapr99
r99adm ALL = (root) NOPASSWD: /bin/systemctl stop z_sapr99
r99adm ALL = (root) NOPASSWD: /bin/systemctl status z_sapr99
r99adm ALL = (root) NOPASSWD: /bin/systemctl reload z_sapr99
```
###### 2.9 Environment:
Create the follow user environment for the SAP router \<sapsid\>adm account.
```
# vi /home/${_SAPINST,,}adm/.cshrc
```
Copy in the following content and save the file, modify if required to reflect the correct SAP System ID.
```
# @(#) $Id: //bas/721_REL/src/krn/tpls/ind/SAPSRC.CSH#1 $ SAP
# systename
setenv SAPSYSTEMNAME R99
set prompt="`hostname`:$LOGNAME \!> "
# no autologout
set autologout = 0
# number of commands saved in history list
set history = 50
# path
setenv PATH ${PATH}:/usr/bin/nohup:/usr/sap/${SAPSYSTEMNAME}/saprouter/exe
# sapgenpse
setenv SECUDIR /usr/sap/${SAPSYSTEMNAME}/saprouter/sec
setenv SNC_LIB /usr/sap/${SAPSYSTEMNAME}/saprouter/exe/libsapcrypto.so
# define some nice aliases
alias dir 'ls -l'
alias l 'ls -abxCF'
alias h 'history'
alias cdexe 'cd /usr/sap/$SAPSYSTEMNAME/saprouter/exe'
alias cdsec 'cd /usr/sap/$SAPSYSTEMNAME/saprouter/sec'
alias cdD 'cd /usr/sap/$SAPSYSTEMNAME/saprouter'
alias cdR 'cd /usr/sap/$SAPSYSTEMNAME/saprouter'
alias saprouttab 'vi /usr/sap/$SAPSYSTEMNAME/saprouter/saprouttab'
alias startsap 'sudo /bin/systemctl start z_sapr99'
alias stopsap 'sudo /bin/systemctl stop z_sapr99'
alias statussap 'sudo /bin/systemctl status z_sapr99'
alias reloadsap 'sudo /bin/systemctl reload z_sapr99'
```
```shell-script
# chown ${_SAPINST,,}adm:sapsys /home/${_SAPINST,,}adm/.cshrc
# chmod 640 /home/${_SAPINST,,}adm/.cshrc
```
###### 2.10 Certificate (Optional):
If Secure Network Communications (SNC) is required, generate the required certificate. The common name is your own, if it is a SNC connection to SAP then it is the value issued by SAP. For more information of this visit the SAP support link below for Connectivity Tools SAP Router.
```shell-script
# sudo su - ${_SAPINST,,}adm
host:r99adm 1> setenv _SAPINST=R99
host:r99adm 2> cd /usr/sap/${_SAPINST}/saprouter/sec
host:r99adm 3> setenv SECUDIR /usr/sap/${_SAPINST}/saprouter/sec
host:r99adm 4> sapgenpse get_pse -v -a sha256WithRsaEncryption -s 2048 -r certreq -p ${_SAPINST}SSLS.pse "CN=...,"
host:r99adm 5> sapgenpse seclogin -p ${_SAPINST}SSLS.pse -O ${_SAPINST,,}adm
host:r99adm 6> chmod 600 ${_SAPINST}SSLS.pse cred_v2
```
The following command imports the 'reponse.crt' file from a Certificate Authority, in this case SAP SE.
```shell-script
host:r99adm 7> sapgenpse import_own_cert -c reponse.crt -p ${_SAPINST}SSLS.pse
host:r99adm 8> sapgenpse get_my_name -p ${_SAPINST}SSLS.pse
```
###### 2.11 Commands:
As root, the SAP Router can be stopped via the init.d, systemctl commands i.e. 
```shell-script
# sudo su - 
# cd /etc/init.d
# ./z_sapr99 start
redirecting to systemctl start .service
Startup SAPRouter R99:                                                done

# ./z_sapr99 stop
redirecting to systemctl stop .service
Shutdown SAPRouter R99:                                               done
```
As \<sapsid\>adm, stopping and starting the SAP router can be done via the predefined alias's. i.e. stopsap. Updates to saprouttab can be activated via the reloadsap command.
```shell-script
# sudo su - r99adm
host:r99adm 1> stopsap
host:r99adm 2> startsap
host:r99adm 3> statussap
z_sapr99.service - LSB: Start the SAProuter
   Loaded: loaded (/etc/init.d/z_sapr99)
   Active: active (running) since Thu 2016-06-22 15:00:35 NZST; 2s ago
  Process: 78976 ExecStart=/etc/init.d/z_sapr99 start (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/z_sapr99.service
           └─79024 /usr/sap/R99/saprouter/exe/saprouter -r -H <HOST> -I <HOST> .... 
host:r99adm 4>
```
# 3. Maintenance
> Patching within Amazon Web Services 

Our SAP systems running in Amazon Web Services (AWS), hence we synchronised the SAP router binaries off a AWS S3 resource. This allows for patching once and maintain a consistent version across all systems with next to zero effort. We appy this same principle to SAP Kernel, SAP Web Dispatcher, SAP Host Controller, SAP Diagnostics Agent etc. To enable this preform the following steps:

###### 3.1 S3 Resource:

Within AWS create a S3 bucket, i.e. s3://software-sap/SAPROUTER_LINUX/exe and upload the extract files from saprouter_<VERSION>.SAR 
and SAPCRYPTOLIBP_<VERSION>.SAR. In addtion to this upload the github script '_aws.sh'and create a file name '.upgrading'.

In addition to to this ensure that the EC2 instance running the SAP router has the AWS Command Line Interface (CLI) installed.
```
# aws --version
aws-cli/1.10.38 Python/2.7.9 Linux/3.12.60-52.54-default botocore/1.4.28
```
###### 3.1 IAM Policy:
Ensure that the EC2 instance running the SAP router can access the S3 bucket, example policy below.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::software-sap",
                "arn:aws:s3:::software-sap/*"
            ]
        }
    ]
}
```
Once done you should be able to list the bucket as follows.
```
$ aws s3 ls s3://software-sap/SAPROUTER_LINUX/exe/
2016-06-30 07:15:51          0
2017-07-04 07:38:13          0 .upgrading
2016-07-24 09:27:42       5290 SIGNATURE.SMF
2017-07-15 09:12:09       2894 _aws.sh
2017-06-30 07:46:12    5861546 libsapcrypto.so
2016-07-24 09:27:42     499679 libslcryptokernel.so
2017-06-30 07:46:12        166 libslcryptokernel.so.sha256
2017-07-15 09:12:09    1402645 niping
2017-07-15 09:12:08        303 patches.mf
2017-06-30 07:46:11        102 sapcrypto.lst
2017-06-30 07:46:12        257 sapcrypto.mf
2017-06-30 07:46:12      38003 sapgenpse
2017-07-15 09:12:08    1826976 saprouter
```
###### 3.1 Configuration:

Within the SAP router init.d script set the parameter `SAPSYNC` equal to 'On' and `AWSREPO` to the S3 resource create above.
```
# cd /etc/init.d
# vi z_sapr99
SAPSYNC=On
AWSREPO=s3://software/SAPROUTER_LINUX/exe
:wq!
# systemctl daemon-reload
```
Once done, stop and start the SAP router. The start process will see the current binaries delete then copied back via the '_aws.sh' script. This script also corrects and file permissions and preforms tidy-up operations on logs files etc, amend and expand upon as required.

# 4. References
> Supporting Documentation

###### 4.1 SAP Help:

Connectivity Tools SAP Router
\- https://support.sap.com/en/tools/connectivity-tools/saprouter.html

SAP Router
\- https://uacp2.hana.ondemand.com/viewer/e245703406684d8a81812f4c6334eb2f/7.51.0/en-US/487612ed5ca5055ee10000000a42189b.html

###### 4.2 SUSE Linux:

SAProuter Integration
SUSE Linux Enterprise Server for SAP Applications 12 SP2
\- https://www.suse.com/documentation/sles-for-sap-12/singlehtml/book_s4s/book_s4s.html#sec.s4s.configure.saprouter

###### @cdavis_nz

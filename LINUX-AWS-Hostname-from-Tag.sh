#!/usr/bin/env bash
#
# ===========================================
# Author
# =========
# Calvin Robinson
# Sr. Consultant at VMware 
# Web - - calvintrobinson.com
# GitHub - - calvintrobinson.com/github
# Twitter - - @calvintrobinson
#
# ===========================================
#
# ===========================================
# Purpose
# =========
# This script allows an administrator to change the hostname of a Linux AWS 
# instance to some value passed from an AWS tag 
#
# ===========================================
#
# ===========================================
# Notes
# =========
# - This script assumes you have Python installed on your Linux Distro
# - In order for this script to be useful, you must create a tag on the AWS Instance 
# that contains as a value, the hostname you wish to use.  In my example, the tag
# is called 'Name' - The value that is assigned is the dynamically assigned hostname
# - Though not a part of this script, we are dynamically generating hostnames for each 
# requested instance and applying the dynamic name to the tag that this script interrogates
# - Though it can be postponed, a reboot should occur after changes are made.
#
# Please replace variables below with those that are appropriate for your environment
# ===========================================
  

#Constants ==================================
hostn=$(cat /etc/hostname)
hostsfile="/etc/hosts"
hostnamefile="/etc/hostname"
hostsfilebak="$hostsfile.bak"
hostnamebak="$hostnamefile.bak"
KEYID=ACCESSKEYIDABCDEFGHIJKLMNOP
SAK=MYSECRETACCESSKEY
curluri="https://bootstrap.pypa.io/get-pip.py"
curlbin="get-pip.py"
PIPDIR=/var/tmp/
curl=$(which curl)
cat=$(which cat)
sed=$(which sed)
TAG=Name
# ===========================================

#Check for Python============================
if which python > /dev/null 2>&1;
then
    #Python is installed
    python_version=`python --version 2>&1 | awk '{print $2}'`
    echo "Python version $python_version is installed.  Commencing Install"

else
    #Python is not installed
    echo "This script requires Python.  Please install before proceeding"
    exit 1
fi
#============================================

#Export AWS Access Keys======================
#Uses Keys for AWS User privileged with ability to read instance tags
export AWS_ACCESS_KEY_ID=$KEYID && export AWS_SECRET_ACCESS_KEY=$SAK;
echo "AWS Access Keys Added to Shell Environment"
echo
# ===========================================

#Curl Pip Binary ============================
$curl $curluri -o ${PIPDIR}${curlbin}
echo "Pip Downloaded to "$PIPDIR
echo
#============================================

#Installing Pip
python $PIPDIR'get-pip.py'
echo "Pip Installed using Python"
echo
# ===========================================

#Install AWS CLI
$(which pip) install awscli
echo "AWS CLI Tools Successfully Installed"
echo
# ===========================================

#Current Hostname============================
echo 'Current hostname is '$hostn
echo
# ===========================================

#Setting AWS Constants=======================
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
HN=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" --region=$REGION "Name=key,Values=$TAG" --output=text | cut -f5)
echo 'Instance ID is: '$INSTANCE_ID
echo 'Region has been determined to be: '$REGION
echo 'Hostname that will be applied is: '$HN
echo
# ===========================================

#Backup Files Prior to Editing them =========
$cat $hostsfile > $hostsfilebak
$cat $hostnamefile > $hostnamebak
# ===========================================

#Modifying /etc/hostname=====================
$sed -i 's/'"$hostn/$HN"'/g' $hostnamefile
echo 'New hostname of '$HN' has been assigned to the /etc/hostname file of this machine'
echo
#============================================

#Remove existing hosts file==================
rm -f $hostsfile
echo '/etc/hosts file removed'
echo

$cat <<EOF >  $hostsfile
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
127.0.1.1   $HN

EOF
# ===========================================

#Confirmational Steps========================
echo 'Output of /etc/hostname is: ' 
$cat $hostnamefile
echo

echo 'Output of /etc/hosts is: '
$cat $hostsfile
echo
# ===========================================

#Cleanup Steps===============================
#The removal of the AWS CLI can be commented out if you intend on retaining them
$(which pip) uninstall awscli -y
echo "AWS CLI Tools Uninstalled"
echo
# ===========================================

#Reboot
reboot

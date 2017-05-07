#
# ===========================================
# Title
# =========
# WINDOWS-AWS-Hostname-from-Tag.ps1
# ===========================================
#
# ===========================================
# Author
# =========
# Calvin Robinson
# Sr. Consultant at VMware 
# Web - - calvintrobinson.com
# GitHub - - calvintrobinson.com/github
# Twitter - - @calvintrobinson
# ===========================================
#
# ===========================================
# Purpose
# =========
# This script allows an administrator to change the hostname of a Windows AWS 
# instance to some value passed from an AWS tag 
# ===========================================
#
# ===========================================
# Notes
# =========
# - In order for this script to be useful, you must create a tag on the AWS Instance 
# that contains as a value, the hostname you wish to use.  In my example, the tag
# is called 'Name' - The value that is assigned is the dynamically assigned hostname
# - Though not a part of this script, we are dynamically generating hostnames for each 
# requested instance and applying the dynamic name to the tag that this script interrogates
# - Though it can be postponed, a reboot should occur after changes are made.
#
# Please replace variables below with those that are appropriate for your environment
# ===========================================

#Constants===================================
$hostn = $env:computername
$KEYID = "ACCESSKEYID"
$SAK = "ACCESSKEY"
$INSTANCE_ID = Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id
$reg = Invoke-RestMethod -uri http://169.254.169.254/latest/dynamic/instance-identity/document | select region
$REGION = $reg -replace ".*=" -replace "}"
$dnetwcl = New-Object System.Net.WebClient
$pypath = "http://www.python.org/ftp/python/2.7.6/python-2.7.6.amd64.msi"
$awspath = "https://s3.amazonaws.com/aws-cli/AWSCLI64.msi"
$awsfile = "AWSCLI64.msi"
$pyfile = "python-2.7.6.amd64.msi"
$TARGETDIR = 'C:\Script_Files\'
# ===========================================

#Set Environment Variables for AWS===========
write-host "Setting environment variables..."
$env:AWS_DEFAULT_REGION = $REGION; $env:AWS_ACCESS_KEY_ID = $KEYID; $env:AWS_SECRET_ACCESS_KEY = $SAK; $env:Path += ';C:\Program Files\Amazon\AWSCLI'
#============================================

#Create Folder Path==========================
New-Item -Path $TARGETDIR  -ItemType directory -Force
write-host "Folder Path of $TARGETDIR has been created"
#============================================

#Download Files==============================
$dnetwcl.DownloadFile("$pypath", "$TARGETDIR\$pyfile")
$dnetwcl.DownloadFile("$awspath", "$TARGETDIR\$awsfile")
Write-Host "Both $pyfile and $awsfile were downloaded to $TARGETDIR"
#============================================

#Install Python and AWS CLI==================
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $TARGETDIR\$pyfile /qn /quiet /norestart" -Wait
Write-Host "Python Installed"

Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $TARGETDIR\$awsfile /qn /quiet /norestart" -Wait
Write-Host "AWS CLI Installed"
#============================================

#Hostname Generation=========================
$HOS = aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" | Select-String -Pattern "Value"
$HN = ("$HOS").Replace('"Value": "',"").Replace('",',"").Replace('            ',"").Replace(' ',"")
write-host 'Old Hostname is :'$hostn
write-host 'Hostname that will be applied is: '$HN
#============================================

#Change Hostname=============================
netdom renamecomputer $env:computername /newname:$HN /Force
write-host "Hostname Changed to $HN"
#============================================

#Cleanup Folder Path=========================
Remove-Item $TARGETDIR -Recurse -Force
Write-Host "$TARGETDIR Folder Cleaned Up"
#============================================

#Reboot======================================
Restart-Computer
write-host "Server Being Rebooted"
#============================================

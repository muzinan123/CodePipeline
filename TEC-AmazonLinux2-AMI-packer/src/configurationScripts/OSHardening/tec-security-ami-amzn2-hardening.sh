#!/bin/bash
LOGFILE="/opt/OShardening-amz-linux-2.log"
VALIDATION="/opt/validatehardening.log"

function set_parameter
{
sed -i -e "s|^$2.*|$2$3|" $1
egrep "^$2*" $1 > /dev/null ||echo "$2$3" >> $1
}

#---------------------------------------------------------------------------------------------------------------
function add_line
{
egrep "^$2" $1 > /dev/null || echo "$2" >> $1
}
# #---------------------------------------------------------------------------------------------------------------


# ################################################################################################################
# ################   Crypto policy settings #############################################################
# ################################################################################################################

# echo -----------------------------------------------------------------------------------------------------------
# echo 1.1 Ensure system-wide crypto policy is not legacy -- system-wide crypto setup as default | tee -a $LOGFILE
# update-crypto-policies --set default
# echo 1.1 Validating if  crypto policy is not legacy
# update-crypto-policies --show | tee -a $VALIDATION

# echo -----------------------------------------------------------------------------------------------------------
# ################################################################################################################
# ################   Disable Mounting of FileSystems #############################################################
# ################################################################################################################



# echo -----------------------------------------------------------------------------------------------------------
# echo 7.1.2 Ensure mounting of freevxfs file systems is disabled | tee -a $LOGFILE
# add_line /etc/modprobe.d/CIS.conf "install freevxfs /bin/true"
# echo 7.1.2 Validating if  unwanted FileSystem is disabled --- freevxfs
# modprobe -n -v freevxfs && lsmod | grep freevxfs | tee -a $VALIDATION
# echo -----------------------------------------------------------------------------------------------------------
# echo 7.1.3 Ensure mounting of jffs2 file systems is disabled | tee -a $LOGFILE
# add_line /etc/modprobe.d/CIS.conf "install jffs2 /bin/true"
# echo 7.1.3 Validating if  unwanted FileSystem is disabled --- jffs2
# modprobe -n -v jffs2 && lsmod | grep jffs2 | tee -a $VALIDATION
# echo -----------------------------------------------------------------------------------------------------------

echo -----------------------------------------------------------------------------------------------------------
echo 1.1.2  Ensure /tmp is configured | tee -a $LOGFILE
mkdir -p /etc/systemd/system/local-fs.target.wants
set_parameter /etc/systemd/system/local-fs.target.wants/tmp.mount "[Mount]" | tee -a $LOGFILE
set_parameter /etc/systemd/system/local-fs.target.wants/tmp.mount "What" "=tmpfs"
set_parameter /etc/systemd/system/local-fs.target.wants/tmp.mount "Where" "=tmp"
set_parameter /etc/systemd/system/local-fs.target.wants/tmp.mount "Type" "=tmpfs"
# add_line /etc/systemd/system/local-fs.target.wants/tmp.mount "Options=mode=1777,strictatime,noexec,nodev,nosuid"
systemctl unmask tmp.mount 
systemctl enable tmp.mount
echo 1.1.2  Validate that /tmp is configured 
mount | grep /tmp | tee -a $VALIDATION
################################################################################################################
############################# Setting  Option on /tmp partition ################################################
################################################################################################################
echo -----------------------------------------------------------------------------------------------------------
echo 1.1.3  Ensure nodev option set on /tmp partition
echo 1.1.4  Ensure nosuid option set on /tmp partition
echo 1.1.5 Ensure noexec option set on /tmp partition
# mkdir -p /etc/systemd/system/local-fs.target.wants
# add_line /etc/systemd/system/local-fs.target.wants/tmp.mount "[Mount]" | tee -a $LOGFILE
add_line /etc/systemd/system/local-fs.target.wants/tmp.mount "Options=mode=1777,strictatime,noexec,nodev,nosuid" | tee -a $LOGFILE

################################################################################################################
############################# Setting  Option on var/tmp partition ################################################
################################################################################################################
echo 1.1.8 Ensure nodev option set on /var/tmp partition | tee -a $LOGFILE
echo 1.1.9 Ensure noexec option set on /var/tmp partition | tee -a $LOGFILE
echo 1.1.10 Ensure nosuid option set on /var/tmp partition | tee -a $LOGFILE
echo "Ensure options added in fstab" | tee -a $LOGFILE
grep -w / /etc/fstab | awk '{print $4}' | grep 'nodev' >> $LOGFILE
grep -w / /etc/fstab | awk '{print $4}' | grep 'noexec' >> $LOGFILE
grep -w / /etc/fstab | awk '{print $4}' | grep 'nosuid' >> $LOGFILE
mount -o remount,noexec /var/tmp
echo -----------------------------------------------------------------------------------------------------------
echo 1.1.14 Ensure nodev option set on /home partition | tee -a $LOGFILE
# mount -o remount,nodev /home
echo -----------------------------------------------------------------------------------------------------------
################################################################################################################
############################# Ensure  Options set  on dev/shm partition ################################################
################################################################################################################
echo -----------------------------------------------------------------------------------------------------------
echo 1.1.15 Ensure nodev option set on /dev/shm partition | tee -a $LOGFILE
echo 1.1.16 Ensure nosuid option set on /dev/shm partition | tee -a $LOGFILE
echo 1.1.17 Ensure noexec option set on /dev/shm partition | tee -a $LOGFILE
sed -i 's|\(/dev/shm\s*\S*\s*defaults\)\S*|\1,nodev,noexec,nosuid|' /etc/fstab
mount | grep /dev/shm  | tee -a $VALIDATION

###################################################################################################################
##########    1.1.18     Ensure sticky bit is set on all worldwritable directories ######################################
###################################################################################################################
echo "1.1.18 checking the sticky bit" |tee -a $LOGFILE
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t >> $LOGFILE
echo -------------------------------------------------------------------------------------------------------------

###################################################################################################################
##########    1.1.19     Disable autofs ######################################
###################################################################################################################
echo -e " 1.1.19 Checking autofs is disabled" | tee -a $LOGFILE
systemctl status autofs.service
if [ $? -eq 0 ]; then
echo -e "1.1.19  disbaling autofs service" |tee -a $LOGFILE
systemctl disable autofs
systemctl stop autofs.service
systemctl status autofs.service >> $LOGFILE
else
echo -e "1.1.19 autofs already disabled"
fi

# echo -----------------------------------------------------------------------------------------------------------
# ################################################################################################################
# ################   Disable Mounting of FileSystems #############################################################
# ################################################################################################################
echo -------------------------------------------------------------------------------------------------------------
echo 1.1.1.1 Ensure mounting of cramfs file systems is disabled -- disabling mounting of cramfs FileSystems | tee -a $LOGFILE
add_line /etc/modprobe.d/CIS.conf "install cramfs /bin/true" 
echo 1.1.1.1 Validating if  unwanted FileSystem is disabled --- cramfs
modprobe -n -v cramfs && lsmod | grep cramfs | tee -a $VALIDATION
echo -----------------------------------------------------------------------------------------------------------
echo 1.1.1.2 Ensure mounting of hfs file systems is disabled | tee -a $LOGFILE
add_line /etc/modprobe.d/CIS.conf "install hfs /bin/true"
echo 1.1.1.2 Validating if  unwanted FileSystem is disabled --- hfs
modprobe -n -v hfs && lsmod | grep hfs | tee -a $VALIDATION
echo -----------------------------------------------------------------------------------------------------------
echo 1.1.1.3 Ensure mounting of hfsplus file systems is disabled | tee -a $LOGFILE
add_line /etc/modprobe.d/CIS.conf "install hfsplus /bin/true"
echo 1.1.1.3 Validating if  unwanted FileSystem is disabled --- hfsplus
modprobe -n -v hfsplus && lsmod | grep hfsplus | tee -a $VALIDATION

echo -----------------------------------------------------------------------------------------------------------
echo 1.1.1.4 Ensure mounting of squashfs file systems is disabled | tee -a $LOGFILE
add_line /etc/modprobe.d/CIS.conf "install squashfs /bin/true"
echo 1.1.1.4 Validating if  unwanted FileSystem is disabled --- squashfs
modprobe -n -v squashfs && lsmod | grep squashfs | tee -a $VALIDATION
echo -----------------------------------------------------------------------------------------------------------
echo 1.1.1.5 Ensure mounting of udf file systems is disabled | tee -a $LOGFILE
add_line /etc/modprobe.d/CIS.conf "install udf /bin/true"
echo 1.1.1.5 Validating if  unwanted FileSystem is disabled --- udf
modprobe -n -v udf && lsmod | grep udf | tee -a $VALIDATION
###################################################################################################################
##########       7.2. 1 Ensure package manager repositories are configured  ######################################
###################################################################################################################
# echo 7.2.1 Ensure package manager repositories are configured  | tee -a $LOGFILE
# yum repolist | tee -a $VALIDATION

###################################################################################################################
##########       1.2. 24 Ensure gpgcheck is globally activated ######################################
###################################################################################################################

echo -----------------------------------------------------------------------------------------------------------
echo  1.2.3 Ensure gpgcheck is globally activated | tee -a $LOGFILE
set_parameter /etc/yum.conf "gpgcheck" "=1"  
grep ^gpgcheck /etc/yum.conf | tee -a $VALIDATION
echo -----------------------------------------------------------------------------------------------------------
# echo 1.3.1 Ensure sudo is installed | tee -a $LOGFILE
# sudo yum install sudo
# sudo -V
# echo sudo is alredy installed | tee -a $VALIDATION

# ###################################################################################################################
# ##########       1.3.2 Ensure sudo commands use pty ######################################
# ###################################################################################################################
# echo -----------------------------------------------------------------------------------------------------------
# echo 1.3.2 Ensure sudo commands use pty | tee -a $LOGFILE
# add_line /etc/sudoers "Defaults use_pty"
# echo -----------------------------------------------------------------------------------------------------------

# echo -----------------------------------------------------------------------------------------------------------
# echo 1.3.3 Ensure sudo log file exists | tee -a $LOGFILE
# add_line /etc/sudoers "Defaults logfile=" 
# echo -----------------------------------------------------------------------------------------------------------
###################################################################################################################
##########       1.4.1 Ensure permissions on bootloader config are configured ######################################
###################################################################################################################
echo -e "1.4.1 Secure boot settings" | tee -a $LOGFILE
for filename in /boot/grub2/grub.cfg /etc/ssh/sshd_config
do
	 chown root:root $filename
	 chmod og-rwx $filename
	 ls -l $filename >> $LOGFILE
done
echo -----------------------------------------------------------------------------------------------------------
###################################################################################################################
##########       1.4.2 Ensure authentication required for single user mode ######################################
###################################################################################################################
echo 1.4.2 Ensure authentication required for single user mode | tee -a $LOGFILE
set_parameter /etc/sysconfig/init "SINGLE" "=/sbin/sulogin"
set_parameter /etc/sysconfig/init "PROMPT" "=no"
grep ^SINGLE /etc/sysconfig/init | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------

###################################################################################################################
##########       1.5.1 Ensure core dumps are restricted ######################################
###################################################################################################################
echo 1.5.1 Ensure core dumps are restricted | tee -a $LOGFILE
add_line /etc/security/limits.conf "* hard core 0"
set_parameter /etc/sysctl.conf "fs.suid_dumpable" "=0"
echo -------------------------------------------------------------------------------------------------------------
###################################################################################################################
##########       1.5.2 Ensure ASLR is enabled ######################################
###################################################################################################################
echo 1.5.2 Ensure ASLR is enabled | tee -a $LOGFILE
set_parameter /etc/sysctl.conf "kernel.randomize_va_space" "=2"
sysctl -w kernel.randomize_va_space=2
sysctl kernel.randomize_va_space | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
###################################################################################################################
##########       1.5.3 Ensure prelink is disabled######################################
###################################################################################################################
# echo 1.5.3 Ensure prelink is disabled  | tee -a $LOGFILE
prelink -ua
yum remove prelink | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
###################################################################################################################
##########       1.7.1.5 Ensure permissions on /etc/issue are configured ############################################
###################################################################################################################
echo 1.7.1.5 Ensure permissions on /etc/issue are configured | tee -a $LOGFILE
chown root:root /etc/issue &&  chmod 644 /etc/Issue
stat /etc/issue | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       2.1.2  Ensure X Window System is not installed ####################################################
####################################################################################################################
echo 2.1.2  Ensure X Window System is not installed | tee -a $LOGFILE
yum remove xorg-x11*
rpm -qa xorg-x11* >>  $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       2.1.3  Ensure Avahi Server is not enabled##########################################################
####################################################################################################################
echo  2.1.3  Ensure Avahi Server is not enabled | tee -a $LOGFILE
chkconfig avahi-daemon off
chkconfig --list avahi-daemon | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       2.1.4  Ensure CUPS is not enabled       ##########################################################
####################################################################################################################
echo 2.1.4  Ensure CUPS is not enabled | tee -a $LOGFILE
chkconfig cups off
chkconfig --list cups | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       2.2.15 Ensure DHCP is not enabled      ##########################################################
####################################################################################################################
echo 2.1.5  Ensure DHCP is not enabled | tee -a $LOGFILE
yum -y -q erase dhcp 
chkconfig --list dhcpd | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
# ####################################################################################################################
# ##########       2.1.6 Ensure LDAP client is not installed   ###########################################
# ####################################################################################################################
echo 2.1.6 Ensure LDAP client is not installed | tee -a $LOGFILE
yum -y -q erase openldap-clients 
rpm -q openldap-clients | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 2.1.7 Ensure LDAP client is not installed | tee -a $LOGFILE
systemctl disable nfs
systemctl disable nfs-server
systemctl disable rpcbind
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       2.2.11  Ensure DNS Server is not enabled      ######################################################
####################################################################################################################
echo   2.1.8  Ensure DNS Server is not enabled | tee -a $LOGFILE
chkconfig named off
chkconfig --list named | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------

####################################################################################################################
##########      2.1.10  Ensure HTTP Server is not enabled      ####################################################
####################################################################################################################
echo 2.1.10 Ensure HTTP Server is not enabled | tee -a $LOGFILE
chkconfig httpd off
chkconfig --list httpd | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       2.1.11  Ensure IMAP and POP3 Server is not enabled      ############################################
####################################################################################################################
echo 2.1.11  Ensure IMAP and POP3 Server is not enabled | tee -a $LOGFILE
chkconfig dovecot off
chkconfig --list dovecot | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       2.2.7 Ensure Samba is not enabled     ############################################
####################################################################################################################
echo 2.2.7  Ensure Samba is not enabled | tee -a $LOGFILE
chkconfig smb off
chkconfig --list smb | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########      2.1.13 Ensure HTTP Proxy Server is not enabled     ###############################################
####################################################################################################################
echo 2.1.13 Ensure HTTP Proxy Server is not enabled | tee -a $LOGFILE
chkconfig squid off
chkconfig --list squid | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       2.2.5  Ensure SNMP Server is not enabled    ###############################################
####################################################################################################################
echo  2.2.5  Ensure SNMP Server is not enabled | tee -a $LOGFILE
chkconfig snmpd off
chkconfig --list snmpd | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------------------------------------
echo 2.1.15 Ensure mail transfer agent is configured for local-only mode | tee -a $LOGFILE
mkdir -p /etc/postfix
add_line /etc/postfix/main.cf "inet_interfaces" "=loopback-only"
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       2.1.16  & 2.2.1 Ensure NIS Server & Client is not enabled    ###########################################
####################################################################################################################
echo 2.1.16  Ensure NIS Server is not enabled | tee -a $LOGFILE
echo 2.2.1  Ensure NIS Client is not enabled | tee -a $LOGFILE
chkconfig ypserv off 
yum -q -y erase ypbind
chkconfig --list ypserv && rpm -q ypbind | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
# ###################################################################################################################
# ##########       2.1.17 Ensure remote shell (RSH) server is not enabled ###########################################
# ###################################################################################################################
echo 2.1.17  Ensure remote shell RSH server is not enabled | tee -a $LOGFILE
systemctl disable rsh.socket
systemctl disable rlogin.socket
systemctl disable rexec.socket
systemctl is-enabled rsh.socket && systemctl is-enabled rlogin.socket | tee -a $VALIDATION
systemctl is-enabled rexec.socket | tee -a $VALIDATION
# echo -------------------------------------------------------------------------------------------------------------
###################################################################################################################
##########       2.1.19  Ensure telnet server is not enabled ########################################################
###################################################################################################################
echo 2.1.19  Ensure telnet server is not enabled | tee -a $LOGFILE
yum -q -y erase telnet-server && yum -q -y erase telnet >>  $VALIDATION
#systemctl disable telnet.socket
# systemctl is-enabled telnet.socket | tee -a $LOGFILE
echo -------------------------------------------------------------------------------------------------------------
# ###################################################################################################################
# ##########       2.1.9  Ensure TFTP server is not enabled ########################################################
# ###################################################################################################################
# echo 2.1.9  Ensure TFTP server is not enabled | tee -a $LOGFILE
yum -q -y erase tftp-server >>  $VALIDATION
systemctl disable tftp.socket
systemctl is-enabled tftp.socket >>  $VALIDATION
# echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       2.2.3  Ensure rsync service is not enabled ########################################################
####################################################################################################################
echo 2.1.20-  Ensure rsync service is not enabled | tee -a $LOGFILE
yum -q -y erase rsync
# systemctl disable rsyncd
# systemctl is-enabled rsyncd >>  $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
# ###################################################################################################################
# ##########       2.1.21  Ensure talk server is not enabled ########################################################
# ###################################################################################################################
echo 2.2.21  Ensure talk server is not enabled | tee -a $LOGFILE
systemctl disable ntalk
systemctl is-enabled ntalk | tee -a $VALIDATION
# echo -------------------------------------------------------------------------------------------------------------
# ####################################################################################################################
# ##########       2.1.1.2  Ensure time synchronization is in use ######################################################
# ####################################################################################################################
echo 2.1.1.2  Ensure time synchronization is in use | tee -a $LOGFILE
sudo yum install ntp -y
rpm -q ntp >>  $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
# ###################################################################################################################
# ##########       2.2.4  Ensure Telnet Client is not enabled ########################################################
# ###################################################################################################################
echo 2.1.9  Ensure TFTP server is not enabled | tee -a $LOGFILE
yum remove telnet >>  $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       3.1.1 Ensure IP forwarding is disabled   ###########################################
####################################################################################################################
echo 3.1.1 Ensure IP forwarding is disabled | tee -a $LOGFILE
set_parameter /etc/sysctl.conf "net.ipv4.ip_forward" "=0"
sysctl net.ipv4.ip_forward | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
###################################################################################################################
#  3.1.2, 3.2.1, 3.2.2, 3.2.3, 3.2.5, 3.2.6, 3.2.8 , 3.2.9  set Parameter in sysctl.conf ############
###################################################################################################################

echo -e "Adding parameters to sysctl.conf" | tee -a $LOGFILE
echo 3.1.2 Ensure packet redirect sending is disabled
set_parameter /etc/sysctl.conf "net.ipv4.ip_forward" "=0"
sysctl -w net.ipv4.ip_forward=0
sysctl -w net.ipv4.route.flush=1
sysctl net.ipv4.ip_forward | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------

echo 3.2.1 Ensure source routed packets are not accepted | tee -a $LOGFILE
set_parameter /etc/sysctl.conf "net.ipv4.conf.all.send_redirects" "=0"
set_parameter /etc/sysctl.conf "net.ipv4.conf.default.send_redirects" "=0"
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.default.send_redirects=0
sysctl -w net.ipv4.route.flush=1
sysctl net.ipv4.conf.default.send_redirects | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------

echo 3.2.2 Ensure ICMP redirects are not accepted | tee -a $LOGFILE
set_parameter /etc/sysctl.conf "net.ipv4.conf.all.accept_source_route" "=0"
set_parameter /etc/sysctl.conf "net.ipv4.conf.default.accept_source_route" "=0"
sysctl -w net.ipv4.conf.all.accept_source_route=0
sysctl -w net.ipv4.conf.default.accept_source_route=0
sysctl -w net.ipv4.route.flush=1
sysctl net.ipv4.conf.all.accept_source_route | tee -a $VALIDATION 
sysctl net.ipv4.conf.default.accept_source_route  | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 3.2.3 Ensure secure ICMP redirects are not accepted | tee -a $LOGFILE
set_parameter /etc/sysctl.conf "net.ipv4.conf.all.accept_redirects" "=0"
set_parameter /etc/sysctl.conf "net.ipv4.conf.default.accept_redirects" "=0"
sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv4.conf.default.accept_redirects=0
sysctl -w net.ipv4.route.flush=1
sysctl net.ipv4.conf.all.accept_redirects | tee -a $VALIDATION
sysctl net.ipv4.conf.default.accept_redirects  | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 3.2.4 Ensure suspicious packets are logged | tee -a $LOGFILE
set_parameter /etc/sysctl.conf "net.ipv4.conf.all.secure_redirects" "=0"
set_parameter /etc/sysctl.conf "net.ipv4.conf.default.secure_redirects" "=0"
sysctl -w net.ipv4.conf.all.secure_redirects=0
sysctl -w net.ipv4.conf.default.secure_redirects=0
sysctl -w net.ipv4.route.flush=1
sysctl net.ipv4.conf.all.secure_redirect && net.ipv4.conf.default.secure_redirects  | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 3.2.5 Ensure broadcast ICMP requests are ignored | tee -a $LOGFILE
set_parameter /etc/sysctl.conf "net.ipv4.icmp_echo_ignore_broadcasts" "=1"
sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
sysctl -w net.ipv4.route.flush=1
sysctl net.ipv4.icmp_echo_ignore_broadcasts | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 3.2.6 Ensure bogus ICMP response ignored | tee -a $LOGFILE
set_parameter /etc/sysctl.conf "net.ipv4.icmp_ignore_bogus_error_responses" "=1"
sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
sysctl -w net.ipv4.route.flush=1
sysctl net.ipv4.icmp_ignore_bogus_error_responses | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 3.2.8 Ensure TCP SYN Cookies is enable | tee -a $LOGFILE
set_parameter /etc/sysctl.conf "net.ipv4.tcp_syncookies" "=1"
sysctl -w net.ipv4.tcp_syncookies=1
sysctl -w net.ipv4.route.flush=1
sysctl net.ipv4.tcp_syncookies | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 3.2.9 Ensure IPv6 router advertisements are not accepted | tee -a $LOGFILE
set_parameter /etc/sysctl.conf "net.ipv6.conf.all.accept_ra" "=0"
set_parameter /etc/sysctl.conf "net.ipv6.conf.default.accept_ra" "=0"
sysctl net.ipv4.tcp_syncookies | tee -a $VALIDATION
echo ----------------------------------------------------------------------------------------------------
####################################################################################################################
##########       4.2.3 Ensure permissions on all logfiles are configured #########################################
####################################################################################################################
echo 4.2.4 Ensure permissions on all logfiles are configured | tee -a $LOGFILE
find /var/log -type f -exec chmod g-wx,o-rwx {} + 
find /var/log -type f -ls | tee -a $VALIDATION
echo ---------------------------------------------------------------------------------------------------------------
# echo 4.2.1.1 Ensure rsyslog or syslog-ng installed | tee -a $LOGFILE
# sudo yum install rsyslog -y && yum install syslog-ng -y
# rpm -q rsyslog && rpm -q syslog-ng | tee -a $VALIDATION
# echo ---------------------------------------------------------------------------------------------------------------
echo 4.2.1.1 Ensure rsyslog service is enabled | tee -a $LOGFILE
systemctl enable rsyslog
systemctl is-enabled rsyslog | tee -a $VALIDATION
echo ---------------------------------------------------------------------------------------------------------------
echo  4.2.1.3 Ensure rsyslog default file permissions configured | tee -a $LOGFILE
set_parameter /etc/rsyslog.conf "$FileCreateMode" "0640"
grep ^\$FileCreateMode /etc/rsyslog.conf /etc/rsyslog.d/*.conf | tee -a $VALIDATIONS
echo ---------------------------------------------------------------------------------------------------------------
echo 4.2.1.4 Ensure Ensure rsyslog is configured to send logs to a remote log host | tee -a $LOGFILE
add_line /etc/rsyslog.conf "*.emerg :omusrmsg:*"
add_line /etc/rsyslog.conf "mail.* -/var/log/mail"
add_line /etc/rsyslog.conf "mail.info -/var/log/mail.info"
add_line /etc/rsyslog.conf "mail.warning -/var/log/mail.warn"
add_line /etc/rsyslog.conf "mail.err /var/log/mail.err"
add_line /etc/rsyslog.conf "news.crit -/var/log/news/news.crit"
add_line /etc/rsyslog.conf "news.err -/var/log/news/news.err"
add_line /etc/rsyslog.conf "news.notice -/var/log/news/news.notice"
add_line /etc/rsyslog.conf "*.=warning;*.=err -/var/log/warn"
add_line /etc/rsyslog.conf "*.crit /var/log/warn"
add_line /etc/rsyslog.conf "*.*;mail.none;news.none -/var/log/messages"
add_line /etc/rsyslog.conf "local0,local1.* -/var/log/localmessages"
add_line /etc/rsyslog.conf "local2,local3.* -/var/log/localmessages"
add_line /etc/rsyslog.conf "local4,local5.* -/var/log/localmessages"
add_line /etc/rsyslog.conf "local6,local7.* -/var/log/localmessages"
#pkill -HUP rsyslogd | tee -a $VALIDATIONS
echo ---------------------------------------------------------------------------------------------------------------
echo 5.6 Ensure access to the su command is restricted | tee -a $LOGFILE
add_line  /etc/pam.d/su  "auth required pam_wheel.so use_uid"
grep pam_wheel.so /etc/pam.d/su | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########      5.1.1 Ensure cron daemon is enabled ##############################################################
####################################################################################################################
echo 5.1.1 Ensure cron daemon is enabled | tee -a $LOGFILE
systemctl enable crond
systemctl is-enabled crond | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo ---------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       5.2.1 Ensure permissions on /etc/ssh/sshd_config at configured ###################################
####################################################################################################################
echo 5.2.1 Ensure permissions on /etc/ssh/sshd_config at configured | tee -a $LOGFILE
chown root:root /etc/ssh/sshd_config && chmod og-rwx /etc/ssh/sshd_config
stat /etc/ssh/sshd_config | tee -a $VALIDATION
echo ---------------------------------------------------------------------------------------------------------------
####################################################################
#####################SSH Server Configuration######################
echo "SSH server configuration" |tee -a $LOGFILE
echo 5.2.4 Ensure SSH Protocol is set to 2
set_parameter /etc/ssh/sshd_config "Protocol" " 2"
grep "^Protocol" /etc/ssh/sshd_config | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 5.2.5  Ensure SSH LogLevel is set to INFO | tee -a $LOGFILE
set_parameter /etc/ssh/sshd_config "LogLevel" "INFO"
grep "^LogLevel" /etc/ssh/sshd_config | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------------------------------------
echo 5.2.7 Ensure SSH MaxAuthTries is set to 4 or less | tee -a $LOGFILE
sed -i 's/^#MaxAuthTries.*/MaxAuthTries 4/' /etc/ssh/sshd_config
echo -------------------------------------------------------------------------------------------------------------
echo 5.2.8 Ensure SSH IgnoreRhosts is enabled | tee -a $LOGFILE
set_parameter /etc/ssh/sshd_config "IgnoreRhosts" " yes"
grep "^IgnoreRhosts" /etc/ssh/sshd_config | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 5.2.9 Disable SSH HostbasedAuthentication | tee -a $LOGFILE
set_parameter /etc/ssh/sshd_config "HostbasedAuthentication" " no"
grep "^HostbasedAuthentication" /etc/ssh/sshd_config | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 5.2.10 Disable SSH root login | tee -a $LOGFILE
set_parameter /etc/ssh/sshd_config "PermitRootLogin" " no"
grep "^PermitRootLogin" /etc/ssh/sshd_config | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 5.2.11 Ensure SSH PermitEmptyPasswords is disabled | tee -a $LOGFILE
set_parameter /etc/ssh/sshd_config "PermitEmptyPasswords" " no"
grep "^PermitEmptyPasswords" /etc/ssh/sshd_config | tee -a $VALIDATION
echo ----------------------------------------------------------------------------------------------------
echo 5.2.12 Ensure SSH PermitUserEnvironment is disabled | tee -a $LOGFILE
set_parameter /etc/ssh/sshd_config "PermitUserEnvironment" " no"
grep "^PermitUserEnviroment" /etc/ssh/sshd_config | tee -a $VALIDATION
echo ----------------------------------------------------------------------------------------------------
echo 5.2.13 Ensure only strong ciphers are used | tee -a $LOGFILE
set_parameter /etc/ssh/sshd_config "Ciphers" " chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr"
grep "^Ciphers" /etc/ssh/sshd_config | tee -a $VALIDATION
echo ---------------------------------------------------------------------------------------------------
echo 5.2.14 Ensure only approved MAC algorithms are used | tee -a $LOGFILE
set_parameter /etc/ssh/sshd_config  "MACs" " hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com" >> /etc/ssh/sshd_config
grep "MACs" /etc/ssh/sshd_config | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
# systemctl restart sshd.service >> $LOGFILE
echo -------------------------------------------------------------------------------------------------------------
echo 5.2.13 Ensure SSH Idle Timeout Interval is configured | tee -a $LOGFILE
set_parameter /etc/ssh/sshd_config "ClientAliveInterval" " 300"
set_parameter  /etc/ssh/sshd_config "ClientAliveCountMax" " 0"
grep "^ClientAliveInterval" /etc/ssh/sshd_config && grep "^ClientAliveCountMax" /etc/ssh/sshd_config | tee -a $VALIDATION
# sed -i 's/^#ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
# sed -i 's/^#LoginGraceTime.*/LoginGraceTime 60/' /etc/ssh/sshd_config
echo -------------------------------------------------------------------------------------------------------------
echo 5.2.17 Ensure SSH LoginGraceTime is set to one minute or less | tee -a $LOGFILE
sudo set_parameter /etc/ssh/sshd_config "LoginGraceTime" " 60"
grep "^LoginGraceTime" /etc/ssh/sshd_config | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########      Password requirements ##########################################################################
####################################################################################################################
echo 5.3.1 Ensure password creation requirements are configured | tee -a $LOGFILE
sudo sed -i '/^#.* minlen /s/^#//' /etc/security/pwquality.conf
sudo sed -i '/^#.* dcredit /s/^#//' /etc/security/pwquality.conf
sudo sed -i '/^#.* ucredit /s/^#//' /etc/security/pwquality.conf
sudo sed -i '/^#.* ocredit /s/^#//' /etc/security/pwquality.conf
sudo sed -i '/^#.* lcredit /s/^#//' /etc/security/pwquality.conf

sudo sed -i 's/minlen = 9*/minlen = 14/g' /etc/security/pwquality.conf
sudo sed -i 's/dcredit = 1*/dcredit=-1/g' /etc/security/pwquality.conf
sudo sed -i 's/ucredit = 1*/ucredit=-1/g' /etc/security/pwquality.conf
sudo sed -i 's/ocredit = 1*/ocredit=-1/g' /etc/security/pwquality.conf
sudo sed -i 's/lcredit = 1*/lcredit=-1/g' /etc/security/pwquality.conf

sudo grep -E 'minlen|dcredit|ucredit|ocredit|lcredit' /etc/security/pwquality.conf | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 5.3.3 Ensure password reuse is limited | tee -a $LOGFILE
add_line /etc/pam.d/password-auth "password required pam_pwhistory.so remember=5"
echo -------------------------------------------------------------------------------------------------------------
echo 5.3.4 Ensure password hashing algorithm is SHA-512 | tee -a $LOGFILE
add_line /etc/pam.d/password-auth "password sufficient pam_unix.so sha512"
add_line /etc/pam.d/system-auth "password sufficient pam_unix.so sha512"
echo -------------------------------------------------------------------------------------------------------------
echo 5.4.2 Ensure system accounts are non-login | tee -a $LOGFILE
for user in `awk -F: '($3 < 1000) {print $1 }' /etc/passwd`; do 
 if [ $user != "root" ]; then
  sudo usermod -L $user 
  if [ $user != "sync" ] && [ $user != "shutdown" ] && [ $user != "halt" ]; then
   sudo usermod -s /usr/sbin/nologin $user 
  fi 
 fi 
done
echo -------------------------------------------------------------------------------------------------------------
echo 5.4.3  Ensure default group for the root account is GID 0 | tee -a $LOGFILE
sudo usermod -g 0 root
sudo grep "^root:" /etc/passwd | cut -f4 -d: | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 5.4.4 Ensure default user umask is 027 or more restrictive | tee -a $LOGFILE
sudo set_parameter /etc/profile "umask" " 027"
grep "umask" /etc/bashrc && grep "umask" /etc/profile | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 5.4.1.3 Ensure password expiration is 365 days or less | tee -a $LOGFILE
sudo set_parameter /etc/login.defs "PASS_MAX_DAYS" " 365"
echo -------------------------------------------------------------------------------------------------------------
echo 6.1.2 Ensure permissions on /etc/passwd are configured | tee -a $LOGFILE
chown root:root /etc/passwd && chmod 644 /etc/passwd
stat /etc/passwd | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
####################################################################################################################
##########       Permission on /etc/* ################################################################################
####################################################################################################################
echo 6.1.3 Ensure permissions on /etc/shadow are configured | tee -a $LOGFILE
chown root:root /etc/group && chmod 644 /etc/group
stat /etc/shadow | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 6.1.4 Ensure permissions on /etc/group are configured | tee -a $LOGFILE
chown root:root /etc/group && chmod 644 /etc/group
stat /etc/group | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 6.1.5 Ensure permissions on /etc/gshadow are configured | tee -a $LOGFILE
chown root:root /etc/gshadow && chmod 000 /etc/gshadow
stat /etc/gshadow | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 6.1.6 Ensure permissions on /etc/passwd- are configured | tee -a $LOGFILE
chown root:root /etc/passwd- && chmod u-x,go-wx /etc/passwd-
stat /etc/passwd- | tee -a $VALIDATION
echo -------------------------------------------------------------------------------------------------------------
echo 6.1.7 Ensure permissions on /etc/shadow- are configured | tee -a $LOGFILE
chown root:root /etc/shadow- && chmod 000 /etc/shadow-
stat /etc/shadow- | tee -a $LOGFILE
echo -------------------------------------------------------------------------------------------------------------
echo 6.1.8 Ensure permissions on /etc/group- are configured | tee -a $LOGFILE
chown root:root /etc/group- && chmod u-x,go-wx /etc/group-
stat /etc/group- tee -a $LOGFILE
echo -------------------------------------------------------------------------------------------------------------
echo 6.1.9 Ensure permissions on /etc/gshadow- are configured | tee -a $LOGFILE
chown root:root /etc/gshadow- && chmod 000 /etc/gshadow-
stat /etc/gshadow- | tee -a $LOGFILE
echo ---------------------------------------------------------------------------------------------------------------
echo 6.2.3 Ensure no legacy "+" entries exist in /etc/passwd | tee -a $LOGFILE
grep '^+:' /etc/passwd
echo ---------------------------------------------------------------------------------------------------------------
echo 6.2.4 Ensure no legacy "+" entries exist in /etc/shadow | tee -a $LOGFILE
grep '^+:' /etc/shadow
echo ---------------------------------------------------------------------------------------------------------------
echo 6.2.4 Ensure no legacy "+" entries exist in /etc/group | tee -a $LOGFILE
grep '^+:' /etc/group
echo ---------------------------------------------------------------------------------------------------------------
echo ---------------------------------------------------------------------------------------------------------------
echo 6.2.5 Ensure root is the only UID 0 account | tee -a $LOGFILE
cat /etc/passwd | awk -F: '($3 == 0) { print $1 }' | tee -a $LOGFILE
echo ---------------------------------------------------------------------------------------------------------------

# Items added as part of the migration efforts not included in the hardening standards


echo -e "Implementing warning banners" | tee -a $LOGFILE
echo -e "                                                                \"ATTENTION\"

Takeda Information Security Notice
This system is for the use of Takeda authorized users only.  By using this system, all users acknowledge notice of, and agree to comply with Takeda’s Global Code of Conduct and Global Acceptable Use of Technology Policy. All Takeda supplied computers, laptops, tablets, mobile phones, systems are and remain at all times the property of Takeda. Takeda may review, monitor, audit and intercept all data created, stored, received, or sent via such equipment or systems for the purposes of administering the network and identifying, investigating or resolving suspected security threats or breaches, to the extent legally permitted. This Notice applies to the extent permissible under, and subject at all times to, applicable law.
-------------------------------------------------------------------------------------------------------------------

本システムは、タケダの許可を受けたユーザー専用です。すべてのユーザーは、本システムを使用することにより、タケダのグローバル行動規準およびテクノロジーの利用に関するグルーバルポリシーを確認し、それに従うことに同意したとみなされます。タケダが支給したコンピュータ、ノートパソコン、タブレット、携帯電話、システムおよびこれらの機器に保存されたデータは、常に会社の資産とみなされます。タケダは、これらのシステムで作成、受信、または送信したすべてのメッセージを許可された法の範囲でレビュー、モニター、監査、傍受する場合があります。目的は、ネットワークの管理や疑わしいセキュリティの脅威や情報漏洩を識別し、調査および解決することです。この通知は、許可された法の範囲で常に適用されます。
." > /etc/motd
echo "Authorized uses only. All activity may be monitored and reported." > /etc/issue
echo "Authorized uses only. All activity may be monitored and reported." > /etc/issue.net



# Disable IPV6 
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo grub2-editenv - set "kernelopts=root=/dev/mapper/rhel-root ro crashkernel=auto resume=/dev/mapper/rhel-swap rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap rhgb quiet ipv6.disable=1"

# Disable ECN 
#sudo sed '$ a net.ipv4.tcp_ecn = 0' /etc/sysctl.conf
sudo grep -qxF 'net.ipv4.tcp_ecn=0' /etc/sysctl.conf || sudo echo 'net.ipv4.tcp_ecn=0' >> /etc/sysctl.conf
sudo grep -qxF 'net.ipv6.conf.all.disable_ipv6=1' /etc/sysctl.conf || sudo echo 'net.ipv6.conf.all.disable_ipv6=1' >> /etc/sysctl.conf
sudo grep -qxF 'net.ipv6.conf.default.disable_ipv6=1' /etc/sysctl.conf || sudo echo 'net.ipv6.conf.default.disable_ipv6=1' >> /etc/sysctl.conf
sudo grep -qxF 'net.ipv6.conf.lo.disable_ipv6=1' /etc/sysctl.conf || sudo echo 'net.ipv6.conf.lo.disable_ipv6=1' >> /etc/sysctl.conf
sudo sysctl --system

# Set NTP server
echo 2.2.1.3  Ensure time synchronization is not use | tee -a $LOGFILE
sudo sed -e '/server/ s/^#*/#/' -i  /etc/chrony.conf
sudo sed -i '/^#.* 169.254.169.123 /s/^#//' /etc/chrony.conf
sudo systemctl enable chronyd.service
sudo systemctl restart chronyd.service
cat /etc/chrony.conf | grep server | grep -v "#" >>  $VALIDATION
echo -------------------------------------------------------------------------------------------------------------

echo "hardening completed" | tee -a $LOGFILE
echo "hardening completed" | tee -a $VALIDATION


#!/bin/bash

# check if dialog is installed and if its not, install it
REQUIRED_PKG="dialog"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
echo Checking for $REQUIRED_PKG: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get --yes install $REQUIRED_PKG
fi

#detect the ldap domain
ldap_domain=$(ldapsearch -LLL -x -b "" -s base namingContexts | grep "namingContexts" | awk '{print $2}')

makegldif() {
# GROUP LDIF EXAMPLE
    cat << EOF > grup.ldif
# Es pot fer servir un dels 2 DN, un per posar-lo dins a una Unitat Organitzativa i l'altre no.
# dn: cn=Grup,ou=UnitatOrganitzativa,$ldap_domain
dn: cn=Grup,$ldap_domain
objectClass: top
objectClass: posixGroup
gidNumber: 2000
cn: Grup
EOF
}

makeuldfif() {
    cat << EOF > usuari.ldif
# Es pot fer servir un dels 2 DN, un per posar-lo dins a una Unitat Organitzativa i l'altre no.
# dn: uid=Usuari,ou=UnitatOrganitzativa,$ldap_domain
dn: uid=Usuari,$ldap_domain
objectClass: top
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: person
cn: Usuari
uid: Usuari
uidNumber 2000
#gidNumber: 2000
#homeDirectory: /home/usuari
#loginShell: /bin/bash
#sn: Cognom
userPassword: caput
EOF
}

makeouldif() {
    cat << EOF > ou.ldif
# Per Afegir aquesta entrada, fes: sudo ldapadd -x -D cn=admin,$ldap_domain
dn: ou=UnitatOrganitzativa,$ldap_domain
objectClass: top
objectClass: organizationalUnit
ou: UnitatOrganitzativa
EOF
}

createxampleldif() {
    makeouldif
    makeuldfif
    makegldif
}


configure_ldapscripts(){
    cat << EOF > /etc/ldapscripts/ldapscripts.conf
# LDAP server
SERVER="ldap://localhost:389"

# Suffixes
SUFFIX="$ldap_domain" # Global suffix
GSUFFIX="ou=Grups"        # Groups ou (just under $SUFFIX)
USUFFIX="ou=Users"         # Users ou (just under $SUFFIX)
MSUFFIX="ou=Maquines"      # Machines ou (just under $SUFFIX)


# Simple authentication parameters
# The following BIND* parameters are ignored if SASLAUTH is set
BINDDN="cn=admin,$ldap_domain"
# The following file contains the raw password of the BINDDN
# Create it with something like : echo -n 'secret' > $BINDPWDFILE
# WARNING !!!! Be careful not to make this file world-readable
BINDPWDFILE="/etc/ldapscripts/ldapscripts.passwd"

# Start with these IDs *if no entry found in LDAP*
GIDSTART="10000" # Group ID
UIDSTART="10000" # User ID
MIDSTART="20000" # Machine ID

# Group membership management
GCLASS="posixGroup"   # Leave "posixGroup" here if not sure !
# When using  groupOfNames or groupOfUniqueNames, creating a group requires an initial
# member. Specify it below, you will be able to remove it once groups are populated.
#GDUMMYMEMBER="uid=dummy,$USUFFIX,$SUFFIX"

# User properties
USHELL="/bin/sh"
UHOMES="/home/%u"     # You may use %u for username here
CREATEHOMES="no"      # Create home directories and set rights ?
HOMESKEL="/etc/skel"  # Directory where the skeleton files are located. Ignored if undefined or nonexistant.
HOMEPERMS="700"       # Default permissions for home directories

# User passwords generation
PASSWORDGEN="cat /dev/random | LC_ALL=C tr -dc 'a-zA-Z0-9' | head -c8"
#PASSWORDGEN="pwgen"
#PASSWORDGEN="echo changeme"
#PASSWORDGEN="echo %u"
#PASSWORDGEN="<ask>"

# User passwords recording
# you can keep trace of generated passwords setting PASSWORDFILE and RECORDPASSWORDS
# (useful when performing a massive creation / net rpc vampire)
# WARNING !!!! DO NOT FORGET TO DELETE THE GENERATED FILE WHEN DONE !
# WARNING !!!! DO NOT FORGET TO TURN OFF RECORDING WHEN DONE !
RECORDPASSWORDS="no"
PASSWORDFILE="/var/log/ldapscripts_passwd.log"

# Where to log : local file and/or syslog
LOGTOFILE="yes"
LOGFILE="/var/log/ldapscripts.log"
LOGTOSYSLOG="no"
SYSLOGFACILITY="local4"
SYSLOGLEVEL="info"

# Temporary folder
TMPDIR="/tmp"

# OpenLDAP client commands
LDAPSEARCHBIN="/usr/bin/ldapsearch"
LDAPADDBIN="/usr/bin/ldapadd"
LDAPDELETEBIN="/usr/bin/ldapdelete"
LDAPMODIFYBIN="/usr/bin/ldapmodify"
LDAPMODRDNBIN="/usr/bin/ldapmodrdn"
LDAPPASSWDBIN="/usr/bin/ldappasswd"

# OpenLDAP client common additional options
# This allows for adding more configuration options to the OpenLDAP clients, e.g. '-ZZ' to enforce TLS
#LDAPBINOPTS="-ZZ"

# OpenLDAP ldapsearch-specific additional options
# The following option disables long-line wrapping (which makes the scripts bug
# when handling long lines). The option was introduced in OpenLDAP 2.4.24, so
# comment it if you are using OpenLDAP < 2.4.24.
LDAPSEARCHOPTS="-o ldif-wrap=no"
# And here is an example to activate paged results
#LDAPSEARCHOPTS="-E pr=500/noprompt"

# Comment ICONVBIN to disable UTF-8 conversion
ICONVBIN="/usr/bin/iconv"
#ICONVCHAR="ISO-8859-15"

# Base64 decoding
# Comment UUDECODEBIN to disable Base64 decoding
UUDECODEBIN="/usr/bin/uudecode"

# Auto
GETENTPWCMD=""
GETENTGRCMD=""

# You can specify custom LDIF templates here
# Leave empty to use default templates
# See *.template.sample for default templates
#GTEMPLATE="/path/to/ldapaddgroup.template"
#UTEMPLATE="/path/to/ldapadduser.template"
#MTEMPLATE="/path/to/ldapaddmachine.template"
GTEMPLATE=""
UTEMPLATE=""
MTEMPLATE=""
EOF
}


#-------------check-if-packages-are-installed-----------------------
pkg1=$(
  # Check if is installed
  PKG_NAME1="slapd"
  # PKG_OKY6=$(dpkg-query -W --showformat='${Package}\n' $PKG_NAME2|grep "PKG_NAME2" 2> /dev/null)
  if dpkg-query -W --showformat='${Status}\n' $PKG_NAME1 2>/dev/null |grep "install ok installed" > /dev/null; then
    echo "$PKG_NAME1 is Installed"
  else
    echo "$PKG_NAME1 is not installed."
  fi
)

pkg2=$(
  PKG_NAME2="ldap-utils"
  if dpkg-query -W --showformat='${Status}\n' $PKG_NAME2 2>/dev/null |grep "install ok installed" > /dev/null; then
    echo "$PKG_NAME2 is Installed"
  else
    echo "$PKG_NAME2 is not installed."
  fi
)

pkg3=$(
PKG_NAME3="ldapscripts"
  if dpkg-query -W --showformat='${Status}\n' $PKG_NAME3 2>/dev/null |grep "install ok installed" > /dev/null; then
    echo "$PKG_NAME3 is Installed"
  else
    echo "$PKG_NAME3 is not installed."
  fi
)

pkg4=$(
  PKG_NAME4="ldap-account-manager"
  if dpkg-query -W --showformat='${Status}\n' $PKG_NAME4 2>/dev/null |grep "install ok installed" > /dev/null; then
    echo "$PKG_NAME4 is Installed"
  else
    echo "$PKG_NAME4 is not installed."
  fi
)


#+++++++++++++set+up+main++Organizational+Units+++++++++++++++++++++++++++++++++++++++++++++++++++++

setup_main_ous(){
  cat << EOF > MAIN-OUS.ldif
dn: ou=Usuaris,$ldap_domain
ob jectClass: organizationalUnit
objectClass: top
ou: Usuaris

dn: ou=Grups,$ldap_domain
ob jectClass: organizationalUnit
objectClass: top
ou: Grups

dn: ou=Maquines,$ldap_domain
ob jectClass: organizationalUnit
objectClass: top
ou: Maquines
EOF

sudo ldapadd -f OUs.ldif -D cn=admin,$ldap_domain -xW
}

#´´´´´´´´´ldap´´password´´stuff´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´
#create temp file for ldap password
set_ldapscripts_passwd() {
    # Prompt user for secret word using dialog
    secret=$(dialog --clear --title "Set LDAP Secret" \
        --inputbox "Enter your LDAP password:" 10 30 2>&1 >/dev/tty)

    # Check if dialog was cancelled or user didn't input anything
    if [ $? -ne 0 ] || [ -z "$secret" ]; then
        echo "Operation cancelled. Maybe you didnt write a password?"
        return
    fi

    # Update the LDAP password file with the secret
    sudo echo -n '$secret' > /etc/ldapscripts/ldapscripts.passwd
    sudo chmod 400 /etc/ldapscripts/ldapscripts.passwd
    echo "Secret word '$secret' successfully set in /etc/ldapscripts/ldapscripts.passwd"
}

#--------------------------------------------------START--GRAPHICAL--INTERFACE------------------------------------------------------#

DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0

display_result() {
  dialog --title "$1" \
    --no-collapse \
    --msgbox "$result" 0 0
}

inputwindow() {
  # show an inputbox
dialog --title "Inputbox - To take input from you" \
--backtitle "Linux Shell Script Tutorial Example" \
--inputbox "Enter your LDAP password " 8 60 2>$OUTPUT
}

while true; do
  exec 3>&1
  selection=$(dialog \
    --backtitle "LDAP CONFIGURATOR v1 GRAPHICAL-EDITION" \
    --title "LDAP CONFIGURATOR - $ldap_domain" \
    --clear \
    --cancel-label "Exit" \
    --menu "$pkg1 \n $pkg2 \n $pkg3 \n $pkg4 \n  \n \n Please select:" $HEIGHT $WIDTH 4 \
    "1" "Instalar tots els paquets ldap" \
    "2" "Reconfigurar slapd i canviar el nom del domini" \
    "3" "Crear Fitxers .LDIF d'exemple" \
    "4" "Configurar LDAPSCRIPTS" \
    2>&1 1>&3)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
      clear
      echo "Program terminated."
      exit
      ;;
    $DIALOG_ESC)
      clear
      echo "Program aborted." >&2
      exit 1
      ;;
  esac
  case $selection in
    1 )
      sudo apt update && sudo apt install -y slapd ldap-utils ldapscripts ldap-account-manager
      result=$(echo && echo "S'han instalat tots els paquets correctament")
      display_result "Instalació de Paquets LDAP"
      ;;
    2 )
      sudo dpkg-reconfigure slapd
      result=$(echo "has reconfigurat el domini LDAP (slapd)".)
      display_result "Reconfiguració del Domini"
      ;;
    3 )
      createxampleldif
      result=$(echo "s'han creat els fitxers ldif d'exemple".)
      display_result "Make LDIF Examples"
      ;;
    4 )
      configure_ldapscripts
      sudo -S set_ldapscripts_passwd
      setup_main_ous
      result=$(printf "s'ha creat 'ldapscripts.conf' amb el domini actual \nS'han creat les Unitats Organitzatives Principals \nS'ha establert la contrasenya de LDAP a ldapscripts.passwd  ")
      display_result "Configuració de ldapscripts"
      ;;
    # 6 )
    #   if [[ $(id -u) -eq 0 ]]; then
    #     result=$(du -sh /home/* 2> /dev/null)
    #     display_result "Home Space Utilization (All Users)"
    #   else
    #     result=$(du -sh $HOME 2> /dev/null)
    #     display_result "Home Space Utilization ($USER)"
    #   fi
    #   ;;
  esac
done
#-----------------------------------------------------END--GRAPHICAL--INTERFACE------------------------------------------------------#

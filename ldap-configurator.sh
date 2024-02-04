#!/bin/bash

# Function to handle Ctrl+C
# exit_script() {
#     echo "Exiting..."
#     exit 1
# }
# Trap Ctrl+C
# trap exit_script SIGINT

#get the current domain name of ldap
ldap_domain=$(ldapsearch -LLL -x -b "" -s base namingContexts | grep "namingContexts" | awk '{print $2}')

# Welcome message
PosarTitol() {
cat << "EOF"

    Benvingut al...

 /$$       /$$$$$$$   /$$$$$$  /$$$$$$$          /$$$$$$   /$$$$$$  /$$   /$$ /$$$$$$$$
| $$      | $$__  $$ /$$__  $$| $$__  $$        /$$__  $$ /$$__  $$| $$$ | $$| $$_____/
| $$      | $$  \ $$| $$  \ $$| $$  \ $$       | $$  \__/| $$  \ $$| $$$$| $$| $$      
| $$      | $$  | $$| $$$$$$$$| $$$$$$$//$$$$$$| $$      | $$  | $$| $$ $$ $$| $$$$$   
| $$      | $$  | $$| $$__  $$| $$____/|______/| $$      | $$  | $$| $$  $$$$| $$__/   
| $$      | $$  | $$| $$  | $$| $$             | $$    $$| $$  | $$| $$\  $$$| $$      
| $$$$$$$$| $$$$$$$/| $$  | $$| $$             |  $$$$$$/|  $$$$$$/| $$ \  $$| $$      
|________/|_______/ |__/  |__/|__/              \______/  \______/ |__/  \__/|__/ v1.0
Fuk those shithead ldap programs! Use this instead!
EOF
}

# Function to install LDAP packages
install_ldap_packages() {
    echo "Installing LDAP packages..."
    sudo apt-get update
    sudo apt-get install -y ldap-utils slapd ldapscripts ldap-account-manager
    echo "LDAP packages installed successfully!"
}

# Function to create ldif examples
make_ldif_examples() {
    echo "Creating ldif examples..."
    cd ~

# OU LDIF EXAMPLE
    cat << EOF > ou.ldif
dn: ou=UnitatOrganitzativa,dc=domini,dc=cat
objectClass: organizationalUnit
objectClass: top
ou: UnitatOrganitzativa
EOF

# GROUP LDIF EXAMPLE
    cat << EOF > ou.ldif
# Es pot fer servir un dels 2 DN, un per posar-lo dins a una Unitat Organitzativa i l'altre no.
# dn: cn=Grup,ou=UnitatOrganitzativa,dc=domini,dc=cat
dn: cn=Grup,dc=domini,dc=cat
objectClass: top
objectClass: posixGroup
gidNumber: 2000
cn: Grup
EOF

# USER LDIF EXAMPLE
    cat << EOF > ou.ldif
# Es pot fer servir un dels 2 DN, un per posar-lo dins a una Unitat Organitzativa i l'altre no.
# dn: uid=Usuari,ou=UnitatOrganitzativa,dc=domini,dc=cat
dn: uid=Usuari,dc=domini,dc=cat
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
#--------------------------------------------------------------------------------------------------------------------


# Function to configure LDAPSCRIPTS
configure_ldapscripts() {
echo "writing the ldapscripts.conf file"
cat <<EOL > /etc/ldapscripts/ldapscripts.conf
# LDAP server
SERVER="ldap://localhost:389"

# Suffixes
SUFFIX="$ldap_domain" # Global suffix
GSUFFIX="ou=Grups"        # Groups ou
USUFFIX="ou=Users"         # Users ou 
MSUFFIX="ou=Maquines"      # Machines ou


# Simple authentication parameters
# The following BIND* parameters are ignored if SASLAUTH is set
BINDDN="cn=admin,$ldap_domain"
# The following file contains the raw password of the BINDDN
# Create it with something like : echo -n 'secret' >
# WARNING !!!! Be careful not to make this file world-readable
BINDPWDFILE="/etc/ldapscripts/ldapscripts.passwd"
# For older versions of OpenLDAP, it is still possible to use
# unsecure command-line passwords by defining the following option
# AND commenting the previous one (BINDPWDFILE takes precedence)
#BINDPWD="secret"

# Start with these IDs *if no entry found in LDAP*
GIDSTART="10000" # Group ID
UIDSTART="10000" # User ID
MIDSTART="20000" # Machine ID

# Group membership management
GCLASS="posixGroup"   # Leave "posixGroup" here if not sure !
# When using  groupOfNames or groupOfUniqueNames, creating a group requires an initial
# member. Specify it below, you will be able to remove it once groups are populated.

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

# Various binaries used within the scripts
# Warning : they also use uuencode, date, grep, sed, cut, which... 
# Please check they are installed before using these scripts
# Note that many of them should come with your OS

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

# Getent command to use - choose the ones used
# on your system. Leave blank or comment for auto-guess.
# GNU/Linux
#GETENTPWCMD="getent passwd"
#GETENTGRCMD="getent group"
# FreeBSD
#GETENTPWCMD="pw usershow"
#GETENTGRCMD="pw groupshow"
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
EOL
sudo echo "ara podriem posar la contrasenya."
}

#function to call all commands
do_all_operations(){
    install_ldap_packages
    make_ldif_examples
    configure_ldapscripts 
}

# Crida al Títol
PosarTitol
# Main menu
# Main menu
options=("Install LDAP Packages" "Make ldif examples" "Configure LDAPSCRIPTS" "Do all operations" "Exit")

select option in "${options[@]}"; do
    case $REPLY in
        1) install_ldap_packages;;
        2) make_ldif_examples;;
        3) configure_ldapscripts;;
        4) do_all_operations;;
        5) echo "Exiting..."; exit;;
        *) echo "Invalid option!";;
    esac
done

#!/bin/bash

makegldif() {
# GROUP LDIF EXAMPLE
    cat << EOF > grup.ldif
# Es pot fer servir un dels 2 DN, un per posar-lo dins a una Unitat Organitzativa i l'altre no.
# dn: cn=Grup,ou=UnitatOrganitzativa,dc=domini,dc=cat
dn: cn=Grup,dc=domini,dc=cat
objectClass: top
objectClass: posixGroup
gidNumber: 2000
cn: Grup
EOF
}

makeuldfif() {
    cat << EOF > usuari.ldif
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

makeouldif() {
    cat << EOF > ou.ldif
# Es pot fer servir un dels 2 DN, un per posar-lo dins a una Unitat Organitzativa i l'altre no.
# dn: cn=Grup,ou=UnitatOrganitzativa,dc=domini,dc=cat
dn: cn=Grup,dc=domini,dc=cat
objectClass: top
objectClass: posixGroup
gidNumber: 2000
cn: Grup
EOF
}

createxampleldif() {
    makeouldif
    makeuldfif
    makegldif
}


#´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´
checkPackages(){
# Check if slapd is installed
    if dpkg-query -l slapd 2> /dev/null; then
            echo "slapd is installed"
    else
            echo "slapd is not installed"
    fi
    
    # Check if ldap-utils is installed
    if dpkg-query -l ldap-utils 2> /dev/null; then
            echo "ldap-utils" is installed"
    else
            echo "ldap-utils" is not installed"
    fi
    
    # Check if ldapscripts is installed
    if dpkg-query -l ldapscripts 2> /dev/null; then
            echo "ldapscripts" is installed"
    else
            echo "ldapscripts" is not installed"
    fi
    
    # Check if ldap-account-manager is installed
    if dpkg-query -l ldap-account-manager 2> /dev/null; then
            echo "ldap-account-manager" is installed"
    else
            echo "ldap-account-manager" is not installed"
    fi
}

#´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´

# Create a temporary file
temp_file=$(/tmp/lconf85.temp)

# Call the function and write its output to the temporary file
checkPackages > "$temp_file"

# Read the content of the temporary file into a variable
chkPkgOutput=$(< "$temp_file")

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

while true; do
  exec 3>&1
  selection=$(dialog \
    --backtitle "LDAP CONFIGURATOR v1 GRAPHICAL-EDITION" \
    --title "LDAP CONFIGURATOR V1-G" \
    --clear \
    --cancel-label "Exit" \
    --menu "$chkPkgOutput \n \n Please select:" $HEIGHT $WIDTH 4 \
    "1" "Instalar tots els paquets ldap" \
    "2" "Reconfigurar slapd i canviar el nom del domini" \
    "3" "Crear Fitxers ldif" \
    "4" "Test Experimental Output (show if packages are installed/not)" \
    # "5" "Display Home Space Utilization" \
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
      result=$(echo "The output will be shown out of the UI.")
      display_result "Experimental"
      ;;
    # 5 )
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

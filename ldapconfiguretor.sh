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


# while-menu-dialog: a menu driven system information program

#´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´

#´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´

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
    --menu "Please select:" $HEIGHT $WIDTH 4 \
    "1" "Instalar tots els paquets ldap" \
    "2" "Crear Fitxers ldif" \
    "3" "Display Home Space Utilization" \
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
      result=$(sudo apt update && sudo apt install -y slapd ldap-utils ldapscripts ldap-account-manager && echo && echo "S'han instalat tots els paquets correctament")
      display_result "Instalació de Paquets LDAP"
      ;;
    2 )
      createxampleldif
      result=$(echo "s'han creat els fitxers ldif d'exemple".)
      display_result "Make LDIF Examples"
      ;;
    3 )
      if [[ $(id -u) -eq 0 ]]; then
        result=$(du -sh /home/* 2> /dev/null)
        display_result "Home Space Utilization (All Users)"
      else
        result=$(du -sh $HOME 2> /dev/null)
        display_result "Home Space Utilization ($USER)"
      fi
      ;;
  esac
done
#-----------------------------------------------------END--GRAPHICAL--INTERFACE------------------------------------------------------#

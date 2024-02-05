#!/bin/bash





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






# while-menu-dialog: a menu driven system information program

##########FUNCTIONS##########
install_ldap_packages() {
    echo "Installing LDAP packages..."
    sudo apt-get update
    sudo apt-get install -y ldap-utils slapd ldapscripts ldap-account-manager
    echo "LDAP packages installed successfully!"
}
#´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´
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
    cat << EOF > grup.ldif
# Es pot fer servir un dels 2 DN, un per posar-lo dins a una Unitat Organitzativa i l'altre no.
# dn: cn=Grup,ou=UnitatOrganitzativa,dc=domini,dc=cat
dn: cn=Grup,dc=domini,dc=cat
objectClass: top
objectClass: posixGroup
gidNumber: 2000
cn: Grup
EOF

# USER LDIF EXAMPLE
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
# passwrod should be generated with slappasswd or similar...
userPassword: caput

EOF
}
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
      make_ldif_examples
      result=$(echo "<S'han creat els fitxers d'exemple")
      display_result "Instalació de Paquets LDAP"
      ;;
    2 )
      result=$(make_ldif_examples)
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

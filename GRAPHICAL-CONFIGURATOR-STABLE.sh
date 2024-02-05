#!/bin/bash

# check if dialog is installed and if its not, install it
REQUIRED_PKG="dialog"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
echo Checking for $REQUIRED_PKG: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get --yes install $REQUIRED_PKG
fi

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

#´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´
ldap_domain=$(ldapsearch -LLL -x -b "" -s base namingContexts | grep "namingContexts" | awk '{print $2}')

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
    --title "LDAP CONFIGURATOR - $ldap_domain" \
    --clear \
    --cancel-label "Exit" \
    --menu "$pkg1 \n $pkg2 \n $pkg3 \n $pkg4 \n  \n \n Please select:" $HEIGHT $WIDTH 4 \
    "1" "Instalar tots els paquets ldap" \
    "2" "Reconfigurar slapd i canviar el nom del domini" \
    "3" "Crear Fitxers ldif" \
    "4" "Test Experimental Output (show if packages are installed/not)" \
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
      result=$($outputito)
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

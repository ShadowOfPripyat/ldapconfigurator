#!/bin/bash

# Welcome message
echo "Welcome to the LDAP installation script!"

# Function to install LDAP packages
install_ldap_packages() {
    echo "Installing LDAP packages..."
    sudo apt-get update
    sudo apt-get install -y ldap-utils slapd ldapscripts ldap-account-manager
    echo "LDAP packages installed successfully!"
}

# Function to create ldif examples
make_ldif_examples() {
    echo "this version of the script does not create examples."
}

# Function to configure LDAPSCRIPTS
configure_ldapscripts() {
    echo "Configuring LDAPSCRIPTS..."

    # Detect LDAP domain
    ldap_domain=$(ldapsearch -LLL -x -b "" -s base namingContexts | grep "namingContexts" | awk '{print $2}')

    # Download the configuration file from GitHub
    curl -o ldapscripts.conf https://raw.githubusercontent.com/ShadowOfPripyat/ldapconfigurator/main/ldapscripts.conf

    # Variables
    SUFFIX=${SUFFIX="$ldap_domain"}

    BINDDN=${BINDDN="cn=admin,$ldap_domain"}

    # Update the configuration file with user input
    sed -i "s|<SUFFIX>|$ldap_server|g" ldapscripts.conf
    sed -i "s|<BINDDN>|$BINDDN|g" ldapscripts.conf

    # Move the configuration file to /etc/ldapscripts/ldapscripts.conf
    sudo mv ldapscripts.conf /etc/ldapscripts/ldapscripts.conf

    echo "LDAPSCRIPTS configured successfully!"
}

# Main menu
while true; do
    echo "Please select an option:"
    echo "1. Install LDAP Packages"
    echo "2. Make ldif examples"
    echo "3. Configure LDAPSCRIPTS"
    echo "0. Exit"

    read -n 1 option
    echo ""

    case $option in
        1) install_ldap_packages;;
        2) make_ldif_examples;;
        3) configure_ldapscripts;;
        0) echo "Exiting..."; exit;;
        *) echo "Invalid option!";;
    esac
done

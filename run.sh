#!/bin/bash
##############################################################################################
#  Copyright Accenture. All Rights Reserved.
#
#  SPDX-License-Identifier: Apache-2.0
##############################################################################################

set -e

#Creating network configuration file
for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

ansible-playbook -vv /home/bevel/platforms/shared/configuration/config.yaml -e 'ansible_python_interpreter=/usr/bin/python3' --extra-vars "ordererOrg1=$ordererOrg1 peerOrg1=$peerOrg1 peerOrg2=$peerOrg2 peerOrg3=$peerOrg3 configFile=$configFile"

echo "Starting build process..."

echo "Adding env variables..."
export PATH=/root/bin:$PATH

#Path to k8s config file
KUBECONFIG=/home/bevel/build/config

# echo "Validatin network yaml"
# ajv validate -s /home/bevel/platforms/network-schema.json -d /home/bevel/build/network.yaml 

# sleep 10
# #Reset the network
# ./reset.sh configFile=$configFile


sleep 10
# echo "Running the playbook..."
exec ansible-playbook -vv /home/bevel/platforms/shared/configuration/site.yaml --inventory-file=/home/bevel/platforms/shared/inventory/ -e "@/home/bevel/build/network.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' -e "reset == 'false'"


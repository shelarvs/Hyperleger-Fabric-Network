#!/bin/bash

#Network Folder Name
cd hlf-network

#-----Chaincode Deployment-----
cd ../chaincode/fabcar/go && GO111MODULE=on 
sudo go mod vendor && cd ../../../hlf-network

echo "============================Compile Chaincode============================"
sleep 3

#Package Chaincode
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
VERSION=2

echo -n "Chaincode Name: "
read chaincodeName

peer lifecycle chaincode package $chaincodeName.tar.gz --path ../chaincode/fabcar/go/ --lang golang --label ${chaincodeName}_${VERSION}

echo "============================Package Chaincode ($chaincodeName.tar.gz)============================"
sleep 1



#Install Chaincode
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

echo "Installing Chaincode for ORG-1...!!!!"
peer lifecycle chaincode install $chaincodeName.tar.gz
sleep 1

export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

echo "Installing Chaincode for ORG-2...!!!!"
peer lifecycle chaincode install $chaincodeName.tar.gz


echo "============================Install Chaincode============================"
sleep 3



#Approve Chaincode
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051


peer lifecycle chaincode queryinstalled
sleep 3

echo -n "ORG-1 Approval----Please Copy and Paste above Package ID: "
read packageId

CC_PACKAGE_ID=$packageId


peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name ${chaincodeName} --version ${VERSION} --package-id $CC_PACKAGE_ID --sequence ${VERSION} --tls true --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem



export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051


peer lifecycle chaincode queryinstalled
sleep 3

echo -n "ORG-2 Approval----Please Copy and Paste above Package ID: "
read packageId

CC_PACKAGE_ID=$packageId

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name ${chaincodeName} --version ${VERSION} --package-id $CC_PACKAGE_ID --sequence ${VERSION} --tls true --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

echo "============================Approve Chaincode============================"
sleep 3


#Check Commit Ready
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name ${chaincodeName} --version ${VERSION} --sequence ${VERSION} --tls true --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --output json

echo "============================Chaincode Ready to Commit============================"
sleep 3

#Commit Chaincode
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name fabcar --version ${VERSION} --sequence ${VERSION} --tls true --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

echo "============================Chaincode Commit Successful============================"
sleep 3

#Check Commit Status
peer lifecycle chaincode querycommitted --channelID mychannel --name fabcar --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
sleep 2

#Invoke Chaincode
peer chaincode query -C mychannel -n $chaincodeName -c '{"Args":["queryAllCars"]}'
sleep 3


peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls true --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n fabcar --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"initLedger","Args":[]}'

echo "============================Chaincode Invoke Successful============================"
sleep 3



#Success
echo "Chaincode Upgraded Successfully.."

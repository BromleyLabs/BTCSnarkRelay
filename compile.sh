#!/bin/sh
# Modify the src file name and witness inputs as appropriate 

REPO=/home/puneet/crypto/BTCSnarkRelay
EXE=$REPO/tools/zokrates
SOLC_PATH=/usr/bin
OPTIONS="--bin --abi --optimize"

SRC_FILE=$REPO/src/btc/verify_header.code

INPUTS="0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 1 1 0 0 1 1 0 1 0 0 0 0 0 0 1 0 1 0 1 0 1 0 1 1 0 1 1 1 1 1 1 0 0 1 0 1 0 1 1 0 1 0 0 1 1 1 1 0 1 0 0 0 1 0 1 1 1 1 0 0 1 1 0 1 1 0 0 1 0 0 1 1 0 0 0 1 0 1 1 1 1 1 1 0 0 0 1 0 1 1 1 1 1 1 1 0 1 0 0 1 1 0 0 1 1 1 1 1 0 0 1 0 1 1 0 1 1 1 1 0 0 1 0 0 0 1 0 0 1 1 0 1 0 1 0 0 1 0 0 1 1 0 1 0 1 0 1 1 0 0 1 0 1 0 1 1 1 0 0 0 1 0 0 0 0 1 0 1 0 0 0 1 1 0 1 1 1 0 1 0 0 1 0 0 1 0 1 0 0 0 1 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0 0 1 1 0 0 1 0 0 0 0 0 1 0 1 1 0 1 1 0 1 1 0 0 0 0 1 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 1 0 0 0 1 1 0 1 0 1 1 1 0 1 0 1 0 0 0 0 0 1 0 0 0 0 1 0 0 0 1 1 1 1 0 1 1 0 1 1 1 0 0 0 1 0 1 1 0 0 0 1 1 1 1 0 1 0 1 1 1 0 0 1 0 1 0 0 0 0 1 0 1 0 1 0 1 1 1 0 0 1 1 1 0 0 0 1 0 0 0 0 1 1 1 0 1 0 0 1 0 1 0 1 0 0 0 1 1 1 1 0 1 1 0 1 0 1 1 1 1 0 0 1 0 1 1 1 1 1 1 1 0 1 1 1 1 0 1 0 1 1 1 1 1 1 1 1 1 1 0 0 1 0 0 0 1 0 0 0 1 0 0 1 0 0 1 0 1 0 1 1 0 0 0 0 1 1 1 1 0 0 0 1 1 1 1 1 1 1 0 0 0 0 0 1 0 0 1 0 0 0 1 0 1 0 1 1 1 1 0 0 0 1 1 1 1 1 1 1 0 1 0 1 1 1 0 1 0 1 1 1 0 1 0 0 1 1 0 1 1 1 1 1 0 0 1 0 1 0 1 1 1 0 0 1 0 1 0 0 0 1 0 0 0 0 0 1 1 0 1 0 0 1 0 0 0 0 1 0 1 0 1 0 0 0 0 1 0 1 0 0 0 1 1 0 1 0 0 1 0 1 0 1   0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 0 1 0 1 1 1 0 1 1 0 0 0 1 0 0 0 0 0 1 0 0 1 1 1 1 1 1 0 1 0 0 1 1 0 1 1 1 0 1 1 1 1 0 0 1 0 0 1 1 0 1 0 0 0 0 1 1 1 0 0 0 1 0 0 1 0 0 0 0 1 0 0 1 1 1 1 1 1 0 0 1 0 1 1 1 0 1 0 1 0 0 0 1 1 0 1 0 1 1 0 0 0 1 1 0 0 0 1 1 1 0 1 1 0 0 0 0 1 1 0 1 1 0 1 0 1 1 1 0 1 1 1 0 1 1 0 0 0 1 1 1 0 1 0 1 1 0 1 0 0 1 0 1 1 0 1 0 0 1 0 0 1 1 1 0 1 1 1 0 1 1 0 0 1 0 0 1 0 0 1 1 0 0 1 1 0 1 1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 1 0 0 1 1 1 0 0 1 1 0 1 0 1 0 1 0 1 0 1 0 0 0 0 0 0 0 1 0 1 1 1 1 1 1 1 1 1 1 0 0 1 0 0 0 0 0 1 1 0 1 0 0 1 1 1 0 1 0 1 1 0 1 0 1 0 0 0 1 1 1 0 0 1 1 0 1 0 0 1 1 0 0 1 0 1 1 0 1 1 1 1 0 1 0 0 0 0 0 1 0 0 0 0 1 1 1 0 0 1 1 1 1 0 1 0 0 1 0 0 1 0 0 0 0 1 1 1 0 1 1 1 0 1 1 1 1 1 1 0 1 1 0 0 1 0 1 0 0 0 0 1 1 1 1 1 0 1 1 0 0 0 1 0 1 1 0 0 1 1 1 0 0 0 0 0 0 1 0 1 1 0 1 1 0 0 0 1 0 1 1 1 1 0 0 1 0 0 1 1 1 0 1 1 1 1 1 0 1 1 0 0 0 1 1 1 0 1 1 0 0 1 1 0 1 1 1 1 1 1 1 0 0 1 0 0 0 0 0 1 0 0 1 0 0 1 0 0 1 1 0 1 1 1 1 1 1 1 1 0 1 0 1 1 1 0 1 0 1 1 1 0 1 0 0 1 1 0 1 1 1 1 1 0 0 1 0 1 0 1 1 1 0 0 1 0 1 0 0 0 1 0 0 0 0 0 1 1 0 1 0 0 0 0 0 0 1 1 1 1 0 1 0 0 0 1 1 0 1 0 1 1 1 0 1 0 1 1 0 0 1 0 1   1305756287  125551 749141948473392236228638560860443038398718001776885808413" 
$EXE compile -i $SRC_FILE --gadgets 
$EXE compute-witness -a $INPUTS  > witness.log
echo 'Setting up..'
$EXE setup 
echo 'export verifier ..'
$EXE export-verifier
echo 'generating proof ..'
$EXE generate-proof > proof.txt
echo 'extracting params from proof ..'
cat proof.txt | grep "^A =" > proof_params.txt
cat proof.txt | grep "^A_p =" >> proof_params.txt
cat proof.txt | grep "^B =" >> proof_params.txt
cat proof.txt | grep "^B_p =" >> proof_params.txt
cat proof.txt | grep "^C =" >> proof_params.txt
cat proof.txt | grep "^C_p =" >> proof_params.txt
cat proof.txt | grep "^H =" >> proof_params.txt
cat proof.txt | grep "^K =" >> proof_params.txt
echo 'compiling .sol..'
### Compile contact file
rm -rf contract_build 
$SOLC_PATH/solc -o contract_build $OPTIONS verifier.sol 

#!/bin/sh
# Modify the src file name and witness inputs as appropriate 

REPO=/home/puneet/crypto/zksnark
EXE=$REPO/tools/zokrates
SOLC_PATH=/usr/bin
OPTIONS="--bin --abi --optimize"

SRC_FILE=$REPO/src/simple.code
INPUTS="1 2"

$EXE compile -i $SRC_FILE 
$EXE setup
$EXE export-verifier
$EXE compute-witness -a $INPUTS 
$EXE generate-proof > proof.txt

cat proof.txt | grep "^A =" > proof_params.txt
cat proof.txt | grep "^A_p =" >> proof_params.txt
cat proof.txt | grep "^B =" >> proof_params.txt
cat proof.txt | grep "^B_p =" >> proof_params.txt
cat proof.txt | grep "^C =" >> proof_params.txt
cat proof.txt | grep "^C_p =" >> proof_params.txt
cat proof.txt | grep "^H =" >> proof_params.txt
cat proof.txt | grep "^K =" >> proof_params.txt

# Compile contact file
rm -rf contract_build 
$SOLC_PATH/solc -o contract_build $OPTIONS verifier.sol 

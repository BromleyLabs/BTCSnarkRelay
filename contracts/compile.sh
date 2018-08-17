#!/bin/bash

SOLC_PATH=/usr/bin
OPTIONS="--bin --abi --optimize"
rm -rf target
$SOLC_PATH/solc -o target $OPTIONS verifier.sol 


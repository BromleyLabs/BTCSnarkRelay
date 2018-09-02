#!/bin/sh

SOLC_PATH=/usr/bin
OPTIONS="--bin --abi --optimize"

rm -rf target 
$SOLC_PATH/solc -o target $OPTIONS btc_store.sol verifier.sol

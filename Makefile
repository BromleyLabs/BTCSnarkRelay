CC=../tools/zokrates
SOURCE_DIR=../src
SOURCE_FILE=verify_header.code
DEPS= $(shell find $(SOURCE_DIR) -name '*.code')
CC_OUT=out
SETUP=variables.inf verification.key proving.key 
PROOF=proof.txt
WITNESS_INPUT=../test/data/test_verify_header.witness
WITNESS_OUT=witness
CONTRACT=./verifier.sol
CONTRACT_EX=../contracts/verifier.sol
CONTRACT_STORE=../contracts/btc_store.sol
CONTRACTS_BIN=BTCHeaderStore.abi BTCHeaderStore.bin Verifier.abi Verifier.bin  
SOLC_PATH=/usr/bin

all: $(WITNESS_OUT) $(SETUP) $(CONTRACT) $(PROOF) $(CONTRACT_EX) $(CONTRACTS_BIN) 

$(CONTRACTS_BIN): $(CONTRACT_EX) $(CONTRACT_STORE) 
	$(SOLC_PATH)/solc --bin --abi --optimize --overwrite -o ./ $(CONTRACT_EX) $(CONTRACT_STORE)

$(PROOF): $(WITNESS_OUT) $(SETUP) 
	$(CC) generate-proof > $(PROOF) 

$(WITNESS_OUT): $(CC_OUT)
	$(CC) compute-witness -a `cat $(WITNESS_INPUT)` > witness.log

$(CONTRACT_EX): $(CONTRACT)
	python ../tools/augment.py $(CONTRACT) $(CONTRACT_EX) 

$(CONTRACT): $(SETUP) 
	$(CC) export-verifier 

$(SETUP): $(CC_OUT) 
	$(CC) setup

$(CC_OUT): $(SOURCE_DIR)/$(SOURCE_FILE) $(DEPS)
	$(CC) compile -i $< -o $@ --gadgets  



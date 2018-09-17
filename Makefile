CC=../tools/zokrates
SOURCE_DIR=../src
SOURCE_FILE=verify_multiple_headers.code
DEPS= $(shell find $(SOURCE_DIR) -name '*.code')
CC_OUT=out
SETUP=variables.inf verification.key proving.key 
PROOF=proof.txt
WITNESS_INPUT=../test/data/test_verify_multiple_headers.witness
WITNESS_OUT=witness
CONTRACT=./verifier.sol
CONTRACT_EX=../contracts/verifier.sol
CONTRACT_STORE=../contracts/btc_store.sol
CONTRACTS_BIN=BTCHeaderStore.abi BTCHeaderStore.bin Verifier.abi Verifier.bin  
SOLC_PATH=/usr/bin

all: code setup witness_out proof contracts 

code: $(CC_OUT)
setup: $(SETUP)
witness_out: $(WITNESS_OUT)
proof: $(PROOF)
contracts: $(CONTRACTS_BIN)

$(CONTRACTS_BIN): $(CONTRACT_EX) $(CONTRACT_STORE) 
	$(SOLC_PATH)/solc --bin --abi --optimize --overwrite -o ./ $(CONTRACT_EX) $(CONTRACT_STORE)

$(CONTRACT_EX): $(CONTRACT)
	python ../tools/augment.py $(CONTRACT) $(CONTRACT_EX) 

$(CONTRACT): $(SETUP) 
	$(CC) export-verifier 

$(PROOF): $(WITNESS_OUT) $(SETUP) 
	$(CC) generate-proof > $(PROOF) 

$(WITNESS_OUT): $(CC_OUT)
	$(CC) compute-witness -a `cat $(WITNESS_INPUT)` > /dev/null

$(SETUP): $(CC_OUT) 
	$(CC) setup

$(CC_OUT): $(SOURCE_DIR)/$(SOURCE_FILE) $(DEPS)
	$(CC) compile -i $< -o $@ --light --gadgets  


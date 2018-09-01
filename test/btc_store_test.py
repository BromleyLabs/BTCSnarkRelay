# Main script to test BTCHeaderStore contract 
#
# @author Bon Filey <bon@bromleylabs.io>
# @author Anurag Gupta <anurag@bromleylabs.io>
# Copyright (c) Bromley Labs Inc.        

from hexbytes import HexBytes
from bitstring import BitArray
import hashlib
import sys
from utils import *
import utils
from web3.auto import w3
from btc_utils import * 

GAS_PRICE = int(2.5*1e9) 
GAS = int(4*1e6)
ABI = '../contracts/target/BTCHeaderStore.abi'
BIN  = '../contracts/target/BTCHeaderStore.bin'
LOGFILE = '/tmp/snark.log'
HEADERS_FILE = './data/btc_headers'

logger = None

def get_hash(hash_input):
    m = hashlib.sha256()
    m.update(hash_input)
    return m.digest()

def main():
    if len(sys.argv) != 1:
        print('Usage: python snarks_test.py')
        exit(0)
    global logger

    logger = init_logger('TEST', LOGFILE)
    utils.logger = logger 

    status, txn_receipt = deploy(w3, ABI, BIN, w3.eth.accounts[0], GAS, 
                                 GAS_PRICE)
    if status != 'mined':
        logger.error('Could not deploy')
        return
    contract_addr = txn_receipt['contractAddress']
    logger.info('Contract address = %s' % contract_addr)
    tx_params = {'from': w3.eth.accounts[0], 
                 #'gas': GAS, 
                 'gasPrice': GAS_PRICE}
    _, concise = init_contract(w3, ABI, checksum(w3,contract_addr))
                               
    b,_ = get_header(12552, HEADERS_FILE) 
    txn_hash = concise.store_block_header(b.block_number, b.version, 
                               b.hash_prev, b.hash_merkel, 
                               int.from_bytes(b.timestamp, 'little'),
                               int.from_bytes(b.nbits, 'little'),
                               int.from_bytes(b.nonce, 'little'),
                               transact = tx_params) 
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)

if __name__== '__main__':
    main()

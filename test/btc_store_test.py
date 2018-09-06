# Main script to test BTCHeaderStore contract as standalone test. 
#
# @author Bon Filey <bon@bromleylabs.io>
# @author Anurag Gupta <anurag@bromleylabs.io>
#
# Copyright (c) 2018 Bromley Labs Inc.        

from hexbytes import HexBytes
from bitstring import BitArray
import hashlib
import sys, os
import re
from utils import *
import utils
from web3.auto import w3
from btc_utils import *

GAS_PRICE = int(2.5*1e9) 
GAS = int(4*1e6)
BUILD_DIR = '../contracts/target'
STORE_ABI = os.path.join(BUILD_DIR, 'BTCHeaderStore.abi')
STORE_BIN = os.path.join(BUILD_DIR, 'BTCHeaderStore.bin')
LOGFILE = '/tmp/snark.log'
HEADERS_DATA = './data/btc_headers'

logger = None

# @param contract Contract instance of BTC Headers Contract
# @param block_numbers List of block numbers
def store_headers(block_numbers, headers_file, contract, txn_params, w3):
    for bn in block_numbers:
        logger.info('Storing block %d' % bn)
        _, bbytes = get_header(bn, headers_file) 
        txn_hash = contract.store_block_header(bbytes, bn,
                                               transact = txn_params) 
        status, txn_receipt = wait_to_be_mined(w3, txn_hash)
        logger.info(txn_receipt)

# @param txn_params dict containing 'from', 'gas', 'gasPrice'
def deploy_and_init(w3, ABI, BIN, txn_params):     
    contract_addr = deploy(w3, ABI, BIN, txn_params['from'] , txn_params['gas'],
                           txn_params['gasPrice'])
    if contract_addr is None:
        return None, None
    logger.info('Contract address = %s' % contract_addr)

    _, concise = init_contract(w3, ABI, contract_addr)
 
    return concise, contract_addr

# @dev set mutual addresses in each contracts as they interact
def set_address(contract, addr, txn_params, w3):
    logger.info('Setting verifier address in headers contract')
    txn_hash = contract.set_verifier_addr(addr, transact = txn_params)
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)

def set_start_block(contract, bbytes, block_number, txn_params, w3):
    logger.info('Setting start block header')
    txn_hash = contract.store_start_block_header(bbytes, block_number,
                                                 transact = txn_params)
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)

def get_int_hash248(block_number):
    _, b0bytes = get_header(block_number, HEADERS_DATA)
    hash0 = get_btc_hash(b0bytes)  
    hash0_int = int.from_bytes(hash0[1:], 'big') # Only 31 bytes
    return hash0_int

# @param blocks Block numbers - concatenation is in order in which they are
# provided
def get_int_concat_hash248(blocks):
    ch = b''
    for b in blocks:
        _, bbytes = get_header(b, HEADERS_DATA)
        ch += bbytes 

    concat_hash = hashlib.sha256(ch).digest()
    concat_hash_int = int.from_bytes(concat_hash[1:], 'big') # Only 31 bytes
    return concat_hash_int

def main():
    if len(sys.argv) != 4:
        print('Usage: python %s <b2> <b1> <b0>' % sys.argv[0])
        print('bn: block numbers in sequencial order highest first')
        exit(0)
    global logger

    logger = init_logger('TEST', LOGFILE)
    utils.logger = logger 

    block2 = int(sys.argv[1])
    block1 = int(sys.argv[2])
    block0 = int(sys.argv[3])

    txn_params = {'from': w3.eth.accounts[0], 
                  'gas': GAS, 
                  'gasPrice': GAS_PRICE}

    contract, _ = deploy_and_init(w3, STORE_ABI, STORE_BIN, 
                                          txn_params)     
    if contract is None:
        logger.error('Could not deploy contract')
        return 1

    set_address(contract, w3.eth.accounts[0], txn_params, w3)
    _, b0bytes = get_header(block0, HEADERS_DATA)
    set_start_block(contract, b0bytes, block0, txn_params, w3)

    store_headers([block1, block2], HEADERS_DATA, contract, txn_params, w3) 

    # Verify
    last_verified_block = block0 
    h0hash_int = get_int_hash248(block0)
    concat_hash_int = get_int_concat_hash248([block2, block1])
    n_headers = 2 
   
    logger.info('Verifying ..')
    txn_hash = contract.verify(125551, 362222075228124323440975452176116135959151765539991078657306363726407925760, 99457748802113952899368401963545431390009651956962153679970886296667461646, n_headers, transact = txn_params)

    #txn_hash = contract.verify(last_verified_block, h0hash_int, concat_hash_int,
    #                           n_headers, transact = txn_params)
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)

    return 0

if __name__== '__main__':
    main()

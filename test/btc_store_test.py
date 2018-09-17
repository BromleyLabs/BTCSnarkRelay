# Main script to test BTCHeaderStore contract as standalone test. 
#
# @author Bon Filey <bon@bromleylabs.io>
# @author Anurag Gupta <anurag@bromleylabs.io>
#
# Copyright (c) 2018 Bromley Labs Inc.        

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

def store_group(bbytes, contract, txn_params, w3):
    logger.info('Storing group')
    txn_hash = contract.store_group(bbytes, transact = txn_params) 
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

def set_start_group(contract, bbytes, block_number, last_diff_adjust_time,  
                    txn_params, w3):
    logger.info('Setting start block group')

    txn_hash = contract.store_start_group(bbytes, block_number, 
                                          last_diff_adjust_time,
                                          transact = txn_params)
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)

# @dev Get BTC hash of a block, convert lowest 31 bytes to integer
# @param bbytes raw 80 bytes of a block header
def get_int_hash248(bbytes):
    hash0 = get_btc_hash(bbytes)  
    hash0_int = int.from_bytes(hash0[1:], 'big') # Only 31 bytes
    return hash0_int

def get_last_diff_adjust_time(curr_block_num, all_headers): 
    last_diff_adjust_block = curr_block_num - (curr_block_num % 2016)
    b,_ = get_header(last_diff_adjust_block, all_headers) 
    timestamp = int.from_bytes(b.timestamp, 'little')
    return timestamp

# @param blocks Block numbers - concatenation is in order in which they are
# provided. The lowest 31 bytes of the result are converted to integer.
# @param List of block bytes to be concatenated. [bytesN, bytesN-1, .. bytes0]
def get_int_concat_hash248(bbytes):
    ch = b''
    for b in bbytes:
        ch += b

    concat_hash = hashlib.sha256(ch).digest()
    concat_hash_int = int.from_bytes(concat_hash[1:], 'big') # Only 31 bytes
    return concat_hash_int

def main():
    if len(sys.argv) != 2:
        print('Usage: python %s <b0>' % sys.argv[0])
        print('b0: first block number')
        exit(0)
    global logger

    logger = init_logger('TEST', LOGFILE)
    utils.logger = logger 

    block0 = int(sys.argv[1])
    block1 = block0 + 1
    block2 = block0 + 2
    block3 = block0 + 3

    txn_params = {'from': w3.eth.accounts[0], 
                  'gas': GAS, 
                  'gasPrice': GAS_PRICE}

    contract, _ = deploy_and_init(w3, STORE_ABI, STORE_BIN, 
                                          txn_params)     
    if contract is None:
        logger.error('Could not deploy contract')
        return 1

    all_headers = open(HEADERS_DATA, 'rb').read() 
    _, b0bytes = get_header(block0, all_headers)
    _, b1bytes = get_header(block1, all_headers)
    _, b2bytes = get_header(block2, all_headers)
    _, b3bytes = get_header(block3, all_headers)

    set_address(contract, w3.eth.accounts[0], txn_params, w3)

    timestamp = get_last_diff_adjust_time(block0, all_headers) 
    set_start_group(contract, b1bytes+b0bytes, block0, timestamp, txn_params,
                    w3)

    store_group(b3bytes+b2bytes, contract, txn_params, w3) 

    # Verify
    last_verified_block = block1 # Part of verified group 
    h0hash_int = get_int_hash248(b1bytes)
    concat_hash_int = get_int_concat_hash248([b3bytes, b2bytes])
    n_headers = 2 
   
    logger.info('Verifying ..')

    txn_hash = contract.verify(timestamp, last_verified_block, h0hash_int, 
                               concat_hash_int, n_headers, 
                               transact = txn_params)
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)

    return 0

if __name__== '__main__':
    main()

# Main script to upload SNARK contract, and send proof for verification. The
# verification is successfully if generated event can be seen in the 
# transaction receipt
#
# @author Bon Filey <bon@bromleylabs.io>
# @author Anurag Gupta <anurag@bromleylabs.io>
# Copyright (c) Bromley Labs Inc.        

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
BUILD_DIR = '../build'
SNARK_ABI = os.path.join(BUILD_DIR, 'Verifier.abi')
SNARK_BIN  = os.path.join(BUILD_DIR, 'Verifier.bin')
HEADERS_ABI = os.path.join(BUILD_DIR, 'BTCHeaderStore.abi')
HEADERS_BIN = os.path.join(BUILD_DIR, 'BTCHeaderStore.bin')
PROOF = os.path.join(BUILD_DIR, 'proof.txt')
LOGFILE = '/tmp/snark.log'
HEADERS_DATA = './data/btc_headers'

logger = None

def read_proof(proof_file):
    lines = open(proof_file, 'rt').readlines()
    v = {}
    for line in lines:
        m = re.match('(^A|A_p|B|B_p|C|C_p|H|K) = Pairing.*?\((.*)\);', line)
        if m: 
            v[m.group(1)] = eval('(' + m.group(2) + ')')    
    return v

# @param contract Contract instance of BTC Headers Contract
def store_header(block_number, headers_file, contract, txn_params, w3):
    b, _ = get_header(block_number, headers_file) 
    txn_hash = contract.store_block_header(b.version, b.hash_prev, 
                                          b.hash_merkel, b.timestamp, b.nbits, 
                                          b.nonce, transact = txn_params) 

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
def set_addresses(contract_s, contract_h, addr_s, addr_h, txn_params, w3):
    logger.info('Setting verifier address in headers contract')
    txn_hash = contract_h.set_verifier_addr(addr_s, transact = txn_params)
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)

    logger.info('Setting headers contract address in verifier')
    txn_hash = contract_s.set_header_contract_addr(addr_h, 
                                                   transact = txn_params)
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)

def main():
    if len(sys.argv) != 2:
        print('Usage: python %s <block_number>' % sys.argv[0])
        exit(0)
    global logger

    logger = init_logger('TEST', LOGFILE)
    utils.logger = logger 
    block_number = int(sys.argv[1])
    txn_params = {'from': w3.eth.accounts[0], 
                  'gas': GAS, 
                  'gasPrice': GAS_PRICE}

    contract_s, addr_s  = deploy_and_init(w3, SNARK_ABI, SNARK_BIN, 
                                          txn_params)     
    contract_h, addr_h  = deploy_and_init(w3, HEADERS_ABI, HEADERS_BIN, 
                                          txn_params)     
    if contract_s is None or contract_h is None:
        logger.error('Could not deploy contracts')
        return 1

    set_addresses(contract_s, contract_h, addr_s, addr_h, txn_params, w3)

    store_header(block_number, HEADERS_DATA, contract_h, txn_params, w3) 

    _, block_bytes = get_header(block_number, HEADERS_DATA)
    block_hash = get_btc_hash(block_bytes) 
    block_hash = swap_bytes(block_hash)  # Swapped needed for input 
    block_hash_int = int.from_bytes(block_hash, 'big')
    v = read_proof(PROOF)
    logger.info('Verifying provided header..')
    txn_hash = contract_s.verifyTx(v['A'], v['A_p'], v['B'], v['B_p'], v['C'], 
                                   v['C_p'], v['H'], v['K'], [block_hash_int, 1],
                                   transact = txn_params)
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)
    
    return 0

if __name__== '__main__':
    main()

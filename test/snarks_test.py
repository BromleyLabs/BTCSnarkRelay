# Main script to upload SNARK contract, and send proof for verification. The
# verification is successful if generated event can be seen in the 
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
from btc_store_test import store_headers, set_start_block, \
                           get_int_hash248, get_int_concat_hash248
import btc_store_test

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
    if len(sys.argv) != 4:
        print('Usage: python %s <b2> <b1> <b0>' % sys.argv[0])
        print('bn: block numbers in sequencial order highest first')
        print('b0: genesis block')
        return 1 
    global logger

    logger = init_logger('TEST', LOGFILE)
    utils.logger = logger 
    btc_store_test.logger = logger

    block2 = int(sys.argv[1])
    block1 = int(sys.argv[2])
    block0 = int(sys.argv[3])
    if (block1 != block0 + 1 or block2 != block1 + 1):
        print('Incorrect block numbers')
        return 1  

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

    _, b0bytes = get_header(block0, HEADERS_DATA)
    set_start_block(contract_h, b0bytes, block0, txn_params, w3)

    store_headers([block1, block2], HEADERS_DATA, contract_h, txn_params, w3) 

    h0hash_int = get_int_hash248(block0)
    concat_hash_int = get_int_concat_hash248([block2, block1])

    v = read_proof(PROOF)
    logger.info('Verifying provided header..')
    txn_hash = contract_s.verifyTx(v['A'], v['A_p'], v['B'], v['B_p'], v['C'], 
                                   v['C_p'], v['H'], v['K'], [125551, 362222075228124323440975452176116135959151765539991078657306363726407925760, 99457748802113952899368401963545431390009651956962153679970886296667461646, 1], transact = txn_params)
    #txn_hash = contract_s.verifyTx(v['A'], v['A_p'], v['B'], v['B_p'], v['C'], 
    #                               v['C_p'], v['H'], v['K'], [block0, 
    #                                h0hash_int, concat_hash_int, 1],
    #                               transact = txn_params)
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)
    
    return 0

if __name__== '__main__':
    main()

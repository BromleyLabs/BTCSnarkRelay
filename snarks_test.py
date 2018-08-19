# Author: Bon Filey (bonfiley@gmail.com)
# Copyright 2018 Bromley Labs Inc.

from hexbytes import HexBytes
from bitstring import BitArray
import hashlib
import sys
from utils import *
import utils
from web3.auto import w3

GAS_PRICE = int(2.5*1e9) 
GAS = int(4*1e6)
ABI = '/home/puneet/crypto/zksnark/contracts/target/Verifier.abi' 
PROOF = '/home/puneet/crypto/zksnark/contracts/proof_params.txt'
PATH = '/home/puneet/crypto/zksnark/contracts/target/' 
VERIFY_KEYS = '/home/puneet/crypto/zksnark/contracts/verification.key'

logger = None

def get_hash(hash_input):
    m = hashlib.sha256()
    m.update(hash_input)
    return m.digest()

def bytes_to_bitlist(b):
    bits = BitArray(b)
    return [int(bit) for bit in bits.bin]
 
def read_proof(params_file):
    exec(open(params_file).read())     
    v = locals() 
    return (v['A'], v['A_p'], v['B'], v['B_p'], v['C'], 
            v['C_p'], v['H'], v['K'])

def read_verification_params(filename):
    exec(open(filename).read())     
    v = locals()
    return v['IC']

def update_verification_params(filename, concise, tx):
    IC = read_verification_params(filename)   
    for i in range(len(IC)):
        txn_hash = concise.update_verification_params(i, IC[i][0], IC[i][1], 
                                                      transact = tx)    
        status, txn_receipt = wait_to_be_mined(w3, txn_hash)
     
def main():
    if len(sys.argv) != 1:
        print('Usage: python snarks_test.py')
        exit(0)
    global logger

    logger = init_logger('TEST', '/tmp/stride.log')
    utils.logger = logger 

    status, txn_receipt = deploy(w3, 'Verifier', PATH, 
                                 w3.eth.accounts[0], GAS, GAS_PRICE)
    if status != 'mined':
        logger.error('Could not deploy')
        return
    contract_addr = txn_receipt['contractAddress']
    logger.info('Contract address = %s' % contract_addr)
    tx_params = {'from': w3.eth.accounts[0], 
                 #'gas': GAS, 
                 'gasPrice': GAS_PRICE}
    _, concise = init_contract(w3, ABI, checksum(w3,contract_addr))
                               
    A, A_p, B, B_p, C, C_p, H, K = read_proof(PROOF)

    # Setup
    #update_verification_params(VERIFY_KEYS, concise, tx_params) 

    #hash_input_str = bytes(64) 
    #hash_out = get_hash(hash_input_str)

    #out_bitlist = bytes_to_bitlist(hash_out)
    #out_bitlist = [1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0]
    txn_hash = concise.verifyTx(A, A_p, B, B_p, C, C_p, H, K, [1], 
                                transact = tx_params) 
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)

if __name__== '__main__':
    main()

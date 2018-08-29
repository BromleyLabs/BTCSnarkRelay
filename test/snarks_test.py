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
ABI = '/home/puneet/crypto/zksnark/build/contract_build/Verifier.abi' 
PROOF = '/home/puneet/crypto/zksnark/build/proof_params.txt'
PATH = '/home/puneet/crypto/zksnark/build/contract_build'
LOGFILE = '/tmp/snark.log'

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
     
def main():
    if len(sys.argv) != 1:
        print('Usage: python snarks_test.py')
        exit(0)
    global logger

    logger = init_logger('TEST', LOGFILE)
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

    txn_hash = concise.verifyTx(A, A_p, B, B_p, C, C_p, H, K, [1], 
                                transact = tx_params) 
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)

if __name__== '__main__':
    main()

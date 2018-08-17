# Author: Bon Filey (bonfiley@gmail.com)
# Copyright 2018 Bromley Labs Inc.

from hexbytes import HexBytes
import sys
from utils import *
import utils
from web3.auto import w3

GAS_PRICE = int(2.5*1e9) 
GAS = int(4*1e6)
CONTRACT_ADDR = '0x8cc1440c6564f53a6cd0d6c95c5a270c597b150a' 
ABI = '/home/puneet/crypto/zksnark/contracts/target/Verifier.abi' 
PATH = '/home/puneet/crypto/zksnark/contracts/target/' 

logger = None
A = [0x30305d5fe746559bf8e70379cc4c65a1493f2f2431d412f933853fcc114e311e, 0xf0980af63d4e7e5e6aa1956159f09f69833079cd3d5581a629b3fee4266f517]
A_p = [0x6314a3eec994e8fd1b06e811ff9eb129f2c4f4e06b5e6e89185ca049293bfc5, 0x24eb8b8622e07fe82988cf0eba3d72964a7425d7c3044a7cb91d0710840520a1]
B = [[0x22ef398a03ee2c6040d84d08f9fa0b8cc7661640992a96d0a4a73b29760d61c7, 0x26562b679809a0b52df320554db506f64eceeca3b6b28bc31fbb01943bee9c12], [0xf1d45042fd5e158cf2b2e6ff86723e5ca2e59ca07033b5bb40f22c1204b5efc, 0x24bd5393413909eb6f274b05b9169a6f99930b6fc3e2ee41ff54f9ddc0d80fd7]]
B_p = [0x11009ef08057d7e73119bd5efaff86109b9e0b09e42c946895f001949328a3fc, 0x815fd651f0d745ce73e1b34ec7752384d6b855707a07965f535af1bf23da3ef]
C = [0x24101e28cbc66a40516e9c1dc9c6a06b934bf7ac1129d3a44e549daecfd5ba76, 0x2c0598db4044005e99c8435451afd689c2eb5680f5952ecd2c250a4e9154dc01]
C_p = [0x1a653003bb75b8e6ed7bcad48abe2b19d2b0047e486cebe00f605f20ba0e97a1, 0x107018798426da37b38bdcdf5e7c17cd09369fd1b1d19052ddabfbea5ff213d0]
H = [0x2260f79c76ccfdeb1b8ef371362e7b8852e1a57ed6df8d728def8f5be113925e, 0x1893702f46fc73e42a61119ed7a74f8b3292c63977a85a913b19166fb80ddee5]
K = [0x1b9e3d68a66cffae2ca32581d691082f7688daeb386d97832f754fa50a71f4aa, 0x21cdc85a3614cd6c06228ccda1d1ce77b0e592374dc1139a1f24742eb1005756]

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
                 'gas': GAS, 
                 'gasPrice': GAS_PRICE}
    _, concise = init_contract(w3, ABI, checksum(w3,contract_addr))
                               
    inputs = [1, 2, 3, 4, 5, 6, 7, 8, 9, 45]
    txn_hash = concise.verifyTx(A, A_p, B, B_p, C, C_p, H, K, inputs, transact = tx_params) 
    status, txn_receipt = wait_to_be_mined(w3, txn_hash)
    logger.info(txn_receipt)

if __name__== '__main__':
    main()

# Various utility functions to run the User and Custodian app.
#
# Author: Bon Filey (bonfiley@gmail.com)
# Copyright 2018 Bromley Labs Inc.

from hexbytes import HexBytes
from web3 import Web3
from web3.contract import ConciseContract
import time
import string
import pika
import logging 
import json
import random
import os

logger = None

def init_logger(module_name, file_name):
    logger = logging.getLogger(module_name)
    logger.setLevel(logging.DEBUG)
    fh = logging.FileHandler(file_name)
    fh.setLevel(logging.DEBUG)
    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    # create formatter and add it to the handlers
    formatter = logging.Formatter('[%(asctime)s][%(name)s][%(levelname)s]: %(message)s')
    fh.setFormatter(formatter)
    ch.setFormatter(formatter)
    # add the handlers to the logger
    logger.addHandler(fh)
    logger.addHandler(ch)
    return logger

def init_contract(w3, abi_file, contract_addr):
    abi = open(abi_file, 'rt').read()
    contract = w3.eth.contract(abi = abi, 
                               address = contract_addr) 
    concise = ConciseContract(contract)
    return contract, concise

def checksum(w3, addr):
    if not w3.isChecksumAddress(addr):
        return w3.toChecksumAddress(addr)
    else:
        return addr

def generate_random_string(w3, length): # Generates random letter string 
    s = ''.join([random.choice(string.ascii_uppercase) for n in range(length)])
    h_hash = w3.sha3(text = s) 
    return s, h_hash

def sign_bytearray(w3, barray, account_adr):
    # Returns hex strings like '0x3532..'
    h = HexBytes(barray)
    h_hash = w3.sha3(hexstr = h.hex())
    sig = w3.eth.sign(account_adr, h_hash) # sig is HexBytes   
    r = w3.toBytes(hexstr = HexBytes(sig[0 : 32]).hex())
    s = w3.toBytes(hexstr = HexBytes(sig[32 : 64]).hex())
    v = sig[64 : 65]
    v_int = int.from_bytes(v, byteorder='big')
    h_hash = w3.toBytes(hexstr = h_hash.hex())
    return h_hash, v_int, r, s
 
# Functon returns (receipt, status)
def get_transaction_receipt(w3, txn_hash):
    txn_receipt = w3.eth.getTransactionReceipt(txn_hash)
    status = 'wait' 
    hash_str = HexBytes(txn_hash).hex()
    if txn_receipt is not None: 
        if txn_receipt['status'] != 1:
            status = 'error' 
            logger.error('Transaction: %s' % hash_str)
        if txn_receipt['blockNumber'] is not None:
            logger.info('Transaction mined: %s' % hash_str) 
            status = 'mined' 
    return txn_receipt, status

def wait_to_be_mined(w3, txn_hash):
    # timeout in nblocks
    logger.info('Tx hash: %s' % HexBytes(txn_hash).hex())
    logger.info('Waiting for transaction to get mined')
    while 1: 
        txn_receipt, status = get_transaction_receipt(w3, txn_hash)  
        if status == 'error' or status == 'mined': 
            break
        time.sleep(5) 
    logger.debug(txn_receipt)
    return status, txn_receipt

def wait_to_be_mined_batch(txn_hashes):
    # txn_hashes: list of txn_hash
    # timeout in nblocks
    logger.info('Tx hashes: %s' % txn_hashes) 
    logger.info('Waiting for transactions to get mined')
    handled = [] 
    while len(handled) != len(txn_hashes): 
        time.sleep(5)
        for i, txn_hash in enumerate(txn_hashes):
            if txn_hash in handled: 
                continue
            txn_receipt, status = get_transaction_receipt(txn_hash)  
            if status == 'error' or status == 'mined':
                handled.append(txn_hash)
    logger.info('All transactions handled')

def erc20_approve(w3, erc20_address, from_addr, to_addr, amount, 
                  gas, gas_price):
    erc20_abi = open('erc20.abi', 'rt').read() 
    erc20 = w3.eth.contract(abi = erc20_abi, address = erc20_address) 
    concise = ConciseContract(erc20)
    txn_hash = concise.approve(to_addr, amount,
                            transact = {'from': from_addr, 'gas': gas, 
                                        'gasPrice': gas_price}) 
    return wait_to_be_mined(txn_hash)

def event_match(event, txn_hash = None, args = None):
    if txn_hash:
        if event['transactionHash'] != txn_hash:
            return False
    if args is not None:
        for k in args:
            if k not in event['args']:
                return False
            if args[k] != event['args'][k]:
                return False
    return True

# expected_args is dict of key value pairs of the event
def wait_for_event(w3, event_filter, txn_hash = None, args = None, 
                   timeout = 200):
    # timout in nblocks
    start = w3.eth.blockNumber
    while w3.eth.blockNumber < start + timeout: 
        time.sleep(3)
        events = event_filter.get_new_entries()
        if len(events) == 0:
            continue 
        for event in events:
            if event_match(event, txn_hash, args):
                return event                    
 
    logger.error('Event wait timeout!') 
    return None

def unlock_accounts(w3, accounts_list, pwd):
    for a in accounts_list:
        w3.personal.unlockAccount(a, pwd) 

def deploy(w3, contract_name, path, owner, gas, gas_price):
    logger.info('Deploying contract %s on Ethereum' % contract_name)
    abi_file = os.path.join(path, contract_name + '.abi')
    bin_file = os.path.join(path, contract_name + '.bin')
    abi = open(abi_file, 'rt').read()
    bytecode = '0x' + open(bin_file, 'rt').read() 
    contract = w3.eth.contract(abi = abi, bytecode = bytecode)
    txn_hash = contract.constructor().transact({
        'from' : owner, 
        #'gas' : gas, 
        'gasPrice' : gas_price
    }) 
    return wait_to_be_mined(w3, txn_hash)

def kill(self, contract_name):
    conf = self.chain_config
    self.logger.info('Killing contract %s on %s' % (contract_name, conf.name)) 
    abi_file = os.path.join(conf.contract_path, contract_name + '.abi')
    bin_file = os.path.join(conf.contract_path, contract_name + '.bin')
    abi = open(conf.abi_file, 'rt').read() 
    contract = self.w3.eth.contract(abi = abi, address = conf.contract_addr)
    concise = ConciseContract(contract)
    txn_hash = concise.kill(transact = {'from' : conf.contract_owner, 
                             'gas' : conf.gas, 'gasPrice' : conf.gas_price}) 
    return self.wait_to_be_mined(txn_hash)


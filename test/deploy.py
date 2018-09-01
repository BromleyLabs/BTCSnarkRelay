# This script deploys a given contact.  PATH where contract ABI is present
# needs to be specified.
#
# @author Bon Filey <bon@bromleylabs.io>
# @author Anurag Gupta <anurag@bromleylabs.io>
# Copyright (c) Bromley Labs Inc.        

from hexbytes import HexBytes
import sys
from utils import *
import utils
from web3.auto import w3

GAS_PRICE = int(2.5*1e9) 
GAS = int(4*1e6)

logger = None

def main():
    if len(sys.argv) != 3:
        print('Usage: python deploy.py  <abi_path> <bin_path>')
        exit(0)
    global logger

    logger = init_logger('DEPLOY', '/tmp/stride.log')
    utils.logger = logger 
    abi_path = sys.argv[1] 
    bin_path = sys.argv[2]
    deploy(w3, abi_path, bin_path, w3.eth.accounts[0], GAS, GAS_PRICE)

if __name__== '__main__':
    main()

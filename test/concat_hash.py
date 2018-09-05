# Script to hash concatenated block hashes of n blocks.  The output is used
# to compute witness for verify_multiple_headers.code.  Note that block hashes
# are BTC block hashes, i.e. double sha256, while the hash of concatenated
# hashes is just sha256 once.  
#
# @author Bon Filey <bon@bromleylabs.io>
# @author Anurag Gupta <anurag@bromleylabs.io>
# Copyright (c) Bromley Labs Inc.        

import sys
import hashlib
from btc_utils import * 
from  bitstring import BitArray

HEADERS_FILE = './data/btc_headers'

def main():
   if len(sys.argv) < 2:
       print('Usage: python %s <bn bn-1 bn-2 ...>')
       print('bn: block number')
       exit(0) 

   block_numbers = [int(x) for x in sys.argv[1:]]
     
   concat_hashes = bytes(0) 
   for bn in block_numbers:
       _, block_bytes = get_header(bn, HEADERS_FILE)
       concat_hashes += get_btc_hash(block_bytes) 

   hash_of_concat = hashlib.sha256(concat_hashes).digest()
   hash248 = hash_of_concat[1:]  # 32 bytes 

   print('Bin: %s' % hash_of_concat)
   print('Hex: %s' % hash_of_concat.hex())
   print('Int: %d' % int.from_bytes(hash_of_concat, 'big'))
   print('Hash248 Int: %d' % int.from_bytes(hash248, 'big'))

   return 0 
   
if __name__== '__main__':
    main()

# Script to extract BTC header from a file that contains multiple such headers
# in raw format. 
#
# @author Bon Filey <bon@bromleylabs.io>
# @author Anurag Gupta <anurag@bromleylabs.io>
# Copyright (c) Bromley Labs Inc.        

import sys
from bitstring import BitArray
from btc_utils import * 

HEADERS_FILE = './data/btc_headers'

def main():
   if len(sys.argv) != 2:
       print('Usage: python get_header.py <block_number>')
       exit(0) 

   block_number = int(sys.argv[1])
   b, block_bytes = get_header(block_number, HEADERS_FILE)
   if b is None: 
       return 1 

   htime = int.from_bytes(b.timestamp, 'little') 
   nbits = int.from_bytes(b.nbits, 'little') 

   block_hash =  get_btc_hash(block_bytes)   
   hash248 = block_hash[1:]  # 31 bytes
   print('Hash (Hex): %s' % block_hash.hex()) 
   print('Hash (Int): %d' % int.from_bytes(block_hash, 'big')) 
   print('Hash248 (Int): %d' % int.from_bytes(hash248, 'big')) 
   print('Block Number: %d' % b.block_number)
   print('Prev Hash: %s' % b.hash_prev.hex())
   print('TimeS: %d' % htime)
   print('NBits: %d' % nbits)
 
   bits = BitArray(block_bytes)
   bits_str = ''
   for bit in bits.bin:  
       bits_str += bit + ' '  
   print(bits_str)
   
   return 0 
   
if __name__== '__main__':
    main()

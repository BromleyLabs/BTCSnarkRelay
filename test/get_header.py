# Script to extract BTC header from a file that contains multiple such headers
# in raw format. 
#
# @author Bon Filey <bon@bromleylabs.io>
# @author Anurag Gupta <anurag@bromleylabs.io>
# Copyright (c) Bromley Labs Inc.        

import sys
from hexbytes import HexBytes
from bitstring import BitArray
from btc_utils import * 

HEADERS_FILE = './data/btc_headers'

def print_block(b, block_bytes):
   bh = bytearray(b.hash_prev)
   bh.reverse()

   htime = int.from_bytes(b.timestamp, 'little') 
   nbits = int.from_bytes(b.nbits, 'little') 

   print('Block Number: %d' % b.block_number)
   print('Prev Hash: %s' % HexBytes(bh).hex())
   print('TimeS: %d' % htime)
   print('NBits: %d' % nbits)
 
   bits = BitArray(block_bytes)
   bits_str = ''
   for bit in bits.bin:  
       bits_str += bit + ' '  
   print(bits_str)

def main():
   if len(sys.argv) != 2:
       print('Usage: python get_header.py <block_number>')
       exit(0) 
   block_number = int(sys.argv[1])
   b, block_bytes = get_header(block_number, HEADERS_FILE)
   if b is None: 
       return 1 

   print_block(b, block_bytes)
   
   return 0 
   
if __name__== '__main__':
    main()

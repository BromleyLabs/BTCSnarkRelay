# Script to extract BTC header from a file that contains multiple such headers
# in raw format. 
#
# @author Bon Filey <bon@bromleylabs.io>
# @author Anurag Gupta <anurag@bromleylabs.io>
# Copyright (c) Bromley Labs Inc.        

import sys
from hexbytes import HexBytes
from bitstring import BitArray

HEADERS_FILE = './data/btc_headers'

def main():
   if len(sys.argv) != 2:
       print('Usage: python get_header.py <block_number>')
       exit(0) 

   all_headers = open(HEADERS_FILE, 'rb').read()
   nblocks = int(len(all_headers) / 80 - 1)  
   block_number = int(sys.argv[1])
   if block_number > nblocks - 1 or block_number < 0:
       print('This block number does not exist')
       exit(0)

   start_byte = block_number * 80
   block_bytes = all_headers[start_byte: start_byte + 80]
   
   prev_hash = block_bytes[4: 4+32]   
   htime = block_bytes[68 : 68+4] 
   nbits = block_bytes[72 : 72+4]
    
   bh = bytearray(prev_hash)
   bh.reverse()

   htime = int.from_bytes(htime, 'little') 
   nbits = int.from_bytes(nbits, 'little') 

   print('Block Number: %d' % block_number)
   print('Prev Hash: %s' % HexBytes(bh).hex())
   print('TimeS: %d' % htime)
   print('NBits: %d' % nbits)
 
   bits = BitArray(block_bytes)
   bits_str = ''
   for bit in bits.bin:  
       bits_str += bit + ' '  
   print(bits_str)

if __name__== '__main__':
    main()

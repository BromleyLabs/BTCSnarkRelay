# Script convert a hex string into bits - returns a string as well as a list 

import sys
from utils import *

def main():
   if len(sys.argv) != 2:
       print('Usage: python hex_to_bits.py <hex string with 0x prefix>')
       exit(0) 

   s,l = hex_to_bits(sys.argv[1][2:])
   print(s)
   print(l)

if __name__== '__main__':
    main()

# Script to present a hash value in hex from output of SNARK output generator 
# The output should be saved in a file with {} around start and end so that
# this python script reads it as a dictionary. Example:
# {"~out_0": 1, "~out_1": 1, "~out_10": 0, "~out_100": 0, "~out_101": 0, "~out_102": 1, "~out_103": 0, ...... }
#
# @author Bon Filey <bon@bromleylabs.io>
# @author Anurag Gupta <anurag@bromleylabs.io>
# Copyright (c) Bromley Labs Inc.        

import sys
from bitstring import BitArray

def main():
    if len(sys.argv) != 2:
       print('Usage: python read_hash.py <filename>')
       exit(0) 

    s = open(sys.argv[1], 'rt').read()   
    d = eval(s)
    out = []
    for i in range(0, 256):
        k = '~out_%d' % i
        out.append(d[k])

    print(BitArray(out))

if __name__== '__main__':
    main()

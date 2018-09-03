# Script to add BTC header verification custom code to verifier.sol generated
# by ZoKrates tool 
#
# @author Bon Filey <bon@bromleylabs.io>
# @author Anurag Gupta <anurag@bromleylabs.io>
# Copyright (c) Bromley Labs Inc.        

import sys

header = \
'''
/**
 * Large portion of this file was auto-generated using ZoKrates tool.   
 * Modifications related to BTCSnarkRelay have been done here which include
 * fetching marking a bitcoin header on BTCHeaderStore contract as verified. 
 *
 * @author Bon Filey (bon@bromleylabs.io)
 * @author Anurag Gupta (anurag@bromleylabs.io)
 * 
 * Copyright (c) 2018 Bromley Labs Inc. 
 */
'''
code0 = \
'''
import "./btc_store.sol";

'''

code1 = \
'''
    address m_header_contract_addr = address(0);

'''

code2 = \
'''
    /**
     * @dev One time setting
     */
    function set_header_contract_addr(address addr) public {
        require(m_header_contract_addr == address(0));    
        m_header_contract_addr = addr; 
    }

'''

code3 = \
'''
            /* Mark header verified */
            require(BTCHeaderStore(m_header_contract_addr).mark_verified(input[0]) == true); 

'''

def line_with_pattern(lines, pattern):
    for i, line in enumerate(lines):
        if line.find(pattern) != -1:
            return i      
    return None

def main():
    if len(sys.argv) != 3:
        print('Usage: python %s <input .sol> <output .sol>' % sys.argv[0])
        return 0

    if sys.argv[1].strip() == sys.argv[2].strip(): 
        print('Specify different input, output file names')
        return 0

    lines = open(sys.argv[1], 'rt').readlines()

    index = line_with_pattern(lines, 'pragma solidity') 
    lines.insert(index-1, header)  
    lines.insert(index+1, code0)  

    index = line_with_pattern(lines, 'contract Verifier {') 
    lines.insert(index+2, code1) 

    index = line_with_pattern(lines, 'function verifyingKey()') 
    lines.insert(index, code2)

    index = line_with_pattern(lines, 'if (verify(inputValues, proof) == 0') 
    lines.insert(index+1, code3) 

    out = open(sys.argv[2], 'wt') 
    for line in lines:
        out.write(line) 
    out.close()

if __name__== '__main__':
    main()

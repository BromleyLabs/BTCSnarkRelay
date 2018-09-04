/** 
 * @title BTCSnarkRelay BTC Header Store Contract 
 * @dev Contract on Ethereum that stores the BTC headers.
 * 
 * @author Bon Filey (bon@bromleylabs.io)
 * @author Anurag Gupta (anurag@bromleylabs.io)
 * 
 * Copyright (c) 2018 Bromley Labs Inc. 
 */

pragma solidity ^0.4.24;

contract BTCHeaderStore {
    
    struct HeaderInfo {
        bytes4 version; // All values byte-swapped  
        bytes32 prev_header_hash;
        bytes32 merkel_root;
        bytes4 timestamp;
        bytes4 nbits;
        bytes4 nonce;
        bool verified; /* Whether this block has been verified to be correct */
    }


    mapping (uint => HeaderInfo) public m_headers;
    address m_verifier_addr = address(0); /* Contract address */
   
   /*
    * @dev One time setting of contract that is going to call mark_verified() 
    * method.
    */
    function set_verifier_addr (address addr) public {
       require(m_verifier_addr == address(0));  
       m_verifier_addr = addr;
    }

    /**
    * @dev The function stores the given BTC header without verifying anything. 
    * Note that all input values in byte-swapped  litte-endian format. 
    */
    function store_block_header(bytes4 version, bytes32 prev_header_hash, 
                                bytes32 merkel_root, bytes4 timestamp, 
                                bytes4 nbits, bytes4 nonce) external { 

        bytes32 hash1 = sha256(abi.encodePacked(version, prev_header_hash, 
                                                merkel_root, timestamp, nbits, 
                                                nonce));
        bytes32 hash2 = sha256(abi.encodePacked(hash1));
        
        m_headers[uint(hash2)] = HeaderInfo(version, prev_header_hash, merkel_root, 
                                      timestamp, nbits, nonce, false);
    } 

    /**
     * @dev Mark a block header verified.  This method can only be called 
     * by verifier contract.
     */
    function mark_verified(uint block_hash) public returns (bool) {
        require(m_verifier_addr != address(0));
        require(msg.sender == m_verifier_addr);

        m_headers[block_hash].verified = true;

        return true;
    }
}

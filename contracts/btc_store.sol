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

import "./BytesLib.sol";

contract BTCHeaderStore {
    using BytesLib for bytes;
     
    struct HeaderInfo { 
        bytes data;  /* Header data */ 
        bool verified; 
    }

    uint m_last_verified_block = 0;
   
    /* block_number => HeaderInfo map */
    mapping (uint => HeaderInfo) public m_headers; 

    address m_verifier_addr = address(0); /* Contract address */

    /**
     * @dev Utility function to computes bitcoin header hash by double hashing 
     * using sha256. 
     */
    function btc_hash(bytes b) internal pure returns(bytes32) {
       bytes32 hash1 = sha256(b);
       bytes32 hash2 = sha256(abi.encodePacked(hash1));
       return hash2;
    }

    /**
     * @dev Utility function to convert first 248 bits (31 bytes) of a given
     * hash into uint. This is needed due to field limitations at the verifier 
     * contract.
     */
    function hash_to_uint248(bytes32 hash) internal pure returns(uint) {
        bytes memory b = abi.encodePacked(hash);
        b[0] = 0x00;
        return BytesLib.toUint(b, 0); 
    }


    /*
     * @dev One time setting of contract that is going to call verify()
     * method.
     */
    function set_verifier_addr (address addr) public {
       require(m_verifier_addr == address(0));  
       m_verifier_addr = addr;
    }

    /**
     * @dev Initialize the start header. The header is assumed to be verified.
     * This is one-time setting. 
     * @param block_number assumed > 0
     */
    function store_start_block_header(bytes data, uint block_number) public {
        require(m_last_verified_block == 0);
        require(block_number > 0);
        m_headers[block_number] = HeaderInfo(data, true); 
        m_last_verified_block = block_number;
    }

    /**
    * @dev The function stores the given BTC header without verifying anything. 
    * Note that all input values in byte-swapped  litte-endian format. 
    */
    function store_block_header(bytes data, uint block_number) public { 
        /* Not already stored and verified */
        require(m_headers[block_number].verified == false);

        m_headers[block_number] = HeaderInfo(data, false); 
    } 

    /**
     * @dev Verify a group of headers. This method can only be called by 
     * by SNARK verifier contract. 
     * @param hash248 Int of lower 248 bits of hash of last verified block
     * @param concatHash248 Int of lower 248 bits of 
     * hash(concat(hash of headers to be verified)
     * @param n_headers Number of headers to be verified. The headers are
     * ordered - latest first
     */
    function verify(uint last_verified_block, uint hash248, uint concatHash248,
                    uint n_headers) public returns (bool) {
        require(m_verifier_addr != address(0));
        require(msg.sender == m_verifier_addr);
        
        require(last_verified_block == m_last_verified_block); 

        bytes32 last_block_hash = btc_hash(m_headers[last_verified_block].data);
        require(hash_to_uint248(last_block_hash) == hash248);

        uint n_highest = m_last_verified_block + n_headers;
        bytes memory concat_headers;
        bytes32 header_hash;
        for (uint i = 0; i < n_headers; i++) { 
            header_hash = btc_hash(m_headers[n_highest - i].data);
            concat_headers = BytesLib.concat(concat_headers, 
                                             abi.encodePacked(header_hash)); 
        }
        bytes32 concatHash = sha256(concat_headers); 
        require(concatHash248 == hash_to_uint248(concatHash));

        for (i = 0; i < n_headers; i++) 
            m_headers[m_last_verified_block + i + 1].verified = true;
         
        m_last_verified_block += n_headers;

        return true;
    }
}

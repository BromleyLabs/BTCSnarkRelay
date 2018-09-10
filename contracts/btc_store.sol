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
    uint m_init_diff_adjust_time; /* Block time when difficulty was adjusted */
   
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

    /**
     * @dev Utility function to extract BTC block time. Block time is stored in 
     * 4 bytes. 28 bytes are padded to make it 32 bytes and then converted to
     * uint.  The function will raise exception if block number provided as 
     * arugment is not available.
     */

    function get_block_time(uint block_number) internal view returns (uint) { 
        bytes memory block_bytes = m_headers[block_number].data;     
        bytes memory time_bytes = BytesLib.slice(block_bytes, 68, 4);
        bytes memory padding = new bytes(28); /* To make it 32 bytes */ 
        time_bytes = BytesLib.concat(padding, time_bytes);
        return BytesLib.toUint(time_bytes, 0); 
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
    function store_start_block_header(bytes data, uint block_number, 
                                      uint diff_adjust_time) public {
        require(m_last_verified_block == 0);
        require(block_number > 0);
        m_headers[block_number] = HeaderInfo(data, true); 
        m_last_verified_block = block_number;
        m_init_diff_adjust_time = diff_adjust_time;
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
     * @dev The function computes the block where difficulty was adjusted last,
     * i.e block % 2016 == 0, and extracts the time of the block.  If there is
     * no previous block present, the initialized time is considered.
     */
    function get_last_diff_adjust_time(uint last_verified_block) internal
                                       view returns (uint) {
        int last_diff_adjust_block = int(last_verified_block) - 
                                     int((last_verified_block % 2016));
        if (last_diff_adjust_block < 0) 
            return m_init_diff_adjust_time;

        return get_block_time(uint(last_diff_adjust_block));
    }

    /**
     * @dev Verify a group of headers. This method can only be called by 
     * by SNARK verifier contract. 
     * @param last_diff_adjust_time Time of the block when difficulty was
     * adjusted.
     * @param hash248 Int of lower 248 bits of hash of last verified block
     * @param concatHash248 Int of lower 248 bits of 
     * hash(concat(hash of headers to be verified)
     * @param n_headers Number of headers to be verified. The headers are
     * ordered - latest first
     */
    function verify(uint last_diff_adjust_time, uint last_verified_block, uint hash248, uint concatHash248,
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

        require(get_last_diff_adjust_time(last_verified_block) == last_diff_adjust_time); 

        for (i = 0; i < n_headers; i++) 
            m_headers[m_last_verified_block + i + 1].verified = true;
         
        m_last_verified_block += n_headers;

        return true;
    }
}

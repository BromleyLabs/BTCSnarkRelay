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
     
    struct GroupInfo {  /* Group of headers */
        bytes data;  /* Concatenated headers data with order: hn, hn-1, ..h0 */ 
        bool verified; 
    }
    uint m_group_len = 2; /* Hard coded */
    uint m_last_verified_group = 0; /* Index */
    uint m_first_block = 0; /* Block number of first block stored */
    uint m_init_diff_adjust_time; /* Block time when difficulty was adjusted */
   
    /* group_hash(248 bits) => GroupInfo */
    mapping(uint => GroupInfo) public m_group_info; 
    /* group_number -> group_hash(248 bits) */ 
    mapping (uint => uint) public m_group_hash;

    address m_verifier_addr = address(0); /* Contract address */

    /**
     * @dev One time setting of contract address that is going to call verify()
     * method.
     */
    function set_verifier_addr (address addr) public {
       require(m_verifier_addr == address(0));  
       m_verifier_addr = addr;
    }

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
     * hash into uint. This is needed due to field limitations of the verifier 
     * contract.
     */
    function hash_to_uint248(bytes32 hash) internal pure returns(uint) {
        bytes memory b = abi.encodePacked(hash);
        b[0] = 0x00;
        return BytesLib.toUint(b, 0); 
    }

    /**
    * Return data of a block given a block number. The data is actually stored
    * in group of headers - as concatenated bytes. The block header bytes are 
    * extracted.
    */
    function get_block(uint block_number) internal view returns (bytes) {
        uint group_number = get_group_number(block_number); 
        bytes memory group_bytes = m_group_info[m_group_hash[group_number]].data; 
        uint block_index = get_block_index(block_number); 
        uint start = block_index * 80; /* 80 bytes per header */ 
        bytes memory block_bytes = BytesLib.slice(group_bytes, start, 80);  
        return block_bytes;
    }

    /**
     * @dev Utility function to extract BTC block time. Block time is stored in 
     * 4 bytes. 28 bytes are padded to make it 32 bytes and then converted to
     * uint. The function raises exception if block number provided is not 
     * available.
     */
    function get_block_time(uint block_number) internal view returns (uint) { 
        bytes memory block_bytes = get_block(block_number);
        bytes memory time_bytes = BytesLib.slice(block_bytes, 68, 4);
        bytes memory padding = new bytes(28); /* To make it 32 bytes */ 
        time_bytes = BytesLib.concat(padding, time_bytes);
        return BytesLib.toUint(time_bytes, 0); 
    }

    /**
     * @dev Compute group number given block_number. 
     */
    function get_group_number(uint block_number) internal view returns (uint) {
        return (block_number - m_first_block) / m_group_len;  
    }

    /**
     * @dev Compute position of a block within a group. Note that order of 
     * headers is reverse - hn,hn-1..h0.  Hence, index obtained after modulo
     * needs to be reversed.
     */
    function get_block_index(uint block_number) internal view returns (uint) {
        uint i = (block_number - m_first_block) % m_group_len;
        return (m_group_len - 1) - i;  /* reverse */
    }

    /**
     * @dev Initialize the start group. The header group is assumed to be 
     * verified. This is one-time setting. 
     * @param data All header bytes concatenated. Order hn,hn-1,...h0
     * @param block_number of first block (oldest) block in the group
     * @param diff_adjust_time Block time when difficulty was adjusted last
     * starting latest block in submitted block headers.
     */
    function store_start_group(bytes data, uint block_number,
                               uint diff_adjust_time) public {
        require(m_first_block == 0); /* One time */ 
        require(block_number > 0); /* TODO: Do we really need this */ 

        m_first_block = block_number;
        m_last_verified_group = get_group_number(block_number); 
        m_init_diff_adjust_time = diff_adjust_time;

        store_group(data);

        m_group_hash[m_last_verified_group] =  hash_to_uint248(sha256(data));
    }

    /**
     * @dev The function stores the group of BTC headers without verifying 
     * anything. Only m_group_len number of blocks can be submitted. 
     * @param data All header bytes concatenated - hn, hn-1, ..h1, h0
     */
    function store_group(bytes data) public { 
        uint hash248 = hash_to_uint248(sha256(data));
        require(m_group_info[hash248].verified == false);
        require(data.length == 80 * m_group_len); 

        m_group_info[hash248] = GroupInfo(data, false); 
    } 

    /**
     * @dev The function computes the block where difficulty was adjusted last,
     * i.e block % 2016 == 0, and extracts the time of the block. If there is
     * no previous block present, the initialized time is considered.
     */
    function get_last_diff_adjust_time(uint last_verified_block) internal
                                        view returns (uint) {
        int last_diff_adjust_block = int(last_verified_block) - 
                                     int(last_verified_block % 2016);

        if (last_diff_adjust_block < int(m_first_block)) 
            return m_init_diff_adjust_time;

        return get_block_time(uint(last_diff_adjust_block));
    }

    /**
     * @dev Verify a group of headers. This method can only be called by 
     * by SNARK verifier contract. 
     * @param last_diff_adjust_time Block time when difficulty was adjusted last
     *        starting latest block in submitted block headers.
     * @param last_verified_block Block Number of latest block of last verified
     *        group.
     * @param hash248 Int of lower 248 bits of BTC hash of last verified block
     * @param concatHash248 Int of lower 248 bits of 
     *        hash(concat(headers to be verified))
     * @param n_headers Number of headers to be verified. The headers are
     *        ordered - latest first
     */
    function verify(uint last_diff_adjust_time, uint last_verified_block, 
                    uint hash248, uint concatHash248, uint n_headers) public 
                    returns (bool) {
        require(m_verifier_addr != address(0));
        require(msg.sender == m_verifier_addr);
        require(n_headers == m_group_len);
        
        require(get_group_number(last_verified_block) == m_last_verified_group); 
        bytes32 last_block_hash = btc_hash(get_block(last_verified_block));
        require(hash_to_uint248(last_block_hash) == hash248);
        require(get_last_diff_adjust_time(last_verified_block) == last_diff_adjust_time); 

        m_group_info[concatHash248].verified = true;
        m_last_verified_group += 1; 
        m_group_hash[m_last_verified_group] = concatHash248;

        return true;
    }
}

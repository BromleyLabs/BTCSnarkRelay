# BTC Snark Relay

zk-SNARKs is a technology that utilises the concept of zero knowledge proofs, that can dramatically improve blockchain scaling. Computations can be carried out offchain and their correctness can be verified onchain without having to execute them onchain. Furthermore, the amount of onchain computation required for verification is independent of the size and complexity of the computation, allowing for arbitrarily complex computations to be carried out for no additional onchain verification cost.

BTCSnarkRelay is a proof-of-concept  implementation of how zk-SNARKs can be used to move computation offchain. It is an implementation of BTC Relay, but using zk-SNARKS for doing the bulk of the Bitcoin block header verification. 

BTC Relay is an Ethereum contract implementation of Bitcoin SPV. This allows secure, onchain verification of Bitcoin transactions without any intermediaries. dApps that need to verify Bitcoin transactions in a trustless manner can make use of this relay.

Relayers submit Bitcoin block headers to the contract. These headers are then verified by the BTC Relay contract and verified headers are stored onchain. The contract can be queried by users/dApps to check for the validity of a Bitcoin transaction, allowing for participation of Bitcoin transactions in Ethereum contracts.

One of the main challenges faced by smart contract platforms such as Ethereum is lack of scalability and costly onchain computation. The validation of a single block header on BTC Relay costs around X gas. On this basis, the cost of updating BTC headers for one month would be around $Y. These costs can become economically prohibitive for a lot of use cases, and some of the more complex computations are cannot be done on chain at all due to the capacity limitations imposed through the block gas limit. BTCSnarkRelay demonstrates an approach to solving this problem by moving this computation offchain.

Implementing zk-SNARKS is quite complex given the number of different parts that make up the machinery behind the technology. (maybe a couple of lines explaining what implementation of snarks entails). Some excellent work has been done by the Zokrates team in building a toolset that helps convert a computational problem to a form to which zk-SNARKs can be applied, and also creation of the other parts required for Snarks machinery. BTCSnarkRelay makes use of this toolset.


## BTC Header Validation Process

### 1. Submission of block headers

Submission of a batch of n Bitcoin block headers. The following information is submitted to the contract:

n Block headers, ordered
Concat Hash = Hash(Hash(Header n) + Hash(Header n-1) +...+ Hash(Header 1))
The hash of the string formed from concatenating all the submitted block headers in sequence.

The contract saves this information, and also creates a mapping from the Concat Hash to the Headers (one to many mapping)

The contract also auto assigns block numbers sequentially to each Header, starting with the block number of the last verified block header + 1.

### 2. Snark Function

This function takes as private input the following:

The block headers Hn, Hn-1,..,H1, H0 

H0 is previous block header which is assumed to be verified.

Public inputs:

1. Block number of H0 which is previous block (also the last verified block).
2. Block Hash of H0.
3. Concat Hash (constructed as in 1 above)

This function will validate the headers, including difficulty and will also validate the passed Concat Hash against the passed block headers.

### 3. Verification Contract. 

This contract takes in the following inputs:

The public inputs from 2.
The proof of the snark function from 2.

The contract will verify the proof.

It will then verify that the Concat Hash is valid, by concatenating all the onchain headers that map to the supplied concat hash, taking the hash of this string and then comparing this hash to the passed concat hash.

It will then compare the passed previous block hash H0 (i.e. the block hash stored in the header before H1)

It will compare the passed Block Number of H0 to the Block Number assigned to H0 stored on chain.

If all these validations pass, it will mark all of these headers as being valid

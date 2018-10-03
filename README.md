# BTC SNARK Relay


BTCSnarkRelay is a proof-of-concept implementation of an onchain Bitcoin light client (SPV) on Ethereum, that carries out verifiable offchain BTC header verification using zk-SNARKs. It is an implementation similar to BTC Relay, but uses zk-SNARKS for carrying out the Bitcoin block header verification offchain.


## Background

[BTC Relay](https://github.com/ethereum/btcrelay) is an Ethereum contract implementation of Bitcoin SPV. This allows secure, onchain verification of Bitcoin transactions without any intermediaries. dApps that need to verify Bitcoin transactions in a trustless manner can make use of this relay.

Relayers submit Bitcoin block headers to the contract. These headers are then verified by the BTC Relay contract and verified headers are stored onchain. The contract can be queried by users/dApps to check for the validity of a Bitcoin transaction, allowing for participation of Bitcoin transactions in Ethereum contracts.

One of the main challenges faced by smart contract platforms such as Ethereum is lack of scalability and costly onchain computation. The cost of validating and storing a single block header on BTC Relay is around [200,000 gas](https://etherscan.io/tx/0x3f84a29f030802bdfda6734eeb3b60ebc4a3d79f92e8249a0733b11c1a5ad85d). These costs can become economically prohibitive for many use cases, and some of the more complex computations are cannot be done on chain at all due to the capacity limitations imposed by the block gas limit. BTCSnarkRelay demonstrates an approach to solving this problem by moving this computation offchain and by batching the verification of BTC headers. Whereas this approach will have a cost benefit vs BTC Relay only if a large number of BTC headers are verified in a single batch ( > 13), it demonstrates how zk-SNARKs can be applied to improve scaling.

## The Technology

[zk-SNARKs](http://chriseth.github.io/notes/articles/zksnarks/zksnarks.pdf) is a technology based on zero knowledge proofs, that has the potential to dramatically improve blockchain scaling. Computations can be carried out offchain and their correctness can be verified onchain without having to execute them onchain. Furthermore, the amount of onchain computation required for verification is independent of the size and complexity of the computation, allowing for arbitrarily complex computations to be carried out at no incremental onchain cost.

Implementing zk-SNARKs is quite complex given the number of different parts that make up the machinery behind the technology. The computational problem has to be converted into the right form through a sequence of non-trivial steps followed by another intricate process of creating the actual proof. Some excellent work has been done by the [ZoKrates](https://github.com/JacobEberhardt/ZoKrates) team in building a toolset that helps convert a computational problem to a form that can be operated upon. The toolset also creates the other parts required for zk-SNARKs verification. BTCSnarkRelay development utilises this toolset.

## How It Works

Unlike in BTCRelay, where the onchain submission of headers and their verification are part of a single Ethereum transaction, BTCSnarkRelay decouples the two so as to remove the bottleneck imposed by the gas limit for a single transaction/block. The overall process is as follows:

* Submission of Bitcoin Block Headers (Onchain)
* Generation of SNARK proof for block headers verification (Offchain)
* Verification of the generated SNARK proof (Onchain)



### Submission of Bitcoin Block Headers

Multiple sequential block headers can be submitted to the contract at a time. Multiple calls for submission can be made to submit a larger number of headers, making up a batch. In the following step, verification of these headers is done for an entire batch in one go, as there is no incremental cost in onchain SNARK verification with increase in batch size.

The submitted batch of block headers is stored, initialised as unverified, and a mapping between a computed batch hash and the headers is created (e.g. with 5 headers):

BatchHash = Hash(Header 1 + Header 2 + ... + Header 5)

For each block header, a sequential block number is assigned continuing from the last verified block stored onchain.


### Generation of SNARK proof for block headers verification

The witness generator for the SNARK function is fed the following inputs:

Private Inputs:
* All the block headers to be verified. These would be the same headers that were submitted in a single batch, H1 to H5.

Public Inputs:
* The BatchHash
* Blocknumber of the last verified block header stored onchain
* The hash of the last verified block header
* The timestamp of the last difficulty adjustment prior to the first submitted block header

The SNARK function carries out the following checks:

* Validates that for each header that its previous block hash matches the computed hash of the previous block header.  
* The target difficulty for each block is verified.  
* The BatchHash is validated against the computed hash of the concatenated block headers.  



### Verification of the generated SNARK proof

The verification contract takes as input the generated proof and the public inputs to the witness generator.

It carries out the following checks on the inputs, and where necessary uses information from previously verified blocks stored onchain:


* Verify the proof
* Verify that the Block Hash of the last verified block is correct
* Verify that the block number of the first header is correct
* Verify that the timestamp of the last difficulty adjustment is correct  

If these verifications are successful, all the block headers stored onchain corresponding to the BatchHash are marked as verified.  

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes

### Installing
Instructions here have been tried on Ubuntu 16.04.  

Clone this repo.

Install the following:
* `python 3.5`
* `solc` (solidity compiler)
* `ganache-cli` (For Ethereum local testing)
* `zokrates` (as given  at https://github.com/JacobEberhardt/ZoKrates). Copy the binary `zokrates` from docker to `./tools`.

From inside Python's virtual environment install following modules using `pip`:
* `bitstring`
* `hexbytes`

To build all modules inside root `BTCSnarkRelay` dir:
* Set `solc` path in `Makefile`
* `> mkdir build`
* `> cd build`
* `> make -f ../Makefile`

This could take several hours.  

### Running the tests
* Run `ganache-cli` in a separate terminal
* `> cd test`
* `> python snarks_test.py 125550`

125550 is the start block number used for testing. To change the same, change corresponding witness file  `test/test_verify_multiple_headers.witness` and re-generate witness and proof using `Makefile`

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

## Acknowledgements

* [ZoKrates](https://github.com/JacobEberhardt/ZoKrates)
* [BTC Relay](https://github.com/ethereum/btcrelay)







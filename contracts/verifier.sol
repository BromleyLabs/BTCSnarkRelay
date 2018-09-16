// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

/**
 * Large portion of this file was auto-generated using ZoKrates tool.   
 * Modifications related to BTCSnarkRelay have been done here which include
 * marking a bitcoin header on BTCHeaderStore contract as verified. 
 *
 * @author Bon Filey (bon@bromleylabs.io)
 * @author Anurag Gupta (anurag@bromleylabs.io)
 * 
 * Copyright (c) 2018 Bromley Labs Inc. 
 */

pragma solidity ^0.4.14;

import "./btc_store.sol"; 

library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point) {
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point p) pure internal returns (G1Point) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return the sum of two points of G1
    function addition(G1Point p1, G1Point p2) internal returns (G1Point r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 6, 0, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point p, uint s) internal returns (G1Point r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 7, 0, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] p1, G2Point[] p2) internal returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 8, 0, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point a1, G2Point a2, G1Point b1, G2Point b2) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2,
            G1Point d1, G2Point d2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;

    address m_header_contract_addr = address(0);  /* BTC Store contract */

    struct VerifyingKey {
        Pairing.G2Point A;
        Pairing.G1Point B;
        Pairing.G2Point C;
        Pairing.G2Point gamma;
        Pairing.G1Point gammaBeta1;
        Pairing.G2Point gammaBeta2;
        Pairing.G2Point Z;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G1Point A_p;
        Pairing.G2Point B;
        Pairing.G1Point B_p;
        Pairing.G1Point C;
        Pairing.G1Point C_p;
        Pairing.G1Point K;
        Pairing.G1Point H;
    }

    /**
     * @dev Set address of contract where BTC headers are stored. This is a
     * one-time setting. 
     */
    function set_header_contract_addr(address addr) public {
        require(m_header_contract_addr == address(0));    
        m_header_contract_addr = addr; 
    }

    function verifyingKey() pure internal returns (VerifyingKey vk) {
        vk.A = Pairing.G2Point([0x2b3513c3a7db37c1f15b1f591170907e7b83a72a5ca34c749a4a084c74c6f19d, 0x2fc021d38475f4b1c56356bac93f957106e3e24629c0fb716470de6709c794ab], [0x5deb97ad2e5441e445c24d38f9f11bb6da6bc6207dca2eaa07fdd5bc2e12a4, 0x1598ec5829b587820f7d4c521c2c8196f0b3e59458c2e1d5a6e7f1e69dc5d2ae]);
        vk.B = Pairing.G1Point(0xe37706d55c40a6153a42090ef65f25186e6a5142eec4c838ec0aacaa3f5478a, 0x16bd54ed41a242768fb317e719e39fa9b3ac50e39f2204ccd52f276f88c0019d);
        vk.C = Pairing.G2Point([0xe20d5be4432efb21f71a11c301ed3e84e2ed6b816084070274aaf28f179e169, 0x2014cddbd8d1c04713c44cb33955830641d45302b99f13c59d395e9279901be2], [0x248635b7e434a4214b4441e4720141cfc7cae61e4cd9ede9b77b925d8324eab3, 0x20a3bd6cff66a1db3b4292c3f199311e376427f4a50311bdaac9ec27891b2cfa]);
        vk.gamma = Pairing.G2Point([0x2d3e5296378e1403bb496e23457a67ea043ef11b25b87c601ec05dd2c7768cdc, 0x17bb15b1f14aa138efcad99dcb893c0222ac73ebadd3a9a9bc385934a621e259], [0xdf18443701614f9e3f7641539f2657ee2b639514710186db1544bf351e645ef, 0x776aa5d890da5c19cc83693ce952a2eea9e6ada653886ed3585a001ec97936d]);
        vk.gammaBeta1 = Pairing.G1Point(0x1621c727354057da0179b2cd406f548b5a28de9e055cdca8928a5ff6906987f8, 0x173d1a390eed4d270b5dc0ccfb94d472d7774dc79c21ce52ee377cd89e6b21aa);
        vk.gammaBeta2 = Pairing.G2Point([0xc96def37b7218245f1b51ef8ea8ec29164596eae710349c54da21f5371330dc, 0x2df0c0f8ad8fc0df76700d0804092e1f54abfb95823562ae8a6309834a2f0e86], [0x18e9fe3e244e7167cfac1ce59064e0fca62ec0399170b8953b73e4ba1708698f, 0x1d4b214f78524a6d7499579ae3c67562d689b22886e7de5d271357b4f9a4aedb]);
        vk.Z = Pairing.G2Point([0x155541585db0e8738eeec697cc90bffe4d71601589f6a4b35e26e692c5aef92d, 0x10d2fe7478a7001265911813216bfdf342be94c41f47b81847bf09b808a3ca0], [0x224d5c2f9ee92dbf74cdfd1a84eccf883f0153a2fe72ea92a3967397500dae23, 0x20205abb96e6db67e63e02c14cdc48ed23efa2fa1775f85815f539ed07d30256]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0x1caa6299e8178b2af90c47903e381f5dbd225ed99ffc4926d546f7b8c1035486, 0xa0b43cd70fd4e52253d06a38da32ba2586953323b75214e04d0b2596bcf2108);
        vk.IC[1] = Pairing.G1Point(0x10f86d669d7423d9ea7576afb9d6ae9a7db2a215a7debe2d1ea6e72e4366b327, 0xdcdc02512118832e7821858e6fe573001f7a2df23c9db6b7ef9d6f9166c3922);
        vk.IC[2] = Pairing.G1Point(0x131748f370ba6b9855b63903a8438c99218a6c146380a47cb5f283109641dfaa, 0x207ae524642c400c5603b46f0b79ac48d0e34604f73cb694ce1d4319fb4a606);
        vk.IC[3] = Pairing.G1Point(0x5df250bb8d9a0b5fee0b19f0f254414ec9a3c88aac72b870720f55912ab019c, 0x216d77e5c03fd2d865b0bc88142727c754229a09b2b37e0e07c95d106c03de59);
        vk.IC[4] = Pairing.G1Point(0x214d058c7077a348ab89f26e359efc6096a197f0ccc8c2b89f4ec00c56d882ab, 0x186f393e1256b445bd786adc7439bf48b3a493be951cad226d1880a4dd4b1afd);
        vk.IC[5] = Pairing.G1Point(0x1931f258ce441b50587f909fe7c9d48f6e9f893cf9186be84015b8e8a30db196, 0x1c912d9f991b7f498b24cd6533be3715fc19b06cf2d91c6a9f9b853618a43f46);
    }
    function verify(uint[] input, Proof proof) internal returns (uint) {
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++)
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd2(proof.A, vk.A, Pairing.negate(proof.A_p), Pairing.P2())) return 1;
        if (!Pairing.pairingProd2(vk.B, proof.B, Pairing.negate(proof.B_p), Pairing.P2())) return 2;
        if (!Pairing.pairingProd2(proof.C, vk.C, Pairing.negate(proof.C_p), Pairing.P2())) return 3;
        if (!Pairing.pairingProd3(
            proof.K, vk.gamma,
            Pairing.negate(Pairing.addition(vk_x, Pairing.addition(proof.A, proof.C))), vk.gammaBeta2,
            Pairing.negate(vk.gammaBeta1), proof.B
        )) return 4;
        if (!Pairing.pairingProd3(
                Pairing.addition(vk_x, proof.A), proof.B,
                Pairing.negate(proof.H), vk.Z,
                Pairing.negate(proof.C), Pairing.P2()
        )) return 5;
        return 0;
    }
    event Verified(string s);
    function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[5] input
        ) public returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.A_p = Pairing.G1Point(a_p[0], a_p[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.B_p = Pairing.G1Point(b_p[0], b_p[1]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.C_p = Pairing.G1Point(c_p[0], c_p[1]);
        proof.H = Pairing.G1Point(h[0], h[1]);
        proof.K = Pairing.G1Point(k[0], k[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {

            /* Mark group of headers verified. In this case 2 headers */ 
            require(BTCHeaderStore(m_header_contract_addr).verify(input[0], 
                                  input[1], input[2], input[3], 2) == true);
            emit Verified("Transaction successfully verified.");
            return true;
        } else {
            return false;
        }
    }
}

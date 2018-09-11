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
        vk.A = Pairing.G2Point([0x540b06f7093346dbad9d30d975872d899de98a7a7bb36f8d2222c456a843cfd, 0x24f75c0be7d69cd689551c38df470699149f5d0480e42680af2149b37ed668c0], [0x19139c0eedc2cb111e846638232a4e8b8a8f919597d4c540b243ccdef4cdd515, 0xa8cc14346eeec025274d568b9fc2a86ffe9a0e85cf40f56c7cef2e5e9d31f4e]);
        vk.B = Pairing.G1Point(0x1da634b1ff60cc66b9873c303e5f8c45907e68a0c6605cf540b267e345956c14, 0x1469122dff9b0d364d1aeef33d61bfdfa3cd62bfeac7e91b9c044ed5f59983fa);
        vk.C = Pairing.G2Point([0x2eeaf819e206705ee3889a9c06d63cd71cf44ffadb10f705232c4f0c291172f5, 0xec4e2db8918155498110bb813b3245a1d5227a0d698e1e8f5e828ebf0dadbf], [0x129b4b0da2ca84187015704d5b728b67493221609d750038e55257add990473b, 0xbb9852f7e80f510435e3c975b51c52f4483ece661d3e5efe12ce8721f7f5b29]);
        vk.gamma = Pairing.G2Point([0x5edb8a37ebcd1d101233f6746fdbef3de24278f2c616adcc02f2b983d89fa7c, 0x3a356718a6ab8a7604a7083d8dc4a582779fa0d24ea31d9d4d76ff58650a03c], [0x2ba7bad48a9c23fd00f116744e4c1e4713183b08916c3d302d9bc0feba87c6a6, 0x13a911063228c2b880d3c0ffc10ac5b4769956fd37e46e1bb067f87d5694d1b0]);
        vk.gammaBeta1 = Pairing.G1Point(0x10af398d2579cf046be0c97ddbbaee6460648ede7481d059ce92a7c128f5f251, 0x1edae91212228b069766d2c28048d9eae3021d0087626575a933594c5ecb17f0);
        vk.gammaBeta2 = Pairing.G2Point([0x2f144d1bebd39dd1e4d4b81d500d018ec16dea192cb99e2f462a25b31a3cf9ae, 0x2fb5c12f624777df771502d1d1e6c2f740f3836ba4483de5efa4c2a50cbe9314], [0x839e7a85ef3e6878c5dca245dc3dd4bf733dee32ddaf45bb85b78f6b44dc11e, 0x2fa703e42c119124571df3a2ac7e7a96272b9e3b01a7be2f031154f1cacca95b]);
        vk.Z = Pairing.G2Point([0x22dcfacd5fa28eb55fcad55bc527517ee46ea76f8554c6580339527ef332bdc2, 0x15565455a0991b396f62bfee1265ddc9b21681bf7ab53dfe32c80c13ded87165], [0x1e0497d6ebc2d655cdf9bbe249f14565a15b72a2312beadfacf7a76aefc8e49f, 0x1b959e46df15e63bf025abbce93beacfdc4ff2d43a76d1570efd803accab8f96]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0x27db854535bdbe5a79cb4f126cbd90611b836c291d4910852f4180953e3f3aea, 0x3165888058b8d7fdd28294cb022d9a029058bf9dae618e6fc7b331b2c184435);
        vk.IC[1] = Pairing.G1Point(0x41bb7dd5111f4267c1fdcbeadd8357939888ae99eb8ffe30b5a50afd598c1c9, 0x26003bb6b7558a9943f7886e9600fdbf7a643ee7edf89f4478194d7c2438aa68);
        vk.IC[2] = Pairing.G1Point(0x5cdcde1b746caa83ad52b7d8cd19e27495ca384c5ad2000acebcffc14f511e5, 0x11d590872b03cd338c345f05bdda10d3976f50f4ce4796b3696256b2822274c6);
        vk.IC[3] = Pairing.G1Point(0x180f5715eb80970bf53c7b45f26ac51d8dfc7610ba78aae80ae21555aeec193b, 0x288a742b5628e0ea1c45e5a17b699f1b9392477e67ae6b3717a3014094a98223);
        vk.IC[4] = Pairing.G1Point(0x13c00a1da1d29aef0234e493c8a03355c064b4e09a8df7fc43d70bbb07764af5, 0x2ccc9fe7c668f41bb6d454d63b695bf654afe0842cc04c553f32cec1ca710760);
        vk.IC[5] = Pairing.G1Point(0x3e67d216779457b2b74ac299d4ded130162ca4a00f9102b59a9ded3f6a70e2a, 0x21cd83df1869ed2700672e527b673ea90bb2eeb59d48761a836e9dfc089382ea);
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

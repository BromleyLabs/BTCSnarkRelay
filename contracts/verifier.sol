// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

    address m_header_contract_addr = address(0);

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
     * @dev One time setting
     */
    function set_header_contract_addr(address addr) public {
        require(m_header_contract_addr == address(0));    
        m_header_contract_addr = addr; 
    }

    function verifyingKey() pure internal returns (VerifyingKey vk) {
        vk.A = Pairing.G2Point([0x31449d41b58dcb7cf022735b067d1ee501cdb9b57a0027409a0672e092e540f, 0x588b638cf53df53b7d08265523de840a0436b4ce61a37731e4b435a5a1a3a98], [0x8deff0b670ab89f48ec51fda8c193af8bc00347d263ca1abc96fe4078c52e07, 0x1d0816ad1ab5e2e74ac94ed667f559518fff8b970561f63a2f282d07d1ba1aff]);
        vk.B = Pairing.G1Point(0x162d8108a0a0544fc7ff46123419452fe281e351b6038443729c8c35d7c4e914, 0x1a89e4f944c09a2be20a61a1b505571726fa9d441d2e49a2bd3f87c37774e24e);
        vk.C = Pairing.G2Point([0x9e336b98f4b0ef636a3cc479b4835a74ad17e41f9e54e54b7e8030c3bf4f3f6, 0x16afee37c742d97db57359d84b3605789f44418bbf923e1de471dde9a9bead18], [0xf518f16001fcaa7c12e2886bdc569c5ba20e205e8b7be6e8ca2d33b3d4735f2, 0x2a649bfa91c97744ed94b9cc2efffcdea6463bd62609095fb322aa0caf7c95a4]);
        vk.gamma = Pairing.G2Point([0xc2bf2f0f82f32d686ce98d9387bda3ef9d091c68a18dcc33501f1b869203acf, 0x141197402c564177ac4ec7abf06433a00d738fb71436f3ef2538f2166e5023ad], [0x7a0b18eda4ea9f0ba71936182e34ac238bbbc9830c09843845ced90c570b90a, 0x2b7fa3bf9b71ae56595c43c4e46f511d7a6a14903d165a2d55d560468c8ef04]);
        vk.gammaBeta1 = Pairing.G1Point(0x2cfe8fb255d4eb5a092609e15aceaa73fb64ce8c6054c68d628331d8077c467e, 0x37e9a3fe09ea08a3f1ffd002cae5cce7d3302cf283cb1398e4ac0df0557e3f7);
        vk.gammaBeta2 = Pairing.G2Point([0x214cb4b0755fe998241cd329a674598f21d7b0c00691c9f2e3658cbc0c62c977, 0x7abc3eacc0912e263656165ea6e1469729698b5e1953fa64c2b17fcc86f07f9], [0x190f01feba3afc8af8c9c589be4f3b47f20b6fd2808d796d1ae2d09063ac068c, 0xb5574469be38c48a9f1267eaa7825281b2fa3cd0b6c62e02c2759e6b4c437cf]);
        vk.Z = Pairing.G2Point([0xcb0845de6479102e3f683d96d27c7cf1b5614021968d190309798a9ce853288, 0x81b973f198c0001becebe312d06dc6cd4cce6b992a040e567faf5e55bebf651], [0x1e777e094106736222a2a076a40d0a29f6f0228748bb004712b439f9b89989dc, 0xe3b433699a9ffb866bebeb9656cf1e2be919b7a31068585aa2d6c0051b51d5a]);
        vk.IC = new Pairing.G1Point[](5);
        vk.IC[0] = Pairing.G1Point(0x2f2f1aaac17bd00435d6b26f39f854676455f8feb78cf1e844d9e14862da74f1, 0x1464fd42819a6cb0f882898f1ff5dfe0233f59ba93a103bbac696d8cb1edbab3);
        vk.IC[1] = Pairing.G1Point(0xfa8bc2897f8f4c7109c238a0f205e71107045fe1a57df154ab90666f33aded2, 0x22c769f202ff92558127a6152e769ac6767b8b3ce9a0896594fbf6ccc42fcb6f);
        vk.IC[2] = Pairing.G1Point(0x281abe41f86301d2bc52bf3c9d2f54715d7da4d8d3c243665a4bcefdf624ace, 0x2af5a28566db374330c91f4262643779cdadb861dfcc62b80c7932a498b3b0);
        vk.IC[3] = Pairing.G1Point(0x1433cbbe7afce4633983b1f5aabdcc79c2f65f347d57a36ac9a18582c8182c7c, 0x2099725ce80115992843b743654042f121f89addad93782d5181a5338d1fbce7);
        vk.IC[4] = Pairing.G1Point(0x4f6b85d7e97e7c114edd25c1f9c2d83833e9438f60ce0fe72698cd197f2783c, 0x2e7c4259000471ec18c2af0a74ac63c8553880646be6d584bdb44183c85c17f9);
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
            uint[4] input
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
                                  input[1], input[2], 2) == true);
            emit Verified("Transaction successfully verified.");
            return true;
        } else {
            return false;
        }
    }
}

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


import "./btc_store.sol";

pragma solidity ^0.4.14;
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
        vk.A = Pairing.G2Point([0x2f376f2ffdd5ad280a7f3f63639e064f6d687c6b3ec3afc8697daa61872ad696, 0x1c9a12dc04c694e863be3ddd70526ca78599144accafa67f8ee46fd02eae9eec], [0xed6a6297f154a4bbf019bd46488db0f744c869ff52e22b1b919d527a6140b53, 0x19b819922a26823e7d856946492b3c3082aade56096ea2a9434d38fa8a9403f3]);
        vk.B = Pairing.G1Point(0x2b1f3aebbf12a15078d4cd764b4f68b05a6a72f30f7414c6dbf31dc3b9dce164, 0x2629da953af719b33c303104cbf53508537d1bda0d871c2e85ffb6d30cdeb74c);
        vk.C = Pairing.G2Point([0xb8426666cd5d83e73abb21584f01cac86bfc7cf2bf378d47e4ba0d6f30e98b2, 0x1e572db7f3629dffa1cc034d1b42d98ea86ceb5df5fa99de7cb6730d36ed4b6b], [0x1b952cd5dd7f87ca3c15cbaa782b8c0fb0233851b920221e7e5e7b4fdfa6459c, 0x2afc8def0256e8d18aefc193eef7ff6e477c93a4c050c88e214094a0b6b98650]);
        vk.gamma = Pairing.G2Point([0x20046160a00019c039c4face8673ccb3de2476dd8c1f2244f2cccbd04fbaa615, 0x36d6dff92ba5fe5d637607f8a2002ec2dd842e877a12e01c4493ebe8a59b69a], [0x277dbd155095d216cb5e3baaeb12d87e48c7c9f403afe8cd04ece9d483a8e540, 0xe0c4bb92c88cfa22962150d2bddc79a993ec64bd89b0ddeb78cca351d2dd41e]);
        vk.gammaBeta1 = Pairing.G1Point(0xc1f6dd716361452176579cd4ee2bd0dd479264668a30553af9cb9dda82656ed, 0x12992a0494711c99c9d9879814fced0395c0e6667e9cf6b46078e10e551ad44e);
        vk.gammaBeta2 = Pairing.G2Point([0x2c1e082abbc2ab5916c64a12c3f7fd3872dce069a0ed702e22da1f0178488ef7, 0x2247a0539271e5e24a6e34591a24316a30f1fe7f618eed40638faad1e6615826], [0x292864c2457cfb6361ec1e99beae8ad9ab7ac3d394dd1429acb971d51f7a121f, 0x1d2adb97948c8138007173b2c94c377f9bbd4602082fce6086d3922ad24f6844]);
        vk.Z = Pairing.G2Point([0x2a0d506363a68db4803479d68955cef81b2727eef89797513cb179411aa5169a, 0x1bfb05be88855ab2d2c43cf16aefd51fa0ecdcc906a8b6e35a14756a14855cd6], [0x566cc2bc5767e4130457190659fcbb0de43b8c2e483ce9c12091b76e6213759, 0x2b32016db99a85795ed679ffb6e10fcc098936b8520dddf2ba912672074cdc30]);
        vk.IC = new Pairing.G1Point[](3);
        vk.IC[0] = Pairing.G1Point(0x12e946bb7fb795e7ce073b2768aefa90a328388d81a1042395654d5d3cc82daf, 0x2e29c781f7f1aee03e9c1362f8b91a1d6dd81068a6dc696b77cf8a851ca4923f);
        vk.IC[1] = Pairing.G1Point(0x2961d22cb4698870a133530a1d39e63819fb7c307efb2de4b2b1d88ee43f2ce4, 0x13ed47c0ad09b54422a1a09af377c64cf38764d7cb8a9382fbd7eadc97f8f97f);
        vk.IC[2] = Pairing.G1Point(0x1efd96d718739c4c0ef3693fffa012ee13b2cfa7f81c87a7282da16791c74e74, 0x4724c27a1da2cd8495f6626133cbe87cf9900ff217cc4d6ccb0702d4f522acb);
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
            uint[2] input
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

            /* Mark header verified */
            require(BTCHeaderStore(m_header_contract_addr).mark_verified(input[0]) == true); 

            emit Verified("Transaction successfully verified.");
            return true;
        } else {
            return false;
        }
    }
}

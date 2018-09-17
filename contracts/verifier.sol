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
        vk.A = Pairing.G2Point([0x2ecd9dfe02c362d3ccadb08eefbee629b5303ddc0883efa4ef94e255967a3efd, 0x1540cba260a46f77b977ebe79424dd95c3854294e9c90cfbd560535a8a240d83], [0x1a1c4aa936c35416091d3cc0bb4dac155afa8a31e5f7fdae6922da552b97c7ba, 0x131f9b553828c267358c11a84bae8e01b3aa4431c343096e53187aa6db891d01]);
        vk.B = Pairing.G1Point(0x26d98224c7e34707f57fa8eb638d6d125faa8b3872845b65144fe811434a8046, 0x2a5a6bbdb7068f2d8981fdb5e3b22a174377cb51232fce51a7c3691a766bb21f);
        vk.C = Pairing.G2Point([0x18e1b1654dc14ac65138469a872dc401491e19a5d0e2c5114d58c6cbf7d5c129, 0x385786d29cebe45c28c9ce5d885ed72ef8b625b2404667a6ec4b7139ee95db1], [0x1bf6a91658b4d9742c0107d6d7310b078baadf945bdebdb9aadf4d6b9192288d, 0x1fdb3dc150c9ce5205346372d18a5232085896dd7fcc3489aca52f7a608b3731]);
        vk.gamma = Pairing.G2Point([0x26707e2366d8464da532bc54e2505405cd4d1988b7a721fbef9b346217424a14, 0x3fac956f249c85dae491d6709649d682d51262e2ad770f827622fc09e9a7145], [0x25c8b7eb3f845f1555f3561f81789424c1321deb4c985afc7fb7d20277676d54, 0x10cb8f53f4f4fb5ace26c19262ddd010a9c4af096c0d135408b08e5a34efc138]);
        vk.gammaBeta1 = Pairing.G1Point(0x79f8643a56bebe6beeac46cb5315306409e56a9c0964fcd829fe749205062ff, 0x1400181f49e6aa51ecf8cd5a8f96f407bf5a275219fd498697b9e3da661e6a13);
        vk.gammaBeta2 = Pairing.G2Point([0x8af05407db898895df50cdb1f29b9549443ec677645909b047c686591724c0f, 0x280e9c6f34eb4e84c4d67b81b49645e60e9e406008be44c38ae56ad85106425d], [0x1c0d52f05a67320f416b79d904a5119e3d850385ba6546b1d64297521e0687d4, 0x2ab018b8ae824da6addbbe86bd03db3362d0539001a4fd400b2160c9b8b3323]);
        vk.Z = Pairing.G2Point([0x1d1f147b0764576f0167bdacbf2238829803c0289eb5f042e5633e33d0c0b40, 0xfe60c19c03eb2e6e051b92e4fc7f208954ab90b7ff38afbdf51ce04f546759], [0x5a031848f455c2a72f17fa85b8dd0ed84187814eab2ca8850e00a6ebb09139e, 0xbbc4b59bbbb158c72de2fd6ffbfa50530d76f6c993639e519333a04c544a162]);
        vk.IC = new Pairing.G1Point[](6);
        vk.IC[0] = Pairing.G1Point(0x18d1306a7dd7774942e9372ffe41709206d51b764eea195bef8b93d037665680, 0x5492f5e818d009102264ccaf331ce38e800fe8f324aac1f71b90be39f87a43a);
        vk.IC[1] = Pairing.G1Point(0x13862efe2f1796214a83433d087c0c3a14b35e8a0d3cbda4dd487be0d4fcfee7, 0x7ca7913a1479411d9cb4d04eaecb33df7d2774b822f22284bba5c4448368d14);
        vk.IC[2] = Pairing.G1Point(0x2358de0b5f8c029832dfcadea4530c76f6d8cbe3e4212e6c32341ec8a9dce465, 0x210619ff682c3df1003f9526fb66d8c1441eb561ad00c9a74bc9f0be1d4556a6);
        vk.IC[3] = Pairing.G1Point(0x20b666beb86fccebe4292c9bcdbf7229025ee60133d749ec43489abee10a8b56, 0x11694ae0cef7ce851cd3d59355e605638be80e1020b773c500c5eb1df70db776);
        vk.IC[4] = Pairing.G1Point(0x2ad329478b6cd9d15b116aef0994e9d01c1df0e5a2131a6ea753fa51b0368d76, 0xfa1b42eee6fe39c835651feaafdab7332c0117ffda517afece7fb4e054aefdc);
        vk.IC[5] = Pairing.G1Point(0x2e8b5f9041f8ef399117800ac5a5b2d2306d70549baafe2feb1b2d5781cf5767, 0x48c4faf29c069a0aeccd6f5be5a6318eea98f52bd452648915f0d6d3b29a7d8);
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

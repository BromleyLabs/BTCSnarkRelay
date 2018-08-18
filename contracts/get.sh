#!/bin/sh

sudo chown puneet verifier.sol
sudo chown puneet proof.txt
cat proof.txt | grep "^A =" > proof_params.txt
cat proof.txt | grep "^A_p =" >> proof_params.txt
cat proof.txt | grep "^B =" >> proof_params.txt
cat proof.txt | grep "^B_p =" >> proof_params.txt
cat proof.txt | grep "^C =" >> proof_params.txt
cat proof.txt | grep "^C_p =" >> proof_params.txt
cat proof.txt | grep "^H =" >> proof_params.txt
cat proof.txt | grep "^K =" >> proof_params.txt

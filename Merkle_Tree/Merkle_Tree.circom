pragma circom 2.1.4;

include "../../circomlib/circuits/bitify.circom";
include "../../circomlib/circuits/sha256/sha256.circom";

//template Merkle_Tree
//input n: depth of merkle tree
//warning?: cause memory allocation failed if n is to large
template Merkle_Tree(n){
   
}

component main{public[witness]} = Merkle_Tree(10);
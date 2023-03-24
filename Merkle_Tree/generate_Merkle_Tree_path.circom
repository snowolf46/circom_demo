pragma circom 2.1.4;

include "../../circomlib/circuits/bitify.circom";
include "../../circomlib/circuits/sha256/sha256_2.circom";
include "../../circomlib/circuits/poseidon.circom";

// template Generate_Tree
// input n: depth of merkle tree
// warning?: cause memory allocation failed if n is to large
template Generate_Tree(){
    signal input in[2];
    component hash;
    var count = 0;

    for(var i = 0;i<2;i = i + 2){
        hash = Poseidon(2);
        hash.inputs[0] <== in[i];
        hash.inputs[1] <== in[i+1];
        log(hash.out);
        count = count + 1;
    }
}

component main{public[in]} = Generate_Tree();
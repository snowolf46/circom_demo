pragma circom 2.1.4;

include "../../circomlib/circuits/bitify.circom";
include "../../circomlib/circuits/sha256/sha256_2.circom";
include "../../circomlib/circuits/poseidon.circom";

// template Generate_Tree
// input n: depth of merkle tree
// warning?: cause memory allocation failed if n is to large
template Generate_Tree(n){
    signal input inputs[n];
    component hash[n/2];
    var count = 0;

    for(var i = 0;i<n;i = i + 2){
        hash[count] = Poseidon(2);
        hash[count].inputs[0] <== inputs[i];
        hash[count].inputs[1] <== inputs[i+1];
        log("'",hash[count].out,"',");
        //log(1);
        count = count + 1;
    }
}

component main{public[inputs]} = Generate_Tree(2);
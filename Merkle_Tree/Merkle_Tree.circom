pragma circom 2.1.4;

include "../../circomlib/circuits/bitify.circom";
include "../../circomlib/circuits/sha256/sha256.circom";
include "../../circomlib/circuits/poseidon.circom";


// template isBit
// check input value is either 0 or 1
template isBit(){
    signal input in;
    in * (1 - in) === 0;
}

// template checkLength
// check all intermedia nodes is of length 256
template checkLength(){
    signal input node;
    signal result;
    result <-- node >> 256;
    result === 0;
}

// template DualMux
// DualMux with input index and in[2]
// if index == 0,then out = [in[0], in[1]]
// if index == 1,then out = [in[1], in[0]]
template DualMux(){
    signal input index;
    signal input in[2];
    signal output out[2];
    
    (1 - index) * index === 0;

    out[0] <== (1 - index) * in[0] + index * in[1];
    out[1] <== index * in[0] + (1 - index) * in[1];
}


// template Merkle_Tree
// input n: depth of merkle tree
// warning?: cause memory allocation failed if n is to large
template Merkle_Tree(n){
    signal input verify_path[n]; // every value is either 0 or 1,where 1 represents right input and 0,left
    signal input root;  //merkle tree root hash
    signal input intermedia_node[n];  // merkle tree verify path node 

    // check all value in verify path is either 0 or 1
    component check_path_bit[n-1];
    for (var i = 0;i<n-1;i++){
        check_path_bit[i] = isBit();
        check_path_bit[i].in <== verify_path[i];
    }

    // check all public input node is of length 256
    component check_node_length[n+1];
    check_node_length[0] = checkLength();
    check_node_length[0].node <== root;
    // check all intermedia nodes 
    for(var i = 1;i<n+1;i++){
        check_node_length[i] = checkLength();
        check_node_length[i].node <== intermedia_node[i-1];
    }
    
    // check all intermedia hash is well form
    signal intermedia_hash[n+1];
    component intermedia_poseidon[n];
    component mux[n];

    for(var i = 0;i < n; i++){
        mux[i] = DualMux();
        mux[i].index <== verify_path[i];
        mux[i].in[0] <== intermedia_node[i];
        mux[i].in[1] <== intermedia_hash[i];

        intermedia_hash[i] = Poseidon(2);
        intermedia_hash[i].a <== mux.out[0];
        intermedia_hash[i].b <== mux.out[1];
        
        intermedia_hash[i+1] <== intermedia_hash[i].out;
    }
    
    root === intermedia_hash[n];


}

component main{public[root]} = Merkle_Tree(4);
pragma circom 2.1.4;

include "../../circomlib/circuits/bitify.circom";
include "../../circomlib/circuits/poseidon.circom";

template Iteration_Poseidon(n){
    signal input witness;
    signal input result;

    // check result is of length 256
    signal res_len;
    res_len <-- result >> 256;
    res_len === 0;

    // check all intermedia poseidon hash is well form
    component intermedia_poseidon[n+1];
    intermedia_poseidon[0] = Poseidon(1);
    intermedia_poseidon[0].inputs[0] <== witness;
    for( var i = 1;i < n + 1; i++){
        intermedia_poseidon[i] = Poseidon(1);
        intermedia_poseidon[i].inputs[0] <== intermedia_poseidon[i-1].out;
    }
    result === intermedia_poseidon[n].out;

}

component main{public[result]} = Iteration_Poseidon(10);
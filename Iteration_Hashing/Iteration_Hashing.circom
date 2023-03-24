pragma circom 2.1.4;

include "../../circomlib/circuits/bitify.circom";
include "../../circomlib/circuits/sha256/sha256.circom";

//template Iteration_Hashing
//input n: Iteration times
//warning: cause memory allocation failed if n is to large
template Iteration_Hashing(n){
    signal input witness;
    signal input result;
    signal bits_input[256]; // transfer int to bits array
    
    component bits = Num2Bits(256); // bitify template, transfer input number to bit array
    bits.in <== witness;
    bits_input <== bits.out;
    
    component test[n];
    test[0] = Sha256(256);
    test[0].in <== bits_input;
    //iterative computation
    for(var i = 1;i<n;i++){
        test[i] = Sha256(256);
        test[i].in <== test[i-1].out;
    }
    
    component out_num = Bits2Num(256); //bitiy template, transfer output hash to integer
    out_num.in <== test[n-1].out;
    result === out_num.out;
    log("Output:",out_num.out);
}

component main{public[result]} = Iteration_Hashing(10);
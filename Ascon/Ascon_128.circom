pragma circom 2.1.4;

/* 
    ===== Ascon-128 Parameters =====
    Key length          : 128 bits
    nonce length        : 128 bits
    tag length          : 128 bits
    block size          : 64 bits
    Permutation round(a): 12
    permutation round(b): 6
    ================================
*/

// ===== some help function =====

// template Bit4
// Enforce that 0 <= in <= 15
template Bits4(){
    signal input in;
    signal bits[4];
    var bitsum = 0;
    for (var i =0;i<4;i++){
        bits[i] <-- (in>>i)&1;
        bits[i]*(bits[i]-1) === 0;
        bitsum = bitsum + 2**i*bits[i];
    }
    bitsum === in;
}

// Ascon finalize depart key to left and right,both of size 64 bits
// we want to get the right half of the original key
// but we can not left shift then right shift due to circom use large prime with length 254 bits
// the solution is use rotate right shift
// first,shift the right half of key to the left side
// then, right shift 64 bits to get the left

// template ror
// implement right rotate shift
// input state: right rotate shift register
// input length: shift length
template ror(){
    signal input state;
    signal input length;
    signal output out;
    var DEBUG = 0;

    var res;
    var tmp[3];
    tmp[0] = state >> length;
    tmp[1] = state & (1 << length) - 1;
    tmp[2] = tmp[1] << (128 - length);
    res = tmp[0] | tmp[2];
    
    if(DEBUG){
        log("tmp0",tmp[0]);
        log("tmp1",tmp[1]);
        log("tmp2",tmp[2]);
        log("res",res); 
    }

    out <-- res;
}

// template len
// get length of an integer
// input in: input a integer
// output  : length of integer
template len(){
    signal input in;
    signal output out;

    var tmp = in;
    var count = 0;
    while(tmp){
        count++;
        tmp = tmp >> 1;
    }
    out <-- count;
}

// template keylen
// check Ascon key length is of 128
// input key:Ascon key
template keylen(){
    signal input key;
    key >> 127 === 1;
    key >> 128 === 0;
}

// ===== some help function =====

// template Permutaion
// input State: Ascon initial/intermedia state, include 5 register of size 64-bits
// input round: permutation iteration round(Ascon-128 round = 6)
template Permutation(){
    signal input round;
    signal input State[5];
    signal input IS_DEBUG;    // log debug info if IS_DEBUG == 1
    signal output out[5];
    // var round = 6;
    var DEBUG_PERMUTATION_FLAG = IS_DEBUG; // log debug info if flag == 1

    // check all State registers are of size 64 bits
    signal checkState[5];
    for(var i = 0;i < 5;i++){
        checkState[i] <-- (State[i] >> 64);
        if(DEBUG_PERMUTATION_FLAG) log("State", i, State[i], "Check_State", i, checkState[i]); 
        checkState[i] === 0;
    }

    // check 1 <= round  <= 12
    if(DEBUG_PERMUTATION_FLAG) log("Round:", round);
    component lowerBound = Bits4();
    component upperBound = Bits4();
    lowerBound.in <== round - 1;
    upperBound.in <== round + 3;

    // permutation
    var roundConstant = 0;
    var intermediaState[5];
    
    for(var i =0;i < 5;i++){
        intermediaState[i] = State[i];
    }
    
    for (var i = 12 - round;i < 12;i++){
        // add round constant layer
        roundConstant = 240 - i * 16 + i;
        if(DEBUG_PERMUTATION_FLAG) log("add round constant:", roundConstant);
        intermediaState[2] = intermediaState[2] ^ roundConstant;

        // substitution layer
        intermediaState[0] ^= intermediaState[4];
        intermediaState[4] ^= intermediaState[3];
        intermediaState[2] ^= intermediaState[1];
        
        var T[5];
        for(var j = 0;j < 5;j++){
            // 0xFFFF FFFF FFFF FFFF = 18446744073709551615
            T[j] = (intermediaState[j] ^ 18446744073709551615) & intermediaState[(j + 1) % 5];
        }
        for(var j = 0;j < 5;j++){
            intermediaState[j] ^= T[(j + 1) % 5];
        }

        intermediaState[1] ^= intermediaState[0];
        intermediaState[0] ^= intermediaState[4];
        intermediaState[3] ^= intermediaState[2];
        intermediaState[2] ^= 18446744073709551615;
        if(DEBUG_PERMUTATION_FLAG)  for(var j = 0;j < 5;j++)  log("substitution layer", j, intermediaState[j]);

        // linear  diffusion layer
        var rorState[5][2];
        rorState[0][0] = (intermediaState[0] >> 19) | (intermediaState[0] & (1<<19) - 1 << (64 - 19));
        rorState[0][1] = (intermediaState[0] >> 28) | (intermediaState[0] & (1<<28) - 1 << (64 - 28));

        rorState[1][0] = (intermediaState[1] >> 61) | (intermediaState[1] & (1<<61) - 1 << (64 - 61));
        rorState[1][1] = (intermediaState[1] >> 39) | (intermediaState[1] & (1<<39) - 1 << (64 - 39));

        rorState[2][0] = (intermediaState[2] >>  1) | (intermediaState[2] & (1<< 1) - 1 << (64 -  1));
        rorState[2][1] = (intermediaState[2] >>  6) | (intermediaState[2] & (1<< 6) - 1 << (64 -  6));

        rorState[3][0] = (intermediaState[3] >> 10) | (intermediaState[3] & (1<<10) - 1 << (64 - 10));
        rorState[3][1] = (intermediaState[3] >> 17) | (intermediaState[3] & (1<<17) - 1 << (64 - 17));

        rorState[4][0] = (intermediaState[4] >>  7) | (intermediaState[4] & (1<< 7) - 1 << (64 -  7));
        rorState[4][1] = (intermediaState[4] >> 41) | (intermediaState[4] & (1<<41) - 1 << (64 - 41));

        for (var j = 0;j < 5;j++){
            intermediaState[j] ^= rorState[j][0] ^ rorState[j][1];
            if(DEBUG_PERMUTATION_FLAG) log("linear diffusion layer", j, intermediaState[j]);
            
        }
    }

    // output intermedia state
    for(var i = 0;i < 5;i++) out[i] <-- intermediaState[i];
}



// template Plaintext_Process
// parameter n: Numbers of plaintext blocks
// input State: Ascon intermedia state
// input plaintext: Plaintext
// output ciphertext:

// Ascon-128 block size is of 8 bytes(rate = 8 bytes)
// Assume plaintext has been properly preprocessed(the last block of plaintext has been padded)

template Plaintext_Process(n){
    signal input State[5];
    signal input plaintext[n];
    signal input IS_DEBUG;    // log debug info if IS_DEBUG == 1
    signal output ciphertext[n];

    var DEBUG_PLAINTEXT_FLAG = IS_DEBUG;   // log debug info if flag == 1

    var intermediaState[5];
    var ct[n];
    component intermedia_pem[n];

    // plaintext padding
    var lastlen = 0;
    component pad_len = len();
    pad_len.in <== plaintext[n-1];
    lastlen = pad_len.out; //padding length(bytes)
    var last_block = (plaintext[n-1] << 1) | 1; // padding 1 bit '1'
    last_block = (last_block << lastlen * 8 - 1); // padding few bits '0'
    if(DEBUG_PLAINTEXT_FLAG) {
        log("last block:", plaintext[n-1]);
        log("last length:", lastlen);
        log("padded block:", last_block);
    }

    // init intermedia state
    for(var i =0;i < 5;i++) intermediaState[i] = State[i];

    //process first t-1 blocks
    for(var i = 0;i < n - 1;i++){
        intermediaState[0] ^= plaintext[i];
        ct[i] = intermediaState[0]; 
        
        //update intermedia state
        intermedia_pem[i] = Permutation();
        for(var j = 0;j < 5;j++) intermedia_pem[i].State[j] <-- intermediaState[j];
        for(var j = 0;j < 5;j++) intermediaState[j] = intermedia_pem[i].out[j];
    }

    // process last block
    intermediaState[0] ^= plaintext[n-1];
    ct[n-1] = intermediaState[0];
    if(DEBUG_PLAINTEXT_FLAG) log("Ciphertext", n-1, ct[n-1]);

    //output ciphertext
    for(var i = 0;i < n;i++){
        ciphertext[i] <-- ct[i];
        if(DEBUG_PLAINTEXT_FLAG) log("Ciphertext", i, ct[i]);
    }
}



// template Ciphertext_Process
// parameter n: Numbers of ciphertext blocks
// input State: Ascon intermedia state
// input ciphertext: 
// output plaintext:

// Ascon-128 block size is of 8 bytes(rate = 8 bytes)
// Assume plaintext has been properly preprocessed(the last block of plaintext has been padded)

template Ciphertext_Process(n){
    signal input State[5];
    signal input ciphertext[n];
    signal input IS_DEBUG;    // log debug info if IS_DEBUG == 1
    signal output plaintext[n];

    var DEBUG_CIPHERTEXT_FLAG = IS_DEBUG;  // log debug info if flag == 1
    var intermediaState[5];
    var pt[n];
    component intermedia_pem[n];

    //ciphertext padding
    var lastlen = 0;
    component pad_len = len();
    pad_len.in <== ciphertext[n-1];
    lastlen = pad_len.out; //padding length(bytes)
    var last_block = (ciphertext[n-1] << 8 * lastlen); // padding few bits '0'
    if(DEBUG_CIPHERTEXT_FLAG) {
        log("last block:", ciphertext[n-1]);
        log("last length:", lastlen);
        log("padded block:", last_block);
    }
    
    // init intermedia state
    for(var i =0;i < 5;i++) intermediaState[i] = State[i];

    //process first t-1 blocks
    var Ci;
    for(var i = 0;i < n - 1;i++){
       Ci = ciphertext[i];
       pt[i] = intermediaState[0] ^ Ci;
       intermediaState[0] = Ci;
       
       //update intermedia state
        intermedia_pem[i] = Permutation();
        for(var j = 0;j < 5;j++) intermedia_pem[i].State[j] <-- intermediaState[j];
        for(var j = 0;j < 5;j++) intermediaState[j] = intermedia_pem[i].out[j];
    }

    // process last block
    var ct_padding = 128 << (56 - 8 * lastlen); // ct_padding = 128 << 8 * (8 - lastlen - 1)
    var c_mask = 18446744073709551615 >> (8 * lastlen); // 0xFFFF FFFF FFFF FFFF = 18446744073709551615
    Ci = last_block >> (8 * lastlen);
    pt[n-1] = Ci ^ (intermediaState[0] >> (8 * lastlen));
    pt[n-1] = pt[n-1] >> (8 * lastlen);
    intermediaState[0] = Ci ^ (intermediaState[0] & c_mask) ^ ct_padding;
    if(DEBUG_CIPHERTEXT_FLAG){
        log("ct_padding:", ct_padding);
        log("c_mask:", c_mask);
        log("Ci:", Ci);
        log("last plaintext:", pt[n-1]);
    }

    //output plaintext
    for(var i = 0;i < n;i++){
        if(DEBUG_CIPHERTEXT_FLAG) log("Plaintext", i, pt[i]);
        plaintext[i] <-- pt[i];
    }
}


// template Finalize
// Ascon finalization phase,an internal helper function
// input State:
// input Key: Ascon-128 key is of size 128 bits
// output : tag(size 128 bits)

// Ascon-128 finalization phase permutation round a = 12
// Ascon-128 block size is of 8 bytes(rate = 8 bytes)
// Ascon finalization phase also update its intermedia state
// todo
template Finalize(){
    signal input State[5];
    signal input Key;
    signal input IS_DEBUG;    // log debug info if IS_DEBUG == 1

    var intermediaState[5];
    var DEBUG_FINALIZE_FLAG = IS_DEBUG;    //log debug info if flag == 1

    // check input key is of length 128
    component check_key = keylen();
    check_key.key <== Key;

    // init intermedia state
    for(var i =0;i < 5;i++) intermediaState[i] = State[i];

    // depart origin key into left and right part
    var key[2];
    component shift_key = ror();
    shift_key.state <== Key;
    shift_key.length <== 64;
    key[0] = Key >> 64; // left half of the original key
    key[1] = shift_key.out >> 64; // right half of the original key
    

    intermediaState[1] ^= (key[0]);
    intermediaState[2] ^= (key[1]);

    
    //intermediaState[2] ^= (Key  )

}

// template Initialize
// Ascon initialize step
// input Key:
// input nonce:
// output updated State

// Ascon-128 IV == 0x80400c0600000000,which is 9241399655273594880 in decimal
// Ascon-128 round a = 12,b = 6
// Ascon-128 nonce is of length 128 bits
template Initialize(){
    signal input Key;
    signal input nonce;
    signal input IS_DEBUG;
    signal output State[5];

    var DEBUG_INITIALIZE_FLAG = IS_DEBUG;
    var intermediaState[5];
    
    // initial ascon state
    var _key[2];
    var _nonce[2];
    var IV;
    component shift[2];
    
    shift[0].state <== Key;
    shift[1].state <== nonce;
    shift[0].length <== 64;
    shift[1].length <== 64;

    _key[0] = Key >> 64;
    _key[1] = shift[0].out;
    _nonce[0] = nonce >> 64;
    _nonce[1] = shift[1].out;
    IV = 9241399655273594880;

    intermediaState[0] = _key[0];
    intermediaState[1] = _key[1];
    intermediaState[2] = _nonce[0];
    intermediaState[3] = _nonce[1];
    intermediaState[4] = IV;
    if(DEBUG_INITIALIZE_FLAG){
        for(var i = 0;i < 5;i++) log("Initial value", i, intermediaState[i]);
    }

    // apply a = 12 rounds permutation
    component initialize_permutation = Permutation();
    initialize_permutation.round <-- 12;
    initialize_permutation.IS_DEBUG <-- 1;
    for(var i = 0;i < 5;i++) initialize_permutation.State[i] <-- intermediaState[i];
    
    // apply key XOR
    var zero_key[5];
    zero_key[0] = 0;
    zero_key[1] = 0;
    zero_key[2] = 0;
    zero_key[3] = _key[0];
    zero_key[4] = _key[1];
    for(var i = 0;i < 5;i++){
        State[i] <-- zero_key[i] ^ initialize_permutation.out[i];
        if(DEBUG_INITIALIZE_FLAG) log("Initialed State", i, State[i]);
    }
}

component main{public[round]} = Permutation();
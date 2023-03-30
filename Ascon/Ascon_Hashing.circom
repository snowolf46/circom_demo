pragma circom 2.1.4;

/* 
    ===== Ascon-Hash Parameters ======
    Hash length         : 256 bits
    block size          : 64 bits
    Permutation round(a): 12
    permutation round(b): 12

    S[0] = 0xEE93 98AA DB67 F03D 
    S[1] = 0x8BB2 1831 C60F 1002
    S[2] = 0xB48A 92DB 98D5 DA62
    S[3] = 0x4318 9921 B8F8 E3E8
    S[4] = 0x348F A5C9 D525 E140
    ==================================

    ===== Ascon-Hasha Parameters =====
    Hash length         : 256 bits
    block size          : 64 bits
    Permutation round(a): 12
    permutation round(b): 8

    S[0] = 0x0147 0194 FC65 28A6
    S[1] = 0x738E C39A C0AD FFA7
    S[2] = 0x2EC8 E329 6C76 384C
    S[3] = 0xD6F6 A54D 7F52 377D
    S[4] = 0xA13C 42A2 23BE 8D87
    ==================================

    ===== Ascon-Xof Parameters =======
    Hash length         : 256 bits
    block size          : 64 bits
    Permutation round(a): 12
    permutation round(b): 12

    S[0] = 0xB57E 273B 814C D416
    S[1] = 0x2B51 0425 62AE 2420
    S[2] = 0x66A3 A776 8DDF 2218
    S[3] = 0x5AAD 0A7A 8153 650C
    S[4] = 0x4F3E 0E32 5394 93B6
    ==================================

    ===== Ascon-Xofa Parameters =======
    Hash length         : 256 bits
    block size          : 64 bits
    Permutation round(a): 12
    permutation round(b): 12

    S[0] = 0x4490 6568 B77B 9832
    S[1] = 0xCD8D 6CAE 5345 5532
    S[2] = 0xF7B5 2127 5642 2129
    S[3] = 0x2468 85E1 DE0D 225B
    S[4] = 0xA8Cb 5CE3 3449 973F
    ==================================
*/

// =============== some help function ===============

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

// =============== some help function ===============


// template Permutaion
// input State: Ascon initial/intermedia state, include 5 register of size 64-bits
// input round: permutation iteration round(Ascon-Hash round a = b = 12)
template Permutation(){
    signal input round;
    signal input State[5];
    signal output out[5];
    
    var DEBUG_PERMUTATION_FLAG = 0; // log debug info if flag == 1

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
    
    for(var i = 0;i < 5;i++){
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
            // T[j]: filp all State[j] bits,then AND with State[j+1]
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

// template Hash
// Ascon-Hash(standard version),Ascon-Hash variants(Ascon-Hasha and Ascon-Xofa) see below
// parameter n: length of input messages
// input m: message of length n bytes
// input initState: depend on variant
// input variant: 0 = Ascon-Hash, 1 = Ascon-Hasha, 2 = Ascon-Xof, 3 = Ascon-Xofa
// output hash[2]:circom default usage large prime of length 254 bits(less than output length 256 bits)
// so spilt it into two parts,both of length 128 bits
template Hash(n){
    signal input m[n];
    signal input variant;
    signal output hash[2];
    
    var IS_DEBUG = 0;
    var mod = variant;
    var intermediaState[5];
    
    // init state
    if(mod == 1){
        intermediaState[0] = 92044056785660070;   
        intermediaState[1] = 8326807830479634343; 
        intermediaState[2] = 3371194088139667532; 
        intermediaState[3] = 15489749720654559101;
        intermediaState[4] = 11618234402860862855;
    }else if(mod == 2){
        intermediaState[0] = 13077933504456348694;
        intermediaState[1] = 3121280575360345120; 
        intermediaState[2] = 7395939140700676632; 
        intermediaState[3] = 6533890155656471820; 
        intermediaState[4] = 5710016986865767350; 
    }else if(mod == 3){
        intermediaState[0] = 4940560291654768690; 
        intermediaState[1] = 14811614245468591410;
        intermediaState[2] = 17849209150987444521;
        intermediaState[3] = 2623493988082852443; 
        intermediaState[4] = 12162917349548726079;
    }
    else{
        intermediaState[0] = 17191252062196199485;
        intermediaState[1] = 10066134719181819906;
        intermediaState[2] = 13009371945472744034;
        intermediaState[3] = 4834782570098516968; 
        intermediaState[4] = 3787428097924915520;
    }

    // process messages (absorbing phase)
    component lastlen = len();
    lastlen.in <-- m[n-1];
    var padding_len = 64 - lastlen.out; //padding 1 bit "1" and fews bits "0"
    var m_padding = 128 << (padding_len - 1);

    // process first n-1 message blocks
    component pem[n-1];
    for(var i = 0;i < n - 1;i++){
        intermediaState[0] ^= m[i];
        pem[i] = Permutation();
        pem[i].round <-- 6;
        for(var j = 0;j < 5;j++) pem[i].State[j] <-- intermediaState[j];
        for(var j = 0;j < 5;j++) intermediaState[j] = pem[i].out[j];
    }

    // process last block
    intermediaState[0] ^= m_padding;

    // finalization (squeezing phase)
    component final_pem = Permutation();
    final_pem.round <-- 12;
    for(var i = 0;i < 5;i++) final_pem.State[i] <-- intermediaState[i];
    for(var i = 0;i < 5;i++) intermediaState[i] = final_pem.out[i];

    var res[4];
    // left 128 bits parts
    component out_pem[4];
    for(var i = 0;i < 4;i++){
        out_pem[i] = Permutation();
        out_pem[i].round <-- 6;
        for(var j = 0;j < 5;j++) out_pem[i].State[j] <-- intermediaState[j];
        for(var j = 0;j < 5;j++) intermediaState[j] = out_pem[i].out[j];
        res[i] = intermediaState[0];
    }
    
    // output hashing
    hash[0] <-- (res[0] << 64) + res[1];
    hash[1] <-- (res[2] << 64) + res[3];
    log("hash[0]", hash[0]);
    log("hash[1]", hash[1]);

    // is ok?
}

component main{public[m]} = Hash(2);
pragma circom 2.1.4;

//template Bit4
//Check input element is in range [0,15]
template Bit4(){
    signal input in;
    signal bits[4];
    var bitsum = 0;

    for(var i=0;i<4;i++){
        bits[i] <-- (in>>i)&1;
        bits[i] * (bits[i] -1) === 0;
        bitsum = bitsum + bits[i]*(2**i);
    }
    bitsum === in;
}

//template rangeCheck
//Check input element is in range [0,10]
//use in ID number checker
template rangeCheck(){
    signal input in;
    component lowerBound = Bit4();
    component upperBound = Bit4();
    lowerBound.in <== in;
    upperBound.in <== in + 5;
}

//template idChecker
//Check input id Number is vaild
template idChecker(){
    signal input in[18];
    component inRange[18];

    //check all elements in id number is in range [0,10]
    for(var i =0;i<18;i++){
        inRange[i] = rangeCheck();
        inRange[i].in <== in[i];
    }
    
    //check flag is vaild
    var weight[18] = [3,7,0,6,8,3,1,9,8,9,0,1,1,1,7,6,5,7];
    var checkSum = 0;
    for (var i=0 ;i<18;i++){
        checkSum = checkSum + in[i]*weight[i];
    }
    var rem = 0;
    rem = checkSum % 11;
    rem === 1;
}

component main {public[in]} = idChecker();
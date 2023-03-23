pragma circom 2.1.4;

// template NonEqual
// Check (in0 - in1) is non-zero(which means in0 non equal to in1)
template NonEqual(){
    signal input in0;
    signal input in1;

    signal inverse;
    inverse <-- 1/(in0 - in1);
    inverse * (in0 - in1) === 1;
}

// template checkBit
// Check every entries in array is single bit
template CheckBit(){
    signal input in;
    in * (1 - in) === 0;
}

// template Bit2
// Check all elements in range [0,3]
template Bits2(){
    signal input in;
    signal bits[2];
    var bitsum = 0;
    for(var i=0;i<2;i++){
        bits[i] <-- (in>>i)&1;
        bits[i]*(1 - bits[i]) === 0;
        bitsum = bitsum +2**i*(bits[i]);
    }
    bitsum === in;
}

// template CheckRange
// Check every entries in witness is in range {1,2,3}
template CheckRange(){
    signal input in;
    component lowerBound = Bits2();
    component upperBound = Bits2();
    lowerBound.in <== in - 1;
    upperBound.in <== in;
}

// template IsColorable
// Check witness is a correct color scheme
// input Graph represent by adjacency form
template IsColorable(n){
    signal input Graph[n][n];
    signal input witness[n];

    //check instance and witness are well form
    component Graph_isBit[n][n];
    component witness_inRange[n];
    for(var i = 0;i<n;i++){
        witness_inRange[i] = CheckRange();
        witness_inRange[i].in  <== witness[i];

        for(var j = 0 ;j<n;j++){
            Graph_isBit[i][j] = CheckBit();
            Graph_isBit[i][j].in <== Graph[i][j];
        }
    }

    var length = (n*(n+1))/2;
    var index[length][2];
    var count = 0;
    for(var i = 0;i<=n-1;i++){
        for(var j = 0;j<=i;j++){
            if(Graph[i][j] == 1){
                //log(i,j,Graph[i][j]);
                index[count][0] = i;
                index[count][1] = j;
                count = count + 1;

            }
            else{
                index[count][0] = 1;
                index[count][1] = 2;
                count = count + 1;
            }
        }
    }
    component isNonEqual[length];
    signal row[length];
    signal col[length];
    //var row,col;
    for(var i=0;i<length;i++){
        isNonEqual[i] = NonEqual();
        var a = index[i][0];
        var b = index[i][1];
        //log(a,b);
        row[i] <-- witness[a];
        col[i] <-- witness[b];

        isNonEqual[i].in0 <== row[i];
        isNonEqual[i].in1 <== col[i];
    }
}

component main {public[Graph]} = IsColorable(5);
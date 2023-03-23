pragma circom 2.1.4;

//template checkBit
//Check every entries in array is single bit
template CheckBit(){
    signal input in;
    in * (1 - in) === 0;
}

// template HamiltonianCycle
// Check witness is satisfied
template HamiltonianCycle(n){
    signal input Graph[n][n];
    signal input witness[n][n];

    // check all entries in Graph array and witness array are single bit
    component Graph_isBit[n][n];
    component witness_isBit[n][n];
    for(var i = 0;i<n;i++){
        for(var j = 0 ;j<n;j++){
            Graph_isBit[i][j] = CheckBit();
            witness_isBit[i][j] = CheckBit();

            Graph_isBit[i][j].in <== Graph[i][j];
            witness_isBit[i][j].in <== witness[i][j];
        }
    }

    // find non-zero entry in witness array, store its index in index array
    var index[n][2];
    var k = 0;
    for(var i = 0;i<n;i++){
        for(var j = 0 ;j<n;j++){
            if(witness[k][j] == 1){
                index[i][0] = k;
                index[i][1] = j;
            }
        }
        k = index[i][1];
    }

    // check that only one element in the row and column where the element is located is non zero
    signal sum[n];
    var tmp[n];
    for(var i = 0;i<n;i++){
        tmp[i] = 0;

        for(var j = 0;j<n;j++){
            var _row = index[i][0];
            tmp[i] = tmp[i] + witness[_row][j];
        }
        for(var j = 0;j<n;j++){
            var _col = index[i][1];
            tmp[i] = tmp[i] + witness[j][_col];
        }
        tmp[i] = tmp[i] - 1;

        sum[i] <-- tmp[i];
        sum[i] * sum[i] === 1;
    }

    // check that there is a circle in the witness
    signal IsCircuit[n];
    for(var i = 0;i<n-1;i++){
        IsCircuit[i] <-- (index[i][1] - index[i+1][0]);
        IsCircuit[i] === 0;
    }
    IsCircuit[n-1] <-- (index[n-1][1] - index[0][0]);
    IsCircuit[n-1] === 0;

}


component main {public[Graph]} = HamiltonianCycle(6);
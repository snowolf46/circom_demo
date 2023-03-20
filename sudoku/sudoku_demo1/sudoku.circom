pragma circom 2.1.4;

//a sudoku demo with 9x9




// template NonEqual
// Check (in0 - in1) is non-zero(which means in0 non equal to in1)
template NonEqual(){
    signal input in0;
    signal input in1;

    signal inverse;
    inverse <-- 1/(in0 - in1);
    inverse * (in0 - in1) === 1;
}

// template Distinct
// Check all elements are unique in the array
template Distinct(n){
    signal input in[n];
    component nonEqual[n][n];

    for(var i=0; i < n;i++){
        for(var j =0; j < i ;j++){
            nonEqual[i][j]=NonEqual();
            nonEqual[i][j].in0 <== in[i];
            nonEqual[i][j].in1 <== in[j];
        }
    }
}

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

// template OneToNine
// Enforce that 1 <= in <= 9
template OneToNine(){
    signal input in;
    component lowerBound = Bits4();
    component upperBound = Bits4();
    lowerBound.in <== in-1;
    upperBound.in <== in+6;
}

// template Sudoku
// Check 2D array is satisfied
template Sudoku(n){
    signal input solution[n][n]; //solution of the given puzzle
    signal input puzzle[n][n]; //puzzle array with zero elements,which represent blank

    component inRange[n][n]; 
    //check solution array is well-form
    for(var i =0 ;i<n;i++){
        for(var j=0;j<n;j++){
            inRange[i][j]= OneToNine();
            inRange[i][j].in<==solution[i][j];
        }
    }

    //check puzzle array and solution array agree
    for(var i =0 ;i<n;i++){
        for(var j=0;j<n;j++){
            // either puzzle_cell = 0(which means blank cell) or puzzle_cell = solution_cell
            puzzle[i][j] *(puzzle[i][j] - solution[i][j]) === 0;
        }
    }

    //check uniqueness in every rows
    component rowDistinct[n];
    for(var i =0 ;i<n;i++){
        rowDistinct[i] = Distinct(n);
        for(var j=0;j<n;j++){
            rowDistinct[i].in[j] <== solution[i][j];
        }
    }

    //check uniqueness in every columncolumn
    component colDistinct[n];
    for(var i=0;i<n;i++){
        colDistinct[i] = Distinct(n);
        for(var j=0;j<n;j++){
            colDistinct[i].in[j] <== solution[j][i];
        }
    }

    //check uniqueness in every 3x3 sub-array
    component subarrDistinct[n];
    var index = 0;
    for(var i=1;i<n;i=i+3){
        for (var j=1;j<n;j=j+3){
            subarrDistinct[index] = Distinct(n);
            subarrDistinct[index].in[0] <== solution[i][j];
            subarrDistinct[index].in[1] <== solution[i][j-1];
            subarrDistinct[index].in[2] <== solution[i-1][j-1];
            subarrDistinct[index].in[3] <== solution[i-1][j];
            subarrDistinct[index].in[4] <== solution[i-1][j+1];
            subarrDistinct[index].in[5] <== solution[i][j+1];
            subarrDistinct[index].in[6] <== solution[i+1][j+1];
            subarrDistinct[index].in[7] <== solution[i+1][j];
            subarrDistinct[index].in[8] <== solution[i+1][j-1];
            index = index + 1;
        }
    }

}

component main {public[puzzle]} = Sudoku(9);



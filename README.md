# circom_demo
some circuit demo,develop by circom 2.1.x



## Makefile

首先需要编写好对应的电路文件，然后**需要修改Makefile中circom电路的文件名及其派生文件的文件名，使其与你的circom文件名`circuit_name`一致**

新建一个文件夹并命名为`circuit_name_input`，将电路的输入文件放入该文件夹内，输入文件命名为`circuit_name.input.json`

**在执行makefle之前，需要先用下列命令检查你的电路约束数量**

> snarkjs ri circuit.r1cs

![image-20230322093303471](README.assets/image-20230322093303471.png)

然后检查makefile文件，确保power参数与电路约束数量满足下列等式（make文件中默认写的是11，也即电路中约束数量最大为2048个）

$$
2^{power} \le Constraints
$$

make文件用于windows平台，Linux平台需要将最后的`del`命令修改为`rm -f`，其余命令可自行修改

## Others

1. makefile文件中的contribute命令中的random text和beacon命令中的随机信标值可以随意修改，命令的执行次数也可以随意添加或删除
2. node命令执行失败通常意味着input文件中的输入不满足约束条件（此时会报错），要么修改电路中的约束条件，要么修改input中对应的输入
3. power参数不宜设置过大，因为`phase2`命令会占据大量CPU（执行该命令后CPU利用率基本会维持在99%以上，直至计算完毕），power越大意味着计算时间越久，因此需要将该参数设置为最接近约束数量的值
4. 如果需要查看中间结果，则把最后的del命令删除


circom = 3Color.circom
r1cs = 3Color.r1cs
wasm = 3Color_js/3Color.wasm
wit_gen = 3Color_js/generate_witness.js
compile_outputs = 3Color_js/witness_calculator.js $(r1cs) $(wasm) $(wit_gen)
pk = 3Color.pk
vk = 3Color_vk.json
ptau = 3Color.ptau
keys = $(pk) $(vk)
circ_input = 3Color_input/3Color_1.input.json
wit = 3Color.wtns
pb_js = 3Color_public.json
pf_js = 3Color_proof.json
js_dir = 3Color_js
power = 7
prove_outputs = $(pf_js) $(pb_js)
zkey_waste = $(wildcard *.zkey)
ptau_waste = $(wildcard *.ptau)

all : verify

$(compile_outputs) : $(circom)
	circom $< --r1cs --wasm

$(wit) : $(circ_input) $(wit_gen) $(wasm)  
	node $(wit_gen) $(wasm) $(circ_input) $@

$(ptau) : 
	snarkjs powersoftau new bn128 $(power) pot12_0000.ptau -v
	snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v -e="some random text"
	snarkjs powersoftau contribute pot12_0001.ptau pot12_0002.ptau --name="Second contribution" -v -e="some random text"
	snarkjs powersoftau beacon pot12_0002.ptau pot12_beacon.ptau 1cbf6603d6ff9ba4e1d15d0fd83be3a80bca470b6a43a7f9055204e860298f99 10 -n="Final Beacon"
	snarkjs powersoftau prepare phase2 pot12_beacon.ptau $(ptau) -v

$(keys) : $(ptau) $(r1cs)
	snarkjs groth16 setup $(r1cs) $(ptau) circuit_0000.zkey
	snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="First contribution Name" -v -e="First random entropy"
	snarkjs zkey contribute circuit_0001.zkey circuit_0002.zkey --name="Second contribution Name" -v -e="Another random entropy"
	snarkjs zkey beacon circuit_0002.zkey $(pk) 1cbf6603d6ff9ba4e1d15d0fd83be3a80bca470b6a43a7f9055204e860298f99 10 -n="Final Beacon phase2"
	snarkjs zkey export verificationkey $(pk) $(vk)

$(prove_outputs) : $(wasm) $(circ_input) $(pk)
	snarkjs groth16 fullprove $(circ_input) $(wasm) $(pk) $(pf_js) $(pb_js)


verify : $(pb_js) $(pf_js) $(vk) $(wit)
	snarkjs groth16 verify $(vk) $(pb_js) $(pf_js)
	del $(zkey_waste) $(ptau_waste) $(r1cs) $(wit)
	del /Q $(js_dir)
	rmdir /Q $(js_dir)

clean : 
	del $(zkey_waste) $(ptau_waste) $(r1cs) $(wit)
	del /Q $(js_dir)
	rmdir /Q $(js_dir)

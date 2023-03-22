circom = idChecker.circom
r1cs = idChecker.r1cs
wasm = idChecker_js/idChecker.wasm
wit_gen = idChecker_js/generate_witness.js
compile_outputs = idChecker_js/witness_calculator.js $(r1cs) $(wasm) $(wit_gen)
pk = idChecker.pk
vk = idChecker_vk.json
ptau = idChecker.ptau
keys = $(pk) $(vk)
circ_input = idChecker_input/idChecker_1.input.json
wit = idChecker_witness.wtns
pb_js = public.json
pf_js = proof.json
js_dir = idChecker_js
prove_outputs = $(pb_js) $(pf_js)
zkey_waste = $(wildcard *.zkey)
ptau_waste = $(wildcard *.ptau)

all : verify clean

$(compile_outputs) : $(circom)
	circom $< --r1cs --wasm

$(wit) : $(circ_input) $(wit_gen) $(wasm)  
	node $(wit_gen) $(wasm) $(circ_input) $@

$(ptau) :
	snarkjs powersoftau new bn128 12 pot12_0000.ptau -v
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



verify : $(pb_js) $(pf_js) $(vk)
	snarkjs groth16 verify $(vk) $(pb_js) $(pf_js)

clean : 
	del $(zkey_waste) $(ptau_waste) $(r1cs) $(wit)
	del /Q $(js_dir)
	rmdir /Q $(js_dir)

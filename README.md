- PS C:\Users\Admin\Desktop\AES\tv> ./aes
- Plaintext message:
2923be84e16cd6ae529049f1f1bbe9eb
- key:
b3a6db3c870c3e99245e0d1c06b747de
- Ciphered message:
3db07b8ccde8947627dfaadc07c163c6

- https://www.hanewin.net/encrypt/aes/aes-test.htm

- Key: 5468617473206D79204B756E67204675
- Plaintext: 54776F204F6E65204E696E652054776F
- Ciphertext: 29c3505f571420f6402299b31a02d73a

- rm work -Recurse; vsim -c -do "vlib work; vlog -sv *.sv; vsim work.tb_aes; run -all; quit"
- rm work -Recurse; vsim -c -do "vlib work; vlog -sv *.sv; vsim work.tb_aes_sbox; run -all; quit"
- rm work -Recurse; vsim -c -do "vlib work; vlog -sv *.sv; vsim work.tb_aes_key_scheduling; run -all; quit"
- rm work -Recurse; vsim -c -do "vlib work; vlog -sv *.sv; vsim work.tb_aes_mixw; run -all; quit"

- PS C:\Users\Admin\Desktop\AES\tv> ./aes       
- Plaintext message:
29 23 be 84 e1 6c d6 ae 52 90 49 f1 f1 bb e9 eb
b3 a6 db 3c 87 0c 3e 99 24 5e 0d 1c 06 b7 47 de
3d b0 7b 8c cd e8 94 76 27 df aa dc 07 c1 63 c6
- key:
e5 44 63 a9 95 a2 ef e7 8d c8 89 4f 60 c2 23 4b
- PS C:\Users\Admin\Desktop\AES\tv> ./aes
- Plaintext message:
29 23 be 84 e1 6c d6 ae 52 90 49 f1 f1 bb e9 eb
- key:
b3 a6 db 3c 87 0c 3e 99 24 5e 0d 1c 06 b7 47 de
- Ciphered message:
3d b0 7b 8c cd e8 94 76 27 df aa dc 07 c1 63 c6
- key:
e5 44 63 a9 95 a2 ef e7 8d c8 89 4f 60 c2 23 4b
- PS C:\Users\Admin\Desktop\AES\tv> make debug=1
cc -o aes -g main.o file.o gmult.o aes.o rand.o
- PS C:\Users\Admin\Desktop\AES\tv> ./aes       
- Plaintext message:
29 23 be 84 e1 6c d6 ae 52 90 49 f1 f1 bb e9 eb
- key:
b3 a6 db 3c 87 0c 3e 99 24 5e 0d 1c 06 b7 47 de
- Ciphered message:
3d b0 7b 8c cd e8 94 76 27 df aa dc 07 c1 63 c6
- key:
e5 44 63 a9 95 a2 ef e7 8d c8 89 4f 60 c2 23 4b

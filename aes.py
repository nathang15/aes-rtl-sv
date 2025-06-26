import os
import random
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad

def hex_to_binary_string(hex_data):
    """Convert hex bytes to binary string"""
    return ''.join(format(byte, '08b') for byte in hex_data)

def write_test_vectors(test_vectors, output_dir='test_vec'):    
    os.makedirs(output_dir, exist_ok=True)
    files = {
        'data_bin': open(os.path.join(output_dir, 'aes_enc_data_i.txt'), 'w'),
        'key_bin': open(os.path.join(output_dir, 'aes_enc_key_i.txt'), 'w'),
        'res_bin': open(os.path.join(output_dir, 'aes_enc_res_o.txt'), 'w'),
        'data_hex': open(os.path.join(output_dir, 'aes_enc_data_i_hex.txt'), 'w'),
        'key_hex': open(os.path.join(output_dir, 'aes_enc_key_i_hex.txt'), 'w'),
        'res_hex': open(os.path.join(output_dir, 'aes_enc_res_o_hex.txt'), 'w'),
    }
    
    try:
        for i, tv in enumerate(test_vectors):
            plaintext = tv['plaintext']
            key = tv['key']
            
            # Perform AES encryption
            cipher = AES.new(key, AES.MODE_ECB)
            ciphertext = cipher.encrypt(plaintext)
            
            # Write binary format
            files['data_bin'].write(hex_to_binary_string(plaintext) + '\n')
            files['key_bin'].write(hex_to_binary_string(key) + '\n')
            files['res_bin'].write(hex_to_binary_string(ciphertext) + '\n')
            
            # Write hex format
            files['data_hex'].write(plaintext.hex() + '\n')
            files['key_hex'].write(key.hex() + '\n')
            files['res_hex'].write(ciphertext.hex() + '\n')
            
            if 'description' in tv:
                print(f"Test {i+1}: {tv['description']}")
                print(f"Plaintext:  {plaintext.hex()}")
                print(f"Key:        {key.hex()}")
                print(f"Ciphertext: {ciphertext.hex()}")
                print()
    
    finally:
        for f in files.values():
            f.close()

def main():
    print("AES-128 Test Vector Generator (Python)")
    print("=====================================\n")
    
    test_vectors = [
        # NIST Test Vector 1
        {
            'plaintext': bytes.fromhex('00112233445566778899aabbccddeeff'),
            'key': bytes.fromhex('000102030405060708090a0b0c0d0e0f'),
            'description': 'NIST Test Vector 1'
        },
        # NIST Test Vector 2
        {
            'plaintext': bytes.fromhex('3243f6a8885a308d313198a2e0370734'),
            'key': bytes.fromhex('2b7e151628aed2a6abf7158809cf4f3c'),
            'description': 'NIST Test Vector 2'
        },
        # All zeros
        {
            'plaintext': bytes(16),
            'key': bytes(16),
            'description': 'All Zeros'
        },
        # All ones
        {
            'plaintext': bytes([0xff] * 16),
            'key': bytes([0xff] * 16),
            'description': 'All Ones'
        },
        # Custom test vector
        {
            'plaintext': bytes.fromhex('54776F204F6E65204E696E652054776F'),
            'key': bytes.fromhex('5468617473206D79204B756E67204675'),
            'description': "Two One Nine Two' with 'Thats my Kung Fu'"
        }
    ]

    write_test_vectors(test_vectors)
    
    print(f"\nGenerated {len(test_vectors)} test vectors")
    print("Test vectors written to test_vec/ directory")

if __name__ == '__main__':
    main()
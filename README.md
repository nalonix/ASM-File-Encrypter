

# XOR File Encryptor/Decryptor

This project provides a simple utility to encrypt and decrypt files using the XOR cipher. It consists of two main parts:

1.  **`xor_encrypt` (Assembly Language Executable):** A highly efficient command-line tool written in x86-64 NASM assembly, responsible for performing the actual byte-by-byte XOR operation on files.
2.  **`xor_gui.py` (Python Tkinter GUI):** A user-friendly graphical interface that interacts with the assembly executable, making it easy to select files and specify the encryption/decryption key.

## Features

  * **Fast XOR Operation:** The core encryption/decryption logic is implemented in optimized assembly language for high performance.
  * **Simple XOR Cipher:** Uses a single character as a key to perform XOR operation, which can be used for both encryption and decryption (XORing with the same key twice returns the original data).
  * **File-Based Operation:** Encrypts/decrypts entire files.
  * **User-Friendly GUI:** A Tkinter-based interface for easy file selection and key input.
  * **Error Handling:** Basic error handling for incorrect arguments or missing executable.

## How it Works

The XOR cipher is a symmetric encryption algorithm where plaintext is combined with a key using the bitwise XOR operation. The same operation with the same key can be used to revert the ciphertext back to the original plaintext.

`Ciphertext = Plaintext XOR Key`
`Plaintext = Ciphertext XOR Key`

The assembly program reads input files in chunks, XORs each byte in the chunk with the provided key character, and then writes the result to the output file. The Python GUI simply provides a wrapper to call this assembly program with the necessary arguments.

## Prerequisites

### For Assembly Program:

  * **NASM (Netwide Assembler):** To assemble the `.asm` file.
  * **GCC (GNU Compiler Collection):** To link the assembled object file.
  * **Linux-like environment:** The assembly code uses Linux system calls.

### For Python GUI:

  * **Python 3:** The GUI is written in Python 3.
  * **Tkinter:** Tkinter is usually included with standard Python installations. If not, you might need to install it:
      * On Debian/Ubuntu: `sudo apt-get install python3-tk`
      * On Fedora: `sudo dnf install python3-tkinter`
      * On macOS: It's usually pre-installed.

## Building and Running

### 1\. Build the Assembly Executable

First, you need to compile the assembly source code into an executable.

1.  **Save the assembly code:**
    Save the provided assembly code (the first block in your prompt) as `xor_encrypt.asm`.

2.  **Assemble:**
    Open your terminal and navigate to the directory where you saved `xor_encrypt.asm`. Then run:

    ```bash
    nasm -f elf64 xor_encrypt.asm -o xor_encrypt.o
    ```

3.  **Link:**

    ```bash
    ld xor_encrypt.o -o xor_encrypt
    ```

    This will create an executable file named `xor_encrypt` in the same directory.

### 2\. Run the Python GUI

1.  **Save the Python GUI code:**
    Save the provided Python code (the second block in your prompt) as `xor_gui.py` in the **same directory** as your `xor_encrypt` executable.

2.  **Make the assembly executable:**
    Ensure the `xor_encrypt` executable has execute permissions:

    ```bash
    chmod +x xor_encrypt
    ```

3.  **Run the GUI:**

    ```bash
    python3 xor_gui.py
    ```

    This will launch the graphical user interface.

## Usage

### Using the GUI (`xor_gui.py`)

1.  **Mode:** Select "Encrypt" or "Decrypt" from the dropdown. Since XORing with the same key character encrypts and decrypts, this selection primarily changes the suggested output filename suffix (`_enc` or `_dec`). The underlying assembly operation is identical.
2.  **Input File:** Click "Browse" to select the file you want to encrypt or decrypt.
3.  **Output File:** An output filename will be automatically suggested based on the input file and selected mode. You can modify this if needed.
4.  **Key:** Enter a **single character** as your encryption/decryption key.
5.  **Process:** Click the "Process" button to start the XOR operation. A success or error message will be displayed.

### Using the Assembly Executable Directly (`xor_encrypt`)

You can also use the `xor_encrypt` program directly from the command line, which can be useful for scripting or if you prefer a non-GUI approach.

**Syntax:**

```bash
./xor_encrypt <input_file> <output_file> <key_character>
```

  * `<input_file>`: The path to the file you want to encrypt/decrypt.
  * `<output_file>`: The path where the encrypted/decrypted file will be saved.
  * `<key_character>`: The single character to use as the XOR key.

**Examples:**

  * **Encrypt a text file:**
    ```bash
    ./xor_encrypt my_document.txt my_document_enc.txt A
    ```
  * **Decrypt the encrypted file:**
    ```bash
    ./xor_encrypt my_document_enc.txt my_document_dec.txt A
    ```
    (Note: Using the same key 'A' for decryption)
  * **Encrypt a binary file (e.g., an image):**
    ```bash
    ./xor_encrypt image.jpg image_enc.jpg x
    ```

## Assembly Code Details

The `xor_encrypt.asm` program implements the following logic:

  * **Argument Parsing:** Checks for exactly four command-line arguments (program name, input file, output file, key character).
  * **Key Validation:** Ensures the key provided is a single character.
  * **File I/O:**
      * Opens the input file in read-only mode (`O_RDONLY`).
      * Creates/opens the output file in write-only, create, and truncate mode (`O_WRONLY | O_CREAT | O_TRUNC`) with file permissions `0o644` (read/write for owner, read-only for group and others).
  * **XOR Loop:** Reads data in `BUFFER_SIZE` (4096 bytes) chunks, iterates through each byte in the buffer, performs the XOR operation with the key, and writes the modified buffer to the output file.
  * **System Calls:** Uses Linux x86-64 system calls for file operations (`sys_open`, `sys_read`, `sys_write`, `sys_close`) and program exit (`sys_exit`).
  * **Helper Functions:** Includes `_print_string` for writing messages to stdout/stderr and `_strlen` for calculating string length.
  * **Progress Messages:** Prints messages to the console indicating the current stage (opening files, processing, done).
  * **Error Exits:** Exits with status code 1 and prints an error message for invalid arguments or key.

## Python GUI Details

The `xor_gui.py` script leverages Tkinter for the graphical interface:

  * **File Dialogs:** Uses `filedialog.askopenfilename` for selecting input files.
  * **`subprocess` module:** Executes the `xor_encrypt` assembly program as a child process. It captures `stdout` and `stderr` to display any messages or errors from the assembly program.
  * **`messagebox`:** Provides pop-up messages for success, warnings, and errors.
  * **Basic Styling:** Uses `ttk.Style` for a cleaner look with the `clam` theme.

## Limitations and Considerations

  * **Simple Cipher:** The XOR cipher with a single character key is *not* cryptographically secure. It's easily breakable and suitable only for very basic obscurity, not for protecting sensitive information.
  * **Fixed Key Length:** The assembly program strictly enforces a single-character key.
  * **Error Handling (Assembly):** The assembly code has simplified error handling. For production-grade code, it would need more robust checks for failed `open`, `read`, or `write` syscalls.
  * **Cross-Platform (Assembly):** The assembly code is specific to Linux x86-64 systems due to its reliance on Linux system calls.
  * **Performance:** While the assembly code is efficient for the XOR operation itself, file I/O speed will be the primary bottleneck for very large files.

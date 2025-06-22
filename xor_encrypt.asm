
section .data
    usage_msg           db "Usage: xor_encrypt <input_file> <output_file> <key_character>", 10, 0
    usage_len           equ $ - usage_msg

    error_prefix_msg    db "Error: ", 0
    error_prefix_len    equ $ - error_prefix_msg

    invalid_args_msg    db "Invalid number of arguments.", 10, 0
    invalid_args_len    equ $ - invalid_args_msg

    invalid_key_msg     db "Key must be a single character.", 10, 0
    invalid_key_len     equ $ - invalid_key_msg  ; 

    ; Progress Messages
    msg_open_input      db "Opening input file...", 10, 0
    len_open_input      equ $ - msg_open_input

    msg_create_output   db "Creating/Opening output file...", 10, 0
    len_create_output   equ $ - msg_create_output

    msg_processing      db "Processing data (reading, XORing, writing)...", 10, 0
    len_processing      equ $ - msg_processing

    msg_done            db "Done!", 10, 0
    len_done            equ $ - msg_done

    O_RDONLY            equ 0o0         
    O_WRONLY            equ 0o1         
    O_CREAT             equ 0o100       
    O_TRUNC             equ 0o1000   

    OUTPUT_FILE_FLAGS   equ O_WRONLY | O_CREAT | O_TRUNC

    FILE_MODE           equ 0o644 

; --- SECTION .bss ---
section .bss
    BUFFER_SIZE         equ 4096
    file_buffer         resb BUFFER_SIZE

; --- SECTION .text ---
section .text
    global _start

; --- Macro for system calls ---
%macro SYSCALL 4
    mov rax, %1     ; syscall number
    mov rdi, %2     ; arg1
    mov rsi, %3     ; arg2
    mov rdx, %4     ; arg3
    syscall
%endmacro

_print_string:
    SYSCALL 1, rdi, rsi, rdx
    ret

_strlen:
    push rbx          ; Save RBX as it's callee-saved
    mov rbx, rdi      ; RBX = string pointer
    xor rax, rax      ; RAX = 0 (length counter)

.strlen_loop:
    cmp byte [rbx], 0
    je .strlen_done

    inc rax
    inc rbx
    jmp .strlen_loop

.strlen_done:
    pop rbx           ; Restore RBX
    ret

_start:
    ; --- 1. Get argc and argv pointers from the stack ---
    ; argv[0] = program name
    ; argv[1] = input_file
    ; argv[2] = output_file
    ; argv[3] = key_character
    mov rbp, rsp        ; Save stack pointer to RBP

    mov rcx, [rbp]      ; rcx = argc (argument count)

    ; --- 2. Check argument count ---
    cmp rcx, 4          ; Expect 4 arguments (program + 3 args)
    jne .invalid_args_exit ; Jump on error

    ; --- 3. Parse and validate the key character ---
    ; argv[3] is the key string
    mov rdi, [rbp + 32] ; RDI = pointer to argv[3] (key string)
    call _strlen        ; Get length of key string into RAX
    
    cmp rax, 1          ; Key must be exactly one character long
    jne .invalid_key_exit ; Jump on error

    ; Get the single key character
    mov r15b, byte [rdi] ; R15B = the actual key character (lower byte of R15)

    ; --- 4. Open Input File ---
    mov rdi, 1 ; stdout
    mov rsi, msg_open_input
    mov rdx, len_open_input
    call _print_string

    ; sys_open(filename, O_RDONLY, mode=0)
    mov rdi, [rbp + 16] ; RDI = pointer to argv[1] (input filename)
    mov rsi, O_RDONLY   ; RSI = flags (read-only)
    xor rdx, rdx        ; RDX = 0 (mode, not used for O_RDONLY)
    SYSCALL 2, rdi, rsi, rdx

    mov r12, rax        ; R12 = input_fd (stores file descriptor)

    ; --- 5. Open Output File ---
    mov rdi, 1 ; stdout
    mov rsi, msg_create_output
    mov rdx, len_create_output
    call _print_string

    ; sys_open(filename, O_WRONLY | O_CREAT | O_TRUNC, FILE_MODE)
    mov rdi, [rbp + 24] ; RDI = pointer to argv[2] (output filename)
    mov rsi, OUTPUT_FILE_FLAGS ; RSI = flags
    mov rdx, FILE_MODE  ; RDX = mode (permissions)
    SYSCALL 2, rdi, rsi, rdx

    mov r13, rax        ; R13 = output_fd (stores file descriptor)

    ; --- 6. Main Encryption Loop ---
    mov rdi, 1 ; stdout
    mov rsi, msg_processing
    mov rdx, len_processing
    call _print_string

.encryption_loop:
    mov rax, 0          ; syscall 0 (sys_read)
    mov rdi, r12        ; RDI = input_fd
    mov rsi, file_buffer ; RSI = buffer address
    mov rdx, BUFFER_SIZE ; RDX = number of bytes to read
    syscall             ; Call sys_read

    cmp rax, 0          ; Check bytes_read (RAX)
    jle .end_encryption ; If 0 or less, end loop (0 = EOF, <0 = error, simplified handling)

    mov r14, rax        ; R14 = bytes_read (actual number of bytes read)

    xor rbx, rbx        ; RBX = current byte index in buffer (0-based)
.xor_byte_loop:
    cmp rbx, r14        ; Compare index with bytes_read
    je .write_data      ; If index == bytes_read, all bytes processed, go to write

    mov cl, byte [file_buffer + rbx] ; Load byte from buffer into CL (low byte of RCX)
    xor cl, r15b        ; XOR CL with the key character (in R15B)
    mov byte [file_buffer + rbx], cl ; Store the encrypted byte back into buffer

    inc rbx             ; Increment byte index
    jmp .xor_byte_loop  ; Loop back for next byte

.write_data:
    mov rax, 1          ; syscall 1 (sys_write)
    mov rdi, r13        ; RDI = output_fd
    mov rsi, file_buffer ; RSI = buffer address (now encrypted)
    mov rdx, r14        ; RDX = number of bytes to write (same as bytes_read)
    syscall             ; Call sys_write

    ; Simplified: No explicit check for write failure. Assumes success.
    ; In a real app, you'd check RAX here for bytes written.

    jmp .encryption_loop ; Continue to next block

; --- 7. End of Encryption / File Closing ---
.end_encryption:
    ; Close input_fd
    mov rax, 3          ; sys_close
    mov rdi, r12        ; RDI = input_fd
    syscall             ; Call sys_close

    ; Close output_fd
    mov rax, 3          ; sys_close
    mov rdi, r13        ; RDI = output_fd
    syscall             ; Call sys_close

    ; Print success message
    mov rdi, 1 ; stdout
    mov rsi, msg_done
    mov rdx, len_done
    call _print_string

    ; --- 8. Exit Successfully ---
    SYSCALL 60, 0, 0, 0 

; --- Error Handling Routines (Only for argument validation) ---
.invalid_args_exit:
    mov rdi, 2 ; stderr
    mov rsi, error_prefix_msg
    mov rdx, error_prefix_len
    call _print_string
    mov rsi, usage_msg
    mov rdx, usage_len
    call _print_string
    SYSCALL 60, 1, 0, 0 ; Exit with error code 1

.invalid_key_exit:
    mov rdi, 2 ; stderr
    mov rsi, error_prefix_msg
    mov rdx, error_prefix_len
    call _print_string
    mov rsi, invalid_key_msg
    mov rdx, invalid_key_len
    call _print_string
    SYSCALL 60, 1, 0, 0 ; Exit with error code 1
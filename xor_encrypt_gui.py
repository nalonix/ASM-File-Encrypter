import tkinter as tk
from tkinter import filedialog, messagebox, ttk
import subprocess
import os

def browse_input():
    filename = filedialog.askopenfilename()
    if filename:
        input_entry.delete(0, tk.END)
        input_entry.insert(0, filename)
        # Auto-generate output filename
        base, ext = os.path.splitext(filename)
        suffix = "_enc" if mode_var.get() == "Encrypt" else "_dec"
        output_path = base + suffix + ext
        output_entry.delete(0, tk.END)
        output_entry.insert(0, output_path)

def run_xor():
    input_file = input_entry.get()
    output_file = output_entry.get()
    key_char = key_entry.get()
    mode = mode_var.get()

    if not input_file or not output_file or not key_char:
        messagebox.showerror("Error", "All fields are required.")
        return

    if len(key_char) != 1:
        messagebox.showerror("Error", "Key must be exactly one character.")
        return

    if not os.path.exists("./xor_encrypt"):
        messagebox.showerror("Error", "Assembly executable 'xor_encrypt' not found.")
        return

    try:
        result = subprocess.run(
            ["./xor_encrypt", input_file, output_file, key_char],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            messagebox.showinfo("Success", f"{mode}ion complete!")
        else:
            messagebox.showerror(f"{mode}ion Failed", result.stderr + result.stdout)
    except Exception as e:
        messagebox.showerror("Execution Error", str(e))

# ---------- UI SETUP ----------
root = tk.Tk()
root.title("XOR File Encryptor")
root.geometry("550x450")
root.resizable(False, False)

# Minimalist color scheme
BG_COLOR = "#ffffff"
TEXT_COLOR = "#2d2d2d"
ACCENT_COLOR = "#007aff"
HOVER_COLOR = "#005bb5"

# Configure style
style = ttk.Style()
style.theme_use('clam')

# Frame style
style.configure("Main.TFrame", background=BG_COLOR)

# Label style
style.configure("TLabel", 
                background=BG_COLOR, 
                foreground=TEXT_COLOR, 
                font=("Helvetica", 10))

# Entry style
style.configure("TEntry", 
                fieldbackground=BG_COLOR, 
                foreground=TEXT_COLOR, 
                borderwidth=1, 
                relief="solid",
                padding=8,
                font=("Helvetica", 10))

# Combobox style
style.configure("TCombobox", 
                fieldbackground=BG_COLOR, 
                foreground=TEXT_COLOR, 
                borderwidth=1, 
                relief="solid",
                padding=8,
                font=("Helvetica", 10))
style.map("TCombobox", 
          fieldbackground=[("readonly", BG_COLOR)],
          selectbackground=[("readonly", BG_COLOR)],
          selectforeground=[("readonly", TEXT_COLOR)])

# Button style
style.configure("TButton", 
                background=ACCENT_COLOR, 
                foreground="white", 
                borderwidth=0, 
                relief="flat",
                padding=10,
                font=("Helvetica", 10, "bold"))
style.map("TButton", 
          background=[("active", HOVER_COLOR)],
          foreground=[("active", "white")])

# Main frame
main_frame = ttk.Frame(root, style="Main.TFrame", padding="20")
main_frame.grid(row=0, column=0, sticky="nsew")
root.grid_rowconfigure(0, weight=1)
root.grid_columnconfigure(0, weight=1)

# Header
header = ttk.Label(main_frame, 
                  text="XOR Encryptor", 
                  font=("Helvetica", 14, "bold"),
                  foreground=TEXT_COLOR)
header.grid(row=0, column=0, columnspan=2, pady=(0, 20), sticky="ew")

# Mode selection
ttk.Label(main_frame, text="Mode:").grid(row=1, column=0, sticky="e", padx=5, pady=8)
mode_var = tk.StringVar(value="Encrypt")
mode_menu = ttk.Combobox(main_frame, 
                        textvariable=mode_var, 
                        values=["Encrypt", "Decrypt"], 
                        state="readonly", 
                        width=15)
mode_menu.grid(row=1, column=1, sticky="w", padx=5, pady=8)

# Input file
ttk.Label(main_frame, text="Input File:").grid(row=2, column=0, sticky="e", padx=5, pady=8)
input_entry = ttk.Entry(main_frame, width=30)
input_entry.grid(row=2, column=1, sticky="ew", padx=5, pady=8)
browse_btn = ttk.Button(main_frame, text="Browse", command=browse_input, width=8)
browse_btn.grid(row=3, column=1, sticky="e", padx=5, pady=(0, 8))

# Output file
ttk.Label(main_frame, text="Output File:").grid(row=4, column=0, sticky="e", padx=5, pady=8)
output_entry = ttk.Entry(main_frame, width=30)
output_entry.grid(row=4, column=1, sticky="ew", padx=5, pady=8)

# Key input
ttk.Label(main_frame, text="Key:").grid(row=5, column=0, sticky="e", padx=5, pady=8)
key_entry = ttk.Entry(main_frame, width=5)
key_entry.grid(row=5, column=1, sticky="w", padx=5, pady=8)

# Run button
run_btn = ttk.Button(main_frame, 
                    text="Process", 
                    command=run_xor)
run_btn.grid(row=6, column=1, sticky="e", pady=20)

# Configure grid weights
main_frame.grid_columnconfigure(1, weight=1)

root.mainloop()
#! /bin/bash

# ==============================================
# YABROOS Build Script
# ==============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if file exists
check_file() {
    if [ ! -f "$1" ]; then
        print_fail "$1 not found"
        return 1
    fi
    return 0
}

# 1. Full cleanup before build
print_status "Cleaning..."
mkdir Disk
print_ok "Clean done"

# 2. Compile kernel and bootloader
print_status "Compiling bootloader..."
if check_file "src/boot.asm"; then
    nasm -f bin src/boot.asm -o bin/boot.bin && print_ok "boot.bin ready"
fi

print_status "Compiling kernel..."
if check_file "src/kernel.asm"; then
    nasm -f bin src/kernel.asm -o bin/kernel.bin && print_ok "kernel.bin ready"
fi

# 3. Compile built-in COM programs
print_status "Compiling COM programs..."

if check_file "programs/COM/calc.asm"; then
    nasm -f bin programs/COM/calc.asm -o bin/calc.com && print_ok "calc.com"
fi

if check_file "programs/COM/clock.asm"; then
    nasm -f bin programs/COM/clock.asm -o bin/clock.com && print_ok "clock.com"
fi

if check_file "programs/COM/fr.asm"; then
    nasm -f bin programs/COM/fr.asm -o bin/fr.com && print_ok "fr.com"
fi

if check_file "programs/COM/paint.asm"; then
    nasm -f bin programs/COM/paint.asm -o bin/paint.com && print_ok "paint.com"
fi

if check_file "programs/COM/hello.asm"; then
    nasm -f bin programs/COM/hello.asm -o bin/hello.com && print_ok "hello.com"
fi
# BIN programs
if check_file "programs/BIN/hellobin.asm"; then
    nasm -f bin programs/BIN/hellobin.asm -o bin/hello.bin && print_ok "hello.bin"
fi

# EXE programs
print_status "Compiling EXE programs..."

if check_file "programs/EXE/clock1.asm"; then
    fasm programs/EXE/clock1.asm bin/clock.exe && print_ok "clock.exe"
fi

if check_file "programs/EXE/test.asm"; then
    fasm programs/EXE/test.asm bin/hello.exe && print_ok "hello.exe"
fi

# 4. Create a clean 2.88 MB floppy image
print_status "Creating floppy image..."
dd if=/dev/zero of=Disk/floppy.img bs=1024 count=2880 2>/dev/null
print_ok "Image created"

# 5. Format strictly according to standard 2.88 MB geometry
print_status "Formatting FAT12..."
mkfs.vfat -I -F 12 -n "YABROOS" Disk/floppy.img 2>/dev/null
print_ok "Formatted"

# 6. Write boot sector without breaking FAT12 structure
print_status "Writing boot sector..."
dd if=bin/boot.bin of=Disk/floppy.img conv=notrunc bs=512 count=1 2>/dev/null
print_ok "Boot sector written"

# 7. Copy OS files to floppy
print_status "Copying OS files..."
if check_file "bin/kernel.bin"; then
    mcopy -i Disk/floppy.img bin/kernel.bin ::KERNEL.BIN 2>/dev/null && print_ok "KERNEL.BIN"
fi

if check_file "programs/yabrus.txt"; then
    mcopy -i Disk/floppy.img programs/yabrus.txt ::YABRUS.TXT 2>/dev/null && print_ok "YABRUS.TXT"
fi

# 8. Copy all compiled programs
print_status "Copying programs..."

if check_file "bin/hello.com"; then
    mcopy -i Disk/floppy.img bin/hello.com ::HELLO.COM 2>/dev/null && print_ok "HELLO.COM"
fi

if check_file "bin/HELLO.EXE"; then
    mcopy -i Disk/floppy.img bin/HELLO.EXE ::HELLO.EXE 2>/dev/null && print_ok "HELLO.EXE"
fi

if check_file "bin/hello.bin"; then
    mcopy -i Disk/floppy.img bin/hello.bin ::HELLO.BIN 2>/dev/null && print_ok "HELLO.BIN"
fi

if check_file "bin/calc.com"; then
    mcopy -i Disk/floppy.img bin/calc.com ::CALC.COM 2>/dev/null && print_ok "CALC.COM"
fi

if check_file "bin/clock.com"; then
    mcopy -i Disk/floppy.img bin/clock.com ::CLOCK.COM 2>/dev/null && print_ok "CLOCK.COM"
fi

if check_file "bin/test.exe"; then
    mcopy -i Disk/floppy.img bin/test.exe ::TEST.EXE 2>/dev/null && print_ok "TEST.EXE"
fi

if check_file "bin/fr.com"; then
    mcopy -i Disk/floppy.img bin/fr.com ::FR.COM 2>/dev/null && print_ok "FR.COM"
fi

if check_file "bin/clock.exe"; then
    mcopy -i Disk/floppy.img bin/clock1.exe ::CLOCK.EXE 2>/dev/null && print_ok "CLOCK1.EXE"
fi

if check_file "bin/paint.com"; then
    mcopy -i Disk/floppy.img bin/paint.com ::PAINT.COM 2>/dev/null && print_ok "PAINT.COM"
fi

if check_file "bin/yabrus.com"; then
    mcopy -i Disk/floppy.img bin/yabrus.com ::YABRUS.COM 2>/dev/null && print_ok "YABRUS.COM"
fi

if check_file "bin/clock.exe"; then
    mcopy -i Disk/floppy.img bin/clock.exe ::CLOCK.EXE 2>/dev/null && print_ok "CLOCK.EXE"
fi

# 9. Ask about QEMU
echo ""
echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "Image: ${CYAN}Disk/floppy.img${NC}"
echo ""

read -p "Run in QEMU? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Starting QEMU..."
    qemu-system-x86_64 \
        -display gtk \
        -fda Disk/floppy.img \
        -machine pcspk-audiodev=snd0 \
        -device adlib,audiodev=snd0 \
        -audiodev pa,id=snd0
else
    print_status "Skipping QEMU"
	read -p "Run in DosBox? (y/n) " -n 1 -r
	echo ""
	if [[ $REPLY =~ ^[Yy]$ ]]; then
    	print_status "Starting DosBox..."
	    dosbox Disk/floppy.img
	else
    	print_status "Skipping all"
fi
fi

# YabroOS-16
free x16 OS YabroOS
use 
    
    mcopy -i yourprogram.bin/.com/.exe Disk/floppy.img :: 
to copy files to a disk

<img width="641" height="407" alt="image" src="https://github.com/user-attachments/assets/71ed349b-0a0d-4ce1-950b-b5eebb71b4a2" />
<img width="645" height="401" alt="image" src="https://github.com/user-attachments/assets/f9088703-3011-457b-8860-1448b0e28c64" />
<img width="434" height="403" alt="image" src="https://github.com/user-attachments/assets/bc804426-1378-4ef4-b1be-70b2703ddc3a" />
<img width="641" height="399" alt="image" src="https://github.com/user-attachments/assets/f46e26aa-79ba-4f54-905e-14392d3561de" />
<img width="721" height="310" alt="image" src="https://github.com/user-attachments/assets/291edf1e-939b-4ae3-9cff-26bb3dce3528" />

Installing packages for build:
Ubuntu/Debian
    
    sudo apt install nasm mtools dosfstools genisoimage

Arch Linux / Manjaro
    
    sudo pacman -Syu nasm mtools dosfstools cdrtools
Fedora
    
    sudo dnf install nasm mtools dosfstools genisoimage
Compilation Steps

Clone the repository:
    
    git clone https://github.com/Ayano4ka1338/YabroOS-16.git
    cd YabroOS-16
Make build script executable:
    
    chmod +x build.sh
build the project:
    
    ./build.sh

# YabroOS-16
Free x16 OS YabroOS.

use 

    mcopy -i yourprogram.bin/.com/.exe Disk/floppy.img :: 
to copy files to a disk

<img width="641" height="407" alt="image" src="https://github.com/user-attachments/assets/0d44d56f-e250-402b-8ada-23bc2c32855d" />
<img width="645" height="401" alt="image" src="https://github.com/user-attachments/assets/e2c46d5b-d1d0-415b-97bc-6073f307163d" />
<img width="434" height="403" alt="image" src="https://github.com/user-attachments/assets/dbcc2d6e-97b0-44ef-a5e6-26630f49e599" />
<img width="641" height="399" alt="image" src="https://github.com/user-attachments/assets/2ea2992f-4453-40f0-99f9-c467149d9e9a" />
<img width="721" height="310" alt="image" src="https://github.com/user-attachments/assets/ec0c65c2-5a75-4103-9241-1195eff81a62" />
U can say "I use YabroOS btw"

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


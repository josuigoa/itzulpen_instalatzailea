zig build -Dinstaller-data=$HOME/git/itzulpenak/$1/data -Doptimize=ReleaseSmall -Dcpu=baseline
mv zig-out/bin/installer $HOME/git/itzulpenak/$1/instalatzailea/$1_euskaraz_linux
zig build -Dinstaller-data=$HOME/git/itzulpenak/$1/data -Dtarget=aarch64-macos -Doptimize=ReleaseSmall 
mv zig-out/bin/installer $HOME/git/itzulpenak/$1/instalatzailea/$1_euskaraz_macos_m1
zig build -Dinstaller-data=$HOME/git/itzulpenak/$1/data -Dtarget=x86_64-macos -Doptimize=ReleaseSmall 
mv zig-out/bin/installer $HOME/git/itzulpenak/$1/instalatzailea/$1_euskaraz_macos
zig build -Dinstaller-data=$HOME/git/itzulpenak/$1/data -Dtarget=x86_64-windows -Doptimize=ReleaseSmall 
mv zig-out/bin/installer.exe $HOME/git/itzulpenak/$1/instalatzailea/$1_euskaraz.exe
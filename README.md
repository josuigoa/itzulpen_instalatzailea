# ITZULPEN INSTALATZAILEA


## GARATZAILEA OHARRAK

* Konpilatzerakoan, `-Dinstaller-data=/jokoaren/instalazio/bidea` parametroaren bidez pasatzen zaio joko bakoitzaren instalazioa eginen duen kodea.
  * `data` izeneko karpeta batean bidea izan behar du. Karpeta honen barrenean:
    * Itzulpenaren instalzazioa eginen duen `installer.zig` fitxategia. Funtzio hauek derrigorrezkoak.
      * pub fn get_game_names() [5]utils.string;
      * pub fn install_translation(game_path: utils.string) !void;
    * Instalazioan agertuko den goiruburko `header.png` izeneko irudia
* `header.png` fitxategia sortzerakoan:
  * 300x180 pixel
  * 8bpc RGBA formatuan esportatu
* Konpilazioa:
  * zig build -Dinstaller-data=/jokoaren/instalazio/bidea -Doptimize=ReleaseSmall 
  * zig build -Dinstaller-data=/jokoaren/instalazio/bidea -Dtarget=x86_64-macos -Doptimize=ReleaseSmall 
  * zig build -Dinstaller-data=/jokoaren/instalazio/bidea -Dtarget=aarch64-macos -Doptimize=ReleaseSmall 
  * zig build -Dinstaller-data=/jokoaren/instalazio/bidea -Dtarget=x86_64-windows -Doptimize=ReleaseSmall 
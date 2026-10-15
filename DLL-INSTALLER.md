# OctoAggro - DLL-installer

For deg som allerede har OctoAggro gjennom launcheren.

1. Last ned **OctoAggro-DLL-installer.zip** fra [nedlastingssiden](https://github.com/machomich123/OctoAggro/releases/latest).
2. Pakk ut hele ZIP-filen.
3. Dobbeltklikk **Installer-DLLer.cmd**. Den finner spillmappen automatisk gjennom OctoLauncher og installerer manglende DLL-er.
4. Start spillet med **VanillaFixes.exe**, eller med launcheren dersom den bruker VanillaFixes. Skriv `/oa status` i spillet.

Lukk WoW helt før installering. En full omstart er nødvendig; `/reload` laster ikke nye DLL-er.

Den leser spillstien fra OctoLaunchers `install.json` og `settings.json`. Hvis disse mangler, sjekker den vanlige spillmapper. Hvis flere gyldige mapper finnes, stopper den uten å gjette. Den åpner ingen mappevelger.

## Dette ordner installeren

- Laster ned manglende **ClassicAPI.dll** (v1.15.16) og **UnitXP_SP3.dll** (v90) fra deres offisielle GitHub-utgaver, kontrollerer SHA256 og legger dem ved WoW.exe.
- Legger inn **OctoAggroNative.dll** under `Interface/AddOns/OctoAggro/native` dersom den mangler. Den medfølgende DLL-en er for OctoAggro 0.8.1.
- Setter opp de tre oppføringene i `dlls.txt` og fjerner duplikater av disse oppføringene.
- Tar sikkerhetskopi av `dlls.txt`. Ved installasjonsfeil angres nye filer automatisk.
- Beholder eksisterende DLL-filer, andre loader-oppføringer og tillegget fra launcheren.

## Krav

Windows, internett ved manglende eksterne DLL-er, støttet OctoWoW 1.12.1.5875, OctoAggro installert gjennom launcheren og **VanillaFixes.exe med dlls.txt** i spillmappen. Installeren gir en tydelig feilmelding hvis dette mangler. VanillaFixes installeres ikke av denne pakken.

Klienten sjekkes mot SHA256 `5014ca1cfedf860f10e93fe7d955c56c28eb11a2bb503030dbb9b1c777f00470`. Andre klientfiler avvises før spillfiler endres.

## Kontrollert 15. oktober 2026

Testet med Windows PowerShell 5.1 i separat spillmappe: faktiske nedlastinger og hashes, automatisk gjenkjenning fra launcher, installering uten mappevalg, avvisning av motstridende spillstier, manglende DLL-er, bevaring av eksisterende filer, dupliserte loader-oppføringer, gjentatt installering, gjenoppretting, avvisning ved kjørende spill/manglende tillegg, manipulert nedlasting og automatisk opprydding etter simulert kopieringsfeil.

Dette bekrefter installering av filer. Visningen i spillet med disse avhengighetsversjonene er ikke bekreftet.

## Kildekode og opprinnelse

- [OctoAggro](https://github.com/machomich123/OctoAggro) - kildekode til den medfølgende DLL-en, installasjonsskript og lisenser.
- [ClassicAPI v1.15.16](https://github.com/brues-code/ClassicAPI/releases/tag/v1.15.16)
- [UnitXP_SP3 v90](https://github.com/brues-code/UnitXP_SP3/releases/tag/v90)
- [VanillaFixes](https://github.com/hannesmann/vanillafixes)

For å angre installasjonen: bruk `tools/Restore-Dependencies.ps1 -BackupPath <sikkerhetskopimappen>` i PowerShell. Stien til sikkerhetskopien vises etter installering. Gjenoppretting avvises hvis filene er endret siden installasjonen.

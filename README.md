# OctoAggro 0.8.1

Viser lokale hodeskaller over valgt fiende og fiender i nærheten som muligens kan bli med i kampen. Vanlige raidmarkeringer har prioritet. Bruk `/oa` for innstillinger.

## Last ned og installer

1. Last ned **OctoAggro-0.8.1.zip** fra [nyeste utgave](https://github.com/machomich123/OctoAggro/releases/latest).
2. Pakk ut ZIP-filen. Lukk WoW helt.
3. Åpne den utpakkede OctoAggro-mappen og dobbeltklikk **Installer.cmd**.
4. Oppgi mappen hvor WoW.exe ligger. Trykk Enter hvis den er `W:\Games\Octowow`.
5. Start WoW og aktiver OctoAggro i AddOns. Skriv `/oa status` for å kontrollere at tillegget og den innebygde delen er lastet.

Installeringen tar sikkerhetskopi og kontrollerer filene. Den krever OctoWoW-klienten 1.12.1.5875 med VanillaFixes og `dlls.txt`. En annen WoW.exe blir avvist før filer endres. Dette er ikke et vanlig tillegg for dagens WoW Classic eller Retail. En full omstart av spillet er nødvendig etter oppdatering.

## Rettelsen i 0.8.1

Oppdaterer spillets lagrede raidikon når lokale hodeskaller legges til, fornyes eller fjernes. Dette retter en påvist feil hvor ikonet kunne forsvinne når fiendens navneskilt var synlig.

## Hva er kontrollert?

Nybygg av DLL, 36 Lua-testgrupper og tester av markører, sirkler og avvisning av feil klient er bestått 15. oktober 2026. Den tidligere feilen gjenskapes i testen, og den nye oppdateringen består samme kontroll.

**Visningen i selve spillet er fortsatt ikke bekreftet for 0.8.1.** Fiender i nærheten er et anslag, ikke bekreftede forbindelser fra serveren.

Tekniske detaljer og kildegrunnlag: [TECHNICAL.md](TECHNICAL.md), [VERIFICATION.md](VERIFICATION.md), [DATA-SOURCES.md](DATA-SOURCES.md).

## Lisens og kildekode

Kildekode følger med og ligger i dette arkivet. AGPL-3.0; tredjepartslisenser følger med under `licenses` og `native/vendor/minhook`.

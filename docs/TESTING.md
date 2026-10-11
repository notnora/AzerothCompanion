# Azeroth Companion - Testdokumentasjon

Dette dokumentet beskriver hvordan vi tester prosjektet i praksis. Målet er å ha en enkel, reell og verifiserbar teststrategi som passer for en WoW Classic addon i et hobbyprosjekt, uten å overkomplikere løsningen.

## Testfilosofi

- Teste real oppførsel i spillet, ikke bare kode i isolasjon.
- Prioritere grunnleggende funksjonalitet først.
- Verifisere at addonet oppfører seg trygt og forutsigbart.
- Dokumentere hva som er verifisert, og hva som fortsatt er estimert eller ikke testet.
- Sørge for at feil i Lua eller UI blir fanget tidlig.

## Testnivåer

### 1. Enkle kode-/strukturtester

Dette er tester vi kan gjøre uten å være inne i spillet, for eksempel:
- kontroll av filstruktur
- kontroll av `.toc`-fil
- kontroll av at viktige filer finnes
- at event handlers og funksjoner er definert som forventet

Dette er ikke en full test-suite, men det er nyttig i tidlig utvikling for å fange enkle feil.

### 2. Manuelle in-game tester

Dette er de viktigste testene for prosjektet. Addonet må testes i en faktisk WoW Classic/SoD klient for å være gyldig.

### 3. Feil- og loggkontroll

Vi bruker WoW sine egne verktøy til å kontrollere om addon-en feiler eller logger problemer.

## Status for gjeldende build

- Lokal deploy er kjørt mot Classic Era AddOns-mappen. `.toc`-filen og begge Lua-filene ble sammenlignet med de deployede kopiene.
- Deploy-skriptet passerer `bash -n`, og editorens Lua-diagnostikk rapporterer ingen feil i hovedfilen eller konstantfilen.
- Lokal kjøring med `lua`/`luac` er ikke tilgjengelig i utviklingsmiljøet.
- Brukeren har bekreftet i WoW at vinduet vises, kan åpnes/lukkes og flyttes, og at knappene viser ulike eksempeldata.
- Spillerstatus inkludert fraksjon vises; brukeren rapporterer ingen feillogg i siste test.
- Resize fungerer innenfor min-/maksgrensene, og størrelsen beholdes etter `/reload`.
- `/reload` og `/ac` fungerer, og ingen Lua-feil ble observert i siste in-game-test.
- Vindusposisjon og -størrelse overlever både reload og relog. Tekstwrapping av hele spillerfelt og soneoppdatering etter hearthstone er bekreftet.
- Anbefalingene bruker strukturerte, fiktive fixtures og filtrerer på nivå, fraksjon, fixture-status og forutsetninger. «Gå videre» utelukker gjeldende sone.
- Ekte questlogg og fullføringsstatus er ikke koblet til. Fixture-status og item-dropstatus er demonstrasjonsdata, ikke spillfakta.
- Anbefalingsområdet har nå scrollframe, mouse-wheel-støtte og dynamisk teksthøyde; visuell scrolling er ikke bekreftet i klienten ennå.
- Koordinatvisning bruker Classic `C_Map`-API og bevegelseshendelser, og er ankret over soneteksten hvis den finnes; faktisk API-resultat og plassering over minimapet må bekreftes i klienten. I instanser kan koordinater være utilgjengelige.

---

## Verktøy og kommandoer vi bruker

### Reload

I spillet:
- `/reload`

Dette brukes for å laste addon-en på nytt etter endringer.

### Lua-feilvisning

I spillet:
- `/console scriptErrors 1`

Dette er nødvendig for å se om det finnes Lua-feil under bruk av addon-en.

### Informasjon om klient/build

For å verifisere klientbuild og kompatibilitet:
- `/dump select(4, GetBuildInfo())`

Dette er nyttig når vi kontrollerer at `.toc`-filen er kompatibel med installert klient.

---

## Tester for første MVP

Første MVP skal være liten, tydelig og reell. Dette er de viktigste testene.

### Test 1: Addonet lastes inn

#### Formål
Sjekke at addon-en blir lastet korrekt uten kritiske Lua-feil.

#### Steg
1. Start WoW Classic/SoD.
2. Sørg for at addonet ligger i riktig AddOns-mappe.
3. Logg inn.
4. Kjør `/reload`.
5. Kjør `/console scriptErrors 1`.

#### Verifisering
- Addonet vises uten kritiske feil.
- Ingen store Lua-feil i konsollen.
- UI-elementet vises som forventet.

### Test 2: Vinduet vises og er flyttbart

#### Formål
Sjekke at UI-et faktisk er synlig og kan brukes.

#### Steg
1. Logg inn med addonet aktivt.
2. Se etter hovedvinduet.
3. Prøv å flytte vinduet.
4. Klikk X for å skjule vinduet, og bruk `/ac` for å åpne det igjen.
5. Dra resize-håndtaket nederst til høyre for å endre størrelse.
6. Gjør vinduet lite, velg en anbefalingsmodus med flere linjer, og scroll med musehjul og scrollbar.

#### Verifisering
- Vinduet er synlig.
- Det kan flyttes eller posisjoneres uten at UI-et krasjer.
- Tekst og knapper vises korrekt.
- Lukkeknappen skjuler vinduet, og `/ac` viser det igjen.
- Resize-håndtaket endrer størrelsen uten at vinduet flyttes.
- Vinduet stopper ved definert minste- og største størrelse.
- Teksten holder seg innenfor vinduet når det endres størrelse.
- Anbefalingsteksten kan scrolles uten å tegnes utenfor vinduet.

Status: Bekreftet i WoW at vinduet vises, kan åpnes/lukkes, flyttes og endre størrelse innenfor min-/maksgrensene. `/ac` åpner det igjen etter lukking. Spillerfelt som `Sone: Stranglethorn Vale` flyttes samlet når teksten brytes.

### Test 11: Koordinater over minimapet

#### Formål
Kontrollere at spillerens posisjon vises over minimap-soneteksten og oppdateres mens karakteren beveger seg.

#### Steg
1. Logg inn i et utendørs område.
2. Kontroller at en linje på formen `Koord: 12.3, 45.6` står over soneetiketten på minimapet.
3. Gå eller løp et lite stykke og kontroller at tallene endrer seg.
4. Gå inn i en instans eller et område uten kartposisjon og kontroller at addon-en viser `Koord: --, --` uten Lua-feil.

#### Verifisering
- Koordinatlinjen ligger over sonenavnet/minimapet uten å dekke dem.
- Verdiene endres under bevegelse og slutter å oppdatere kontinuerlig når karakteren står stille.
- Manglende kartposisjon håndteres uten Lua-feil.

### Test 3: Spillerstatus oppdateres riktig

#### Formål
Verifisere at vi leser riktig spillerstatus.

#### Steg
1. Gå inn i en sone.
2. Se om addonet viser riktig nivå, klasse, fraksjon og sone.
3. Endre sone eller logg ut/logg inn.

#### Verifisering
- Informasjonen stemmer overens med faktisk karakterstatus.
- Vinduet oppdateres ved relevante events.

Status: Spillerinformasjon inkludert fraksjon vises i WoW, og sonen oppdateres etter hearthstone til Orgrimmar.

### Test 4: To hovedhandlinger vises

#### Formål
Sjekke at addonet har de to brukskontekstene.

#### Steg
1. Observer hovedvinduet.
2. Sjekk at følgende er synlig:
   - “Hva bør jeg gjøre her?”
   - “Jeg er klar til å gå videre!”

#### Verifisering
- Begge knapper/handlinger vises.
- De er tydelige og lesbare i spillet.
- Begge viser ulike eksempeldata. Bekreftet i WoW av brukeren.

### Test 5: Reload og relog fungerer

#### Formål
Sjekke at addonet håndterer lagring og oppstart korrekt.

#### Steg
1. Kjør `/reload`.
2. Logg ut og inn igjen.
3. Sjekk om vindu og innstillinger fortsatt er aktive.

#### Verifisering
- `/reload` fungerer, og vindusstørrelsen beholdes. Bekreftet i WoW.
- Vindusposisjon og -størrelse overlever både reload og relog. Bekreftet i WoW.

---

## Tester for anbefalingslogikk

Når vi kommer til fase 2 og senere, bør vi ha test av logikken separat fra UI.

### Test 6: Anbefalinger vises med begrunnelser

#### Formål
Sjekke at anbefalingene er forståelige for spilleren.

#### Steg
1. Åpne “Hva bør jeg gjøre her?”
2. Se resultater.
3. Kontroller om hver anbefaling har en enkel og kontekstbasert begrunnelse.

#### Verifisering
- Hver anbefaling har en tydelig forklaring.
- Det er klart hvorfor den blir foreslått.

### Test 7: “Jeg er klar til å gå videre!” er forskjellig fra “Hva bør jeg gjøre her?”

#### Formål
Sjekke at de to modene faktisk oppfører seg forskjellig.

#### Steg
1. Bruk “Hva bør jeg gjøre her?”
2. Bruk “Jeg er klar til å gå videre!”
3. Sammenlign resultatene.

#### Verifisering
- De to modene returnerer ikke identiske forslag.
- “Gå videre” ekskluderer i praksis ikke relevant sone når dette er forventet.

### Test 8: Nåværende sone blir ikke prioritert som hovedmål i “gå videre”-modus

#### Formål
Verifisere at vi ikke anbefaler den samme sonen når spilleren ønsker å flytte videre.

#### Steg
1. Vær i en sone.
2. Bruk “Jeg er klar til å gå videre!”
3. Se på de første forslagene.

#### Verifisering
- Nåværende sone vises ikke som hovedanbefaling.
- Nyere regioner eller relevante hubs får prioritet når de er passende.

### Test 9: Tydelig markering av eksempeldata

#### Formål
Sikre at vi klart skiller mellom ekte spilldata og demo-/fixture-data.

#### Steg
1. Se på anbefalinger i første iterasjon.
2. Sjekk om det er tydelig at data er eksempeldata.

#### Verifisering
- Brukeren forstår at det er testdata, ikke en full questdatabase.

### Test 10: Fixture-filtrering og quest-item-status

#### Formål
Kontrollere fixture-filteret og vise begrensningene tydelig.

#### Steg
1. Kjør `/reload` og kontroller at vinduet viser at forslagene er fiktive.
2. Trykk «Hva bør jeg gjøre her?» og kontroller at alle forslagene er fra gjeldende sone.
3. Trykk «Jeg er klar til å gå videre!» og kontroller at gjeldende sone ikke foreslås.
4. Sammenlign story, hub og begrunnelser; kontroller også at forslagene passer nivå og fraksjon.
5. Se etter item-meldinger for før aksept, etter aksept og ukjent status.
6. Kontroller at fullførte, låste og ukjente fixtureposter ikke vises.
7. Kontroller at fixtures med kjent questline-plassering viser `Questlinje: x/y`, mens fixtures uten slik metadata ikke får en oppdiktet plassering.
8. Gjør vinduet lavt, scroll nedover i forslagene, og se at hvert forslag har egen parchment-bakgrunn med tydelig skilt tittel, sone, story/hub, begrunnelse og item-status.

#### Verifisering
- Forslagene bruker strukturert fixture-data, ikke den virkelige questloggen.
- Quest-item-teksten skiller mellom før aksept, etter aksept og ukjent.
- Questline-plassering vises bare når både stegnummer og totalt antall steg finnes og er gyldige.
- Hvert questforslag er visuelt separat, parchment-bakgrunnen dekker kortet, og scrolling viser hele kortinnholdet.
- Ingen fixture eller dropstatus framstilles som verifiserte spilldata.

---

## Feilsøking og nøkkelverifisering

### Når noe ikke vises

Sjekk dette først:
- er addonet lastet i riktig AddOns-mappe?
- er `.toc`-filen riktig?
- er `/reload` kjørt?
- er Lua-feil logget med `/console scriptErrors 1`?

### Når UI ikke oppdateres

Sjekk:
- event registration
- om spillerstate blir oppdatert
- om frame refresh blir trigget
- om funksjonen som oppdaterer tekst faktisk blir kalt

### Når data ser feil ut

Sjekk:
- struktur i table/object
- felt-navn
- forutsetninger for data
- om det er eksempeldata eller faktisk data

---

## Testchecklist for hver fase

### Fase 1: MVP
- [x] Ingen Lua-feil observert i siste in-game-test
- [x] Vinduet vises, kan lukkes og flyttes (bekreftet i WoW)
- [x] Spillerstatus inkludert fraksjon vises (bekreftet i WoW)
- [x] Sonefeltet oppdateres etter sonebytte/hearthstone
- [x] To handlinger vises og gir ulike eksempeldata (bekreftet i WoW)
- [x] Resize-håndtaket endrer vindusstørrelsen (bekreftet i WoW)
- [x] Resize fungerer innenfor min-/maksgrensene
- [x] Hele spillerfelt holdes samlet når statuslinjen brytes ved resize
- [x] `/ac` åpner et skjult vindu
- [x] Vindusstørrelsen beholdes etter `/reload`
- [x] Vindusposisjon og -størrelse overlever reload og relog
- [x] `/reload` fungerer
- [x] `/console scriptErrors 1` viser ingen kritiske feil

### Fase 2: Fiksturer og anbefalinger
- [ ] Begge moduser viser fixtureforslag med begrunnelser
- [ ] Fiktive data og fravær av ekte questlogg er tydelig markert
- [ ] Nivå-, fraksjons-, status- og forutsetningsfilter fungerer
- [ ] «Hva bør jeg gjøre her?» viser bare aktuell sone
- [ ] «Gå videre» utelukker gjeldende sone
- [ ] Quest-item-status vises som før aksept, etter aksept eller ukjent

### Fase 3: Reise-/storylogikk
- [ ] Går videre-modus er forskjellig fra hva-bør-jeg-gjøre-her
- [ ] Nåværende sone ekskluderes som hovedmål
- [ ] Lang reise er ikke automatisk dårlig
- [ ] Tilbakevandring blir nedprioritert

### Senere faser
- [ ] Ekte data håndteres forsvarlig
- [ ] Manglende felter håndteres uten krasch
- [ ] Trenerdata er tydelig markert som usikre eller begrensede

---

## Oppsummering

Dette prosjektet skal testes på den måten som virkelig betyr noe:
- vi trenger et fungerende addon-vindu
- vi trenger fungerende overganger mellom events og UI
- vi trenger reelle sjekker i WoW
- og vi trenger dokumentasjon av hva som faktisk er verifisert

Det gjør prosjektet både mer pålitelig og mer lærerikt.

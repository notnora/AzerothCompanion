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
- `BackdropTemplate`-rettelsen er dermed bekreftet for innlasting og visning av vinduet. Fraksjon er nå lagt til i spillerstatus, men verdien er ikke bekreftet i klienten ennå. `/reload`, `/console scriptErrors 1`, `/ac`, spillerstatus og SavedVariables er heller ikke rapportert testet.
- Resize-håndtak med grenser, responsiv tekstbredde og lagring av størrelse er implementert og deployet; faktisk resizing og persistering må bekreftes i klienten.
- Anbefalingene er statiske eksempeldata. De sjekker ikke ekte quest-tilgjengelighet, nivå eller om spilleren allerede er i foreslått sone.

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

#### Verifisering
- Vinduet er synlig.
- Det kan flyttes eller posisjoneres uten at UI-et krasjer.
- Tekst og knapper vises korrekt.
- Lukkeknappen skjuler vinduet, og `/ac` viser det igjen.
- Resize-håndtaket endrer størrelsen uten at vinduet flyttes.
- Vinduet stopper ved definert minste- og største størrelse.
- Teksten holder seg innenfor vinduet når det endres størrelse.

Status: Delvis bekreftet i WoW: vinduet vises, kan åpnes/lukkes og flyttes. Åpning via `/ac` er ikke bekreftet særskilt.

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
- Addonet fungerer fortsatt etter reload.
- Innstillinger eller vindusposisjon beholdes der dette er implementert.

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
- [ ] Addonet laster inn uten feil, inkludert lasting av konstantmodulen før hovedfilen
- [x] Vinduet vises, kan lukkes og flyttes (bekreftet i WoW)
- [ ] Spillerstatus vises korrekt, inkludert fraksjon
- [x] To handlinger vises og gir ulike eksempeldata (bekreftet i WoW)
- [ ] Resize-håndtaket endrer størrelse innenfor grensene, og innholdet tilpasser seg
- [ ] `/ac` åpner et skjult vindu
- [ ] Vindusposisjon og størrelse overlever reload og relog
- [ ] `/reload` fungerer
- [ ] `/console scriptErrors 1` viser ingen kritiske feil

### Fase 2: Fiksturer og anbefalinger
- [ ] Forslag vises
- [ ] Forslag har begrunnelser
- [ ] Fiktive data er tydelig markert
- [ ] Filter for fullførte/ugyldige quests fungerer

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

# Azeroth Companion - Roadmap

Dette dokumentet beskriver en tydelig utviklingsplan for prosjektet. Målet er å kombinere læring i Lua og WoW-addon-utvikling med et hobbyprosjekt som faktisk blir nyttig og brukbart i World of Warcraft Classic: Season of Discovery.

## Hovedmål

- Bygge en liten, forklarbar quest-assistent som anbefaler relevante aktiviteter.
- Prioritere historier, nivåpassende innhold og minimal meningsløs tilbakevandring.
- Lære gradvis, uten å gjøre prosjektet for komplekst fra starten.
- Fokusere på en fungerende MVP først, og bygge videre i små vertikale skiver.

## Prinsipper for utvikling

- Start med minste fungerende MVP.
- Bygg i små, testbare steg.
- Bruk fiksturer først, ikke full quest-database.
- Verifiser WoW Classic/SoD API før antagelser.
- Forklar hvert forslag på en måte spilleren forstår.
- Behold spillerens kontroll. Vi anbefaler, vi tvinger ikke.

---

## Fase 0: Oppsett og prosjektforståelse

Status: fullført

### Mål
- Opprette prosjektstrukturen og dokumentasjon.
- Sikre at vi har en tydelig produktretning.
- Definere hvilke deler som er MVP, og hvilke som er senere forbedringer.

### Sjekkliste
- [x] Oppdatere README med prosjektoversikt
- [x] Opprette roadmap for utvikling
- [x] Lese product spec og prosjektinstruksjoner
- [x] Definere hvilke funksjoner som er i MVP
- [x] Definere hvilke funksjoner som kommer senere

### Akseptkriterier
- Prosjektet har en tydelig målsetning og en enkel utviklingsretning.
- Alle beslutninger bygger på konseptet om “story-first, not speedleveling”.
- Vi har en konkret MVP-definisjon før kode skrives.

---

## Fase 1: MVP-addon shell

Status: pågår — implementert lokalt, in-game-verifisering gjenstår

### Mål
- Bygge et fungerende addon-vindu i WoW.
- Vise spillerstatus og grunnleggende UI.
- Opprette en struktur som kan vokse uten store omskrivinger.

### Innhold
- Movable main frame
- Visning av nivå, klasse, fraksjon og sone
- To hovedhandlinger:
  - “Hva bør jeg gjøre her?”
  - “Jeg er klar til å gå videre!”
- Grundleggende layout og tekst
- SavedVariables for window position

### Sjekkliste
- [x] Definere addon-filstruktur med `.toc`, konstantmodul og hovedfil
- [x] Opprette `.toc` med Interface 11509, basert på klientversjonen oppgitt for prosjektet
- [x] Lage hovedframe og UI-layout, inkludert lukkeknapp
- [x] Registrere nødvendige events
- [x] Hente spillerstatus fra WoW API
- [ ] Vise alle ønskede spillerdata; navn, klasse, nivå og sone vises, men fraksjon vises ikke ennå
- [x] Lagre vindusposisjon i SavedVariables
- [x] Lage lokalt deploy-skript og kopiere addon-filene til installert klientmappe
- [ ] Verifisere `/reload` og `scriptErrors`

### Akseptkriterier
- Addonet lastes inn uten Lua-feil.
- Vinduet vises og er flyttbart.
- Spillerdata oppdateres korrekt.
- Addonet tåler reload og relog uten kritiske feil.

### Status og neste kontroll
- Deploy-skriptet er kjørt, og de deployede `.toc`- og Lua-filene er sammenlignet med kildefilene.
- `BackdropTemplate` er lagt til etter en rapportert feil fra `SetBackdrop`; rettelsen er deployet, men ikke bekreftet i klienten ennå.
- Test i WoW: aktiver `/console scriptErrors 1`, kjør `/reload`, kontroller at vinduet vises, flyttes og lukkes, og at `/ac` åpner det igjen.
- Flytt vinduet, kjør `/reload` og relog for å kontrollere at posisjonen beholdes.
- Visning av fraksjon må legges til før Fase 1 er helt ferdig.

---

## Fase 2: Fiktive quest-data og anbefalinger

Status: planlagt — MVP-en har foreløpig bare statiske eksempelanbefalinger

### Mål
- Lære grunnleggende data-modellering og rekommendasjonslogikk.
- Lage eksempeldata som representerer quests, hubs og story-tråder.
- Vise menneskeleselige begrunnelser for forslag.

### Innhold
- Fiktivt quest-repository
- Quest struktur med minst:
  - id
  - nivå
  - sone
  - story-id
  - hub
  - status
  - begrunnelse
- Filtrering for:
  - tilgjengelighet
  - nivåpassende innhold
  - fullførte quests
  - forutsetninger
- Enkel rangering av forslag

### Sjekkliste
- [ ] Definere datastruktur for quest
- [ ] Lage eksempelquester i fixture-data
- [ ] Filtrere ut fullførte eller ugyldige quests
- [ ] Prioritere quests som hører til samme historie eller hub
- [x] Vise enkle, menneskeleselige begrunnelser i eksempelanbefalingene
- [x] Markere anbefalingene som eksempeldata i UI-et

De nåværende anbefalingene er hardkodede demonstrasjonsforslag. De er ikke en strukturert quest-fixture med nivå, status, historie-ID eller hub, og de filtreres ikke mot karakteren eller questloggen.

### Akseptkriterier
- Spieler får konkrete forslag i UI-et.
- Forslagene kommer med forklaring, ikke bare uforståelige verdier.
- Datan er tydelig skilt fra ekte spilldata i første iterasjon.

---

## Fase 3: Reiskap for eventyrsammenheng og reiseplanlegging

Status: planlagt

### Mål
- Lære å analysere not just “quest quality”, men også “reiseeffektivitet”.
- Unngå anbefalinger som er meningsløse fordi de krever konstant tilbakevandring.

### Innhold
- Reise-/turn-in scoring
- Oppdeling i:
  - naturlig hub-progresjon
  - isolert turn-in
  - en engangs lang reise til nytt område
  - gjentatt tilbakevandring
- Forslag som kombinerer flere mål

### Sjekkliste
- [ ] Modellere start -> mål -> innlevering -> neste quest
- [ ] Definere regresjoner for tilbakevandring
- [ ] Penaliser mer enn én isolert innleveringstype
- [ ] Favorisere naturlig progression mellom nærliggende hubs
- [ ] La lange reiser være mulig når de er verdt det

### Akseptkriterier
- Vi kan forklare hvorfor et forslag er bedre enn et annet uten å bruke “score” som magi.
- Repetitive turn-in loops blir nedprioritert.
- Long-distance travel er ikke automatisk dårlig.

---

## Fase 4: Quest-repository og faktisk quest-data

Status: senere

### Mål
- Bytte ut fixture-data med en mer realistisk datastore.
- Koble logikk mot reelle quest-kilder på en trygg måte.

### Innhold
- Datasett med
  - quest-id
  - nivå
  - sone
  - forutsetninger
  - starter
  - innlevering
  - humant lesbar tekst
- Kvalitetssikring av data
- Robust håndtering av manglende felt

### Sjekkliste
- [ ] Velge datastruktur for ekte quest-repository
- [ ] Verifisere kompatibilitet med SoD-data
- [ ] Definere adapter-lag for data
- [ ] Implementere filtrering av prestasjoner og forutsetninger
- [ ] Dokumentere usikre felter tydelig

### Akceptkriterier
- Addonet kan skille mellom verifiserte data, ukjent data og sample data.
- Manglende felter fører ikke til feil i UI eller logikk.

---

## Fase 5: Trener- og bybesøkslogikk

Status: senere

### Mål
- Legge til “smart city visits” uten å overkomplikere prosjektet.
- Koble trening og quests når det er naturlig.

### Innhold
- Trenerdata for klasse og profesjon
- Lokasjonstilpasning
- Kombinere trening med quest-innleveringer
- Forhindre unødvendig downtime eller unnødvendige bybesøk

### Sjekkliste
- [ ] Definere trainer-model
- [ ] Legge til nivå/klasse kompatibilitet
- [ ] Implementere lokasjonsprioritering
- [ ] Kombinere bybesøk med naturlige errands
- [ ] Dokumentere usikre trenerdata

### Akseptkriterier
- Trenerforslag er et supplement, ikke en tvangsflyt.
- Bybesøk blir anbefalt når det er naturlig, ikke automatisk.

---

## Fase 6: Polering, testing og kvalitet

Status: senere

### Mål
- Sørge for at addon er stabil og brukbar.
- Verifisere at det fungerer i WoW uten feil.

### Sjekkliste
- [ ] Tester for hver viktig logikkmodul
- [ ] Verifisere UI i spillet
- [ ] Sjekk `/reload`
- [ ] Sjekk `/console scriptErrors 1`
- [ ] Verifiser minimal funksjonalitet ved relog og zone changes
- [ ] Dokumentere hvilke deler som er verifisert og hvilke som er fortsatt estimert

### Akseptkriterier
- Prosjektet har tydelig dokumentasjon for hva som er verifisert.
- Det finnes en tydelig liste over kjente begrensninger.
- Addonet er nyttig uten å være overbygd.

---

## Prioritetsmodell

### Først
- MVP shell
- UI og spillerstatus
- fiksturer og grunnleggende anbefalinger

### Deretter
- reisen og story-cohesion
- reell questdata
- mer robuste anbefalinger

### Til slutt
- trenerlogikk
- polish
- ekstra forbedringer

---

## Neste steg

1. Fullføre manuell Fase 1-test i WoW, inkludert lukkeknapp, `/ac`, spillerstatus og lagring av vindusposisjon.
2. Legge til visning av fraksjon og rette eventuelle klientfeil.
3. Starte Fase 2 med et tydelig merket, strukturert quest-fixture og små testbare filtreringsregler.

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

Status: fullført — UI, spillerstatus, resize, wrapping, soneoppdatering, reload, `/ac` og lagring er testet i WoW

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
- [x] Vise navn, klasse, nivå, fraksjon og sone i spillerstatus
- [x] Lagre vindusposisjon i SavedVariables
- [x] Implementere resize-håndtak med størrelsesgrenser og lagring av vindusstørrelse
- [x] Bekrefte i WoW at resize endrer vindusstørrelsen
- [x] Lage lokalt deploy-skript og kopiere addon-filene til installert klientmappe
- [x] Bekrefte i WoW at vinduet vises, kan åpnes/lukkes og flyttes
- [x] Bekrefte i WoW at de to knappene viser ulike eksempeldata
- [x] Bekrefte at resize fungerer innenfor min-/maksgrensene
- [x] Bekrefte at vindusstørrelsen overlever `/reload`
- [x] Bekrefte at vindusposisjonen overlever reload og relog
- [x] Bekrefte at vindusstørrelsen overlever relog
- [x] Bekrefte at spillerstatus oppdateres etter sonebytte, også ved hearthstone
- [x] Ingen Lua-feil observert i siste in-game-test
- [x] Bekrefte at `/reload` og `/ac` fungerer

### Akseptkriterier
- Addonet lastes inn uten Lua-feil.
- Vinduet vises og er flyttbart.
- Spillerdata oppdateres korrekt.
- Addonet tåler reload og relog uten kritiske feil.

### Status og neste kontroll
- Deploy-skriptet er kjørt, og de deployede `.toc`- og Lua-filene er sammenlignet med kildefilene.
- `BackdropTemplate`-rettelsen er bekreftet indirekte i klienten ved at vinduet nå vises og kan brukes.
- Brukeren har bekreftet at vinduet vises, kan åpnes/lukkes og flyttes, at begge knappene viser ulike eksempeldata, og at resize endrer størrelsen.
- Spillerstatus inkludert fraksjon vises, og ingen feillogg ble observert i siste test.
- Tekstwrapping er bekreftet i WoW: hele felt, som `Sone: Stranglethorn Vale`, flyttes samlet mellom linjer.
- Soneoppdatering er bekreftet i WoW etter hearthstone til Orgrimmar.
- Fase 1 er verifisert i klienten; Fase 2 er neste steg.

---

## Fase 2: Fiktive quest-data og anbefalinger

Status: pågår — strukturert fiktivt quest-fixture og filtreringsmodul er implementert; in-game-verifisering gjenstår

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
- [x] Definere datastruktur med nivå, fraksjon, status, forutsetninger, story, hub, quest-item-dropstatus og valgfri questlineposisjon (`x/y`)
- [x] Lage eksplisitt fiktive eksempelquester i en egen fixture-fil
- [x] Filtrere fixtures etter nivå, fraksjon, tilgjengelighet, forutsetninger og modus/sone
- [x] Vise om fixture-item kan droppe før aksept, krever aksept eller har ukjent status
- [ ] Prioritere quests som hører til samme historie eller hub
- [x] Vise enkle, menneskeleselige begrunnelser i eksempelanbefalingene
- [x] Markere anbefalingene som eksempeldata i UI-et

Fixture-dataene er oppdiktede og ligger adskilt fra anbefalingslogikken. Filteret bruker karakterens nivå, fraksjon og sone, men queststatus og fullførte forutsetninger er ikke koblet til den virkelige questloggen. UI-et opplyser om denne begrensningen; item-dropverdiene er også bare eksempler.

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

1. Teste begge anbefalingsmodusene i WoW og kontrollere nivå-/fraksjonsfilter, at «her» bare viser aktuell sone, «gå videre» utelukker den, og item-statusmeldinger.
2. Teste scrollområdet ved liten vindusstørrelse og koordinatvisningen over minimapet, inkludert oppdatering under bevegelse og manglende posisjon i instanser.
3. Utvide fixture-filtrene med eksplisitt testbar questprogresjon når en verifisert Classic API-adapter er valgt.
4. Vurdere faktiske datakilder først etter at fixture-modellen og filtreringsreglene er validert.

---
name: azeroth-addon-development
description: Utvikle, gjennomgå, feilsøk og utvid gradvis Azeroth Companion-addonet for WoW Classic Season of Discovery. Bruk for Lua og TOC-filer, integrasjon med Classic Era API, quest-data, anbefalinger for historier og hubs, scoring av reise/tilbakevandring, trening for klasse/profesjon, UI, SavedVariables og testing i spillet.
---

# Arbeidsflyt for Azeroth Companion

Les `docs/PRODUCT.md` og `.github/copilot-instructions.md` før implementering av oppførsel. Behold spillerens kontroll: gi råd, aldri tving en rute.

## For hver oppgave
1. Identifiser den minste observerbare oppførselen og akseptkriteriene.
2. Identifiser spill-API-kall og databehov. Verifiser kompatibilitet med Classic Era/SoD; merk usikre API-er tydelig.
3. Foreslå en minimal endring i relevant lag: adapter, repository, anbefalingsmotor, lagring eller UI.
4. Implementer kun ønsket del, med defensiv håndtering av manglende data.
5. Valider ren scoring-/filtreringslogikk med fixturer når det er mulig; beskriv manuelle sjekker i spillet og kommandoer for feilrapportering.
6. Rapporter hva som fungerer, hva som bruker fixturer, og hva som fortsatt ikke er verifisert.

## Arkitektoniske grenser
- **Spillerstatusadapter:** nivå, klasse, fraksjon, sone, questlog/fullføring, kjente spells, profesjoner. Anta aldri at et manglende API-resultat betyr at en quest ikke er tilgjengelig.
- **Quest-repository:** abstrakt håndtering av quest-tilgjengelighet, forutsetninger, kjeder, oppstart, mål, innlevering, XP og lokasjonsmetadata. Hold eksterne dataformater bak en adapter.
- **Anbefalingsmotor:** pure funksjoner der det er mulig; returner scorerte kandidater sammen med strukturert begrunnelse og advarsler.
- **Reiseplanlegger:** vurder start -> mål -> innlevering -> neste quest og samling med errands. Skille mellom en engangs lang reise til et nytt eventyr og gjentatt tilbakevandring.
- **Trenerplanlegger:** vurder kommende/tilgjengelige klasse- og profesjonstrening, trenerkvalifisering og lokasjon, samt muligheter for å kombinere by-errands. Ukjente tilbud må ikke bli definitive anbefalinger.
- **UI:** et lite flyttbart vindu med `Hva bør jeg gjøre her?` og `Jeg er klar til å gå videre!`; vis 3–5 forklarbare forslag når data støtter det.
- **Lagring:** SavedVariables for vindusposisjon, innstillinger og midlertidig avviste soner.

## Regler for anbefalinger
- Prioriter sammenhengende historier, tilgjengelige quests som gir meningsfull XP og flere quests i samme hub.
- Prioriter å bli i det nåværende området til et naturlig stoppunkt, med mindre spilleren uttrykkelig ber om å flytte videre.
- Når `gå videre` er valgt, ekskluder nåværende sone fra primære forslag og tillat fjerne destinasjoner med nok nyttig innhold.
- Straf gjentatte innleveringsreiser og tilbakevandring mellom soner/hovedsteder, men ikke lang reise i seg selv.
- Foretrekk å kombinere trenerbesøk med innleveringer og andre errands; krev aldri et hovedstad besøk hvis en passende nærmere trener finnes.
- Forklar hvert forslag på enkel norsk; avslør manglende quest- eller trenerdata.
- Påstå aldri at en numerisk score er et objektivt XP/time-estimat.

## Første vertikale skive
Implementer bare når det er ønsket:
- Last inn i den faktiske SoD-klienten med et verifisert `.toc`-grensesnittnummer.
- Vis spillerens nivå, klasse, fraksjon og sone.
- Gi et flyttbart vindu og de to handlingene.
- Ranger et lite **eksplicit fiktivt fixture-datasett** og vis menneskelesbare begrunnelser.
- Lagre vindusposisjon og grunnleggende innstillinger.

Ikke integrer full quest-database, pathfinding eller trener-tabeller i første skive.

## Datakilder
Vurder Questie som mulig kilde, men verifiser lisens, SoD-kompatibilitet, tilgjengelige felter og stabilitet før integrasjon. Foretrekk en utskiftbar repository-adapter. Scrape aldri Wowhead eller presentér gjetne NPC-er, quester, lokasjoner eller spell-data som verifiserte fakta.

## Testsjekkliste
- Ny innlogging og `/reload` fungerer begge to.
- `/console scriptErrors 1` viser ingen Lua-feil under grunnleggende handlinger.
- Manglende API-/datafelter feiler på en trygg måte.
- De to anbefalingsmodusene oppfører seg forskjellig.
- Nåværende sone blir ikke foreslått på nytt som primært mål i `gå videre`-modus.
- Lang énveis reise straffes ikke som gjentatt tilbakevandring.
- Lagring overlever reload og relog.
- Anbefalinger viser begrunnelser og merker tydelig eksempeldata.

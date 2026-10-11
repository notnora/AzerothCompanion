# Azeroth Companion — produktspesifikasjon

## Visjon
En hjelpsom reiseassistent for World of Warcraft Classic: Season of Discovery. Anbefal meningsfulle, nivåpassende eventyr med historier og XP, ikke speedleveling eller stive XP/time-ruter. Spillerne bestemmer hva de vil gjøre.

## Kjerneopplevelser

### Hva bør jeg gjøre her?
Anbefal tilgjengelige quests, inkludert quests som ikke er akseptert ennå, i den nåværende sonen. Grupper dem i historie-kjeder og quest-hubs. Prioriter sammenhengende narrativer, håndterlig vanskelighetsgrad, meningsfull XP og mål som kan fullføres sammen. Forklar hvorfor hvert forslag passer. Unngå allerede fullførte quests eller quests låst av forutsetninger.

### Jeg er klar til å gå videre!
Tilby 3–5 nye soner eller hubs med nok passende innhold til å rettferdiggjøre reisen. En lang engangsreise til et nytt område er greit; prioriter ikke nærmeste sone som standard. Ekskluder den nåværende sonen fra primære resultater. Støtt midlertidig avvisning av forslag og ikke mas på spilleren for å returnere til en uønsket sone.

### Eventyrsammenheng
Vurder hele reisen: questgiver -> mål -> innlevering -> oppfølgingsquest. Gjentatte reiser mellom The Barrens og Orgrimmar bare for isolerte innleveringer skal score dårlig. Naturlig progression fra hub til hub skal score godt. Hvis en avstandsmessig innlevering kan kombineres med andre errands, reduser straffen. Advar om reise-tunge kjeder uten å forby dem.

### Smarte bybesøk
Forutse nyttig trening for klasse og profesjon ved å bruke karakternivå, klasse, kjente evner, profesjonsskill/rang, verifiserte trenertilbud og trenerlokasjoner. Foreslå trening når det passer naturlig etter en quest-kjede eller før du drar til en ny sone. Kombiner klassetrening, profesjonstrening og quest-innleveringer når det er praktisk. Foretrekk en passende nær trener fremfor et hovedstad. Avbryt ikke eventyr automatisk bare fordi spilleren har levelt opp.

## Filosofi for anbefalinger
Kvalitativ prioritet: (1) sammenhengende historier, (2) minimal meningsløs tilbakevandring, (3) nivåpassende og XP, (4) tetthet av tilgjengelige quests, (5) naturlig hub-progresjon, (6) nyttige kombinerte errands. Langdistanse er ikke i seg selv dårlig. Anbefalinger må være transparente og overstyrbare.

## Datakrav
Quest-ID, påkrevd/anbefalt nivå, fraksjon, forutsetninger, fullføringsstatus, kjedekoblinger, oppstartsmål-/innleveringslokasjoner, historiegruppering, hub-gruppering og XP der det er pålitelig. Trenerdata trenger klassen/profesjonstilpasning, tilbudt trening, forutsetninger og lokasjon. Ukjente data må representeres eksplisitt; aldri gjett.

For quest-items skal data kunne si om itemet kan droppe før questen aksepteres, først etter aksept, eller om dette er ukjent. Ikke oppgi drop-rate eller behandle fixtureverdier som spillfakta uten en verifisert kilde.

## Milepæler
1. Addon-shell: flyttbart vindu, spillerstatus, to handlinger, eksempelanbefalinger, SavedVariables.
2. Integrasjon av faktisk quest-repository og filtrering av tilgjengelighet.
3. Story/hub-gruppering og reise-scoring for eventyrssammenheng.
4. Trenerdata og kombinerte bybesøksforslag.
5. Valgfrie forbedringer: informasjon om quest-item drop-rate, bag-relatert kontekst, forbedrede kart.

## Utenfor MVP
Speedleveling, automatisert gameplay, live HTTP-tilgang, komplett routing, omfattende trenerdata, full ingesting av quest-database og automatisk scraping av eksterne nettsider.

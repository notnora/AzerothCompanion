# Azeroth Companion — Copilot-instruksjoner

## Prosjekt
Bygg en liten, forklarbar quest-guide for World of Warcraft Classic: Season of Discovery (Classic Era-klienten). Dette er **ikke** en speedleveling- eller XP/time-optimering. Prioriter sammenhengende historier, quests som passer nivået, nærliggende quest-hubs og unngå meningsløs tilbakevandring. Lange reiser til verdifulle nye soner er velkomne.

Les `docs/PRODUCT.md` før du endrer anbefalingsoppførselen.

## Ingeniørregler
- Ta mål av den faktisk installerede Classic Era/SoD-API-en, ikke Retail. Verifiser API-tilgjengelighet; marker usikkerhet i stedet for å oppfinne funksjoner, interface-numre, quest-data eller trenerdata.
- Bruk Lua og `.toc`-filer. Hold moduler små og løst koblet. Foretrekk event-drevet oppdatering og SavedVariables for lagring.
- Skil mellom WoW-API-adaptere, quest-/trenerdata, anbefalingslogikk og UI. Hold scoringslogikken testbar utenfor WoW der det er praktisk.
- Behandle tredjeparts quest-datasett og addon-interne detaljer som valgfrie og potensielt ustabile. Verifiser lisenser og kompatibilitet før gjenbruk. Scrape aldri Wowhead eller anta en støttet offentlig API.
- Respekter sikre UI-/kamprestriksjoner. Automatiser ikke gameplay eller utfør beskyttede handlinger.
- Unngå unødvendige biblioteker, spekulativ abstraksjon, store omskrivinger og kontinuerlig polling.
- Skil tydelig mellom ekte spilldata og eksempel-fixturer.

## Samarbeid
Utvikleren kjenner Java, Spring Boot, React og TypeScript, men er ny i WoW Lua. Forklar ukjente Lua/WoW-mønstre kort ved hjelp av sammenligninger når det er nyttig; hopp over generiske programmeringslekser.

Arbeid i små, testbare vertikale skiver. Før større endringer, beskriv omfang, antagelser, filer som skal endres og hvordan det skal verifiseres i spillet. Implementer ikke fremtidige milepæler med mindre det er ønsket. Ta med `/reload`, `/console scriptErrors 1` og relevante manuelle sjekker når du beskriver tester. Hvis en API eller datasett ikke kan verifiseres, gjør begrensningen tydelig.

For addon-implementasjon, quest-anbefalinger, reise-scoring, trenerbesøk eller WoW-API-integrasjon, bruk `azeroth-addon-development`-skillen når den er tilgjengelig.

## Sikkerhet og pålitelighet
- Bruk kun offisielle, velkjente og godt vedlikeholdte pakker, biblioteker og verktøy fra pålitelige kilder.
- Unngå uverifiserte, malte, forkastede eller anonymt publiserte avhengigheter, spesielt fra ukjente GitHub-repoer, forumtråder eller “quick-fix”-scripts uten tydelig opphav og legitimitet.
- Verifiser at eksterne avhengigheter er offisielle, oppdatert, godt vedlikeholdt og passende for prosjektets sammenheng før de blir brukt.
- Ikke installere eller importere pakker som har uklare lisensforhold, manglende dokumentasjon, lite aktivitet eller bekymringsfull historie.
- Behandle all ekstern kode som potentielt usikker frem til den er verifisert og vurdert.
- Hold utviklingsmiljøet trygt ved å bruke kjente, offisielle kanaler og unngå å kjøre scripts fra ukjente kilder.
- Del ikke hemmelige data, API-nøkler eller personlige tokens i prompt, repo, logs eller kode.
- Hvis en kilde eller pakke ikke kan verifiseres som trygg og pålitelig, skal den avvises eller eksplisitt markeres som usikker.
- Generelle sikkerhetsprinsipper: minst mulig skjermet tilgang, ingen automatisk kjøring av fremmede scripts, liten blast radius, tydelig validering av innputt og håndtering av feil uten å gjemme alvorlige problemer.
- Dokumentér klare grenser for hva som er “verifisert” versus “ukjent”, og ikke antak at usikre data er pålitelige.

## Gjenbrukbarhet og vedlikehold
- Prioriter gjenbrukbarhet så mye som mulig: unngå hardkodede strenger, tall og verdier som oppstår flere ganger i koden.
- Definer statiske konstanter for ofte brukte strenger, tekstnøkler, tekstlabels, event-navn, defaultverdier og UI-konstanter.
- Sørg for at samme verdi brukes fra én definisjon, ikke kopiert flere steder.
- Centraliser standardverdier i én plass for å gjøre endringer enklere og mindre risikabelt.
- Bruk meningsfulle, konsistente konstanter og navn som gjør koden lettere å forstå og vedlikeholde.
- Unngå “magic strings” og “magic numbers” når det er praktisk å definere dem som konstanter.
- Når en verdi brukes i flere funksjoner eller moduler, vurder om den bør være en konstant, en hjelpefunksjon eller en liten resirkulérbar modul.
- Hold kodeen liten, tydelig og gjenbrukbar uten å over-optimere eller lage unødvendige abstraksjoner.

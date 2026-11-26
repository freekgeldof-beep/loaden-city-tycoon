# Loaden City Tycoon (Roblox)

Begin met een klein perceel en bouw het uit tot een metropool.

## Hoe het werkt

- Je start met 100 munten en een perceel van 6x6 vakjes.
- Kies een gebouw onderin, beweeg de muis over je perceel en klik om te bouwen.
  `Q` of `X` annuleert.
- Elk gebouw levert elke seconde munten op. Huizen en flats brengen inwoners.
- Met meer inwoners stijgt je stad: Gehucht → Dorp → Stad → Grote stad → Metropool.
  Elk niveau ontgrendelt nieuwe gebouwen.
- Met "Land vergroten" maak je je perceel groter (tot 30x30 vakjes).
- Voortgang wordt automatisch opgeslagen (DataStore).

## Starten

1. Installeer [Rojo](https://rojo.space) (VS Code-extensie of CLI) en Roblox Studio.
2. Maak in Studio een lege Baseplate-place. Verwijder de standaard Baseplate; het script maakt zelf grond.
3. Voer in deze map `rojo serve` uit en klik in Studio op Connect in de Rojo-plugin.
4. Druk op Play.

Voor DataStore-opslag in Studio: Game Settings → Security → "Enable Studio Access to API Services".
Zonder die instelling werkt het spel nog steeds, maar zonder opslaan.

## Structuur

- `src/shared/Config.luau`: gebouwen, niveaus, prijzen (hier balanceer je).
- `src/server/Main.server.luau`: wereld, economie, plaatsen, opslaan.
- `src/client/Client.client.luau`: HUD en bouwmenu.

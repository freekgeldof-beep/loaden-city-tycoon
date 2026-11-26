# Loaden City Tycoon (Roblox)

Begin met een klein perceel en bouw het uit tot een metropool.

## Hoe het werkt

- Je start met 100 munten en één stuk land (6x6 vakjes) in een grote open wereld.
- Kies een gebouw onderin, beweeg de muis over je land en klik om te bouwen. `Q` of `X` annuleert.
- Elk gebouw levert elke seconde munten op. Huizen en flats brengen inwoners.
- Met meer inwoners stijgt je stad: Gehucht, Dorp, Stad, Grote stad, Metropool. Elk niveau ontgrendelt nieuwe gebouwen (20 soorten, van kiosk tot pretpark).
- Met "Land kopen" koop je een stuk land naast je eigen stad, in elke richting. Hoe meer land je hebt, hoe duurder het volgende stuk.
- Je loopt vrij rond in de wereld en ziet de steden van andere spelers.
- Voortgang wordt automatisch opgeslagen (DataStore).

## Starten (makkelijkste manier, zonder Rojo)

1. Open Roblox Studio en maak een nieuwe **Baseplate**-place.
2. Open het bestand `installeer.lua` op GitHub, klik op "Raw" en kopieer alles (Ctrl+A, Ctrl+C).
3. Zet in Studio de Command Bar aan: tabblad **View** > **Command Bar**.
4. Plak de tekst in de Command Bar en druk op **Enter**.
5. Druk op **Play**.

Na elke update van de code plak je `installeer.lua` opnieuw; de oude scripts worden vervangen.

Opslaan van voortgang: Game Settings > Security > "Enable Studio Access to API Services".
Zonder die instelling werkt het spel nog steeds, maar zonder opslaan.

## Starten met Rojo (voor gevorderden)

Voer in deze map `rojo serve` uit en klik in Studio op Connect in de Rojo-plugin.

## Structuur

- `src/shared/Config.luau`: gebouwen, niveaus, prijzen (hier balanceer je).
- `src/server/Main.server.luau`: wereld, economie, plaatsen, opslaan.
- `src/client/Client.client.luau`: HUD en bouwmenu.

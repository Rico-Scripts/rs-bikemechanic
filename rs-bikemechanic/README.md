# RS Bike Mechanic

Professionele standalone motorwerkplaats voor FiveM, gebouwd door **Rico Scripts**. De resource combineert onderhoud, performance tuning, personeel, duty, productverkoop, logging en een moderne werkplaatstablet in één systeem.

## Features

- Volledig standalone medewerkerssysteem met eigen database
- Zeven configureerbare rangen en rechten
- Medewerkers aannemen, promoveren, degraderen en ontslaan
- In- en uitdienst systeem
- Onderhoud en reparaties met server-side validatie
- Performance upgrades voor motoren
- Turbo, ECU, sportuitlaat, race-remmen, transmissie en sportvering
- Antilag, launch control en Stage 2 software
- Eigen producten en ox_inventory items
- Unieke inventory-afbeeldingen per onderdeel
- Werkhistorie per voertuig
- Koppeling met `rs-dyno`
- Liberty Walk / moto workshop configuratie
- Discord webhook logging voor personeel, producten, services en security
- Moderne donkerblauwe Bike Mechanic NUI

## Dependencies

- `ox_lib`
- `ox_target`
- `ox_inventory`
- `oxmysql`

Start deze resources vóór `rs-bikemechanic`.

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure rs-bikemechanic
```

## Installatie

1. Plaats de map `rs-bikemechanic` in je FiveM resources-map.
2. Importeer `sql/install.sql` in de database.
3. Voeg de items uit `ox_inventory_items.lua` toe aan de itemdefinities van ox_inventory.
4. Kopieer de bestanden uit `inventory_images` naar `ox_inventory/web/images`.
5. Controleer `config.lua` en pas locaties, rangen, prijzen en services aan.
6. Configureer indien gewenst de Discord webhooks.
7. Restart de resource.

```text
restart rs-bikemechanic
```

## Inventory items

| Item | Omschrijving |
| --- | --- |
| `rs_bikemechanic_tablet` | Werkplaatstablet |
| `rs_moto_engine_oil` | Motorolie |
| `rs_moto_spark_plugs` | Bougies |
| `rs_moto_brake_pads` | Remblokken |
| `rs_moto_chain` | Motorketting |
| `rs_moto_tire_set` | Motorbandenset |
| `rs_moto_battery` | Motoraccu |
| `rs_moto_clutch_cable` | Koppelingskabel |
| `rs_moto_turbo_kit` | Turbo kit |
| `rs_moto_ecu` | Race ECU |
| `rs_moto_sport_exhaust` | Sportuitlaat |
| `rs_moto_race_brakes` | Race-remmenset |
| `rs_moto_race_transmission` | Race-transmissie |
| `rs_moto_sport_suspension` | Sportvering |
| `rs_moto_antilag_software` | Antilag software |
| `rs_moto_launch_control` | Launch control |
| `rs_moto_stage2_software` | Stage 2 software |

## Eerste eigenaar instellen

```text
rsbikeowner SERVER_ID
```

Admins die dit commando in-game mogen gebruiken hebben deze ACE nodig:

```cfg
add_ace group.admin rs.bikemechanic.admin allow
```

## Webhook logging

Algemene webhook:

```cfg
set rs_bikemechanic_webhook_default "DISCORD_WEBHOOK_URL"
```

Gebruik aparte logging waar geconfigureerd voor medewerkers, producten, services en security. Zet webhook-URLs nooit in publieke clientbestanden.

## Werkplaatstablet

De NUI bevat:

- **Service & reparatie** — onderhoud en herstelwerkzaamheden
- **Performance** — tuning en performance upgrades
- **Onderdelen shop** — onderdelen kopen vanuit de werkplaats
- **Werkhistorie** — eerdere werkzaamheden per voertuig
- **Medewerkers** — personeel beheren voor bevoegde rangen

De tablet toont daarnaast kenteken, motorconditie, carrosserieconditie en dienststatus.

## Configuratie

Controleer in `config.lua` onder andere:

- werkplaatslocaties
- target-zones
- rangen en permissies
- producten en prijzen
- services en benodigde items
- tuningwaarden
- `rs-dyno` integratie
- webhookinstellingen

## Troubleshooting

### Inventory-afbeeldingen ontbreken

Controleer of de bestanden uit `inventory_images` in `ox_inventory/web/images` staan. De bestandsnaam moet exact overeenkomen met `client.image` in `ox_inventory_items.lua`.

### Tablet opent niet

Controleer of `ox_lib`, `ox_target`, `ox_inventory` en `oxmysql` gestart zijn en bekijk F8/serverconsole op errors.

### Medewerkers-tab ontbreekt

Deze tab wordt alleen getoond wanneer de huidige rang de juiste permissie heeft.

### Databasefout

Controleer of `sql/install.sql` volledig geïmporteerd is en of de MySQL connection string werkt.

### Dyno-koppeling werkt niet

Controleer of `rs-dyno` gestart is voordat functies worden gebruikt die daarvan afhankelijk zijn.

## Resource structuur

```text
rs-bikemechanic/
├── client/
├── inventory_images/
├── nui/
│   ├── index.html
│   ├── style.css
│   ├── app.js
│   └── sounds/
├── server/
├── sql/
├── config.lua
├── fxmanifest.lua
└── ox_inventory_items.lua
```

## Security

Belangrijke acties worden server-side gecontroleerd. Vertrouw nooit uitsluitend op NUI- of clientdata voor geld, items, rangen of voertuigupgrades.

## Credits

**Rico Scripts** — FiveM development, Bike Mechanic en het RS ecosystem.

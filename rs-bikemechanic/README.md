# rs-bikemechanic

Standalone motorwerkplaats voor FiveM met `ox_lib`, `ox_target`, `ox_inventory` en `oxmysql`.

Functies:

- eigen medewerkersdatabase zonder framework;
- zeven configureerbare rangen en rechten;
- aannemen, rang wijzigen en ontslaan via de tablet;
- dienststatus;
- eigen onderdelen en inventory-afbeeldingen;
- server-side gecontroleerde reparaties en upgrades;
- afzonderlijke Discord-logs voor personeel, producten, services en security.

## Installatie

Importeer `sql/install.sql`, voeg `ox_inventory_items.lua` toe aan de items van ox_inventory en kopieer de SVG-bestanden naar `ox_inventory/web/images`. Stel daarna de webhook-convars in in `server.cfg`. Gebruik `set rs_bikemechanic_webhook_default "URL"` als algemene webhook.

Deze versie is gekoppeld aan de Liberty Walk werkplaats en `rs-dyno`. Stel de eerste eigenaar vanuit de serverconsole in:

```text
rsbikeowner SERVER_ID
```

Geef admins die het commando in-game mogen gebruiken deze ACE:

```cfg
add_ace group.admin rs.bikemechanic.admin allow
```

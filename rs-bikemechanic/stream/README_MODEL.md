# RS Moto Lift - Blender / CodeWalker model specification

Deze map is voorbereid voor de uiteindelijke lore-friendly `rs_moto_lift` FiveM prop.

## Bestandsnamen

Gebruik exact:

- `rs_moto_lift.ydr`
- `rs_moto_lift.ytyp`
- optioneel `rs_moto_lift.ytd`

De scriptconfig gebruikt al:

```lua
model = 'rs_moto_lift'
```

Zodra de prop in `stream/` staat hoeft de Lua-code dus niet meer gewijzigd te worden.

## Aanbevolen afmetingen

- totale lengte: circa **2.20 m**
- platformbreedte: circa **0.70 m**
- lage platformhoogte: circa **0.18 m**
- maximale werkhoogte: circa **1.10 m**
- script raise offset: **0.92 m**

De 0.92 m beweging is het verschil tussen de lage en hoge stand.

## Ontwerp

Lore-friendly RS-uitvoering, zonder echte merklogo's:

- zwart/donker gepoedercoat staal
- blauwe RS-accenten
- diamond-plate / antislip platform
- voorwielklem
- afneembare of vaste oprijplaat
- schaarmechanisme
- hydraulische cilinder
- stevige vloerpoten
- subtiele `RS` / `MOTO LIFT` decals

## Origin / pivot

Zet de object origin:

- horizontaal exact midden van de lift
- op vloerniveau van de **lage** stand
- X/Y gecentreerd
- Z = onderzijde basisframe

De scriptlaag verplaatst het complete object verticaal. Een correcte origin voorkomt dat de lift in de grond zakt of zweeft.

## Oriëntatie

Aanbevolen Blender oriëntatie:

- +Y = voorkant / oprijrichting
- +Z = omhoog
- origin in het midden van het basisframe

Controleer na export in CodeWalker dat GTA heading 0 dezelfde verwachte voorzijde gebruikt. Indien nodig kan `vehicleHeadingOffset` in `lift_config.lua` worden aangepast.

## Collision

Maak een eenvoudige maar solide collision mesh. Vermijd een collision die alle hydraulische details exact volgt; dit is onnodig zwaar.

Aanbevolen collisiondelen:

1. basisframe / vloerpoten
2. platform als eenvoudige box
3. oprijplaat
4. wielklem als kleine boxen

Gebruik geen extreem hoge poly collision. De motor moet stabiel op het platform kunnen staan zonder haken of stuiteren.

## LOD

Voor één werkplaatsprop is dit voldoende:

- LOD0: volledig model
- LOD1: vereenvoudigd frame/platform
- verdere LODs optioneel

Houd textures bij voorkeur op 1024x1024 of 2048x2048. Gebruik een atlas indien mogelijk.

## Materialen

Aanbevolen:

- `rs_lift_metal_black`
- `rs_lift_diamondplate`
- `rs_lift_blue`
- `rs_lift_hydraulic`
- `rs_lift_decals`

Geen echte merken gebruiken.

## YTYP

Maak een archetype `rs_moto_lift` met correcte bounding box en bounding sphere. Na wijzigingen altijd extents opnieuw berekenen.

## Testvolgorde

1. exporteer model vanuit Blender/Sollumz
2. controleer `.ydr` in CodeWalker
3. maak/controleer `.ytyp`
4. plaats bestanden in `rs-bikemechanic/stream/`
5. restart `rs-bikemechanic`
6. controleer lage stand
7. zet motor op lift
8. test omhoog/omlaag
9. controleer collision en wielpositie
10. pas eventueel `vehicleOffsetZ` en `vehicleHeadingOffset` aan in `lift_config.lua`

## Huidige fallback

Zolang `rs_moto_lift` nog niet bestaat gebruikt de resource tijdelijk:

```lua
fallbackModel = 'prop_tool_bench02_ld'
```

Dit is alleen bedoeld om interactie, duty-permissies, synchronisatie en hoogtebeweging alvast te testen. Zodra het echte model wordt gestreamd kiest de resource automatisch `rs_moto_lift`.

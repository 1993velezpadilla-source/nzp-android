# COD Mobile Universal Attachment Baseline — Historical 2020/2021

Source type: community measurement / GPLv3 helper derived from early Gunsmith research.

**Do not treat these as current 2026 balance values.**
They are preserved because they reveal the attachment trade-off grammar and provide test vectors for our modifier engine.

Sign convention in this document:
- negative recoil/spread/time = reduction/improvement
- positive range/move speed = increase
- positive ADS time/spread/recoil = penalty unless otherwise noted

## Muzzles

### Tactical Suppressor
- ADS time: +5
- ADS movement speed: -5

### OWC Light Suppressor
- range: -20

### OWC Light Compensator
- vertical recoil: -11.1
- horizontal recoil: -7
- ADS time: +6
- ADS spread: +8

### MIP Light Flash Guard
- ADS spread: -9.2
- hip spread: -7.7
- ADS time: +5

### RTC Light Muzzle Brake
- horizontal recoil: -10.5
- vertical recoil: -7.8
- ADS time: +5
- ADS spread: +8

### Monolithic Suppressor
- range: +25
- ADS spread: +7
- ADS time: +7
- ADS movement speed: -5

## Barrels

### MIP Light
- ADS time: -10
- ADS spread: +8

### MIP Light Barrel (Short)
- ADS time: -12
- movement speed: +3
- ADS spread: +3
- vertical recoil: +11.2

### OWC Marksman
- ADS spread: -8
- range: +30
- horizontal recoil: -16.5
- vertical recoil modifier recorded in source as 5.9 without a clear sign in the mirrored snippet; preserve as unresolved until original dataset is verified

## Stocks

### YKM Light Stock
- ADS movement speed: +25
- ADS spread: +6.7

### YKM Combat Stock
- ADS time: -8
- ADS spread: +6.5
- flinch: +6
- vertical recoil: +3.9

### MIP Strike Stock
- ADS spread: -7.5
- flinch: -10
- horizontal recoil: -8
- ADS time: +12
- ADS movement speed: -15

### No Stock
- ADS time: -13
- movement speed: +3
- ADS spread: +9.6
- flinch: +8
- vertical recoil: +12.9

## Perks

### Enhanced Bolt
- fire interval: -13

### Sleight of Hand
- reload time: -15

## Lasers

### OWC Laser - Tactical
- ADS time: -9
- ADS spread: -9.4

### RTC Laser 1mW
- hip spread: -14.5

### MIP Laser 5mW
- hip spread: -13.5
- sprint/fire delay: -25

## Underbarrels

### Strike Foregrip
- vertical recoil: -8.3
- ADS spread: -3.8
- movement speed: -1

### Merc Foregrip
- vertical recoil: -6.9
- hip spread: -3
- ADS movement speed: -10
- ADS time: +10

### Operator Foregrip
- vertical recoil: -13.9
- ADS time: +8

### Ranger Foregrip
- vertical recoil: -13.8
- ADS spread: -12.9
- ADS movement speed: -10
- ADS time: +15

### Tactical Foregrip A
- ADS spread: -10
- movement speed: -1

## Magazines

### Fast Reload
- reload time: -15

### Extended Mag A
- movement speed: -10
- reload time: +5

## Rear grips

### Stippled Grip Tape
- ADS time: -5
- sprint/fire delay: -15
- ADS spread: +12

### Granulated Grip Tape
- ADS spread: -11.9
- ADS movement speed: -4

## Why save this old dataset?

It provides clear examples of the core Gunsmith design:

`benefit A + benefit B + penalty C + penalty D`

For example:
No Stock makes a weapon faster to aim and move with, but increases recoil/spread/flinch.

That is exactly the build-composition behavior our original weapon system should support.

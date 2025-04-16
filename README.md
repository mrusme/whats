# whats

[![Static 
Badge](https://img.shields.io/badge/Join_on_Matrix-green?style=for-the-badge&logo=element&logoColor=%23ffffff&label=Chat&labelColor=%23333&color=%230DBD8B&link=https%3A%2F%2Fmatrix.to%2F%23%2F%2521PHlbgZTdrhjkCJrfVY%253Amatrix.org)](https://matrix.to/#/%21PHlbgZTdrhjkCJrfVY%3Amatrix.org)

Command line tool for getting answers to everyday questions like:

```sh
whats 2 meters in feet
```

... or more importantly:

```sh
whats 1.21 gigawatts in watts
```

This tool is in its **very** early stages and right now primarily a _finger
exercise_ for me while getting into Zig.

## TODO

- [ ] Percentage calculation:
  - [ ] `whats 10 of 100` -> `10%`
  - [ ] `whats 200 of 100` -> `200%`
  - [ ] `whats 50% of 100` -> `50`
  - [ ] `whats 80 to 100` -> `+25%`
  - [ ] `whats 100 to 50` -> `-50%`
- [ ] Add lazy loading of data based on command (e.g. if no money required don't
      load)

## `whats --help`

```sh
Usage: whats [OPTION]... NUMBER [UNIT] [OPERATOR] [NUMBER] [UNIT]
A command for basic convertion and calculation.

  -h, --help       display this help and exit
  -v, --version    output version information and exit

Units:
  Symbol  Name
--------------------------------------------------------------------------------
MONEY:
  EUR     EUR
  RON     RON
  PLN     PLN
  USD     USD
  ILS     ILS
  KRW     KRW
  MYR     MYR
  MXN     MXN
  NOK     NOK
  JPY     JPY
  ISK     ISK
  SGD     SGD
  BGN     BGN
  DKK     DKK
  TRY     TRY
  ZAR     ZAR
  CZK     CZK
  CNY     CNY
  BRL     BRL
  PHP     PHP
  NZD     NZD
  HKD     HKD
  INR     INR
  AUD     AUD
  IDR     IDR
  GBP     GBP
  SEK     SEK
  THB     THB
  CHF     CHF
  CAD     CAD
  HUF     HUF

DATA:
  b       bit
  Kb      kilobit
  Mb      megabit
  Gb      gigabit
  Tb      terabit
  Pb      petabit
  Eb      exabit
  Zb      zettabit
  Yb      yottabit
  B       byte
  KB      kilobyte
  MB      megabyte
  GB      gigabyte
  TB      terabyte
  PB      petabyte
  EB      exabyte
  ZB      zettabyte
  YB      yottabyte
  KiB     kibibyte
  MiB     mebibyte
  GiB     gibibyte
  TiB     tebibyte
  PiB     pebibyte
  EiB     exbibyte
  ZiB     zebibyte
  YiB     yobibyte

ENERGY:
  J       joule
  qJ      quectojoule
  rJ      rontojoule
  yJ      yoctojoule
  zJ      zeptojoule
  aJ      attojoule
  fJ      femtojoule
  pJ      picojoule
  nJ      nanojoule
  μJ      microjoule
  mJ      millijoule
  cJ      centijoule
  dJ      decijoule
  daJ     decajoule
  hJ      hectojoule
  kJ      kilojoule
  MJ      megajoule
  GJ      gigajoule
  TJ      terajoule
  PJ      petajoule
  EJ      exajoule
  ZJ      zettajoule
  YJ      yottajoule
  RJ      ronnajoule
  QJ      quettajoule
  Wh      watthour
  kWh     kilowatthour
  MWh     megawatthour
  GWh     gigawatthour
  TWh     terawatthour
  PWh     petawatthour
  eV      electronvolt
  cal     calorie

LENGTH:
  m       meter
  am      attometer
  fm      femtometer
  pm      picometer
  nm      nanometer
  µm      micrometer
  mm      millimeter
  cm      centimeter
  dm      decimeter
  dam     decameter
  hm      hectometer
  km      kilometer
  Mm      megameter
  Gm      gigameter
  Tm      terameter
  Pm      petameter
  Em      exameter
  Å       angstrom
  in      inch
  ft      foot
  yd      yard
  mi      mile
  nmi     nauticalmile
  lea     league
  fur     furlong

MASS:
  g       gram
  qg      quectogram
  rg      rontogram
  yg      yoctogram
  zg      zeptogram
  ag      attogram
  fg      femtogram
  pg      picogram
  ng      nanogram
  μg      microgram
  mg      milligram
  cg      centigram
  dg      decigram
  dag     decagram
  hg      hectogram
  kg      kilogram
  Mg      megagram
  Gg      gigagram
  Tg      teragram
  Pg      petagram
  Eg      exagram
  Zg      zettagram
  Yg      yottagram
  Rg      ronnagram
  Qg      quettagram
  gr      grain
  dr      drachm
  oz      ounce
  lb      pound
  st      stone
  t       ton
  ___     slug

POWER:
  W       watt
  qW      quectowatt
  rW      rontowatt
  yW      yoctowatt
  zW      zeptowatt
  aW      attowatt
  fW      femtowatt
  pW      picowatt
  nW      nanowatt
  μW      microwatt
  mW      milliwatt
  cW      centiwatt
  dW      deciwatt
  daW     decawatt
  hW      hectowatt
  kW      kilowatt
  MW      megawatt
  GW      gigawatt
  TW      terawatt
  PW      petawatt
  EW      exawatt
  ZW      zettawatt
  YW      yottawatt
  RW      ronnawatt
  QW      quettawatt

PRESSURE:
  Pa      pascal
  qPa     quectopascal
  rPa     rontopascal
  yPa     yoctopascal
  zPa     zeptopascal
  aPa     attopascal
  fPa     femtopascal
  pPa     picopascal
  nPa     nanopascal
  μPa     micropascal
  mPa     millipascal
  cPa     centipascal
  dPa     decipascal
  daPa    decapascal
  hPa     hectopascal
  kPa     kilopascal
  MPa     megapascal
  GPa     gigapascal
  TPa     terapascal
  PPa     petapascal
  EPa     exapascal
  ZPa     zettapascal
  YPa     yottapascal
  RPa     ronnapascal
  QPa     quettapascal
  mbar    millibar
  cbar    centibar
  dbar    decibar
  bar     bar
  kbar    kilobar
  Mbar    megabar
  Gbar    gigabar
  at      technicalatmosphere
  atm     standardatmosphere
  Ba      barye
  inH20   inchofwatercolumn
  mmH20   meterofwatercolumn
  inHg    inchofmercury
  mmHg    meterofmercury
  N/m²    newtonpersquaremeter
  psi     poundforcepersquareinch
  Torr    torr

TEMPERATURE:
  C       celsius
  F       fahrenheit
  K       kelvin

TIME:
  s       second
  qs      quectosecond
  rs      rontosecond
  ys      yoctosecond
  zs      zeptosecond
  as      attosecond
  fs      femtosecond
  ps      picosecond
  ns      nanosecond
  μs      microsecond
  ms      millisecond
  cs      centisecond
  ds      decisecond
  das     decasecond
  hs      hectosecond
  ks      kilosecond
  Ms      megasecond
  Gs      gigasecond
  Ts      terasecond
  Ps      petasecond
  Es      exasecond
  Zs      zettasecond
  Ys      yottasecond
  Rs      ronnasecond
  Qs      quettasecond
  min     minute
  hr      hour
  d       day
  ___     month
  yr      year
  ___     decade
  ___     century
  ___     millennium
  𝑡ₚ      plancktime
  ___     fortnight
  ___     score

VOLUME:
  L       liter
  qL      quectoliter
  rL      rontoliter
  yL      yoctoliter
  zL      zeptoliter
  aL      attoliter
  fL      femtoliter
  pL      picoliter
  nL      nanoliter
  μL      microliter
  mL      milliliter
  cL      centiliter
  dL      deciliter
  daL     decaliter
  hL      hectoliter
  kL      kiloliter
  ML      megaliter
  GL      gigaliter
  TL      teraliter
  PL      petaliter
  EL      exaliter
  ZL      zettaliter
  YL      yottaliter
  RL      ronnaliter
  QL      quettaliter
  min     minim
  qt      quart
  pt      pint
  gal     gallon
  floz    fluidounce
  fldr    usfluiddram
  tsp     teaspoon
  tbsp    tablespoon
  uspt    uspint
  usqt    usquart
  pot     uspottle
  usgal   usgallon
  usfloz  usfluidounce
  c       uscup
  jig     usshot
  gi      usgill
  bbl     barrel
  ___     oilbarrel
  ___     hogshead

CALCULATION:
  %       percent
--------------------------------------------------------------------------------
Note:
  Symbols are case-sensitive, names are not.

Operators:
  in: Conversion, e.g. 2m in feet
  to: Conversion or calculation, e.g. 2m to feet, 10 to 20
  of: Calculation, e.g. 20% of 100, 20 of 100

The operator is optional when units are present:
  whats 2 m ft
  whats 10% 100

Examples:
  whats 2 meters in feet
  whats 1.21 gigawatts in watts
  whats 8 kg in grams
  whats 1024 KiB in MiB

Spaces are optional:
  whats 2m ft

Report bugs at: https://github.com/mrusme/whats/issues
Home page: http://xn--gckvb8fzb.com/projects/whats/
```

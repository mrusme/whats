# whats

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

- [ ] Temperature conversion
  - [ ] Celsius <-> Fahrenheit
  - [ ] Celsius <-> Kelvin
  - [ ] Kelvin <-> Fahrenheit
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
Usage: whats [OPTION]... NUMBER UNIT [in|of] NUMBER UNIT
A command for basic convertion and calculation.

  -h, --help       display this help and exit
  -v, --version    output version information and exit

Units:
  Symbol  Name                    Category
--------------------------------------------------------------------------------
  b       bit                     data
  Kb      kilobit                 data
  Mb      megabit                 data
  Gb      gigabit                 data
  Tb      terabit                 data
  Pb      petabit                 data
  Eb      exabit                  data
  Zb      zettabit                data
  Yb      yottabit                data
  B       byte                    data
  KB      kilobyte                data
  MB      megabyte                data
  GB      gigabyte                data
  TB      terabyte                data
  PB      petabyte                data
  EB      exabyte                 data
  ZB      zettabyte               data
  YB      yottabyte               data
  KiB     kibibyte                data
  MiB     mebibyte                data
  GiB     gibibyte                data
  TiB     tebibyte                data
  PiB     pebibyte                data
  EiB     exbibyte                data
  ZiB     zebibyte                data
  YiB     yobibyte                data
  J       joule                   energy
  qJ      quectojoule             energy
  rJ      rontojoule              energy
  yJ      yoctojoule              energy
  zJ      zeptojoule              energy
  aJ      attojoule               energy
  fJ      femtojoule              energy
  pJ      picojoule               energy
  nJ      nanojoule               energy
  μJ      microjoule              energy
  mJ      millijoule              energy
  cJ      centijoule              energy
  dJ      decijoule               energy
  daJ     decajoule               energy
  hJ      hectojoule              energy
  kJ      kilojoule               energy
  MJ      megajoule               energy
  GJ      gigajoule               energy
  TJ      terajoule               energy
  PJ      petajoule               energy
  EJ      exajoule                energy
  ZJ      zettajoule              energy
  YJ      yottajoule              energy
  RJ      ronnajoule              energy
  QJ      quettajoule             energy
  Wh      watthour                energy
  kWh     kilowatthour            energy
  MWh     megawatthour            energy
  GWh     gigawatthour            energy
  TWh     terawatthour            energy
  PWh     petawatthour            energy
  eV      electronvolt            energy
  cal     calorie                 energy
  m       meter                   length
  am      attometer               length
  fm      femtometer              length
  pm      picometer               length
  nm      nanometer               length
  µm      micrometer              length
  mm      millimeter              length
  cm      centimeter              length
  dm      decimeter               length
  dam     decameter               length
  hm      hectometer              length
  km      kilometer               length
  Mm      megameter               length
  Gm      gigameter               length
  Tm      terameter               length
  Pm      petameter               length
  Em      exameter                length
  Å       angstrom                length
  in      inch                    length
  ft      foot                    length
  yd      yard                    length
  mi      mile                    length
  nmi     nauticalmile            length
  lea     league                  length
  fur     furlong                 length
  g       gram                    mass
  qg      quectogram              mass
  rg      rontogram               mass
  yg      yoctogram               mass
  zg      zeptogram               mass
  ag      attogram                mass
  fg      femtogram               mass
  pg      picogram                mass
  ng      nanogram                mass
  μg      microgram               mass
  mg      milligram               mass
  cg      centigram               mass
  dg      decigram                mass
  dag     decagram                mass
  hg      hectogram               mass
  kg      kilogram                mass
  Mg      megagram                mass
  Gg      gigagram                mass
  Tg      teragram                mass
  Pg      petagram                mass
  Eg      exagram                 mass
  Zg      zettagram               mass
  Yg      yottagram               mass
  Rg      ronnagram               mass
  Qg      quettagram              mass
  gr      grain                   mass
  dr      drachm                  mass
  oz      ounce                   mass
  lb      pound                   mass
  st      stone                   mass
  t       ton                     mass
  ___     slug                    mass
  W       watt                    power
  qW      quectowatt              power
  rW      rontowatt               power
  yW      yoctowatt               power
  zW      zeptowatt               power
  aW      attowatt                power
  fW      femtowatt               power
  pW      picowatt                power
  nW      nanowatt                power
  μW      microwatt               power
  mW      milliwatt               power
  cW      centiwatt               power
  dW      deciwatt                power
  daW     decawatt                power
  hW      hectowatt               power
  kW      kilowatt                power
  MW      megawatt                power
  GW      gigawatt                power
  TW      terawatt                power
  PW      petawatt                power
  EW      exawatt                 power
  ZW      zettawatt               power
  YW      yottawatt               power
  RW      ronnawatt               power
  QW      quettawatt              power
  Pa      pascal                  pressure
  qPa     quectopascal            pressure
  rPa     rontopascal             pressure
  yPa     yoctopascal             pressure
  zPa     zeptopascal             pressure
  aPa     attopascal              pressure
  fPa     femtopascal             pressure
  pPa     picopascal              pressure
  nPa     nanopascal              pressure
  μPa     micropascal             pressure
  mPa     millipascal             pressure
  cPa     centipascal             pressure
  dPa     decipascal              pressure
  daPa    decapascal              pressure
  hPa     hectopascal             pressure
  kPa     kilopascal              pressure
  MPa     megapascal              pressure
  GPa     gigapascal              pressure
  TPa     terapascal              pressure
  PPa     petapascal              pressure
  EPa     exapascal               pressure
  ZPa     zettapascal             pressure
  YPa     yottapascal             pressure
  RPa     ronnapascal             pressure
  QPa     quettapascal            pressure
  mbar    millibar                pressure
  cbar    centibar                pressure
  dbar    decibar                 pressure
  bar     bar                     pressure
  kbar    kilobar                 pressure
  Mbar    megabar                 pressure
  Gbar    gigabar                 pressure
  at      technicalatmosphere     pressure
  atm     standardatmosphere      pressure
  Ba      barye                   pressure
  inH20   inchofwatercolumn       pressure
  mmH20   meterofwatercolumn      pressure
  inHg    inchofmercury           pressure
  mmHg    meterofmercury          pressure
  N/m²    newtonpersquaremeter    pressure
  psi     poundforcepersquareinch pressure
  Torr    torr                    pressure
  s       second                  time
  qs      quectosecond            time
  rs      rontosecond             time
  ys      yoctosecond             time
  zs      zeptosecond             time
  as      attosecond              time
  fs      femtosecond             time
  ps      picosecond              time
  ns      nanosecond              time
  μs      microsecond             time
  ms      millisecond             time
  cs      centisecond             time
  ds      decisecond              time
  das     decasecond              time
  hs      hectosecond             time
  ks      kilosecond              time
  Ms      megasecond              time
  Gs      gigasecond              time
  Ts      terasecond              time
  Ps      petasecond              time
  Es      exasecond               time
  Zs      zettasecond             time
  Ys      yottasecond             time
  Rs      ronnasecond             time
  Qs      quettasecond            time
  min     minute                  time
  hr      hour                    time
  d       day                     time
  ___     month                   time
  yr      year                    time
  ___     decade                  time
  ___     century                 time
  ___     millennium              time
  𝑡ₚ      plancktime              time
  ___     fortnight               time
  ___     score                   time
  L       liter                   volume
  qL      quectoliter             volume
  rL      rontoliter              volume
  yL      yoctoliter              volume
  zL      zeptoliter              volume
  aL      attoliter               volume
  fL      femtoliter              volume
  pL      picoliter               volume
  nL      nanoliter               volume
  μL      microliter              volume
  mL      milliliter              volume
  cL      centiliter              volume
  dL      deciliter               volume
  daL     decaliter               volume
  hL      hectoliter              volume
  kL      kiloliter               volume
  ML      megaliter               volume
  GL      gigaliter               volume
  TL      teraliter               volume
  PL      petaliter               volume
  EL      exaliter                volume
  ZL      zettaliter              volume
  YL      yottaliter              volume
  RL      ronnaliter              volume
  QL      quettaliter             volume
  min     minim                   volume
  qt      quart                   volume
  pt      pint                    volume
  gal     gallon                  volume
  floz    fluidounce              volume
  fldr    usfluiddram             volume
  tsp     teaspoon                volume
  tbsp    tablespoon              volume
  uspt    uspint                  volume
  usqt    usquart                 volume
  pot     uspottle                volume
  usgal   usgallon                volume
  usfloz  usfluidounce            volume
  c       uscup                   volume
  jig     usshot                  volume
  gi      usgill                  volume
  bbl     barrel                  volume
  ___     oilbarrel               volume
  ___     hogshead                volume
--------------------------------------------------------------------------------
Note:
  Symbols are case-sensitive, names are not.

Examples:
  whats 2 meters in feet
  whats 1.21 gigawatts in watts
  whats 8 kg in grams
  whats 1024 KiB in MiB

The [in|of] keywords are optional:
  whats 2 m ft

Spaces are optional:
  whats 2m ft

Report bugs at: https://github.com/mrusme/whats/issues
Home page: http://xn--gckvb8fzb.com/projects/whats/
```

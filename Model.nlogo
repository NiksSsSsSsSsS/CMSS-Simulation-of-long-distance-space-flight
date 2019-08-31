breed [males male]
breed [females female]

males-own
[
  ; When dies a specific male? Value in years.
  ageOfDeathYears

  ; Age in years, e.g. for plotting and statistics.
  ageYears

  ; Age in days. Makes things easier due to the fact that one tick is a day.
  ageDays

  ; Is a specific male able to breed?
  isFertile
]

females-own
[
  ; When dies a specific female? Value in years.
  ageOfDeathYears

  ; Age in years, e.g. for plotting and statistics.
  ageYears

  ; Age in days. Makes things easier due to the fact that one tick is a day.
  ageDays

  ; Is a specific female able to breed?
  isFertile

  ; How many children can a specific female become?
  maxChildren

  ; How many children had this female?
  previousChildren

  ; When does the menopause begins?
  startMenopauseYears

  ; Is an individual female pregnant?
  isPregnant

  ; How long is a female pregnant?
  pregnantSinceDays
]

globals
[
  ; The chip's capacity.
  capacity

  ; How many females are on board? This number gets updates on each tick.
  numberFemales

  ; How many females alive are infertile? Gets updated each tick.
  numberFemalesInfertile

  ; How many males are on board? This number gets updated on each tick.
  numberMales

  ; How many males alive are infertile? Gets updated each tick.
  numberMalesInfertile

  ; How many accidents happens in the mission?
  numberAccidents

  ; How many crew members died by accidents?
  numberDeathsByAccidents

  ; How many crew members are died?
  numberDeaths

  ; How many births?
  numberBirths

  ; How many females are born?
  numberBirthsFemales

  ; How many males are born?
  numberBirthsMales

  ; The current year.
  currentYear

  ; The crew's mean age.
  meanAgeYears

  ; The mean age of females.
  meanAgeFemalesYears

  ; The mean age of males.
  meanAgeMalesYears
]

to setup
  clear-all

  ; Configure the plots' pens to behave on a daily or monthly basis:
  ifelse simulateMonthsInsteadOfDays
  [
    set-current-plot "Population over time (6300 years)"

    set-current-plot-pen "females"
    set-plot-pen-interval 30.42

    set-current-plot-pen "males"
    set-plot-pen-interval 30.42

    set-current-plot-pen "total"
    set-plot-pen-interval 30.42

    set-current-plot "Population over time (last 365 days)"

    set-current-plot-pen "females"
    set-plot-pen-interval 30.42

    set-current-plot-pen "males"
    set-plot-pen-interval 30.42

    set-current-plot-pen "total"
    set-plot-pen-interval 30.42
  ]
  [
    set-current-plot "Population over time (6300 years)"

    set-current-plot-pen "females"
    set-plot-pen-interval 1

    set-current-plot-pen "males"
    set-plot-pen-interval 1

    set-current-plot-pen "total"
    set-plot-pen-interval 1

    set-current-plot "Population over time (last 365 days)"

    set-current-plot-pen "females"
    set-plot-pen-interval 1

    set-current-plot-pen "males"
    set-plot-pen-interval 1

    set-current-plot-pen "total"
    set-plot-pen-interval 1
  ]

  ; The ship's capacity:
  set capacity 500

  ; Load the ships's environment:
  import-pcolors "Spaceship.png"

  ; Half the crew consists of males:
  create-males initialCrewSize / 2
  [
    ; Set the shape and color:
    set shape "person"
    set color blue ; males are blue

    ; Determine the date of death for each individual.
    ; The time of death is a normal distribution:
    set ageOfDeathYears random-normal maxAgeMales ageStdDeviation

    ; Determine the initial age at time of mission's start:
    set ageYears random-normal initialAgeMales initialAgeStdDeviation

    ; Calculate the corresponding age as days:
    set ageDays ageYears * 365

    ; Initially, set all individuals to be fertile. We fix this in a moment.
    set isFertile true
  ]

  ; Half the crew consists of females:
  create-females initialCrewSize / 2
  [
    ; Set the shape and color:
    set shape "person"
    set color red ; females are red

    ; Determine the date of death for each individual.
    ; The time of death is a normal distribution:
    set ageOfDeathYears random-normal maxAgeFemals ageStdDeviation

    ; Determine the initial age at time of mission's start:
    set ageYears random-normal initialAgeFemales initialAgeStdDeviation

    ; Calculate the corresponding age as days:
    set ageDays ageYears * 365

    ; Initially, set all individuals to be fertile. We fix this in a moment.
    set isFertile true

    ; Determine how many children a specific female can have.
    ; When the specific female is infertile, use 0. Otherwise, it is a normal distribution:
    set maxChildren random-normal maxChildrenPerFemale maxChildrenStdDeviation

    ; Determine when the menopause begins:
    set startMenopauseYears random-normal meanAgeMenopause ageMenopauseStdDeviation

    ; No female is pregnant at the time of mission's start:
    set isPregnant false
    set pregnantSinceDays 0
  ]

  ; Now, some initial crew members might got a negative age:
  ask turtles with [ ageYears < 0 ]
  [
    set ageDays random 365
    set ageYears ageDays / 365
  ]

  ; Distribute the crew across the spaceship:
  ask turtles [ setxy random-xcor random-ycor ]

  ; Ensure the crew is not in space:
  moveAwayFromSpace

  ; Count the number of females and males on board.
  ; This is necessary to this point in time, to
  ; calculate the fertile state of the crew:
  countSex

  ; Get the initial crew's mean age:
  determineMeanAges

  ; Now, we are fixing the crew's fertile state:
  ask n-of (numberMales * (infertilityMales / 100)) males [ set isFertile false ]
  ask n-of (numberFemales * (infertilityFemales / 100)) females [ set isFertile false ]

  ; Next, we can fix the number of possible children accordingly:
  ask females [ set maxChildren ifelse-value isFertile [ maxChildren ] [ 0 ] ]

  ; Count the number of females and males, again.
  ; This time it is necessary, to show the correct statistics
  ; in the dashboard:
  countSex

  reset-ticks
  output-print "Please wait until the mission's\nsimulation ends ..."
end

to go
  ; Check if and who died:
  checkLife

  ; Determine if any accident occurs today:
  checkAccident

  ; Count the number of females and males to consider
  ; the deaths:
  countSex

  ; The mission might ended:
  if missionEnds?
  [
    stop
  ]

  ; Doing males' actions:
  actMales

  ; Doing females' actions:
  actFemals

  ; Do mating:
  mate

  ; Protect children and pregnant individuals:
  protect

  ; Ensure the crew is not in space:
  moveAwayFromSpace

  ; Determine the number of females and males, again.
  ; Due to births, the numbers might be increased:
  countSex

  ; Calculate the mean age:
  determineMeanAges

  ; Determine the current year:
  determineYear

  ; Update the plotting:
  updatePlots

  ; Next day or month (cf. simulateMonthsInsteadOfDays) ...
  ifelse simulateMonthsInsteadOfDays
  [
    ; Next month...
    tick-advance 30.42
  ]
  [
    ; Next day...
    tick
  ]
end

to actMales
  ask males
  [
    forward random 6
    right random 90
  ]
end

to actFemals
  ask females
  [
    forward random 6
    right random 90

    ; Doing pregnancy management:
    if isPregnant
    [
      ifelse simulateMonthsInsteadOfDays
      [
        set pregnantSinceDays pregnantSinceDays + 30.42
      ]
      [
        set pregnantSinceDays pregnantSinceDays + 1
      ]
    ]
  ]

  ; Determine how many births we have today:
  let births count females with [ pregnantSinceDays > 270 ]

  ; End the pregnancy:
  ask females with [ pregnantSinceDays > 270 ]
  [
    set pregnantSinceDays 0
    set isPregnant false
    set previousChildren previousChildren + 1
  ]

  ; For each birth...
  repeat births
  [
    ; Twin rate is approx. 1% per birth:
    let isTwin random 100 > 98

    ; How many children does the female gets?
    let numberChildren ifelse-value isTwin [ 2 ] [ 1 ]

    ; For each child:
    repeat numberChildren
    [
      ; 50/50 chance for sex:
      let isMale random 100 > 50

      ; Birth:

      ifelse not isMale
      [
        create-females 1
        [
          ; Set the shape and color:
          set shape "person"
          set color red ; females are red

          ; Determine the date of death for each individual.
          ; The time of death is a normal distribution:
          set ageOfDeathYears random-normal maxAgeFemals ageStdDeviation

          ; Determine the initial age at time of mission's start:
          set ageYears 0

          ; Calculate the corresponding age as days:
          set ageDays 1

          ; Is this individual fertile?
          set isFertile random 100 < (100 - infertilityFemales)

          ; Determine how many children a specific female can have.
          ; When the specific female is infertile, use 0. Otherwise, it is a normal distribution:
          set maxChildren random-normal maxChildrenPerFemale maxChildrenStdDeviation

          ; Determine when the menopause begins:
          set startMenopauseYears random-normal meanAgeMenopause ageMenopauseStdDeviation

          ; Not yet pregnant:
          set isPregnant false
          set pregnantSinceDays 0
        ]

        ; Statistics:
        set numberBirths numberBirths + 1
        set numberBirthsFemales numberBirthsFemales + 1
      ]
      [
        create-males 1
        [
          ; Set the shape and color:
          set shape "person"
          set color blue ; males are blue

          ; Determine the date of death for each individual.
          ; The time of death is a normal distribution:
          set ageOfDeathYears random-normal maxAgeMales ageStdDeviation

          ; Determine the initial age at time of mission's start:
          set ageYears 0

          ; Calculate the corresponding age as days:
          set ageDays 1

          ; Is this individual fertile?
          set isFertile random 100 < (100 - infertilityMales)
        ]

        ; Statistics:
        set numberBirths numberBirths + 1
        set numberBirthsMales numberBirthsMales + 1
      ]
    ]
  ]

  ; Move all newborn to the secure area:
  ask turtles with [ ageDays = 1 ]
  [
    setxy 0 0
  ]

end

to checkAccident

  ; Determine if there is any accident. We choose a random number between 0 and 99.
  ; Any value below 99 means no accident.
  let accident random 100

  ; Are we having an accident today?
  if accident >= 99
  [
    set numberAccidents numberAccidents + 1

    ; Okay. Now we have to determine where in spaceship the accident occurs.
    ; As darker the color of the patches, as higher is the risk. The white
    ; areas are save. But from time to time, even there an accident happens.
    ;
    ; Value mappings:
    ; 0  - 70 = black area (pcolor 0)
    ; 71 - 90 =  dark area (pcolor > 0 and pcolor < 2.9)
    ; 91 - 98 =  gray area (pcolor > 2.9 and pcolor < 9)
    ;      99 = white area (pcolor > 9 and pcolor <= 9.9)
    let affectedArea random 100

    ; The black area:
    if affectedArea >= 0 and affectedArea <= 70
    [
      ; Approx. 30% of these accidents are mortal:
      let mortal random 100 >= 70
      if mortal
      [
        ; Determine how many crew members are killed:
        let kills floor random-normal 1 1.1
        if kills > 0
        [
          ; Kill the affected members:
          ask up-to-n-of kills turtles with [pcolor = 0] [ die ]

          ; Statistics:
          set numberDeathsByAccidents numberDeathsByAccidents + kills
          set numberDeaths numberDeaths + kills
        ]
      ]
    ]

    ; The dark area:
    if affectedArea > 70 and affectedArea <= 90
    [
      ; Approx. 15% of these accidents are mortal:
      let mortal random 100 >= 85
      if mortal
      [
        ; Determine how many crew members are killed:
        let kills floor random-normal 0.9 0.8
        if kills > 0
        [
          ; Kill the affected members:
          ask up-to-n-of kills turtles with [pcolor = 0] [ die ]

          ; Statistics:
          set numberDeathsByAccidents numberDeathsByAccidents + kills
          set numberDeaths numberDeaths + kills
        ]
      ]
    ]

    ; The gray area:
    if affectedArea > 90 and affectedArea <= 98
    [
      ; Approx. 5% of these accidents are mortal:
      let mortal random 100 >= 95
      if mortal
      [
        ; Determine how many crew members are killed:
        let kills floor random-normal 0.8 0.8
        if kills > 0
        [
          ; Kill the affected members:
          ask up-to-n-of kills turtles with [pcolor = 0] [ die ]

          ; Statistics:
          set numberDeathsByAccidents numberDeathsByAccidents + kills
          set numberDeaths numberDeaths + kills
        ]
      ]
    ]

    ; The white, save area:
    if affectedArea > 98
    [
      ; Approx. 1% of these accidents are mortal:
      let mortal random 100 > 98
      if mortal
      [
        ; Determine how many crew members are killed:
        let kills floor random-normal 0.5 0.5
        if kills > 0
        [
          ; Kill the affected members:
          ask up-to-n-of kills turtles with [pcolor = 0] [ die ]

          ; Statistics:
          set numberDeathsByAccidents numberDeathsByAccidents + kills
          set numberDeaths numberDeaths + kills
        ]
      ]
    ]
  ]
end

to checkLife
  ask males
  [
    ifelse ageYears > ageOfDeathYears
    [
      set numberDeaths numberDeaths + 1
      die
    ]
    [
      ifelse simulateMonthsInsteadOfDays
      [
        set ageDays ageDays + 30.42
      ]
      [
        set ageDays ageDays + 1
      ]

      set ageYears ageDays / 365
    ]
  ]

  ask females
  [
    ifelse ageYears > ageOfDeathYears
    [
      set numberDeaths numberDeaths + 1
      die
    ]
    [
      ifelse simulateMonthsInsteadOfDays
      [
        set ageDays ageDays + 30.42
      ]
      [
        set ageDays ageDays + 1
      ]

      set ageYears ageDays / 365
    ]
  ]
end

to countSex
  set numberMales count males
  set numberMalesInfertile count males with [ isFertile = false ]
  set numberFemales count females
  set numberFemalesInfertile count females with [ isFertile = false ]
end

to determineMeanAges
  if any? females
  [
    set meanAgeFemalesYears mean [ageYears] of females
  ]

  if any? males
  [
    set meanAgeMalesYears mean [ageYears] of males
  ]

  set meanAgeYears (meanAgeMalesYears + meanAgeFemalesYears) / 2
end

to determineYear
  set currentYear ticks / 365
end

to mate

  ; The maximal number of males:
  let maxAllowedMales count males with [ ageYears >= startAgePermittedMating and ageYears <= endAgePermittedMating ]

  ; Dynamic control?
  if useDynamicPermittedMating
  [
    ; Reached 90% of spaceship's capacity?
    if count turtles + count females with [ isPregnant ] > capacity * 0.8
    [
      ; Allow approx. 1/3 to be mate:
      set maxAllowedMales floor maxAllowedMales / 3
    ]

    ; Reached 95% of spaceship's capacity?
    if count turtles + count females with [ isPregnant ] > capacity * 0.9
    [
      ; Restrict the males down to three:
      set maxAllowedMales 3
    ]

    if count turtles + count females with [ isPregnant ] > capacity * 0.95
    [
      ; Restrict the males down to three:
      set maxAllowedMales 0
    ]
  ]

  ; Start by selecting the allowed number of males in the correct age:
  ask up-to-n-of maxAllowedMales males with [ ageYears >= startAgePermittedMating and ageYears <= endAgePermittedMating ]
  [
    ; Choose a random partner:
    let partner one-of females with [ not isPregnant and ageYears >= startAgePermittedMating and ageYears <= endAgePermittedMating and ageYears < startMenopauseYears]

    ; Both are fertile?
    if partner != nobody and isFertile and [isFertile] of partner and [ previousChildren < maxChildren ] of partner
    [
      ; Chances of pregnancy after intercourse: 75%
      let getsPregnant random 100 > 75
      if getsPregnant
      [
        ask partner
        [
          set isPregnant true
        ]
      ]
    ]
  ]
end

to-report missionEnds?
  if (currentYear > 6300)
  [
    clear-output
    output-print "The mission was successful:\nsurvivors reached the\ndistant planet."
    report true
  ]

  if (numberFemales + numberMales > capacity)
  [
    clear-output
    output-print "Unfortunately, there was too\nmuch offspring, so that the\ncapacity of the spaceship was\nexceeded. The crew has starved,\ndied of thirst or suffocated."
    report true
  ]

  if (numberFemales = 0 and numberMales = 0)
  [
    clear-output
    output-print "The mission failed because\nthe crew was extinct."
    report true
  ]

  report false
end

to moveAwayFromSpace

  ; Patch color >10 means red, which is the space around the ship.
  ; We move all crew members away into the ship:

  while [any? turtles with [ pcolor > 10]]
  [
    ask turtles with [ pcolor > 10]
    [
        forward random 6
        right random 90
    ]
  ]
end

to protect
  ; Protect children:
  ask turtles with [ ageYears < 16  and pcolor < 9.8 ]
  [
    facexy 0 0
    forward random 3
  ]

  ; Protect pregnant females:
  ask females with [ isPregnant and pcolor < 9.8 ]
  [
    facexy 0 0
    forward random 4
  ]
end

to updatePlots

  ; Set the range of the population's plot. We want to see the
  ; last year in more detail. Thus, we use this function to
  ; move the window of the plot along:

  set-current-plot "Population over time (last 365 days)"
  ifelse currentYear < 1.0
  [
    set-plot-x-range 0 365
  ]
  [
    set-plot-x-range ceiling ((currentYear * 365) - 365) ceiling (currentYear * 365)
  ]

  update-plots
end
@#$#@#$#@
GRAPHICS-WINDOW
625
18
1397
415
-1
-1
11.76
1
10
1
1
1
0
0
0
1
-32
32
-16
16
1
1
1
ticks
30.0

SLIDER
9
31
224
64
initialCrewSize
initialCrewSize
2
250
100.0
2
1
people
HORIZONTAL

BUTTON
249
21
337
67
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
249
68
337
117
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
367
107
497
152
# males
numberMales
17
1
11

MONITOR
498
107
617
152
# females
numberFemales
17
1
11

PLOT
626
420
1396
570
Population over time (6300 years)
Days
Number Peoples
0.0
2299500.0
0.0
500.0
false
true
"" ""
PENS
"females" 1.0 1 -5298144 true "" "plot numberFemales"
"males" 1.0 1 -13345367 true "" "plot numberMales"
"total" 1.0 0 -16777216 true "" "plot numberFemales + numberMales"

PLOT
625
577
1397
727
Population over time (last 365 days)
Days
Number Peoples
0.0
365.0
0.0
500.0
false
true
"" ""
PENS
"females" 1.0 1 -5298144 true "" "plot numberFemales"
"males" 1.0 1 -13345367 true "" "plot numberMales"
"total" 1.0 0 -16777216 true "" "plot numberFemales + numberMales"

MONITOR
366
20
618
85
Current Year
currentYear
1
1
16

SLIDER
8
247
225
280
maxAgeFemals
maxAgeFemals
0.5
120
85.0
0.1
1
years
HORIZONTAL

SLIDER
8
281
225
314
maxAgeMales
maxAgeMales
0.5
120
79.0
0.1
1
years
HORIZONTAL

SLIDER
8
315
225
348
ageStdDeviation
ageStdDeviation
0
25
15.0
1
1
years
HORIZONTAL

MONITOR
368
266
548
311
mean age crew
meanAgeYears
2
1
11

MONITOR
498
199
617
244
mean age femals
meanAgeFemalesYears
2
1
11

MONITOR
367
199
497
244
mean age males
meanAgeMalesYears
2
1
11

TEXTBOX
11
10
161
30
Initial parameters:
16
0.0
1

TEXTBOX
9
109
159
127
Crew's initial age:
11
0.0
1

SLIDER
8
127
223
160
initialAgeFemales
initialAgeFemales
1
80
20.0
1
1
years
HORIZONTAL

SLIDER
8
161
223
194
initialAgeMales
initialAgeMales
1
80
20.0
1
1
years
HORIZONTAL

SLIDER
8
194
223
227
initialAgeStdDeviation
initialAgeStdDeviation
0
36
22.0
1
1
years
HORIZONTAL

TEXTBOX
10
231
160
249
Max. age:
11
0.0
1

TEXTBOX
371
93
491
111
Males' statistics:
11
0.0
1

TEXTBOX
503
93
612
111
Females' statistics:
11
0.0
1

TEXTBOX
11
366
161
384
Crew's bio parameters:
11
0.0
1

SLIDER
9
381
224
414
infertilityFemales
infertilityFemales
0
100
10.0
1
1
%
HORIZONTAL

SLIDER
9
415
224
448
infertilityMales
infertilityMales
0
100
15.0
1
1
%
HORIZONTAL

MONITOR
498
153
617
198
# females (infertile)
numberFemalesInfertile
0
1
11

MONITOR
367
153
497
198
# males (infertile)
numberMalesInfertile
0
1
11

SLIDER
9
449
224
482
maxChildrenPerFemale
maxChildrenPerFemale
1
10
2.0
0.1
1
children
HORIZONTAL

SLIDER
9
483
224
516
maxChildrenStdDeviation
maxChildrenStdDeviation
0
2
0.5
0.1
1
NIL
HORIZONTAL

OUTPUT
247
598
603
737
16

TEXTBOX
249
552
605
636
After the mission ended, the reason why this was the case is given here:
16
0.0
1

MONITOR
368
313
548
358
# accidents
numberAccidents
17
1
11

MONITOR
369
360
548
405
# deaths caused by accidents
numberDeathsByAccidents
17
1
11

TEXTBOX
369
249
519
267
Crew's statistics:
11
0.0
1

SLIDER
8
647
221
680
meanAgeMenopause
meanAgeMenopause
40.0
50.0
48.81
0.5
1
years
HORIZONTAL

TEXTBOX
10
630
160
648
Females's bio parameters:
11
0.0
1

SLIDER
8
683
222
716
ageMenopauseStdDeviation
ageMenopauseStdDeviation
1
6
3.9
0.1
1
years
HORIZONTAL

SLIDER
9
517
224
550
startAgePermittedMating
startAgePermittedMating
16
50
35.0
1
1
years
HORIZONTAL

SLIDER
9
551
224
584
endAgePermittedMating
endAgePermittedMating
20
100
40.0
1
1
years
HORIZONTAL

MONITOR
369
406
548
451
# deaths
numberDeaths
17
1
11

MONITOR
369
499
439
544
# births
numberBirths
17
1
11

MONITOR
440
499
502
544
# females
numberBirthsFemales
17
1
11

MONITOR
503
499
566
544
# males
numberBirthsMales
17
1
11

MONITOR
369
453
548
498
# pregnancies
count females with [ isPregnant ]
17
1
11

SWITCH
9
584
224
617
useDynamicPermittedMating
useDynamicPermittedMating
0
1
-1000

SWITCH
9
67
224
100
simulateMonthsInsteadOfDays
simulateMonthsInsteadOfDays
0
1
-1000

@#$#@#$#@
## Model Description

### Introduction

This model is an attempt to recreate the experiment of Frédéric Marin and Camille Beluffi from 2018 [1] by means of ABM. The experiment deals with the questions of how to choose the initial crew of a spacecraft and how to regulate its reproduction in order to survive a 6,300 year intergalactic journey from Earth to the distant planet Proxima Centauri b.

### Scope
The model considers the number of people, their sex and the simplified biological parameters relevant for reproduction. In addition and in contrast to the original experiment, the risk of different tasks in the spaceship is considered. Some activities, e.g. at the technical facilities, are associated with a higher accident risk.

Essential resources such as water, food and medicine, etc. are explicitly not taken into account. The basic assumption is that the spaceship offers enough resources for everyone or can produce them during the journey.

The settlement of Proxima Centauri b is also not taken into account. The experiment is successful if survivors arrive on the distant planet.

## Running the Model

### Dependencies
The model needs the representation of the spaceship in order to execute the setup function. Therefore the `Spaceship.png` file must be located in the directory of the `Survival on Space Flight.nlogo` file. This file is read in automatically. Further manual steps are therefore not necessary.

### Time Scale
The model simulates a day of travel as a tick. In order to simulate the 6,300 years i.e. 2,299,500 ticks, technical challenges arise. Among others, the standard memory allocated for NetLogo is not sufficient to simulate this number of years on a daily basis. This problem is due to the fact that NetLogo is a Java program. One solution is to allocate more memory to the program.

Another solution is the parameter `simulateMonthsInsteadOfDays` in the user interface. If this parameter is enabled, the simulation calculates 30.42 days for each tick instead of one day per tick.

Thus, the parameter `simulateMonthsInsteadOfDays` is enabled by default.

### Necessary Time for a Run i.e. a Mission
Several test runs with four CPU cores have shown that with default parameters approx. 10 minutes are needed for a mission or 6,300 years.

## Environment

The environment used is a two-dimensional representation of a spaceship. The top view from above was chosen as viewpoint. The spaceship is divided into different areas. These areas are represented by grey shades. The darker an area is, the higher is the accident risk. The brighter an area is, the lower is the accident risk.

These areas with the positions of the agents model e.g. different professions and tasks. Work on the engines or other mechanical facilities entails a higher accident risk. Work on the IT infrastructure, in resource extraction (e.g. food) or in the preparation of food is potentially less dangerous.

The spaceship is surrounded by space, which is represented in the model as red color. Space is deadly.

## Agents

### Femals

#### Properties
- `ageOfDeathYears`: At what age will the agent die (in years)?

- `ageYears`: The current age of the agent (in years).

- `ageDays`: The current age of the agent (in days).

- `isFertile`: Is this agent fertile and can produce offspring?

- `maxChildren`: What is the maximum number of children this female can have?

- `previousChildren`: How many children has this female given birth to?

- `startMenopauseYears`: At what age (in years) does menopause begin for this female?

- `isPregnant`: Is this female currently pregnant?

- `pregnantSinceDays`: If this female is currently pregnant, since how many days?

#### Behaviour / Actions
- **Movement:** In every tick a female moves randomly in the spaceship as long as she is older than 15 years and not pregnant. Pregnant females and females younger than 16 years only stay in the middle of the spacecraft so that they are protected from lethal accidents.

- **Pregnancy:** If a female is pregnant, the pregnancy progresses. If a female has been pregnant for at least 270 days, her pregnancy gets terminated and at least one offspring is born. There is a 1% probability that twins will be born. The probability that the offspring is male or female is 50%.

- **Accidents:** A female might be involved in an accident. The probability depends on the position in the spaceship. Not every accident is lethal. Every day, the probability of an accident occurrence is 1%. When an accident happens, it happens 70% in a black area, 20% in a dark area, 8% in a gray area, and 1% in the white area. The accidents in the black area end in 30%, in the dark area in 15%, in the grey area in 5%, and in the white area in 1% of the cases deadly.

- **Reproduction:** A female can reproduce. All males and females that are within the allowed age of reproduction try to mate. The couples are formed randomly. If one of the two partners is not fertile, no pregnancy occurs. If both partners are fertile, there is a 75% probability of pregnancy after intercourse.

- **Death:** A female can die. Either due to age or an accident.

### Males

#### Properties

- `ageOfDeathYears`: At what age will the agent die (in years)?

- `ageYears`: The current age of the agent (in years).

- `ageDays`: The current age of the agent (in days).

- `isFertile`: Is this agent fertile and can produce offspring?


#### Behaviour / Actions
- **Movement:** In every tick a male moves randomly in the spaceship as long as he is older than 15 years. Males younger than 16 years only stay in the middle of the spacecraft so that they are protected from lethal accidents.

- **Accidents:** A male might be involved in an accident. The probability depends on the position in the spaceship. Not every accident is lethal. Every day, the probability of an accident occurrence is 1%. When an accident happens, it happens 70% in a black area, 20% in a dark area, 8% in a gray area, and 1% in the white area. The accidents in the black area end in 30%, in the dark area in 15%, in the grey area in 5%, and in the white area in 1% of the cases deadly.

- **Reproduction:** A male can reproduce. All males and females that are within the allowed age of reproduction try to mate. The couples are formed randomly. If one of the two partners is not fertile, no pregnancy occurs. If both partners are fertile, there is a 75% probability of pregnancy after intercourse.

- **Death:** A male can die. Either due to age or an accident.

## Order of Events

### Function: Setup

1. **Reset:** Reset i.e. clear the entire simulation.

1. **Pens:** Initialize all pens of both diagrams. This is necessary so that the user can choose between a simulation on a daily or monthly basis.

1. **Capacity:** Define the capacity of the spaceship so that a maximum of 500 people can live on it.

1. **Import representation:** Import the two-dimensional representation of the spaceship from the `Spaceship.png` file. This will also import the colors that indicate which risk zones exist where in the spaceship.

1. **Create males:** Creates the first half of the crew (males): Set males' color to blue. Define the date of death and the age of all males as the normal distribution with the parameters selected from the user interface. Define all males as fertile (all males were examined before the mission so that initially only fertile members are present).

1. **Create females:** Creates the second half of the crew (females): Set females' color to red. Define the date of death and the age of all females as the normal distribution with the parameters selected from the user interface. Define all females as fertile (all females were examined before the mission so that initially only fertile members are present). Determine how many children a female can have and when her menopause begins, both as normal distribution with the parameters selected in the user interface. Define that all females are not pregnant.

1. **Fixing crew's age:** Depending on the parameters selected in the user interface, it might happen that some crew members have a negative age due to the normal distribution of age. Therefore, this step ensures that the members affected by this effect receive an age between 0 and 365 days.

1. **Random position:** Assign a random position in the spaceship to each crew member.

1. **Not in space:** Make sure no crew member was randomly positioned outside the spacecraft.

1. **Count sex:** Count how many males and females currently exist and how many are fertile or infertile. This step is necessary to subsequently calculate the initial infertility as a distribution over the crew.

1. **Determine mean age:** Calculate the average age of the crew.

1. **Crews' infertility:** Randomly distribute the infertility status to the crew according to the parameters configured in the user interface.

1. **Unfertile women cannot have children:** This step ensures that women who are infertile cannot have children.

1. **Count sex:** Count how many males and females currently exist and how many are fertile or infertile. This step will now be performed again after the infertility status has been correctly distributed across the crew. This will give us statistics about the actual infertility at the start time of the mission.

1. **Reset ticks:** The ticks of the simulation are reset.

### Function Go
At each tick of the simulation the following events take place. Reminder: A tick simulates one day of the intergalactic journey or approx. one month (depending on your choice in the user interface).

1. **Check life:** The first step is to check if and how many crew members die today. Everyone whose lifespan has expired is marked dead and is no longer part of the simulation. All members who do not die naturally today will become one day or month older.

1. **Check if accidents occur:** It will be checked whether there will be an accident on the spaceship today. The statistical probability of an accident is 1%. If this probability applies, an accident occurs. It is also checked in which part of the spaceship the accident occurs. When an accident happens, it happens 70% in a black area, 20% in a dark area, 8% in a gray area, and 1% in the white area. The accidents in the black area end in 30%, in the dark area in 15%, in the grey area in 5%, and in the white area in 1% of the cases deadly. Depending on whether and where an accident occurs, appropriate crew members from the affected part of the ship are randomly selected and marked as dead. These members are then no longer part of the simulation.

1. **Count sex:** Count how many males and females currently exist and how many are fertile or infertile. This will update the mission's statistic after all natural and unnatural deaths have been addressed.

1. **Mission ended?** It will be checked if the mission has been completed. This is the case when the mission year 6300 has been reached. The survivors of the mission can then colonize the distant planet. If the number of crew members is above the capacity limit, the mission also ends: In this case the members starve, die of thirst or suffocate because the resources are not sufficient. The mission can also end when all humans on the ship are extinct.

1. **Male actions:** The actions of the males are limited to the fact that their agents move randomly in the spaceship.

1. **Female actions:** The females move first randomly in the spaceship. With all females that are pregnant, the pregnancy progresses by one or 30 day(s). Afterwards it is determined whether and how many births there will be today. The pregnancy of the affected females is terminated and the birth is initiated. For each birth it is statistically determined whether there will be twins. The probability of this is 1%. Then it is decided whether a male or female will be born. The probability is the same for both sexes. For each newborn the age is set to zero and the other parameters are assigned as in the setup (day of death, fertility, number of children, menopause, etc.) The newborns are added to the crew.

1. **Mating:** In this step it is first determined how many males are at the permitted age for reproduction. This number indicates the maximum number of theoretically possible reproductions for that day. If the option for dynamic control of allowed reproduction is enabled in the user interface, this number is dynamically reduced if necessary to prevent overpopulation on the spacecraft. If the capacity limit is reached to 80%, only 30% of the males are allowed to mate with a female. If the capacity limit was reached to 90%, only three males are allowed to mate with a female. If the capacity limit is already reached to 95% or more, no reproduction at all is permitted on this day. The number of males determined in this way is selected randomly. The selected males randomly select a suitable female. Suitable females are not yet pregnant, are in the age range for permitted reproduction and are younger than the time of menopause. Now it is checked whether both partners are fertile and the female has not yet exceeded her child limit. If all conditions are met, intercourse occurs. After that there is a 75% probability that the female has become pregnant. If this probability is fulfilled, the female is marked as pregnant.

1. **Protection:** This step ensures that all children younger than 17 years and all pregnant females are in the safest area of the spacecraft. This measure ensures that the highest mission priority is maintained (crew survival).

1. **Not in space:** Make sure no crew member was randomly positioned outside the spacecraft.

1. **Count sex:** Count how many males and females currently exist and how many are fertile or infertile. This will update the statistics after all births due for that day have been handled.

1. **Determine mean age:** Calculate the average age of the crew.

1. **Determine year:** Calculate the current mission year.

1. **Update plots:** The "*Population over time (last 365 days)*" diagram is updated. This cannot be done automatically because, so to speak, the window of the graph has to move, so that the last 365 days are always visible.

1. **Time advancement:** Depending on the configuration, the simulation progresses by one day or one month.

## User Interface
The user interface is divided into six parts. For each part there is subsequently a separate section so that the information is better arranged.

### Initial parameters

- `initialCrewSize` The number of crew members to the mission's start. **Default: 100**

- `simulateMonthsInsteadOfDays` Should one day or one month be simulated per tick of the simulation? **Default: On = Months**

### Crew's initial age

- `initialAgeFemales` The age of females at the beginning of the mission. **Default: 20 years**

- `initialAgeMales` The age of males at the beginning of the mission. **Default: 20 years**

- `initialAgeStdDeviation` The age of the crew is a normal distribution. This is its standard deviation. **Default: 22 years**

### Max. age

- `maxAgeFemals` The maximum age of females. **Default: 85 years**

- `maxAgeMales` The maximum age of males. **Default: 79 years**

- `ageStdDeviation` The maximum age is a normal distribution. This is its standard deviation. **Default: 15 years**

### Crew's bio parameters

- `infertilityFemales` The infertility of females. **Default: 10%**

- `infertilityMales` The infertility of males. **Default: 15%**

- `maxChildrenPerFemale` The maximum number of children a woman can give birth to. **Default: 2 children**

- `maxChildrenStdDeviation` The maximum number of children per female is a normal distribution. This is its standard deviation. **Default: 0.5 children**

- `startAgePermittedMating` The age at which reproduction is allowed on this mission. **Default: 35 years**

- `endAgePermittedMating` The age up to which reproduction is permitted during this mission. **Default: 40 years**

- `useDynamicPermittedMating` Enables or disables the dynamic control of reproduction. Might prevents overpopulation. **Default: On**

### Females's bio parameters

- `meanAgeMenopause` The age at which the female menopause begins. Frédéric Marin and Camille Beluffi indicate 45 years as mean age, cf. [1]. A standard deviation is missing in their paper. I therefore use the default values from Magurský, Mesko, and Sokolík from 1975, cf. [2]. **Default: 48.81 years**

- `ageMenopauseStdDeviation` The age at which female menopause begins is a normal distribution. This is its standard deviation. As mentioned before, Frédéric Marin and Camille Beluffi [1] do not mention any standard deviation. I therefore use the information from Magurský, Mesko, and Sokolík [2]. **Default: 3.9 years**

### Statistics

- *Current year*: Indicates the current year of the mission.

- *Males' statistics* and *Females' statistics*: Indicates the total number of males and females, their average age, and the number of infertile individuals.

- *Crew's statistics*: Indicates the average age of the entire crew, how many accidents there were, how many deadly accidents and how many deaths overall. The number of pregnancies, the total number of births and the number of males and females born are also specified.

- *Population over time (6300 years)*: A time series over the duration of the entire mission, i.e. 6300 years. The time series indicates the size of the population. The total population, as well as the number of males and females.

- *Population over time (last 365 days)*: A time series of the population size over the last 365 days. The total population as well as the number of males and females are given.

## Things to Notice
This model has a lot of parameters, so a lot of interesting insights can be obtained. A first example is given here: It seems to be very difficult to find a stable combination of parameters so that the mission is guaranteed to be successful (even if the experiment is repeated several times). At least, without the dynamic control of propagation. I have not succeeded so far.

When the dynamic control of reproduction is activated, success can be guaranteed with two allowed children per female. However, this dynamic control is a significant cut in the freedom of the crew. From an ethical point of view it does not seem to be acceptable.

It would lead to a situation in which only a few selected people would be allowed to reproduce, which could lead to corruption and crime. The crew might tend to eliminate older crew members in order to escape the strict rules of dynamic control, etc. Therefore, it seems useful to find a parameter set under which dynamic control of reproduction is not necessary.

## Citation and References

### Cite this Model
This model can be cited in its entirety by citing the repository: "Sommer, Thorsten, 2019. Simulation of long-distance space flight. DOI: XXXX. Source Code: https://github.com/SommerEngineering/Simulation-of-long-distance-space-flight"

The procedure of the simulation can be cited dedicated: "Sommer, Thorsten, 2019. Simulation of 6300 year intergalactic journey. DOI: [dx.doi.org/10.17504/protocols.io.6zshf6e](https://dx.doi.org/10.17504/protocols.io.6zshf6e).

### References

- [1] https://arxiv.org/abs/1806.03856 

- [2] https://www.ncbi.nlm.nih.gov/pubmed/4380
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="test experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="initialCrewSize">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endAgePermittedMating">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialAgeFemales">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ageStdDeviation">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialAgeStdDeviation">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infertilityMales">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxChildrenStdDeviation">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meanAgeMenopause">
      <value value="48.81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ageMenopauseStdDeviation">
      <value value="3.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxChildrenPerFemale">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxAgeMales">
      <value value="73.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initialAgeMales">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startAgePermittedMating">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxAgeFemals">
      <value value="80.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infertilityFemales">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="useDynamicPermittedMating">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@

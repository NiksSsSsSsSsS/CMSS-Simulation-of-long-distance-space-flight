## Model Description

[![DOI](https://zenodo.org/badge/204130885.svg)](https://zenodo.org/badge/latestdoi/204130885)

### Introduction

This model for the [NetLogo system](https://github.com/NetLogo/NetLogo) is an attempt to recreate the experiment of Frédéric Marin and Camille Beluffi from 2018 [1] by means of ABM. The experiment deals with the questions of how to choose the initial crew of a spacecraft and how to regulate its reproduction in order to survive a 6,300 year intergalactic journey from Earth to the distant planet Proxima Centauri b.

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
This model can be cited in its entirety by citing the repository: "Sommer, Thorsten (2019). Simulation of a long-distance space flight. DOI: [10.5281/zenodo.3382913](https://doi.org/10.5281/zenodo.3382913).

DOI of latest state i.e. version:

[![DOI](https://zenodo.org/badge/204130885.svg)](https://zenodo.org/badge/latestdoi/204130885)

The procedure of the simulation can be cited as: "Sommer, Thorsten (2019). Simulation of a 6300 year intergalactic journey. DOI: [10.17504/protocols.io.6zshf6e](https://doi.org/10.17504/protocols.io.6zshf6e)".

### References

- [1] https://arxiv.org/abs/1806.03856 

- [2] https://www.ncbi.nlm.nih.gov/pubmed/4380
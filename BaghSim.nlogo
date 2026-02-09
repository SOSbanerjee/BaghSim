;;;;; BaghSim v0.9.0 - Tiger Population Dynamics Model
;;;;; Copyright (c) 2024-2026 Dr Indushree Banerjee
;;;;; Water Management, Civil Engineering and Geosciences, TU Delft
;;;;; https://doi.org/10.5281/zenodo.18554417
;;;;; LICENSE AND USAGE TERMS:
;;;;; ========================
;;;;; This software is provided for EDUCATIONAL AND NON-COMMERCIAL USE ONLY.
;;;;;
;;;;; You MAY:
;;;;;   - Download and use this model for personal educational purposes
;;;;;   - Use this model for academic teaching and learning
;;;;;   - Cite this model in academic publications with appropriate credit
;;;;;
;;;;; You MAY NOT:
;;;;;   - Use this model for any commercial purposes
;;;;;   - Modify, extend, or build upon this model without explicit written permission
;;;;;   - Redistribute modified versions of this model
;;;;;   - Incorporate this model into other software without permission
;;;;;
;;;;; For permissions beyond educational use, including extensions, modifications,
;;;;; or commercial applications, please contact: Dr Indushree Banerjee (i.banerjee@tudelft.nl | banerjee.indushree@gmail.com)
;;;;;
;;;;; Required attribution for all permitted uses:
;;;;; "BaghSim Tiger Population Dynamics Model by Dr Indushree Banerjee, TU Delft"
;;;;;
;;;;; ALL RIGHTS RESERVED for uses not explicitly granted above.
;;;;;
;;;;;; The following code represents Tigers as agents and patches as forest cover.
;;;;;; The world uses procedurally-generated landscapes (synthetic generation).
;;;;;; The world has global values that impact all agents: temperature.
;;;;;; Each tick in the simulation represents 24 hours (one day) for each agent.

;; No extensions required - uses procedurally-generated landscapes only
globals
[
  current-run  ;; for BehaviorSpace test

  temperature ;; currently unused integer number, that currently follows a sine-wave with max temperature at summer solstice, min temperature at winter solstice
  day-of-year ;; integer number that determines date (with summer solstice = 0)
  rain ;; currently unused and undefined. might determine blue patches, tiger movement, tiger fatigue, temperature

  marked-patches ;; performance solution, so that not all patches have to be queried in finding nearby marked patches. patch-set of currently marked patches.

  ;; initialization phase hacks
  memory-initialized? ;; boolean to check whether while loop of initialization phase can be terminated
  count-tigers-with-three-memories ;; integer that counts the number of tigers with knowledge of at least one water patch, one shade patch, and one food patch
  ;; when this variable equals the total number of tigers, initialization is done

  gestation-length ;; currently unused biological information, that will determine when pregnancy results in birth
  age-of-maturation ;; currently unused biological information, that will determine when cubs lose cub status

  prey-reduction-number

  global-hunger
  global-thirst
  global-fatigue
  global-mate
  global-fear-of-humans
  global-fear-of-competitors
  global-prey

  scenario-message

  death-records
  death-cause-total

  adult-male-tiger
  adult-female-tiger
  total-old-tiger
  total-cub
  juvenile-tiger
  total-transient

  cumulative-cub-mortality
  cumulative-cub-grownup

  yearly-cumulative-cub-mortality
  yearly-cumulative-cub-grownup

  yearly-births
  yearly-deaths-hunger
  yearly-deaths-thirst
  yearly-deaths-competition
  yearly-deaths-old-age
  yearly-deaths-infanticide
  yearly-deaths-total
  previous-year-population

  current-week
  simulation-days

  GPScollarfilenum
]

breed [tigers tiger]
;;;; Tiger as an agent has certain needs represented by variables, all these variables are individually calculated to maintain all needs of the tiger.
;;;; In order to maintain all the needs resources needs to be collected by each tiger, such as access to water for thirst, access to prey for hunger..etc.
;;;; As a tiger moves around it senses its environment and stores the information about the location of water, prey in its memory.
;;;; The memory guides the tiger to navigate to patches that it knows may be used to meet its needs (unless the context has changed in the meantime).
;;;; These markings serve as warning to other tigers to avoid these areas/patches to prevent contest for resources.
;;;; The tigers leave their marks such as scratchings, urine, scatter, pheromoes, as part of their daily activities to learn about their surroundings and resources for survival.
;;;; As these markings are left and resources identified, tigers use these areas for their habitat, each tiger has a certain area tht it traverses each day to fulfil needs.
;;;; All activities are initiated and prioritised based on individual tiger needs on each day
;;;; As resources are dynamic due to changes in the space they traverse, the areas they leave markings to avoid contest also changes over time.
;;;; Eventually areas used by each tiger marked suitable for its habitat or in very generic terminology "territories" emerge and disappear.

tigers-own [
  tiger-id

  female   ;; used to distinguish between male and female, female is "yes", male is "NO".
  age      ;; integer representing age of a tiger determines if it is adult or sub-subadult. As per its age its needs change, a adult tiger has an extra need of mating.
  age-days ;; total days old (incremented by 1 every tick)
  hunger   ;; integer value between 0 and 15, tiger can go 15 days without food before it dies. Every time it hunts successfuly the number goes down to 0, each day increments it by 1

  fatigue             ;; integer value between 0 and 15, tiredness due to hunting, increase in temperature goes up all the time by an increment of 1 (not ideal)
  thirst              ;; integer value between 0 and 15, tiger can go 3 days without water before it dies. Every time it on a water body,the number goes down to 0, each day increments it by 5
  fear-of-competitors ;; integer value between 0 & 15, increases by 1 when encounters a competitor or a marking by other tiger
  fear-of-humans      ;; integer value 1 - 15, increases by 1 when it encounters a human settlement/human
  mate                ;; integer value 1-15, need to still think

  pregnant?       ;; boolean to indicate if the tiger is pregnant
  gestation-timer ;; counter for the gestation period
  fertility-age?  ;; boolean to indicate if the tiger is of reproductive age

  exploration       ;; integer value of currently 5
  total-needs       ;; sum of hunger + thirst + fear of competitors + humans +(seasonal) mating + exploration
  current-need      ;; the one activity that the tiger is currently focusing on
  current-need-met? ;; boolean to check if current-need is met or not
  steps-taken       ;;  number of patches a tiger actually traverses which might be lower than it actually intended.

  energy            ;; number of patches a tiger can traverse during a day, which is decremented as the tiger traverses patches.
  base-speed        ;;  integer value set as per gender, age and temperature of the day
  total-speed       ;; number of patches this tiger can traverse during a day, which may become age and temperature-dependent.

  water-memory-locations  ;; patch-set of patches with pcolor = blue that this tiger has visited in the past (and was not different the last time it was there)
  shade-memory-locations  ;; patch-set of patches with pcolor = black that the tiger has visited in the past
  food-memory-locations   ;; patch-set of patches with prey > 0 that the tiger has visited in the past
  female-memory-locations ;; patch-set of patches with female tigers > 0 or female-marking of a different female tiger that the tiger has visited in the past
  male-memory-locations   ;; patch-set of patches with male tigers > 0 or male-marking of a different male tiger that the tiger has visited in the past
  human-memory-locations  ;; patch-set of patches with pcolor = white that the tiger has visited in the past
  cub-memory-locations    ;; patch-set of patches a cub inherit from mother once it is 1 month old and can start following her around

  is-mother?            ;; boolean to indicate if the tiger just gave birth and is a mother
  cubs                  ;;  List of cub IDs for mother tiger
  mother                ;; Who number of the mother for cubs, agent-set of 1 that will affect its movements, as it stays close
  father                ;; who number of the father for the cubs, father will not kill its cubs.
  is-cub?               ;; boolean to determine cubness
  self-reliance         ;; Every tiger now has a numeric variable self-reliance, which we'll use to track how ready it is to live independently i.e. transition from cub to adult
  time-away-from-mother ;; Before a cub becomes dispersal, it must be able to spend time by itself


  nursing?      ;; Boolean to indicate if the mother is nursing cubs
  nursing-timer ;; Timer for the nursing period
  cub-hunger    ;; Sum of hunger levels of cubs
  cub-thirst    ;; Sum of thirst level of cubs

  transient?      ;; Tigers that are no longer cub and are self-relient but cant find safe habitat to leave mother
  estrus-day
  litter-ids

  total-distance-walked ;;; for debugging
  daily-steps-taken    ;; Actual patches traversed today
  daily-energy-allocated ;; Energy allocated for the day

  ;; Diagnostic tracking variables
  daily-hunt-attempts    ;; How many times tiger tried to hunt today
  daily-hunt-successes   ;; How many successful hunts today
  daily-water-visits     ;; How many times reached water today
  daily-shade-visits     ;; How many times reached shade today
  daily-mating-attempts  ;; How many mating attempts today
]

patches-own [
 prey ;; currently set to 1% of patches have 100 prey. Unrealistic and need to get from other Work Package
 male-marking ;; each patch is 9999 by default so not marked as a habitat for any tiger, until marked by a tiger, when marked the patch bears the who-id of the tiger
 female-marking ;; same as above
 female-litter-ids
 male-litter-ids
 female-marking-fading-clock ;;  memory clock to keep location of a particular resource available for 15 days, an integer that is basically a countdown to refresh markings of patches into default.
 male-marking-fading-clock ;; same as above, as name suggests markings (urine, scratch, scatter) fade over time.
]

to setup
  clear-all
  set current-run behaviorSpace-run-number
  ;;;; resize-world -518 518 -518 518
  ;;;; This yields 1037 patches horizontally and vertically (because from -518 to 518 inclusive is 1037 distinct integers).
  ;;;; each patch in your model represents a 30 × 30 m area (i.e., 0.0009 km²).
  ;;;; Study area: ~968 km²
  ;;;; Patch area: 0.0009 km²
  ;;;; So the total number of patches needed is: 968÷0.0009≈1,075,556 patches. Taking a square grid: 1037

  ;;;; Resizing World from 1037×1037 to 384×384 Patches
  ;;;; -----------------------------------------------
  ;;;; The original world was defined with 1037×1037 patches,
  ;;;; where each patch represented a 30m × 30m area.
  ;;;; This resulted in 1,075,556 patches, making the simulation computationally expensive.
  ;;;;
  ;;;; To improve efficiency while maintaining realism:
  ;;;; We increased the patch size to 100m × 100m.
  ;;;; This reduces the number of patches to ~147,456 (384 × 384),
  ;;;; covering the same real-world area of 1475 km² (968 km² National Park + 507 km² Buffer Zone).
  ;;;; The new world coordinates are set from -192 to 191 in both x and y directions.
  ;;;;
  ;;;; This adjustment significantly enhances performance while preserving spatial accuracy.


  resize-world -192 191 -192 191   ;; Adjust world size to 384 x 384 patches
  set-patch-size 1.464             ;; Adjust for better visibility

  ;; Initialize landscape using procedural generation
  ask patches with [abs pxcor < 191 or abs pycor < 191][
    set pcolor green
    set male-marking 9999
    set female-marking 9999
    set male-marking-fading-clock 0
    set female-marking-fading-clock 0
    set prey 0
  ]

  ;; Define Buffer Zone (around the edges)
  ask patches with [abs pxcor > 160 or abs pycor > 160] [
    set pcolor white  ;; Buffer Zone
  ]
  ;; Call the river-making function based on the chooser selection
  apply-scenario
  set day-of-year 0
  set temperature 25
  update-temperature

  ;; Environmental setup:

  introduce-tigers-into-world
  set memory-initialized? false
  set count-tigers-with-three-memories 0
  set gestation-length 100
  set age-of-maturation 5
  set marked-patches no-patches


 ; make-some-herds

  ifelse prey-situation = "Prey unaffected" [ set prey-reduction-number 0] [ set prey-reduction-number 1 ]

  ask tigers [
    set is-mother? false
    set cubs []
    set mother nobody
  ]

  ;; Uncomment the following code to collect movement data of simulated tigers for analysis.
  ;; Create a file called output in the same folder as the model to save the csv files

  ;;set GPScollarfilenum current-run  ;; Use run number for unique filenames
  ;;file-open (word "output/BaghSim_GPScoordinates_Run" GPScollarfilenum "_" num-of-water-channel ".csv")
  ;;file-print (word "tick" "," "day.of.year" "," "x" "," "y" "," "id" "," "female" "," "age" "," "litter-ids" "," "current-need" "," "nursing" "," "is_mother" "," "is_cub" )
  ;;file-close

  ;;file-open (word "output/BaghSim_death_records_Run" GPScollarfilenum "_" num-of-water-channel ".csv")
  ;;file-print "tick,who,age,age_days,female,cause"
  ;;file-close



  set death-records (list)

  set yearly-births 0
  set yearly-deaths-hunger 0
  set yearly-deaths-thirst 0
  set yearly-deaths-competition 0
  set yearly-deaths-old-age 0
  set yearly-deaths-infanticide 0
  set yearly-deaths-total 0
  set previous-year-population Total-tiger-count

  ;; export-landscape-setup ;; uncomment if you want to store landscape data, create a folder output in the same folder as the model

  reset-ticks
end ;; setup


to apply-scenario

ifelse scenario = "Default" [
  setup-default-scenario
]
[ ifelse scenario = "Uniform" [
    setup-uniform-scenario
  ]
  [ ifelse scenario = "Clustered" [
      setup-clumped-scenario
    ]
      [ user-message (word "Unknown scenario: " scenario)
      ]
  ]
]
sprinkle-random-water 1000
  ;export-water-data
end

;;; This procedure is to ensure that all tigers start with some knowledge of their surroundings. The pupose it to give them memory.
;;; For this each tiger traverses its patches where it is initialised to find a blue patch for water,
;;; a balck patch for shade, and a patch with prey. TeDuring this phase there is no fear as it is not aware of another tiger in its vicinity.
;;; It does learn about patches that are white (with human settlements).
;;; IT does have needs to water, food and shade to rest but the tiger does not die in this learning the environment process.
;;; Neither prey is decresed.

to initialize-go ;; Called from the Interface  ;;v everything that is defined or called on the interface should be referred to the Interface via
                                               ;;V comments like this one.
  ask tigers
  [
    set thirst 0
    set fatigue 0
    set hunger 0
    set exploration 25
  ]
  while [memory-initialized? = false]
  [
    set count-tigers-with-three-memories 0
    ask tigers [
    if min (list count water-memory-locations count shade-memory-locations count food-memory-locations) > 2
      [ set count-tigers-with-three-memories count-tigers-with-three-memories + 1 ]
    ]

    ask tigers [
    update-tiger-daily-speed
    increment-needs-initialization-phase
    set energy total-speed
    ]
    ask tigers [
       sum-needs
       go-towards-water-initialization-phase energy * (thirst / total-needs)
       go-towards-shade-initialization-phase energy * (fatigue / total-needs)
       go-towards-food-initialization-phase energy * (hunger / total-needs)
       go-forward-initialization-phase energy * (exploration / total-needs)
  ]
  ifelse (count-tigers-with-three-memories = count tigers )
   [
    set memory-initialized? true
    ask tigers [
    set thirst 0
    set fatigue 0
    set hunger 0
    set exploration 2.0 ;!!!!!!!!!!!

  ]
    ][
      ]
  ]

  ask tigers [
    move-to one-of shade-memory-locations
  ]
end ; initialize-go

to introduce-tigers-into-world
  create-tigers Total-tiger-count
  [
    set tiger-id who
    set shape "circle"
    set color yellow
    set size 5
    move-to one-of patches with [pcolor != white]

    ; Set gender
    ifelse random-float 1 < 0.587 [  ; 58.7% adult females
      set female 1
      set shape "triangle"
      set size 10
      set estrus-day random 40
      set color red  ;; female is red
    ] [
      set female 0
    ]

    ; Set age
    ifelse random-float 1 < 0 [  ; 13.5% cubs was ifelse random-float 1 < 0.135, but don't want cubs at initialization, so now 0
      set age random 3  ; 0-2 years
      set age-days age * 365 ;; converting age into days.

      set color pink  ; Different color for cubs
    ] [
      set age 3 + random 13  ; 3-15 years for adults
      set age-days age * 365

    ]

    set hunger 0
    set fatigue 0
    set thirst 0
    set fear-of-competitors 0
    set fear-of-humans 0
    set mate 0
    set exploration 2.0

    ; Initialize movement speed of tiger based on age, gender
    update-tiger-base-speed

    ;; Initiliase fertilityand set gestation to zero
    set pregnant? false
    set gestation-timer 0
    set nursing? false
    set nursing-timer  0
    set cub-hunger 0
    set cub-thirst 0
    set is-cub? false
    set transient? false
    set litter-ids (list (word "init-class-" who))

    update-fertility-status

    ; Initialize memory locations
    set water-memory-locations no-patches
    set shade-memory-locations no-patches
    set food-memory-locations no-patches
    set female-memory-locations no-patches
    set male-memory-locations no-patches
    set human-memory-locations no-patches
    set cub-memory-locations no-patches

    ; Initialize diagnostic counters
    set daily-hunt-attempts 0
    set daily-hunt-successes 0
    set daily-water-visits 0
    set daily-shade-visits 0
    set daily-mating-attempts 0
  ]

end



;--------------------------------------------------------------------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------------------------------------------------------

to setup-default-scenario
  make-some-dirt
  make-new-forests

  ifelse river-type = "central" [
    make-central-river
  ] [
    if river-type = "boundary" [
      make-boundary-river
    ]
  ]

  make-some-waterholes
  make-some-herds


   ;----------------------------------------------------------
  ; Print stats or store scenario message
  ; This helps you confirm how many patches ended up water
  ; vs shade, etc.  (Check the Command Center for prints.)
  ;----------------------------------------------------------
  let water-patches count patches with [pcolor = blue]
  let shade-patches count patches with [pcolor = black]
  let total-prey sum [prey] of patches

  ;; Store a message for display in a monitor if you like:
  set scenario-message (word "Default scenario "
                             ", water=" water-patches
                             ", shade=" shade-patches
                             ", total prey=" total-prey)
end

;------------------------------------------------------------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------------------------------------------------------------

to go
  set global-hunger 0
  set global-thirst 0
  set global-fatigue 0
  set global-fear-of-humans 0
  set global-fear-of-competitors 0
  set global-mate 0
  set global-prey 0


  set day-of-year (day-of-year + 1) mod 365

  update-temperature
  ;; Age each tiger by 1 day
  ask tigers [
    set age-days age-days + 1
    set age floor (age-days / 365)

    ;; If you want them to die at 18 years:
    if age >= 18 [ record-death "old-age" alt-die ]
    if age-days = 1095 [ set father -1 ]
    ;; Recompute speed because age might have changed
    update-tiger-base-speed
    if female = 1 [ set estrus-day estrus-day + 1
     ]
    if estrus-day > 40 [
      set estrus-day 0
    ]
  ]


  increment-female-marking-fading
  increment-male-marking-fading

  remove-female-marking
  remove-male-marking


  ; Monthly update (assumes 30-day months) to regenerate prey
  if (day-of-year mod 30) = 0 [  ; Every 30 days
    if  prey-situation = "Prey eaten and reproducing" [
  ask patches [
    if prey > 0 [
      ; For each existing prey, 0.3% chance to add a new one
      let new-prey 0
      repeat prey [
        if random-float 1 < 0.003 [  ;0.3% chance per prey
          set new-prey new-prey + 1
        ]
      ]
      set prey prey + new-prey
      ]
     ]
    ]
  ]

  foreach sort-on [age] tigers [  i -> ask i [
   update-tiger-daily-speed
   update-fertility-status
   increment-needs
   sum-needs                ;; This is necessary to update total-needs
   set energy scale-energy-by-needs

   ;set energy total-speed

   set daily-steps-taken 0
   set daily-energy-allocated energy  ; Store today's allocated energy

   ;; Reset daily diagnostic counters
   set daily-hunt-attempts 0
   set daily-hunt-successes 0
   set daily-water-visits 0
   set daily-shade-visits 0
   set daily-mating-attempts 0
   ]
  ]


  ask tigers with [female = 0] [
    sum-needs
    run-away-from-males energy * (fear-of-competitors / total-needs)
    sum-needs
    run-away-from-humans energy * (fear-of-humans / total-needs)
    sum-needs
    run-towards-females energy * (mate / total-needs)
    sum-needs
    go-towards-water energy * (thirst / total-needs)
    sum-needs
    if age-days > 700 [
    mark-territory-male
    ]
    go-towards-shade energy * (fatigue / total-needs)
    sum-needs
    go-towards-food energy * (hunger / total-needs)
    sum-needs
    go-forward energy * (directionless-need-male / total-needs)
    sum-needs
    ;mark-territory-male
  ]
  ask tigers with [female = 1 AND not is-mother?] [
    sum-needs
    run-away-from-females energy * (fear-of-competitors / total-needs)
    sum-needs
    run-away-from-humans energy * (fear-of-humans / total-needs)
    sum-needs
    run-towards-males energy * (mate / total-needs)
    sum-needs
    go-towards-water energy * (thirst / total-needs)
    sum-needs
    if age-days > 700 [
    mark-territory-female
    ]
    go-towards-shade energy * (fatigue / total-needs)
    sum-needs
    go-towards-food energy * (hunger / total-needs)
    sum-needs
    go-forward energy * (directionless-need-female / total-needs)
    sum-needs
    ;mark-territory-female
  ]

    ask tigers with [female = 1 AND is-mother?] [
    ;; DIAGNOSTIC: Track energy allocation AND target locations for mothers with young cubs
    run-towards-cubs  energy * (cub-thirst / total-needs)
    sum-needs
    run-away-from-females energy * (fear-of-competitors / total-needs)
    sum-needs
    run-towards-cubs  energy * (cub-thirst / total-needs)
    sum-needs
    run-away-from-humans energy * (fear-of-humans / total-needs)
    sum-needs
    run-towards-cubs  energy * (cub-thirst / total-needs)
    sum-needs
    run-towards-males energy * (mate / total-needs)
    sum-needs
    run-towards-cubs  energy * (cub-thirst / total-needs)
    sum-needs
    go-towards-water energy * (thirst / total-needs)
    sum-needs
    run-towards-cubs  energy * (cub-thirst / total-needs)
    sum-needs
    mark-territory-female
    go-towards-shade energy * (fatigue / total-needs)
    sum-needs
    run-towards-cubs  energy * (cub-thirst / total-needs)
    sum-needs
    go-towards-food energy * ((hunger + cub-hunger) / total-needs)
    sum-needs
    run-towards-cubs  energy * (cub-thirst / total-needs)
    sum-needs
    go-forward energy * (directionless-need-female / total-needs)
    sum-needs
    run-towards-cubs  energy * (cub-thirst / total-needs)
    sum-needs
    ;mark-territory-female
  ]


  if (tigers with [is-cub?]) != nobody [
  ask tigers with [is-cub?] [
  grow-cub-behaviors
  update-time-away
    ; Then decide if I'm transient:
  ifelse (self-reliance >= 0.9) and (not is-comfortable?) [
    set transient? true
    set shape "square"
    set color violet
  ][
    set transient? false
    ; maybe revert color to pink if I'm still a normal cub
    ; or keep color if I'm subadult
  ]
]
  ]


  ask tigers [
    set global-hunger global-hunger + hunger
    set global-thirst global-thirst + thirst
    set global-fatigue global-fatigue + fatigue
    set global-fear-of-humans global-fear-of-humans + fear-of-humans
    set global-fear-of-competitors global-fear-of-competitors + fear-of-competitors
    set global-mate global-mate + mate
  ]

  ifelse count tigers > 0 [
  set global-hunger global-hunger / (count tigers)
  set global-thirst global-thirst / (count tigers)
  set global-fatigue global-fatigue / (count tigers)
  set global-fear-of-humans global-fear-of-humans / (count tigers)
  set global-fear-of-competitors global-fear-of-competitors / (count tigers)
  set global-mate global-mate / (count tigers)
  ]



  [stop]

  ask patches [
    set global-prey global-prey + prey
  ]

  tiger-population-demographic

  plot-death-causes

   ; collect-all-data

   if day-of-year mod 365 = 0 and ticks > 0 [

    ;; export-yearly-summary   ;; uncomment this code for data collection

    set previous-year-population count tigers
    set yearly-cumulative-cub-mortality 0
    set yearly-cumulative-cub-grownup 0
    set yearly-births 0
    set yearly-deaths-hunger 0
    set yearly-deaths-thirst 0
    set yearly-deaths-competition 0
    set yearly-deaths-old-age 0
    set yearly-deaths-infanticide 0
    set yearly-deaths-total 0

  ]

  tick

end

to update-temperature
  let average-temp 25  ; Average annual temperature in Celsius
  let temp-range 10    ; Temperature range (difference between hottest and coldest)
  set temperature average-temp + (temp-range / 2) * cos (day-of-year * 360 / 365)
end

to make-new-forests
  ;; First, select initial forest patches within the park (green patches)
  let green-patches patches with [pcolor = green]
  if any? green-patches [
    ask n-of min (list 150 count green-patches) green-patches [ set pcolor black ]  ;;; change the list to 100 if you change the patch size to 30m
  ]

  ;; Expand the forest clusters
  foreach [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 ] [
    ask patches with [pcolor = black] [
      let nearby-green neighbors with [pcolor = green]  ;; Get only green neighbors
      if count nearby-green > 0 [
        ask n-of min (list 3 count nearby-green) nearby-green [ set pcolor black ]
      ]
    ]
  ]
end

to make-river
  create-turtles 2 [
    set color blue
    set shape "triangle"
    set size 10
    set ycor -192
    set xcor random 384 - 192
    face patch 0 0
  ]
  ask turtles with [shape = "triangle"] [
    loop [

    ask patch-here [
      set pcolor blue
      ask neighbors [
        set pcolor blue
      ]
    ]
    left random-normal 0 2
    fd 1
    if not can-move? 1 [ stop ]
    ]

  ]
  ask turtles with [shape = "triangle"] [
    die
  ]
  foreach [1 2 ] [
  ask patches with [ pcolor = blue][
    ask neighbors [
    set pcolor blue
    ]
  ]
  ]
end

to make-some-waterholes
  ;; Parameters for waterhole placement
  let total-waterholes 50  ;; Total number of waterholes (tune based on area) because now the patch size is 100mx100m, if we go 30mx30m, we will do 50
  let bias-near-rivers 0.05  ;; Probability bias for patches near rivers
  let bias-near-grassland 0.03  ;; Probability bias for patches in grassland
  let edge-avoidance-radius 10  ;; Distance from park edges to avoid


  ;; Place waterholes
  repeat total-waterholes [
    let candidate-patch one-of patches with [
      pcolor = green and
      distancexy 0 0 < world-width / 2 and  ;; Avoid edge zones
      not any? neighbors4 with [pcolor = blue] and  ;; Avoid existing waterholes
      (random-float 1 <
        (ifelse-value (any? neighbors4 with [pcolor = blue]) [bias-near-rivers] [0]) +
        (ifelse-value (pcolor = green) [bias-near-grassland] [0.01])  ;; Grassland bonus
      )
    ]

    if candidate-patch != nobody [
      ask candidate-patch [
        set pcolor blue  ;; Designate as a waterhole
        ;; Optionally color nearby patches for visual realism
        ask neighbors [ set pcolor blue ]
      ]
    ]
  ]
end

to sprinkle-random-water [n]
  ;; n = number of single-patch water sources to add
  let candidates patches with [pcolor = green]
  ask n-of n candidates [
    set pcolor blue
  ]
end

 to make-some-dirt ;;V you mean: create open space?
  ask n-of (10000 / 7.3) patches with [pxcor >= -161 and pxcor <= 160 and pycor >= -161 and pycor <= 160] [
    set pcolor one-of [brown]
  ]
  ask patches with [ pcolor = brown ][
    ask neighbors with [pxcor >= -161 and pxcor <= 160 and pycor >= -161 and pycor <= 160][
    set pcolor brown
    ]
  ]
  ask patches with [ pcolor = brown][
    ask neighbors with [pxcor >= -161 and pxcor <= 160 and pycor >= -161 and pycor <= 160][
    set pcolor brown
    ]
  ]
end

 to make-some-herds
    ;; Literature-based prey distribution
    ;; Chital: 90%, riverine habitat, herds of 2-15 (mean ~5)
    ;; Sambar: 10%, forest habitat, 52% solitary, rest 2-4
    ;; Sources: Moe & Wegge 1994, Karanth & Sunquist 1992/1995

    ask patches [ set prey 0 ]

    ;; === PARAMETERS (adjust to calibrate) ===
    let chital-density 50      ;; per km² in suitable habitat
    let sambar-density 5       ;; per km² in forest
    let chital-buffer 6        ;; patches (~600m) from water
    let patch-area 0.01        ;; km² per patch (100m × 100m)

    ;; === IDENTIFY HABITATS ===
    let water-patches patches with [pcolor = blue]

    ;; Chital: riverine/floodplain (near water, not settlements)
    let chital-habitat patches with [
      pcolor != white and pcolor != blue and pcolor != brown and
      any? water-patches in-radius chital-buffer
    ]

    ;; Sambar: forest interior (green/black, away from water)
    let sambar-habitat patches with [
      (pcolor = green or pcolor = black) and
      pcolor != white and pcolor != brown
    ]

    ;; === CALCULATE TARGETS ===
    let chital-target round (count chital-habitat * patch-area * chital-density)
    let sambar-target round (count sambar-habitat * patch-area * sambar-density)

    let chital-mean-herd 5
    let sambar-mean-group 1.5  ;; 52% solitary

    let chital-herds round (chital-target / chital-mean-herd)
    let sambar-groups round (sambar-target / sambar-mean-group)

    ;; === PLACE CHITAL HERDS ===
    repeat chital-herds [
      let center one-of chital-habitat
      if center != nobody [
        ask center [
          ;; Right-skewed: many small herds, few large
          let herd-size 2 + random 13  ;; 2-14, mean ~8
          let targets (patch-set self neighbors) with [member? self chital-habitat]
          ask targets [
            if herd-size > 0 [
              let here 1 + random 3
              set prey prey + min list here herd-size
              set herd-size herd-size - here
            ]
          ]
        ]
      ]
    ]

    ;; === PLACE SAMBAR ===
    repeat sambar-groups [
      let spot one-of sambar-habitat
      if spot != nobody [
        ask spot [
          ;; 52% solitary (Karanth & Sunquist 1992)
          set prey prey + ifelse-value (random-float 1 < 0.52) [1] [2 + random 3]
        ]
      ]
    ]

  end


to increment-needs
  set hunger hunger + 1

  set thirst thirst + 3.5
    if is-mother? [
    set cub-hunger sum [hunger] of tigers with [mother = [who] of myself]
    set cub-thirst sum [thirst] of tigers with [mother = [who] of myself]
  ]
  set fear-of-competitors min ( list max (list ( fear-of-competitors - 2 ) (0)) 15) ;; - 5
  set fear-of-humans min (list max (list ( fear-of-humans - 2 ) (0)) 15 ) ;; were - 5
  ;set fatigue fatigue + 0.5
  set fatigue min (list max (list ( fatigue + 0.5 ) (0)) 15 )

  ;; Increment male mating drive gradually
  if female = 0 and fertility-age? [
    set mate min (list (mate + 0.5) 10)
  ]

  ;; Female mating drive based on estrus cycle
  if female = 1 [
    ifelse pregnant? = false and nursing? = false and fertility-age? and estrus-day < 5 [
      set mate 12
    ] [
      set mate 0
    ]
  ]

  if thirst > 15 [
    record-death "thirst"
    alt-die
  ]
    if hunger > 15 [
     record-death "hunger"
    alt-die
  ]

  ;; Decrement nursing timer and update nursing status
  if nursing-timer > 0 [
    set nursing-timer nursing-timer - 1
    if nursing-timer = 0 [
      set nursing? false  ;; Lactation period ended, can mate again
    ]
  ]

  handle-gestation
end

to increment-needs-initialization-phase
    set fear-of-humans 0
    set fear-of-competitors 0
    set mate 0
    set hunger hunger + 1
    set thirst thirst + 5
    set fatigue fatigue + 0.5
    set thirst min (list thirst 15)
    set fatigue min (list fatigue 15)
    set hunger min (list hunger 15)
end

to increment-female-marking-fading
  ask marked-patches with [female-marking-fading-clock > 0] [
  set female-marking-fading-clock female-marking-fading-clock - 1
  ]
end

to increment-male-marking-fading
  ask marked-patches with [male-marking-fading-clock > 0] [
  set male-marking-fading-clock male-marking-fading-clock - 1
  ]
end

;;;;;;;;;;;;;; FIX here
to remove-female-marking
  ask marked-patches with [female-marking-fading-clock < 1] [
    set female-marking 9999
    set female-litter-ids nobody
  ]
  ask marked-patches with [female-marking-fading-clock < 1 AND male-marking-fading-clock < 1] [set marked-patches other marked-patches]
end

to remove-male-marking
  ask marked-patches with [male-marking-fading-clock < 1] [
  set male-marking 9999
  set male-litter-ids nobody]
end

to sum-needs
  set total-needs hunger + fatigue + thirst + fear-of-competitors + fear-of-humans + mate + exploration + cub-hunger + cub-thirst
end

to alt-fd [steps]
  set steps-taken 0
  repeat steps [

  if current-need-met? = false [
  if current-need = "explore" [
       ifelse can-move? 1 = true [
       ifelse [pcolor] of patch-ahead 1 = white [
          left random 161 + 100
        ] [
        left random 11 - 5
        ]
        ] [ left 180]
      ]

  if current-need = "mate" and female = 0 [
        ifelse any? tigers with [female = 1 AND distance myself <= 5 and not shares-litter-id? myself and fertility-age?] [
          let nearest-female min-one-of tigers with [female = 1 AND distance myself <= 5 and not shares-litter-id? myself and fertility-age?] [distance myself]
          face nearest-female
        ] [
          if any? female-memory-locations [
            let nearest-female min-one-of female-memory-locations [distance myself]
            face nearest-female
        ] ]
      ]

  if current-need = "mate" and female = 1 [
        ifelse any? tigers with [female = 0 AND distance myself <= 5 and not shares-litter-id? myself and fertility-age? ] [
          let nearest-male min-one-of tigers with [female = 0 AND distance myself <= 5 and not shares-litter-id? myself and fertility-age?] [distance myself]
          face nearest-male
        ] [
          if any? male-memory-locations [
            let nearest-male min-one-of male-memory-locations [distance myself]
            face nearest-male
        ] ]
      ]

   if current-need = "fear-of-competition" and female = 0 [
     ifelse any? tigers with [female = 0 AND distance myself <= 5 and not shares-litter-id? myself and fertility-age? ] [
  let nearest-male min-one-of tigers with [female = 0 AND distance myself <= 5 and not shares-litter-id? myself and fertility-age?] [distance myself]
  face nearest-male
  left 180
  ] [ if any? male-memory-locations [
  let nearest-male min-one-of male-memory-locations [distance myself]
  face nearest-male
  left 180
  ] ]
      ]

         if current-need = "fear-of-competition" and female = 1 [
         ifelse any? tigers with [female = 1 AND distance myself <= 5 and not shares-litter-id? myself and fertility-age?] [
  let nearest-female min-one-of tigers with [female = 1 AND distance myself <= 5 and not shares-litter-id? myself and fertility-age?] [distance myself]
  face nearest-female
  left 180
  ] [ if any? female-memory-locations [
  let nearest-female min-one-of female-memory-locations [distance myself]
  face nearest-female
  left 180
  ] ]
      ]

  ;; Re-orient toward food during walk (prevents "depressed penguin" behavior)
  if current-need = "hunger" [
    if any? food-memory-locations [
      let nearest-food min-one-of food-memory-locations [distance myself]
      face nearest-food
    ]
  ]

  ;; Note: Cub re-orientation removed - landing fix alone should suffice
  ;; since cubs < 14 days don't move and nothing changes heading during cub-thirst walk

  ;; Land on target when close (prevents near-miss interactions)
  ;; Instead of always fd 1, check if we're within 1 patch of our target
  ;; and if so, move directly to it. This fixes mating, fighting, nursing, etc.
  let landed-on-target false

  ;; For hunger: land on food patch
  if current-need = "hunger" and any? food-memory-locations [
    let target min-one-of food-memory-locations [distance myself]
    if target != nobody and distance target < 1 [
      move-to target
      set landed-on-target true
    ]
  ]

  ;; For water: land on water patch
  if current-need = "water" and any? water-memory-locations [
    let target min-one-of water-memory-locations [distance myself]
    if target != nobody and distance target < 1 [
      move-to target
      set landed-on-target true
    ]
  ]

  ;; For fatigue/shade: land on shade patch
  if current-need = "fatigue" and any? shade-memory-locations [
    let target min-one-of shade-memory-locations [distance myself]
    if target != nobody and distance target < 1 [
      move-to target
      set landed-on-target true
    ]
  ]

  ;; For cub-thirst: land on cub
  if current-need = "cub-thirst" [
    let target highest-thirst-cub
    if target != nobody and distance target < 1 [
      move-to target
      set landed-on-target true
    ]
  ]

  ;; For mate: land on potential partner
  if current-need = "mate" [
    let target nobody
    ifelse female = 0 [
      ;; Male looking for female
      if any? tigers with [female = 1 AND distance myself <= 5 and not shares-litter-id? myself and fertility-age?] [
        set target min-one-of tigers with [female = 1 AND distance myself <= 5 and not shares-litter-id? myself and fertility-age?] [distance myself]
      ]
    ] [
      ;; Female looking for male
      if any? tigers with [female = 0 AND distance myself <= 5 and not shares-litter-id? myself and fertility-age?] [
        set target min-one-of tigers with [female = 0 AND distance myself <= 5 and not shares-litter-id? myself and fertility-age?] [distance myself]
      ]
    ]
    if target != nobody and distance target < 1 [
      move-to target
      set landed-on-target true
    ]
  ]

  ;; Default movement if we didn't land on a target
  if not landed-on-target [
    fd 1
  ]


  memorize-water-locations
  memorize-shade-locations
  memorize-food-locations
  memorize-female-locations
  memorize-male-locations
  memorize-human-locations

;; The following commented code collect GPS locations of tigers in the simulation
;;  if random 100 < 8 [
;;       file-open (word "output/BaghSim_GPScoordinates_Run" GPScollarfilenum "_" num-of-water-channel ".csv")
;;        file-print (word ticks "," day-of-year "," pxcor "," pycor "," [who] of self "," female "," age "," litter-ids "," current-need "," nursing? "," is-mother? "," is-cub?)
;;        file-close
;;     ]

  update-status
  set steps-taken steps-taken + 1
  ]
  ]
  set energy energy - steps-taken

  set daily-steps-taken daily-steps-taken + steps-taken
end



to update-status
  let mysex female
  let mywho who
  if [pcolor = blue] of patch-here [
    if thirst > 0 [
    set thirst 0
    set daily-water-visits daily-water-visits + 1  ;; DIAGNOSTIC
    if current-need = "water" [

      set current-need-met? true ]
  ]
  ]
  if [pcolor = white] of patch-here [
    set fear-of-humans min (list max (list ( fear-of-humans + 0.25 ) (0)) 15 )
  ]
  if [prey > 0] of patch-here [
    if hunger > 3 [
    set daily-hunt-attempts daily-hunt-attempts + 1  ;; DIAGNOSTIC
    let hunt-roll random 6
    ifelse hunt-roll = 0 [
    set hunger 0
    set daily-hunt-successes daily-hunt-successes + 1  ;; DIAGNOSTIC
        if current-need = "hunger" [
          set current-need-met? true
        ]
        if is-mother? [
  if any? tigers with [member? who cubs and mother = [who] of myself] [
    ask tigers with [member? who cubs and mother = [who] of myself] [
      set hunger 0
    ]
         set cub-hunger sum [hunger] of tigers with [mother = [who] of myself]
  ]
]

      ask patch-here [ set prey prey - prey-reduction-number ]
    ] [
      ]
  ]
  ]
  if [pcolor = black] of patch-here [
    if fatigue > 0 [set fatigue 0
    set daily-shade-visits daily-shade-visits + 1  ;; DIAGNOSTIC
    ]
    if current-need = "fatigue" or current-need = "fear-of-humans" [
          set current-need-met? true
        ]
  ]

  ;;;Implementing mating

 if mate > 0 and fertility-age? [
  if any? tigers-here with [female != mysex and pregnant? = false and fertility-age? and mate > 0 and not shares-litter-id? myself ] [
    let partner one-of tigers-here with [female != mysex and pregnant? = false and fertility-age? and mate > 0 and not shares-litter-id? myself ]
    set daily-mating-attempts daily-mating-attempts + 1  ;; DIAGNOSTIC

    ;; Both tigers have mating drive fulfilled
    set mate 0
    ask partner [ set mate 0 ]

    ;; Handle pregnancy logic for the female tigers only
    if female = 1 and not nursing? [  ;; If the current tiger is female
      set pregnant? true
      set gestation-timer 0
      set father [who] of partner  ;; Partner is male.
    ]

    ask partner [  ;; Check if the partner is female
      if female = 1 and not nursing? [
        set pregnant? true
        set gestation-timer 0
        set father [who] of myself
      ]
    ]

    ;; Mark the current need as met
    if current-need = "mate" [
      set current-need-met? true
    ]
  ]
]







  if is-mother? [
    ;; Check for any cubs on the same patch
    let cubs-here tigers-here with [mother = mywho]

    ;; If there are cubs here, reduce their thirst
    if any? cubs-here [
      ask cubs-here [
        set thirst 0
        set hunger 0
      ]
      set cub-thirst sum [thirst] of tigers with [mother = [who] of myself]
      ;; Satisfy the mother's cub-thirst need if it's her current-need
      if current-need = "cub-thirst" [
        set current-need-met? true
      ]
    ]
  ]

  ;;; the following should not happen to young cubs or brothers, still need to implement
  ;;; scared males (fear >= 10) also don't fight
  if female = 0 and age > 3 and fear-of-competitors < 10 [
  if any? other tigers-here with [female = 0 and age > 3 and fear-of-competitors < 10] [

  let opponent one-of other tigers-here with [female = 0]
  let p prob-winning self opponent

  ifelse random-float 1.0 < p [
    ; I win
    ask opponent [
      ifelse random-float 1.0 < 0.1  ; Chance of death in defeat
      [record-death "competition" alt-die ]
      [set fear-of-competitors 15]  ; Max fear if survive

    ]
  ][
    ; I lose
    ifelse random-float 1.0 < 0.1  ; Same chance of death
    [record-death "competition"
          alt-die
          ]
    [set fear-of-competitors 15]
  ]
]


    if [male-marking < 9999 AND male-marking != mywho] of patch-here  [
      set fear-of-competitors min ( list max (list ( fear-of-competitors + 2 ) (0)) 15) ;; Made this higher, used to be 2

    ]

  if fear-of-competitors < 10 and any? tigers-here with [age-days < 730 and father != [who] of myself] [
  let threatened-cubs tigers-here with [age-days < 730 and father != [who] of myself]
  let num-threatened count threatened-cubs
  let their-mother one-of tigers with [
    is-mother? and
    distance myself <= 10 and
    member? [who] of one-of threatened-cubs cubs
  ]
  ifelse their-mother != nobody [  ; If their mother is close enough to defend
    let p prob-winning self their-mother
    ifelse random-float 1.0 < p [
      ; Male wins
      ask threatened-cubs [
        let cub-death-prob 0.5
        ifelse random-float 1.0 < cub-death-prob [
          record-death "infanticide"
          alt-die
            ] [ ]
      ]
    ][
      ; Mother successfully defends
      ifelse random-float 1.0 < 0.1
      [alt-die]
      [set fear-of-competitors 15  ; Male backs off after mother defends
         ]
    ]
      ] [
        ask threatened-cubs [

        let cub-death-prob 0.5
        ifelse random-float 1.0 < cub-death-prob [
          record-death "infanticide"
          alt-die
          ] [ ]
      ] ]
]
  ]

  ;; scared females (fear >= 10) don't fight
  if female = 1 and age > 3 and fear-of-competitors < 10 [
  if any? other tigers-here with [female = 1 and age > 3 and fear-of-competitors < 10] [

  let opponent one-of other tigers-here with [female = 1 and age > 3 and fear-of-competitors < 10]
  let p prob-winning self opponent
  let are-sisters shares-litter-id? opponent

  ifelse random-float 1.0 < p [
    ; I win
    ask opponent [
      ifelse random-float 1.0 < 0.1  ; Chance of death in defeat
      [record-death "competition" alt-die ]
      [set fear-of-competitors 15]  ; Max fear if survive

    ]
  ][
    ; I lose
    ifelse random-float 1.0 < 0.1  ; Same chance of death
    [record-death "competition"
          alt-die
          ]
    [set fear-of-competitors 15]
  ]
]


    if [female-marking < 9999 AND female-marking != mywho] of patch-here  [
      set fear-of-competitors min ( list max (list ( fear-of-competitors + 2 ) (0)) 15) ;; Made this higher, used to be 2
    ]

  ]


end

to run-towards-cubs [speed]
  set current-need "cub-thirst"
  set current-need-met? false

  ;; Check for the cub with the highest thirst
  let priority-cub highest-thirst-cub

  ;; Run toward the prioritized cub or its last-known location
  if priority-cub != nobody [
      face priority-cub
    ]
    alt-fd speed
end



to run-towards-males [speed]
  set current-need "mate"
  set current-need-met? false
  let candidate min-one-of tigers with [female = 0 and not shares-litter-id? myself and fertility-age?] [distance myself]
  ifelse candidate != nobody and distance candidate <= 5 [
    face candidate
  ] [
    if any? male-memory-locations [
      let nearest-male min-one-of male-memory-locations [distance myself]
      face nearest-male
    ]
  ]
  alt-fd speed
end

to run-towards-females [speed]
  set current-need "mate"
  set current-need-met? false
  let candidate min-one-of tigers with [female = 1 and not shares-litter-id? myself and fertility-age?] [distance myself]
  ifelse candidate != nobody and distance candidate <= 5 [
    face candidate
  ] [
    if any? female-memory-locations [
      let nearest-female min-one-of female-memory-locations [distance myself]
      face nearest-female
    ]
  ]
  alt-fd speed
end

to run-away-from-males [speed]
  set current-need "fear-of-competition"
  set current-need-met? false
  let candidate min-one-of tigers with [female = 0 and not shares-litter-id? myself and fertility-age?] [distance myself]
  ifelse candidate != nobody and distance candidate <= 5 [
    face candidate
    left 180
  ] [
    if any? male-memory-locations [
      let nearest-male min-one-of male-memory-locations [distance myself]
      face nearest-male
      left 180
    ]
  ]
  alt-fd speed
end

to run-away-from-females [speed]
  set current-need "fear-of-competition"
  set current-need-met? false
  let candidate min-one-of tigers with [female = 1 and not shares-litter-id? myself and fertility-age?] [distance myself]
  ifelse candidate != nobody and distance candidate <= 5 [
    face candidate
    left 180
  ] [
    if any? female-memory-locations [
      let nearest-female min-one-of female-memory-locations [distance myself]
      face nearest-female
      left 180
    ]
  ]
  alt-fd speed
end

to run-away-from-humans [speed]
  set current-need "fear-of-humans"
  set current-need-met? false
  if any? shade-memory-locations [
  let nearest-shade min-one-of shade-memory-locations [distance myself]
  face nearest-shade
  ]
  alt-fd speed
end

to go-towards-water [speed]
  set current-need "water"
  set current-need-met? false
  ifelse any? water-memory-locations [
  let nearest-water min-one-of water-memory-locations [distance myself]
  face nearest-water
][
  if mother != nobody [  ; If I'm a cub with no water memory
    let mom one-of tigers with [who = [mother] of myself]
    if mom != nobody [
      face mom
    ]
  ]
]
  alt-fd speed
end


to memorize-human-locations
  if [pcolor = white] of patch-here and not member? patch-here human-memory-locations [
  set human-memory-locations (patch-set human-memory-locations patch-here)
  ]
  if member? patch-here human-memory-locations AND [pcolor != white] of patch-here [
    set human-memory-locations human-memory-locations with [[patch-here] of myself != self]
    ]
end

to memorize-water-locations
  if [pcolor = blue] of patch-here and not member? patch-here water-memory-locations[
  set water-memory-locations (patch-set water-memory-locations patch-here)
  ]
  if member? patch-here water-memory-locations AND [pcolor != blue] of patch-here [
    set water-memory-locations water-memory-locations with [[patch-here] of myself != self]
    ]
end

to memorize-shade-locations
  if [pcolor = black] of patch-here and not member? patch-here shade-memory-locations [
  set shade-memory-locations (patch-set shade-memory-locations patch-here)
  ]
  if member? patch-here shade-memory-locations AND [pcolor != black] of patch-here [
    set shade-memory-locations shade-memory-locations with [[patch-here] of myself != self]
    ]
end

to memorize-food-locations
  if [prey > 0 ] of patch-here and not member? patch-here food-memory-locations[
  set food-memory-locations (patch-set food-memory-locations patch-here)
  ]
  if member? patch-here food-memory-locations AND not [prey > 0 ] of patch-here [
    set food-memory-locations food-memory-locations with [[patch-here] of myself != self]
    ]
end

to memorize-female-locations
  let mywho who
  if ( any? other tigers-here with [female = 1] OR ( [female-marking] of patch-here < 9999 AND [female-marking] of patch-here != mywho )) and not member? patch-here female-memory-locations [
    set female-memory-locations (patch-set female-memory-locations patch-here)
  ]
  if member? patch-here female-memory-locations AND not (any? other tigers-here with [female = 1] OR ( [female-marking] of patch-here < 9999 AND [female-marking] of patch-here != mywho )) [
    set female-memory-locations female-memory-locations with [[patch-here] of myself != self]
  ]
end


to-report highest-thirst-cub
  if any? tigers with [mother = [who] of myself] [
    report max-one-of tigers with [mother = [who] of myself] [thirst]
  ]
  report nobody
end

to memorize-male-locations
  let mywho who
  if (any? other tigers-here with [female = 0] OR ( [male-marking] of patch-here < 9999 AND [male-marking] of patch-here != mywho )) and not member? patch-here male-memory-locations [
    set male-memory-locations (patch-set male-memory-locations patch-here)
  ]
  if member? patch-here male-memory-locations AND not (any? other tigers-here with [female = 0] OR ( [male-marking] of patch-here < 9999 AND [male-marking] of patch-here != mywho )) [
    set male-memory-locations male-memory-locations with [[patch-here] of myself != self]
  ]
end

to mark-territory-male
  let mywho who
  let my-litter-ids litter-ids
  if [male-marking] of patch-here = 9999 [
  set marked-patches (patch-set marked-patches patch-here)
  ask patch-here [
  set male-marking mywho
  set male-litter-ids my-litter-ids
  set male-marking-fading-clock 15
  ]
  ]
end

to mark-territory-female
  let mywho who
  let my-litter-ids litter-ids
  if [female-marking] of patch-here = 9999 [
  set marked-patches (patch-set marked-patches patch-here)
  ask patch-here [
  set female-marking mywho
  set female-litter-ids my-litter-ids
  set female-marking-fading-clock 15
  ]
  ]
end




to go-towards-food [speed]
  set current-need "hunger"
  set current-need-met? false
  ifelse any? food-memory-locations [
  let nearest-food min-one-of food-memory-locations [distance myself]
  face nearest-food
][
  if mother != nobody [  ; If I'm a cub with no water memory
    let mom one-of tigers with [who = [mother] of myself]
    if mom != nobody [
      face mom
    ]
  ]
]
  alt-fd speed
end

to go-towards-shade [speed]
  set current-need "fatigue"
  set current-need-met? false
  if any? shade-memory-locations [
  let nearest-shade min-one-of shade-memory-locations [distance myself]
  face nearest-shade
  ]
  alt-fd speed
end

to go-forward [speed]
  set current-need "explore"
  set current-need-met? false
  left random 360
  alt-fd speed
end



to alt-fd-initialization-phase [steps]
  set steps-taken 0
  repeat steps [
  if current-need-met? = false [
  fd 1
  memorize-water-locations
  memorize-shade-locations
  memorize-food-locations
  memorize-human-locations
  update-status-initialization-phase
  set steps-taken steps-taken + 1
  ]
  ]
  set energy energy - steps-taken
end

to update-status-initialization-phase
  let mysex female
  let mywho who
  if [pcolor = blue] of patch-here [
    set thirst 0
    if current-need = "water" [

      set current-need-met? true ]
  ]
  if [prey > 0] of patch-here [
    if hunger > 3 [
    ifelse random 6 = 0 [
    set hunger 0
        if current-need = "hunger" [
          set current-need-met? true
        ]
      set thirst thirst + 0.5
      set fatigue fatigue + 0.5

    ] [ set thirst thirst + 0.25
        set fatigue fatigue + 0.5 ]
  ]
  ]
  if [pcolor = black] of patch-here [
    set fatigue 0
    if current-need = "fatigue" [
          set current-need-met? true
        ]
  ]
end

to-report scale-energy-by-needs

  ;; Calculate the current proportion (0 to 1) of maximum needs
  let ceiling-cub-hunger min ( list (cub-hunger) 15)
  let ceiling-cub-thirst min ( list (cub-thirst) 15)
  let need-proportion (sum sublist reverse sort ( list hunger fatigue thirst fear-of-competitors fear-of-humans mate exploration ceiling-cub-hunger ceiling-cub-thirst ) 0 2) / 30

  report total-speed * need-proportion
end

to-report directionless-need-male
  let factor exploration
  if not any? food-memory-locations [ set factor factor + hunger ]
  if not any? water-memory-locations [ set factor factor + thirst ]
  if not any? female-memory-locations [ set factor factor + mate ]
  if not any? shade-memory-locations [ set factor factor + fatigue + fear-of-humans ]
  report factor
end

to-report directionless-need-female
  let factor exploration
  if not any? food-memory-locations [ set factor factor + hunger ]
  if not any? water-memory-locations [ set factor factor + thirst ]
  if not any? male-memory-locations [ set factor factor + mate ]
  if not any? shade-memory-locations [ set factor factor + fatigue + fear-of-humans ]
  report factor
end


to go-towards-water-initialization-phase [speed]
  set current-need "water"
  set current-need-met? false
  if any? water-memory-locations [
  let nearest-water min-one-of water-memory-locations [distance myself]
  face nearest-water
  ]
  alt-fd-initialization-phase speed
end

to go-towards-food-initialization-phase [speed]
  set current-need "hunger"
  set current-need-met? false
  if any? food-memory-locations [
    let nearest-food min-one-of food-memory-locations [distance myself]
    face nearest-food
  ]
  alt-fd-initialization-phase speed
end

to go-towards-shade-initialization-phase [speed]
  set current-need "fatigue"
  set current-need-met? false
  if any? shade-memory-locations [
  let nearest-shade min-one-of shade-memory-locations [distance myself]
  face nearest-shade
  ]
  alt-fd-initialization-phase speed
end

to go-forward-initialization-phase [speed]
  set current-need "explore"
  set current-need-met? false
  left random 360
  alt-fd-initialization-phase speed
end




;;;;;;; updating speed at which tigers exlore,hunt,,waterevr
;;;;;;; this needs to be fixed


 to-report calculate-base-speed
   let local-base-speed 0

   ;; 1) Old tigers (≥13 years)
   ;;;   at 120 steps (~12 km/day), reflecting reduced mobility.
   ifelse (age-days >= 13 * 365) [
     set local-base-speed 120

   ;; 2) Adults (4–13 years)
   ;; Each patch ~100 m, and you have 1 day per tick,
   ;; so 200 patches/day ≈ 20 km/day. This is within the real‐life range that prime adult tigers may travel.
   ] [
     ifelse (age-days >= 4 * 365) [
       set local-base-speed 200

     ;; 3) Sub-adults (2–4 years), They’re still growing; not quite prime adults but significantly more mobile than juveniles.
     ;; at 130 steps (~13 km/day)
     ] [
       ifelse (age-days >= 2 * 365) [
         set local-base-speed 130  ;; ~13 km/day

       ;; 4) Juveniles (1–2 years)
       ;; Starting to explore, but still rely heavily on mother’s hunts.
       ] [
         ifelse (age-days >= 365) [
           set local-base-speed 60  ;; ~6 km/day

         ;; 5) Cubs (<1 year) => multiple milestones
         ;; From 0 steps as a newborn up to 40 steps by the end of 12 months (~4 km/day).
         ;; Even at 2–3 months (15 steps, ~1.5 km/day),
         ;; it ensures small but nonzero movement if subdivided across needs.
         ] [
           ifelse (age-days < 14) [
             ;; 0–2 weeks old (eyes closed, near 0 movement)
             set local-base-speed 0
           ] [
             ifelse (age-days < 30) [
               set local-base-speed 5   ;; ~2–4 weeks
             ] [
               ifelse (age-days < 60) [
                 set local-base-speed 10   ;; ~1–2 months
               ] [
                 ifelse (age-days < 90) [
                   set local-base-speed 15 ;; ~2–3 months
                 ] [
                   ifelse (age-days < 120) [
                     set local-base-speed 20 ;; ~3–4 months
                   ] [
                     ifelse (age-days < 180) [
                       set local-base-speed 25  ;; ~4–6 months
                     ] [
                       ifelse (age-days < 240) [
                         set local-base-speed 30 ;; ~6–8 months
                       ] [
                         ifelse (age-days < 300) [
                           set local-base-speed 35  ;; ~8–10 months
                         ] [
                           set local-base-speed 40  ;; ~10–12 months
                         ]
                       ]
                     ]
                   ]
                 ]
               ]
             ]
           ]
         ]
       ]
     ]
   ]

  ;; Adjust for gender at the end
  if female = 1 [
    set local-base-speed local-base-speed * 0.9 ;; for females the speed decreases by 10%
  ]
  if female = 0 [
    set local-base-speed local-base-speed * 1.2 ;; for males increase by 20%
  ]

  report local-base-speed
end


to-report calculate-daily-speed [speed]
  let daily-speed speed
  if temperature > 25 [  ; Hot season, reduced by 20%
    set daily-speed daily-speed * 0.8
  ]

  report daily-speed
end

; Call this once per year or when a tiger ages
to update-tiger-base-speed
  set base-speed calculate-base-speed
end

; Call this every day (tick) for each tiger
to update-tiger-daily-speed
  set total-speed calculate-daily-speed base-speed
end

;; This reports the fighting strength, which depends on total speed
;; Total speed represents current vitatlity , Current vitality depends on age, sex, temperature,
;; Here lack of fulfilment of hunger, thirst and fatigue is summed and divided by maximum lack of need fulfilment
;; For example a tiger is fully satisfied , all needs are met hence 0, the penalty will be (0+0+0)/45
;; Then penalty is 0 and fighting strength = total speed
;; if the tiger is about to die then its hunger will be 15, thirst will be 15 and fatigue will be 15, hence penalty will be 1
;; total speed wil then be multiplied by (1- 1) equivalent to no strength to win a fight, increasing probability of death in a fight.
to-report fighting-strength
  let condition-penalty (hunger + thirst + fatigue) / 45
  report total-speed * (1 - condition-penalty)
end

;; this is a logistic scale of winning where the difference in strength does not lead to a liner increase or decrease chance of winning,
;; rather it follows a sigmoid curve of winning.
;; Which means that the probability if higher if the strength differential is bigger.
to-report prob-winning [tiger1 tiger2]
  let strength-diff [fighting-strength] of tiger1 - [fighting-strength] of tiger2
  report 1 / (1 + exp(-0.05 * strength-diff))
end

;; first report if it isfavourable as per temperature to mate, seasonality in mating
to-report shares-litter-id? [ other-tiger ]
  let match? false
  foreach litter-ids [
    id ->
    if member? id [litter-ids] of other-tiger [
      set match? true
    ]
  ]
  report match?
end


;;; update fertility status based on age of the tiger
;;; changed in the flight added and pregnant? false, i.e once pregnant during gestation not available for mating
to update-fertility-status
  ifelse female = 1
  [
    set fertility-age? (age >= 3 and age <= 15)  ; Females are fertile from 3-15 years old
  ]
  [
    set fertility-age? (age >= 4 and age <= 17)  ; Males are fertile from 4-17 years old
  ]
end



to alt-die ;; Need to make age of cubness consistent across functions.
  ;; Check that this agent is a cub
  if age-days < 366  [
    let dead-cub self
    ;; Ask all tigers that are mothers and have this cub in their list
    ask tigers with [ is-mother? and member? ([who] of dead-cub) cubs ] [
      ;; Remove the dead cub's who number from the mother's cub list.
      set cubs remove ([who] of dead-cub) cubs
      ;; If the mother's cub list is now empty, reset her status.
      if empty? cubs [
        set is-mother? false
        set nursing? false
        set exploration 2.0  ; Reset to normal exploration speed/behavior.
      ]
    ]
    ;; Finally, kill this cub.
    set cumulative-cub-mortality cumulative-cub-mortality + 1
    set yearly-cumulative-cub-mortality yearly-cumulative-cub-mortality + 1

    die
  ]
  ;; If not a cub (juveniles and adults), simply call die.
  if age-days >= 366 [
    die
  ]
end




to handle-gestation
  if pregnant? [

    ;; Increment gestation timer
    set gestation-timer gestation-timer + 1

    ;; Gradual reduction in speed and increase in fatigue
    let fraction-of-gestation (gestation-timer / gestation-length)
    set total-speed total-speed * (1 - 0.3 * fraction-of-gestation) ;;; Slow down as pregnancy progresses
    set fatigue fatigue + 0.2  ;; Increased fatigue from physical strain

    ; if near due date, search for birth location more strongly
    if (gestation-length - gestation-timer <= 15) [
      ; raise some "nesting-need" or reassign exploration to 10
      set exploration 2.0
    ]

    ;; Only give birth if we are at or past due date
    ;; AND the mother is in a safe location
    ;; Handle birthing
    if (gestation-timer >= gestation-length) and (is-in-safe-birthing-location?) [
      give-birth
    ]
  ]
end

to-report is-in-safe-birthing-location?
  ;; Mother must be in forest (shade) with known water AND known food nearby
  report (pcolor = black) and (any? water-memory-locations in-radius 5) and (any? food-memory-locations in-radius 10)
end

to give-birth
   set pregnant? false
   set gestation-timer 0
   set is-mother? true
   set exploration 2.0 ;; Reduce exploration during nursing
   set nursing? true
   set nursing-timer 150 ;; 5 months nursing period (literature: lactation ~165 days)
   let new-litter-id (ticks * 1000) + who
   set litter-ids lput new-litter-id litter-ids
   let litter-size random 3 + 2
   set yearly-births yearly-births + litter-size
   hatch litter-size [  ; Create 2-4 cubs
    ;; Reset all "adult-only" variables for cubs
    set litter-ids (list new-litter-id)
    set father [father] of myself
    set is-mother? false
    set pregnant? false
    set nursing? false
    set gestation-timer 0
    set fertility-age? false
    set self-reliance 0  ;; Cub are completely dependent on their mother until they start learning
    set is-cub? true  ;;
    set time-away-from-mother 0 ;; cubs will not spend anytime away from mother in the first few weeks before they can even see.
    set transient? false  ;;; they are not transient to start with

    ;; Memory locations are empty for cubs
    set water-memory-locations no-patches
    set shade-memory-locations no-patches
    set food-memory-locations no-patches
    set male-memory-locations no-patches
    set female-memory-locations no-patches
    set human-memory-locations no-patches


    ;; Initialize cub-specific properties
    set age 0
    set age-days 0
    set base-speed 1
    ;; Assign gender
    ifelse random-float 1 < 0.587 [  ; 58.7% adult females
      set female 1
    ] [
      set female 0
    ]  ;; 50% chance of being female
    set color ifelse-value female = 1 [pink] [blue]  ;; Pink for females, blue for males, easy color nothing to do with stereotypes
    set size 10

    set mother [who] of myself
    set hunger 0 ;; Cubs start with no hunger
    set thirst 0 ;; Cubs start with no thirst
    set fatigue 0 ;; Cubs start rested
    ;set base-speed 0.1 ;; they dont move the very moment they are born
    set exploration 2.0

    ; Initialize diagnostic counters for cubs
    set daily-hunt-attempts 0
    set daily-hunt-successes 0
    set daily-water-visits 0
    set daily-shade-visits 0
    set daily-mating-attempts 0
  ]
set cubs [who] of tigers with [mother = [who] of myself]
  set father -1
end


;;;; Each day, the cub's self-reliance moves closer to 1.0. At 1.0, it's basically fully self‐sufficient.
;;;; You can adjust 0.01 to 0.02 if you want faster growth, or do a random approach.

to grow-cub-behaviors
  ;; This is called daily on any cub
  ;; We'll just increment self-reliance a bit each day.
  set self-reliance min (list (self-reliance + 0.01) 1.0)
end

;;;; We want a reporter that checks resource memory, safety, etc.
;;;; We’ll keep it simple first: requires 3 water patches, 5 food patches, 2 shade.
;;;; If a cub is comfortable because it has enough survival patches that could be used
to-report is-comfortable?
  ;; We'll define some basic resource thresholds:
  let resource-ok (
    (count water-memory-locations >= 3) and
    (count food-memory-locations  >= 5) and
    (count shade-memory-locations >= 2)
  )

  ;; Removed: "safe patch" with no markings requirement
  ;; Cubs can disperse into marked territory (including family territory)
  ;; Biologically, dispersal is driven by mating needs, not territory availability

  ;; Now also require self-reliance e.g. 0.9
  let enough-self (self-reliance >= 0.9)

  let old-enough ( age-days > 730 )
  report (resource-ok and enough-self and old-enough)
end


;;; We want the cub to physically be away from mother for 15 consecutive days,
;;; plus we want high self-reliance, and we want is-comfortable? to be true.
to update-time-away
  if mother != nobody [
    let mom one-of tigers with [who = [mother] of myself]
    if mom != nobody [

      ;; A single `ifelse`:
      ifelse distance mom > 5 [
        ;; If I'm far from mother, then check comfort
      ifelse is-comfortable? [
          set time-away-from-mother time-away-from-mother + 1
        ] [
          set time-away-from-mother 0
        ]
      ] [
        ;; else block of the first ifelse => I'm near mother
        set time-away-from-mother 0
      ]

      ;; If I've been away for 15 days, separate:
      if time-away-from-mother >= 15 [
        separate-from-mother
      ]
    ]
  ]
end

;;; Each day, if the cub is physically > 5 patches from mother,
;;; has self-reliance >= 0.9 (you pick the threshold),
;;; and is “comfortable” with resources, we increment time-away-from-mother.
;;; If it returns or is not comfortable, we reset the counter to 0.
;;; After 15 days, it calls separate-from-mother. hence transient or dispersal is emergent and not hard-coded.
to separate-from-mother
  ;; 1) Remove me from the mother's cub list, if mother is alive & valid
  if mother != nobody [
    let my-mom one-of tigers with [who = [mother] of myself]
    if my-mom != nobody [
      ask my-mom [
        set cubs remove ([who] of myself) cubs
        if empty? cubs [
        set is-mother? false
        set nursing? false
        set exploration 2.0  ; Reset to normal exploration speed/behavior.
      ]
      ]
    ]
  ]

  ;; 2) Clear my mother pointer
  set mother nobody

  ;; 3) Mark me as adult
  set is-cub? false

  ;; 4) Change color to adult color
  ifelse female = 1 [
    set color red  ;; adult female color
    set shape "triangle"
  ] [
    set color yellow   ;; adult male color
    set shape "circle"
  ]

  ;; Optionally print a confirmation
  set cumulative-cub-grownup cumulative-cub-grownup + 1
  set yearly-cumulative-cub-grownup yearly-cumulative-cub-grownup + 1
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;Scenario;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; We assume “uniform” means that across the core region ;;;;;;;;;;;;;;;;;;;;;;;
;;;; (excluding rivers/white buffer zones), ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; you want a constant or near-constant proportion of water, shade, and prey. ;;
;;;; Uniform Distribution of resources  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Example of uniform distribution approach:  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; - 5% chance water ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; - 15% chance shade (black)  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; - 80% remain green ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-uniform-scenario

  ;; First clear or reset patch properties
  ask patches [
    set pcolor green
    set male-marking 9999
    set female-marking 9999
    set male-marking-fading-clock 0
    set female-marking-fading-clock 0
    set prey 0
  ]


  ask patches with [pcolor = green] [
    let r random-float 1
    if r < 0.05 [ set pcolor blue ]         ;; water
    if r >= 0.05 and r < 0.20 [ set pcolor black ] ;; shade
  ]

  ;; Next, set uniform prey distribution, e.g., each green or black patch has a set number of prey
  ask patches with [pcolor = green or pcolor = black] [
  set prey 3  ;; or whatever constant you want
  ]


   ;----------------------------------------------------------
  ; Print stats or store scenario message
  ; This helps you confirm how many patches ended up water
  ; vs shade, etc.  (Check the Command Center for prints.)
  ;----------------------------------------------------------
  let water-patches count patches with [pcolor = blue]
  let shade-patches count patches with [pcolor = black]
  let total-prey sum [prey] of patches

  ;; Store a message for display in a monitor if you like:
  set scenario-message (word "Uniform distribution: "

                             ", water=" water-patches
                             ", shade=" shade-patches
                             ", total prey=" total-prey)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; We assume “clumped ” means that across the core region ;;;;;;;;;;;;;;;;;;;;;;;
;;;; we concentrate water in a few patches, group them together, ;;;;;;;;;;;;;;;;;;
;;;; and place prey in large herds near those water patches. ;;;;;;;;;;;;;;;;;;;;;;
;;;; You can refine the sizes of clusters, the distribution of prey, etc.;;;;;;;;;
;;;; The overall idea is to produce a few big resource “hotspots” that are far apart,
;;;; forcing tigers to converge or compete in those areas. ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-clumped-scenario

  ;----------------------------------------------------------
  ; Define cluster parameters
  ; You can later replace these fixed numbers with sliders if
  ; you want your user to control them.
  ;----------------------------------------------------------
  let number-of-clusters 200
  let cluster-radius 100

  ;----------------------------------------------------------
  ; Pick cluster centers
  ; We'll do a "repeat" loop for each cluster.
  ;----------------------------------------------------------
  repeat number-of-clusters [
  let center-patch one-of patches with [pcolor = green]
  if center-patch != nobody [
    ;; Switch to patch context by asking center-patch:
    ask center-patch [
      ;; 1) color the center
      ifelse random-float 1 < 0.5
        [ set pcolor blue ]
        [ set pcolor black ]

      ;; 2) Now in patch context, we can do "in-radius 3":
      let cluster-area (patch-set self (patches in-radius 5))

      ask cluster-area [
        if random-float 1 < 0.3 [
            ;; only recolor patches that are still green
          if pcolor = green [
          ifelse random-float 1 < 0.5
            [ set pcolor blue ]
            [ set pcolor black ]
          ] ]
        set prey prey + random 100
      ]
    ]
  ]
]


  ;----------------------------------------------------------
  ; Print stats or store scenario message
  ; This helps you confirm how many patches ended up water
  ; vs shade, etc.  (Check the Command Center for prints.)
  ;----------------------------------------------------------
  let water-patches count patches with [pcolor = blue]
  let shade-patches count patches with [pcolor = black]
  let total-prey sum [prey] of patches

  ;; Store a message for display in a monitor if you like:
  set scenario-message (word "Clustered: " number-of-clusters
                             " clusters, radius=" cluster-radius
                             ", water=" water-patches
                             ", shade=" shade-patches
                             ", total prey=" total-prey)
end




to make-central-river

  ifelse num-of-water-channel = "None" [ make-some-waterholes ]

  [

  let river-channel 0

  ifelse num-of-water-channel = "One"
  [ set river-channel 1 ]

  [ ifelse num-of-water-channel = "Two"
    [ set river-channel 2]
    [ set river-channel 6 + random (6 - 4 + 1)]
  ]


  create-turtles river-channel [
    set color blue
    set shape "triangle"
    set size 10
    setxy 0 -192  ;; Start in the center at the top
    face patch 0 191  ;; Face downward
  ]

  ask turtles [
    loop [
      ask patch-here [
        set pcolor blue
        ask neighbors [
          set pcolor blue
        ]
      ]
      left random-normal 0 2  ;; Small random turns for meandering effect
      fd 1
      if not can-move? 1 [ die ]
    ]
    die  ;; Remove the turtle after creating the river
  ]
  ]
end

to make-boundary-river
  ;; Create two river turtles for the boundary effect
  ask patches with [pycor <= 160 AND pycor > 155] [
    set pcolor blue  ;; Buffer Zone
  ]
  ask patches with [pycor >= -161 AND pycor < -154] [
    set pcolor blue  ;; Buffer Zone
  ]
end






;;;;; for dashboard display

to-report count-adult-females
  report count tigers with [female = 1 and age-days >= 365 * 3]
end

to-report count-female-cubs
  report count tigers with [female = 1 and age-days < 366]
end

to-report count-pregnant
  report count tigers with [pregnant? = true]
end

to-report count-mothers
  report count tigers with [is-mother? = true]
end

to-report count-adult-males
  report count tigers with [female = 0 and age-days >= 365 * 3]
end

to-report count-male-cubs
  report count tigers with [female = 0 and age-days < 366]
end

to-report juvenile
  report count tigers with [age-days > 366 AND age-days < 365 * 3]
end

to record-death [cause]
  set death-records lput (list who age cause ticks) death-records
  set yearly-deaths-total yearly-deaths-total + 1
  if cause = "hunger"      [ set yearly-deaths-hunger      yearly-deaths-hunger      + 1 ]
  if cause = "thirst"      [ set yearly-deaths-thirst      yearly-deaths-thirst      + 1 ]
  if cause = "competition" [ set yearly-deaths-competition yearly-deaths-competition + 1 ]
  if cause = "old-age"     [ set yearly-deaths-old-age     yearly-deaths-old-age     + 1 ]
  if cause = "infanticide" [ set yearly-deaths-infanticide yearly-deaths-infanticide + 1 ]

  ;; uncomment the following code to store causes of death in the csv file
  ;;file-open (word "output/BaghSim_death_records_Run" GPScollarfilenum "_" num-of-water-channel ".csv")
  ;;file-print (word ticks "," who "," age "," age-days "," female "," cause)
  ;;file-close

end

to-report count-deaths-by [ cause ]
  ;; "record" is a sublist like [who age cause ticks]
  ;; so item 2 is the cause
  report length filter [ record ->
    item 2 record = cause
  ] death-records
end


to plot-death-causes
  set-current-plot "Cause of Death"

  ;; Plot how many have died so far of Hunger:
  set-current-plot-pen "Hunger"
  plot count-deaths-by "hunger"

  ;; Plot how many have died so far of Thirst:
  set-current-plot-pen "Thirst"
  plot count-deaths-by "thirst"

  ;; Plot how many have died so far of Competition:
  set-current-plot-pen "Competition"
  plot count-deaths-by "competition"

  ;; Plot how many have died so far of Fatigue:
  set-current-plot-pen "Fatigue"
  plot count-deaths-by "fatigue"

  ;; Plot how many have died of Old Age:
  set-current-plot-pen "Old Age"
  plot count-deaths-by "old-age"

  ;; If you have other causes, just repeat...
end




to tiger-population-demographic
  set total-cub count tigers with [ age-days < (365 * 1) ]
  set total-old-tiger count tigers with [ age-days > (365 * 10) ]
  set juvenile-tiger count tigers with [age-days > (365 * 1) AND age-days < (365 * 3)]
  set adult-male-tiger count tigers with [female = 0 AND ( age-days > 365 * 3 ) ]
  set adult-female-tiger count tigers with [ female = 1 AND (age-days > 365 * 3 ) ]
  set total-transient count tigers with [transient? = true]
end

to export-yearly-summary
  let current-pop count tigers
  let lambda-val ifelse-value (previous-year-population > 0) [current-pop / previous-year-population] [0]
  ;; Count tigers at each age 0-18
  let age-counts n-values 19 [ a -> count tigers with [age = a] ]
  let filename (word "output/BaghSim_yearly_summary_Run" GPScollarfilenum "_" num-of-water-channel ".csv")
  let file-is-new? not file-exists? filename
  file-open filename
  if file-is-new? [
    file-print "year,tick,population,adult_males,adult_females,cubs,juveniles,transients,births,deaths_total,deaths_hunger,deaths_thirst,deaths_competition,deaths_old_age,deaths_infanticide,cub_mortality_yearly,cub_grownup_yearly,previous_year_pop,lambda,age_0,age_1,age_2,age_3,age_4,age_5,age_6,age_7,age_8,age_9,age_10,age_11,age_12,age_13,age_14,age_15,age_16,age_17,age_18"
  ]
  file-print (word
    floor (ticks / 365) ","
    ticks ","
    current-pop ","
    adult-male-tiger ","
    adult-female-tiger ","
    total-cub ","
    juvenile-tiger ","
    total-transient ","
    yearly-births ","
    yearly-deaths-total ","
    yearly-deaths-hunger ","
    yearly-deaths-thirst ","
    yearly-deaths-competition ","
    yearly-deaths-old-age ","
    yearly-deaths-infanticide ","
    yearly-cumulative-cub-mortality ","
    yearly-cumulative-cub-grownup ","
    previous-year-population ","
    lambda-val ","
    item 0 age-counts "," item 1 age-counts "," item 2 age-counts ","
    item 3 age-counts "," item 4 age-counts "," item 5 age-counts ","
    item 6 age-counts "," item 7 age-counts "," item 8 age-counts ","
    item 9 age-counts "," item 10 age-counts "," item 11 age-counts ","
    item 12 age-counts "," item 13 age-counts "," item 14 age-counts ","
    item 15 age-counts "," item 16 age-counts "," item 17 age-counts ","
    item 18 age-counts
  )
  file-close
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Procedure to collect overall model statistics ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main data collection procedure to call at regular intervals
to collect-all-data
   export-comprehensive-data

  ;; Only export water locations once (they don't change)
  if ticks = 0 [
    export-landscape-setup
    export-water-data
    export-human-settlement-data
    export-shade-location-data
    export-Prey-location-data
  ]
end

;; Procedure to collect and export comprehensive data about all tigers
to export-comprehensive-data
  ;; Create a descriptive filename
  ;let filename (word word "Run_" current-run "_All_Tiger_comprehensive_data_" num-of-water-channel ".csv")
  let filename "Nov2025_BaghSim_comprehensive_data.csv"
  ;; If this is the first entry, write the header
  ifelse not file-exists? filename [
    file-open filename
    file-print "tick,tiger_id,xcor,ycor,female,age,hunger,thirst,fatigue,fear_of_competitors,fear_of_humans,mate,exploration,total_needs,pregnant,is_mother,is_cub,water_memory_count,food_memory_count,shade_memory_count,alive,death_cause,death_tick"
    file-close
  ] []

  ;; Open file to append data
  file-open filename

  ;; For each living tiger, collect all data and write to file
  ask tigers [
    ;; Safely handle boolean values
    let pregnant-value ifelse-value (is-turtle? self and is-boolean? pregnant?) [pregnant?] [false]
    let mother-value ifelse-value (is-turtle? self and is-boolean? is-mother?) [is-mother?] [false]
    let cub-value ifelse-value (is-turtle? self and is-boolean? is-cub?) [is-cub?] [false]
    let transient-value ifelse-value (is-turtle? self and is-boolean? transient?) [transient?] [false]

    ;; Write data row with alive status
    file-print (word ticks "," who "," xcor "," ycor "," female "," age "," hunger "," thirst "," fatigue ","
                fear-of-competitors "," fear-of-humans "," mate "," exploration "," total-needs ","
                pregnant-value "," mother-value "," cub-value ","
                count water-memory-locations "," count food-memory-locations "," count shade-memory-locations ","
                "true,NA," ticks)  ;; Alive tigers have "true" for alive, "NA" for death_cause
  ]

  ;; Also log any deaths that occurred on this tick
  foreach death-records [ record ->
    if item 3 record = ticks [  ;; If the death occurred on this tick
      file-print (word ticks "," item 0 record "," 0 "," 0 "," "NA" "," item 1 record "," "NA" "," "NA" "," "NA" ","
                  "NA" "," "NA" "," "NA" "," "NA" "," "NA" ","
                  "NA" "," "NA" "," "NA" "," "NA" ","
                  "NA" "," "NA" "," "NA" ","
                  "false," item 2 record "," ticks)  ;; Dead tigers have "false" for alive, and the death cause
    ]
  ]

  file-close
end




to export-landscape-setup
    let filename (word "output/BaghSim_landscape_Run" GPScollarfilenum "_" num-of-water-channel ".csv")
    file-open filename
    file-print "patch_x,patch_y,pcolor,prey"
    ask patches [
      file-print (word pxcor "," pycor "," pcolor "," prey)
    ]

    file-close
  end



;; Procedure to collect and export human-settlemet locations
to export-human-settlement-data
  ;; Create a filename
  let filename (word word "BaghSim_Nov2025_Run_" current-run "_human_settlements_locations_with_number_of_water_channels" num-of-water-channel ".csv")

  ;; Open file and write header
  file-open filename
  file-print "patch_x,patch_y"

  ;; Write data for water patches
  ask patches with [pcolor = white] [
    file-print (word pxcor "," pycor)
  ]

  file-close
end


;; Procedure to collect and export shade locations
to export-shade-location-data
  ;; Create a filename
  let filename (word word "BaghSim_Nov2025_Run_" current-run "_shade_locations_with_number_of_water_channels" num-of-water-channel ".csv")

  ;; Open file and write header
  file-open filename
  file-print "patch_x,patch_y"

  ;; Write data for water patches
  ask patches with [pcolor = black] [
    file-print (word pxcor "," pycor)
  ]

  file-close
end


;; Procedure to collect and export water resource locations
to export-water-data
  ;; Create a filename
  let filename (word word "output/" GPScollarfilenum "BaghSim_Nov2025_Run_" current-run "_water_locations_with_number_of_channels" num-of-water-channel ".csv")

  ;; Open file and write header
  file-open filename
  file-print "patch_x,patch_y"

  ;; Write data for water patches
  ask patches with [pcolor = blue] [
    file-print (word pxcor "," pycor)
  ]

  file-close
end

;; Procedure to collect and export Prey locations
to export-Prey-location-data
  ;; Create a filename
  let filename (word word "BaghSim_Nov2025_Run_" current-run "_Prey_locations_with_number_of_channels" num-of-water-channel ".csv")

  ;; Open file and write header
  file-open filename
  file-print "patch_x,patch_y"

  ;; Write data for water patches
  ask patches with [prey >= 1] [
    file-print (word pxcor "," pycor)
  ]

  file-close
end


to-report time-string
  let current-year floor (ticks / 365) + 1
  let current-day (ticks mod 365) + 1
  report (word "Year " current-year "  Day " current-day)
end


to-report km2-per-patch
  ;; 100 m × 100 m
  report 0.01
end

to-report model-area-km2
  ;; Count *all* non-buffer patches (exclude white)
  report (count patches with [pcolor != white]) * km2-per-patch
end
@#$#@#$#@
GRAPHICS-WINDOW
387
55
957
626
-1
-1
1.464
1
10
1
1
1
0
0
0
1
-192
191
-192
191
0
0
1
ticks
30.0

BUTTON
0
10
73
59
setup
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
184
10
239
56
go
go
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
240
10
295
55
go
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

BUTTON
74
10
183
58
Give Initial Memory
initialize-go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
0
120
388
255
Temperature
tick
temp
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot temperature"

PLOT
960
60
1430
202
Tiger population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count tigers"

PLOT
959
349
1429
490
Needs
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Hunger" 1.0 0 -14439633 true "" "plot global-hunger"
"Thirst" 1.0 0 -14454117 true "" "plot global-thirst"
"Fatigue" 1.0 0 -12895429 true "" "plot global-fatigue"
"Fear of humans" 1.0 0 -955883 true "" "plot global-fear-of-humans"
"Competition" 1.0 0 -8431303 true "" "plot global-fear-of-competitors"
"Mating" 1.0 0 -8630108 true "" "plot global-mate"

INPUTBOX
154
58
262
118
Total-tiger-count
20.0
1
0
Number

PLOT
0
257
387
392
Prey
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot global-prey"

CHOOSER
296
10
406
55
scenario
scenario
"Default" "Uniform" "Clustered"
0

MONITOR
0
394
386
439
Resource Distribution (number of patches)
scenario-message
17
1
11

CHOOSER
264
56
387
101
river-type
river-type
"none" "central" "boundary"
1

PLOT
960
200
1430
350
Cause of Death
NIL
NIL
0.0
50.0
0.0
5.0
true
true
"" ""
PENS
"Hunger" 1.0 0 -15040220 true "" ""
"Thirst" 1.0 0 -14454117 true "" ""
"Fatigue" 1.0 0 -12895429 true "" ""
"Competition" 1.0 0 -6459832 true "" ""
"Old Age" 1.0 0 -2674135 true "" ""

MONITOR
1030
10
1116
55
Adult Female  
adult-female-tiger
17
1
11

MONITOR
958
10
1029
55
Adult Male
adult-male-tiger
17
1
11

MONITOR
1193
10
1267
55
Cubs
total-cub
17
1
11

MONITOR
1267
10
1347
55
Transient 
total-transient
17
1
11

MONITOR
886
10
958
55
Population
count tigers
17
1
11

MONITOR
1117
10
1192
55
In Gestation
count tigers with [pregnant? = true]
17
1
11

CHOOSER
0
59
154
104
num-of-water-channel
num-of-water-channel
"None" "One" "Two" "Many"
2

MONITOR
771
10
884
55
Time
time-string
17
1
11

PLOT
1205
490
1429
627
Proportion male
NIL
NIL
0.0
1000.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (count tigers with [female = 0]) / (count tigers)"

CHOOSER
406
10
539
55
prey-situation
prey-situation
"Prey unaffected" "Prey eaten and not reproducing" "Prey eaten and reproducing"
0

PLOT
959
490
1204
625
Proportion cub mortality
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot cumulative-cub-mortality / ( cumulative-cub-mortality + cumulative-cub-grownup)"

BUTTON
539
10
663
55
Map Tiger movement
ask tigers [pen-down]
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
664
10
769
55
clear movement
clear-drawing\nask tigers [pen-up]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1347
10
1430
55
Juvenile Tiger
juvenile-tiger
17
1
11

@#$#@#$#@
## WHAT IS IT?

BaghSim is an individual-based model simulating tiger behavior, movement, and population dynamics in a spatially explicit environment representing generic tiger habitat with national park, buffer zone, and surrounding areas.

The model employs a comprehensive needs-based behavior system. Each tiger has multiple needs represented by numeric variables: hunger (0-15), thirst (0-15), fatigue (0-15), fear-of-competitors (0-15), fear-of-humans (0-15), mate (0-12), and exploration (fixed at 2.0). These needs change daily and reset upon fulfillment. Tigers allocate energy proportionally to ALL needs simultaneously (not highest-need-first), with available energy scaled by the sum of the two highest needs divided by 30.

Tigers maintain spatial memory of resource locations: water sources (blue patches), shaded rest areas (black patches), prey locations, and locations of other tigers and human settlements. Memory is updated continuously - new resources are added when encountered, and removed when tigers revisit locations where resources are no longer present.

## HOW IT WORKS

**Daily Cycle:** Each tick represents one day. Tigers age daily and may die at 18+ years from old age.

**Needs Processing:** All tigers process needs sequentially with proportional energy allocation:
1. Run away from same-sex competitors (5-patch detection range)
2. Run away from human areas
3. Move toward opposite-sex for mating
4. Go toward water
5. Mark territory (tigers > 700 days old)
6. Go toward shade for rest
7. Go toward food for hunting
8. Explore (directionless need fulfillment)

Mothers additionally return to cubs after each major activity.

**Movement:** Tigers move step-by-step toward targets, allowing opportunistic encounters:
- Water patches reset thirst to zero
- Prey patches trigger hunting (1/6 success rate when hunger > 3)
- Shade patches reset fatigue to zero
- Each step on white (human) patches adds +0.25 fear-of-humans

**Speed Parameters:** (each unit = 100 meters)
- Adults (3+ years): 200 units/day (~20 km/day)
- Sub-adults (1-3 years): 130 units/day (~13 km/day)
- Juveniles (6-12 months): 60 units/day (~6 km/day)
- Old tigers (15+ years): 120 units/day (~12 km/day)
- Cubs: gradually increases from 0 to 40 units/day
- Female modifier: 0.9x (90% of base)
- Male modifier: 1.2x (120% of base)
- Hot weather (>25°C): speed reduced by 20%

**Territorial Marking:** Tigers mark patches by placing their ID on them. Markings are binary (marked or not) and fade after 15 days through daily decrements. Only unmarked patches can be newly marked. Males and females have separate marking systems.

**Reproduction:**
- Females fertile ages 3-15, males fertile ages 4-17
- Males: mating drive increases +0.5/day, capped at 10 (year-round, no seasonal restriction)
- Females: mating drive = 12 during estrus days 0-4 of 41-day cycle, otherwise 0
- Mating occurs when fertile, unrelated tigers share a patch (no probability gate - always succeeds if conditions met)
- Gestation: 100 days
- Litter size: 2-4 cubs
- Cubs develop self-reliance (+0.01/day) and separate from mothers when self-reliance >= 0.9, age > 730 days, and 15+ consecutive days > 500m away

**Mortality:**
- Starvation: death after 15 days without food (hunger > 15)
- Dehydration: death after ~5 days without water (thirst > 15)
- Competition: 10% death probability for fight losers
- Infanticide: males may kill unrelated cubs (50% probability)
- Old age: death at 18+ years

## HOW TO USE IT

1. **Setup Phase:**
   - Set `Total-tiger-count` slider to desired initial population
   - Select `scenario`: Default (procedural with rivers, forests, dirt patches), Uniform (5% water, 15% shade), or Clustered (200 resource hotspots)
   - Set `river-type` (none/central/boundary) and `num-of-water-channel` (None/One/Two/Many where Many = 6-8 channels)
   - Click `setup` to initialize the world
   - Click `Initialize` to let tigers build initial memory of surroundings

2. **Running the Simulation:**
   - Click `go` to run continuously, or click once for single-step
   - Each tick represents one day
   - Monitor population demographics in the interface monitors
   - Use `Map Tiger movement` to visualize movement paths

3. **Output:**
   - GPS coordinate data is saved to the `output/` folder
   - Death records are saved with cause of death
   - Population statistics are displayed in monitors and plots

## THINGS TO NOTICE

- Territory emergence through marking behavior over time
- Population dynamics: births, deaths, dispersal events
- Cubs following mothers and gradually becoming independent
- Male-male competition effects on population structure
- Sex ratio and age distribution changes over time
- How water availability affects tiger distribution and survival

## THINGS TO TRY

- Compare population outcomes with different initial tiger counts
- Test effect of water availability (None vs. Many channels)
- Compare scenarios: Default vs. Uniform vs. Clustered
- Watch individual tigers to understand decision-making
- Run multiple replicates to understand stochastic variation

## LANDSCAPE FEATURES

- Green patches: grasslands (main habitat)
- Blue patches: water sources (rivers, waterholes, and 1000 sprinkled puddles)
- Black patches: dense forests (shade/rest areas)
- Brown patches: open dirt areas (Default scenario only)
- White patches: buffer zone/human settlements (tigers avoid these)
- World boundaries are non-wrapping (immigration/emigration not possible)

## CREDITS AND REFERENCES

BaghSim v0.9.0 - Tiger Population Dynamics Model
Copyright (c) 2024-2026 Dr Indushree Banerjee
Water Management, Civil Engineering and Geosciences, TU Delft

LICENSE: Educational and non-commercial use only. Extensions, modifications, or commercial use require explicit written permission from the author. Contact: i.banerjee@tudelft.nl

Citation: "BaghSim Tiger Population Dynamics Model by Dr Indushree Banerjee, TU Delft"

This model was developed as part of research on tiger conservation and landscape connectivity.
Save The Tiger, Save The Grasslands, Save The Water
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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="33" runMetricsEveryStep="true">
    <setup>setup
initialize-go</setup>
    <go>go</go>
    <timeLimit steps="16425"/>
    <exitCondition>ticks &gt;= 16425</exitCondition>
    <metric>count tigers</metric>
    <metric>count-adult-females</metric>
    <metric>count-adult-males</metric>
    <metric>count-female-cubs</metric>
    <metric>count-male-cubs</metric>
    <metric>count-pregnant</metric>
    <metric>count-mothers</metric>
    <metric>total-transient</metric>
    <metric>cumulative-cub-mortality</metric>
    <metric>cumulative-cub-grownup</metric>
    <metric>length death-records</metric>
    <enumeratedValueSet variable="Total-tiger-count">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;Default&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="river-type">
      <value value="&quot;central&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-water-channel">
      <value value="&quot;None&quot;"/>
      <value value="&quot;One&quot;"/>
      <value value="&quot;Two&quot;"/>
      <value value="&quot;Many&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-situation">
      <value value="&quot;Prey unaffected&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="equilibrium" repetitions="10" runMetricsEveryStep="false">
    <setup>setup
initialize-go</setup>
    <go>go</go>
    <timeLimit steps="73000"/>
    <exitCondition>ticks &gt;= 73000</exitCondition>
    <metric>count tigers</metric>
    <metric>count-adult-females</metric>
    <metric>count-adult-males</metric>
    <metric>total-cub</metric>
    <metric>juvenile-tiger</metric>
    <metric>total-transient</metric>
    <metric>cumulative-cub-mortality</metric>
    <metric>cumulative-cub-grownup</metric>
    <metric>length death-records</metric>
    <enumeratedValueSet variable="Total-tiger-count">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;Default&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="river-type">
      <value value="&quot;central&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-water-channel">
      <value value="&quot;None&quot;"/>
      <value value="&quot;One&quot;"/>
      <value value="&quot;Two&quot;"/>
      <value value="&quot;Many&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-situation">
      <value value="&quot;Prey unaffected&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No-River-Multiple-Tiger-Different-Seed-variability" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
initialize-go</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <exitCondition>ticks &gt;= 365</exitCondition>
    <enumeratedValueSet variable="Total-tiger-count">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-seed">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;Default&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="river-type">
      <value value="&quot;central&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-water-channel">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Boundary-River" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
initialize-go</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <exitCondition>ticks &gt;= 365</exitCondition>
    <enumeratedValueSet variable="Total-tiger-count">
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-seed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;Default&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="river-type">
      <value value="&quot;boundary&quot;"/>
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

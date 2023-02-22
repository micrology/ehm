;extensions [profiler]
;;;
;;; PwC Housing Market model
;;;
;;; written by Nigel Gilbert, n.gilbert@surrey.ac.uk
;;;
;;; Disclaimer
;;; This model has been prepared for general guidance on matters of interest only, and
;;; does not constitute professional advice.  The results are purely illustrative. You
;;; should not act upon any results from this model without obtaining specific professional
;;; advice.  No representation or warranty (express or implied) is given as to the accuracy
;;; or completeness of the model, and, to the extent permitted by law, PricewaterhouseCoopers,
;;; its members, employees and agents accept no liability, and disclaim all responsibility,
;;; for the consequences of you or anyone else acting, or refraining to act, in reliance on
;;; the model or for any decision based on it.
;;;
;;; This Housing Market model was developed by Nigel Gilbert with the assistance of John Hawksworth
;;;   and Paul Sweeney of PricewaterhouseCoopers and is licensed under a
;;;  Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License:
;;;  <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br /><span xmlns:dct="http://purl.org/dc/terms/" property="dct:title">Housing Market model</span> by <a xmlns:cc="http://creativecommons.org/ns#" href="http://cress.soc.surrey.ac.uk/housingmarket/ukhm.html" property="cc:attributionName" rel="cc:attributionURL">Nigel Gilbert</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.
;;;
;;; To refer to this model in academic literature, cite:
;;; Gilbert, N, Hawksworth, J C, and Sweeney, P (2008) 'An Agent-based Model of the UK
;;;   Housing Market'.  University of Surrey http://cress.soc.surrey.ac.uk/housingmarket/ukhm.html
;;;
;;;  version 0    NG 18 October 2007
;;;  version 0.1  NG 09 November 2007
;;;  version 0.2  NG 17 November 2007
;;;  version 0.3  NG 23 November 2007 (bug: new entrants with zero mortgage)
;;;  version 0.4  NG 08 December 2007 (bug: movers not recorded as being in new house;
;;;                                    house prices reduced after no sale; purchasers
;;;                                    only have upper bound limiting offer;
;;;                                    entrants exit after a period if they can't find
;;;                                    a house; realtors add a percentage on to the
;;;                                    average price of local houses in forming their
;;;                                    valuation
;;;  version 0.5  NG 02 January 2008  New processes for realtor valuations and for
;;;                                    making offers
;;;  version 0.6  NG 26 January 2008  Added affordability, interest rate, house
;;;                                    construction, sliders and code
;;;  version 0.61 NG 11 February 2008 Added demolish proc to allow houses to die
;;;  version 0.72 NG 24 March 2008    Redid house valuation to allow for quality
;;;  version 0.8  JH, NG 4 April 2008 Adjusted initial parameters for more realistic
;;;                                    behaviour
;;;               NG 5  April 2008    Added gamma distribution for income, and income
;;;                                    plot
;;;  version 0.9  NG 17 April 2008    Added gini coefficient plot, changed display icons
;;;  version 0.91 NG 18 April 2008    Added mortgage interest/income plot
;;;  version 9.2  NG 19 April 2008    Added time on market plot, v. cheap houses get demolished
;;;  version 10.2 NG 26 May 2008      Added gains from investment, re-did paint houses to
;;;                                    use quantiles,
;;;                                    re-did clustering, made sure realtors did not
;;;                                    over-value
;;;  version 10.4 NG 22 Jun 2008      Added fake realtor records at setup.  Added correct
;;;                                    mortgage interest calculations,
;;;                                    inflation, slider for ticks per year
;;;  version 1.1  NG 22 Jun 2008      Up and down shocks now defined in terms of
;;;                                    Affordability, rather than hardwired numbers
;;;                                    adjusted initial valuations to value houses for
;;;                                    sale at start better
;;;  version 1.2   NG 17 Jul 2008     Dealt with -ve equity, repayments > income, and
;;;                                    further corrections to handling of mortgages.
;;;                                    General tidy up.  This is the version used for the
;;;                                    ESSA paper
;;;  version 1.3  NG 5 Sept 2008       1st time buyers get fixed capital
;;;  version 1.4  NG 6 Sept 2008       Added initial savings slider and disclaimer
;;;  version 1.5  NG 20 Jun 2011       Upgraded to work with NetLogo 1.4.3
;;;  version 1.6  NG 21 Dec 2013       Upgraded to NetLogo 5.0.4 and open sourced under a Creative Commons licence
;;;  version 1.61 NG 24 Jan 2013       Corrected bug introduced in upgrading to NL 5.0.4
;;;  version 1.62 NG  7 Oct 2021       Saved as a NetLogo 6.2.2 model
;;;  version 1.63 NG  7 Oct 2021       Optimisations to make it run faster

globals [
  scenario            ; to illustrate various step changes
  ;; these could become sliders
  initialVacancyRate  ; proportion of empty houses at start
  nRealtors           ; number of realtors
  min-price-fraction  ; if a house price falls below this fraction of the median price, it is demolished

  ; globally accessible variables (mainly here as globals so that they can be plotted)
  moves               ; number of households moving in this step
  interestPerTick     ; interest rate, after cyclical variation has been applied
  nUpshocked          ; number of owners putting their house for sale because their income has risen
  nDownshocked        ; number of owners putting their house for sale because their income has dropped
  nDemolished         ; number of houses demolished in this step
  medianPriceOfHousesForSale ; guess!
  ]

breed [houses house ]      ; a house, may be occupied and may be for sale
breed [owners owner ]      ; a household, may be living in a house, or may be seeking one
breed [realtors realtor ]  ; an estate agent
breed [records record ]    ; a record of a sale, kept by realtors

houses-own [
  my-owner            ; the owner who lives in this house
  local-realtors      ; the local realtors
  quality             ; index of quality of this house relative to its neighbours
  for-sale?           ; whether this house is currently for sale
  sale-price          ; the price of this house (either now, or when last sold)
  date-for-sale       ; when the house was put on the market
  my-realtor          ; if for sale, which realtor is selling it
  offered-to          ; which owner has already made an offer for this house
  offer-date          ; date of the offer (in ticks)
  end-of-life         ; time step when this house will be demolished
  ]

owners-own [
  my-house            ; the house which this owner owns
  income              ; current income
  mortgage            ; value of mortgage - reduces as it is paid off
  capital             ; capital that I have accumulated from selling my house
  repayment           ; my mortgage repayment amount, at each tick
  date-of-purchase    ; when my-house was bought
  made-offer-on       ; house that this owner wants to buy
  homeless            ; count of the number of periods that this owner has been
                      ;  without a house
  ]

realtors-own [
  my-houses           ; the houses in my territory
  sales               ; the last few house sales that I have made
  average-price       ; the average price of a house in my territory
  ]

records-own [         ; object holding a realtor's record of a transaction
  the-house           ; the house that was sold
  selling-price       ; the selling price
  date                ; the date of the transaction (in ticks)
  ]


to setup

  clear-all
  reset-ticks

;; set scenario to illustrate the effect of step changes.  scenario can
;; be one of
;     if scenario = "ltv"  [ set MaxLoanToValue 60 ]
;     if scenario = "ratefall" [ set InterestRate 3 ]
;     if scenario = "influx" [ set EntryRate 10 ]
;     if scenario = "poorentrants" [ set MeanIncome 24000 ]
;     if scenario = "clusters", continue for 400 steps

  set scenario "ratefall"

;; initialise globals
  set initialVacancyRate 0.05
  set nRealtors 6
  set maxHomelessPeriod 5
  set interestPerTick InterestRate / ( TicksPerYear * 100 )
  set min-price-fraction 0.1

  no-display

  ask patches [ set pcolor 57 ] ; muddy green colour

;; create and distribute the realtors (estate agents)

  set-default-shape realtors "cylinder"
  let direction random 360
  create-realtors nRealtors [
    set color yellow
    ; distribute realtors in a rough circle
    set heading direction
    jump (max-pxcor - min-pxcor) / 4
    set direction direction + 120 + random 30
    set size 3
    ; draw a circle to indicate this realtor's territory
    draw-circle RealtorTerritory
    ]

;; create and distribute the houses

  repeat (count patches * Density / 100) [ build-house ]

;; create the owners, one per house

  set-default-shape owners "dot"
  let occupied-houses n-of ((1 - initialVacancyRate) * count houses) houses
  ask occupied-houses [
    set for-sale? false
    hatch-owners 1 [
      set color gray
      set my-house myself
      ask my-house [set my-owner myself ]
      assign-income
      ; if required, artificially impose an income (and therefore a house price) gradient
      ;   on the distribution of house prices
      if InitialGeography = "Gradient" [ set income income * ( xcor + ycor + 50) / 50 ]
      ; set  mortgage to a multiple of my income
      set mortgage income * Affordability / ( interestPerTick * ticksPerYear * 100 )
      ; calculate value of the deposit for this house
      let deposit mortgage * ( 100 /  MaxLoanToValue - 1 )
      ; set value of house to the mortgage + deposit
      ask my-house [ set sale-price [mortgage] of myself + [deposit] of myself ]
      set repayment mortgage * interestPerTick /
                 (1 - ( 1 + interestPerTick ) ^ ( - MortgageDuration * TicksPerYear ))
      ]
    ]

   ; value all empty houses according to average values of local occupied houses
   let median-price median [ sale-price ] of houses with [ sale-price > 0 ]
   ask houses with [ sale-price = 0 ] [
     let local-houses houses with [distance myself < Locality and sale-price > 0]
     ifelse any? local-houses
       [ set sale-price  median [ sale-price ] of local-houses ]
       [ set sale-price  median-price ]
     ]

   if InitialGeography = "Clustered" [ cluster ]

   set medianPriceOfHousesForSale median [sale-price] of houses

   ask houses [
      ; calculate quality index as ratio of this house's price to the median house price
      set quality sale-price / medianPriceOfHousesForSale
      if quality > 3 [set quality 3] if quality < 0.3 [set quality 0.3]
      ]

   ; note the average price of a house in each realtor's territory

   ask realtors [
     set sales []
     set my-houses houses with [member? myself local-realtors ]
     set average-price median [ sale-price ] of my-houses
     ]

    ask houses [
     ; insert fake selling records in the histories of the realtors, so that they have
     ; something to base their step 0 valuations on, and specify an average level of
     ; buyer interest
     let the-record nobody
     hatch-records 1 [
       hide-turtle
       set the-house myself
       set selling-price [ sale-price ] of myself
       set the-record self
       ]
     set my-realtor one-of local-realtors
     ask my-realtor [ file-record the-record ]
     ]

   paint-houses

   display

   do-plots

   reset-ticks

end

to assign-income    ;; owner procedure
;; assigns the income and savings of a new owner
;; uses gamma (alpha, lambda) distribution
;; mean of a gamma distribution = alpha / lambda
; parameters taken from http://www2.physics.umd.edu/~yakovenk/papers/PhysicaA-370-54-2006.pdf
  let alpha 1.3
  let lambda 1 / 20000
  set income 0
  ; avoid impossibly low incomes (i.e. less than half the desired mean income)
  while [ income < MeanIncome / 2 ] [
    set income (MeanIncome * lambda / alpha ) * (random-gamma alpha lambda) *
                      (1 + (Inflation / (TicksPerYear * 100)) ) ^ ticks
    ]
  ; give them a proportion of a year's income as their savings
  set capital income * Savings / 100
end

to build-house     ;; observer procedure
;; add a single house to the town, in a random location
  create-houses 1 [
   ; house turtles are never displayed; instead the patch is used to show the
   ;  presence of a house
   hide-turtle
   ; for speed, dump the house anywhere, check if there is already a house there,
   ;  and if so, move to an empty spot
    move-to one-of patches with [ not any? houses-here ]
    ; assign to a realtor or realtors if in their territory
    set local-realtors realtors with [ distance myself < RealtorTerritory ]
    ; if no realtor, then choose nearest
    if not any? local-realtors [ set local-realtors turtle-set min-one-of realtors [ distance myself ] ]
    put-on-market  ; initially empty houses are for sale
    ; note how long this house will last before it falls down and is demolished
    set end-of-life ticks + int random-exponential ( HouseMeanLifetime * TicksPerYear )
    ]
end

to put-on-market        ;; house procedure
;; show that this house is for sale
    set for-sale? true
    set date-for-sale ticks
end

to draw-circle [radius]    ;; observer procedure
;; draw the circumference of a circle at the given radius
  hatch 1 [
    set pen-size 1 set color yellow set heading -90 fd radius
    set heading 0
    pendown
    while [heading < 359 ] [ rt 1 fd (radius * sin 1)  ]
    die
   ]
end

to paint-houses       ;; observer procedure
;; recolor patches to show the current sale price of houses
; use log sale -price to get a better variation in colour
  let ln-min-price ln [sale-price] of min-one-of houses [sale-price]
  let ln-max-price ln [sale-price] of max-one-of houses [sale-price]
  ask houses [
;    set pcolor palette:scale-scheme "Divergent" "RdYlBu" 10 (ln sale-price) ln-min-price ln-max-price
    set pcolor scale-color red (ln sale-price) ln-min-price ln-max-price
    ]
end

to cluster          ;; observer procedure
;; move the houses (and their owners) so that they are adjacent to other houses in the same
;; price range

  ; repeatedly move houses, so that they get a bit more clustered each time
  repeat 3 [
    ; start by moving houses that are most wrong
    let houses-to-move sort-by [ [?1 ?2] -> price-diff ?1 > price-diff ?2 ] houses
    foreach houses-to-move [ ?1 ->
      ; only move a house if the price difference between it and its local neighbors is
      ; greater than a constant
      if price-diff ?1 > 10000 [
        ; find a vacant patch with neighbours in the right price bracket and move
        ; the house there
        let vacant-plot one-of patches with [ not any? houses-here and
                                  abs (local-price - [sale-price] of ?1) < 10000 ]
        if vacant-plot != nobody [
          ask ?1 [ move-to vacant-plot ]
          ]
        ]
      ]
    ]
    ; make sure the owners are located in their own houses
    ask houses [
      if is-owner? my-owner [ ask my-owner [ move-to myself ] ]
      ]

end

to-report local-price         ;; house procedure
;; report the average price of houses around myself
  let local-houses houses-on neighbors
  ifelse any? local-houses
    [ report median [sale-price] of local-houses ]
    [ report 0 ]
end

to-report price-diff [ a-house ]  ;; house procedure
;; report the difference between my sale price and the prices of other houses around me
  report abs ([sale-price] of a-house - [local-price] of a-house)
end


to go
;; basic loop
   if ticks > 400 [ stop ]
   if ticks = 200 [
     if scenario = "ltv"  [ set MaxLoanToValue 60 ]
     if scenario = "ratefall" [ set InterestRate 3 ]
     if scenario = "influx" [ set EntryRate 10 ]
     if scenario = "poorentrants" [ set MeanIncome 24000 ]
     ]
  ; do one time step (a quarter of a year?)
  step
  ; stop if no owners or houses left
  if not any? owners [ print "Finished: no remaining people" stop ]
  if not any? houses [ print "Finished: no remaining houses" stop ]
  ; update the plots
  do-plots
  ; advance the clock
  tick
end

to step
;;  each time step...

  let n-owners count owners

  ; add an exogenous cyclical interest rate, if required: varies around mean of
  ; the rate set by slider with a fixed period of 10 years

  set interestPerTick InterestRate / ( TicksPerYear * 100 )
  if CycleStrength > 0 [
    set interestPerTick interestPerTick * (1 + (CycleStrength / 100 ) *
                                            sin ( 36 * ticks / TicksPerYear ))
    ]

  ; add inflation to salary, at inflation rate / TicksPerYear
  if Inflation > 0 [
    ask owners [ set income income * (1 + Inflation / ( TicksPerYear * 100 )) ]
    ]

  let owner-occupiers owners with [ is-house? my-house ]

  ; some have an income shock
  let shocked-owners n-of (Shocked * count owner-occupiers / 100) owner-occupiers
  ; either a shock of 20% more income than before
  let upshocked n-of (count shocked-owners / 2) shocked-owners
  set nUpShocked 0
  ask upshocked [ set income income * 1.2 ]
   ; or a shock of 20% less income than before
  let downshocked shocked-owners with [ not member? self upshocked ]
  set nDownShocked 0
  ask downshocked [ set income income * 0.8 ]

  ask owner-occupiers with [ not [for-sale?] of my-house ][
   ; if they are now spending less than half the Affordability ratio of their
   ; income on their mortgage repayments, they want to move up
   let ratio repayment * TicksPerYear / income
   if  ratio < Affordability / 200 [
      ask my-house [ put-on-market ]
      set nUpShocked nUpShocked + 1
      ]
     ; if they are now spending more than twice the Affordability ratio of
     ; their income on their mortgage repayments, they want to move down
   if ratio > Affordability / 50 [
      ask my-house [ put-on-market ]
      set nDownShocked nDownShocked + 1
      ]
   ]

  ; some owners put their houses on the market and leave town
  ask n-of (ExitRate * n-owners / 100) owners with [ is-house? my-house ] [
    ask my-house [
      put-on-market
      set my-owner nobody
      ]
    die
    ]

  ; some new owners arrive
  create-owners EntryRate * n-owners / 100 [
    set color gray
    ; set initial income and savings
    assign-income
    ; give them an initial capital equal to the deposit for the house they could afford
    ; new owners are not located anywhere yet
    hide-turtle
    ]

  ; note that those without houses are homeless for another period, and remove those who
  ; have given up waiting for a house

  if MaxHomelessPeriod  > 0 [ ; after this number of periods, the homeless emigrate
       ask owners with [ not is-house? my-house ] [
         set homeless homeless + 1
         if homeless > maxHomelessPeriod [ die ]
         ]
      ]

  ; those who are paying mortgages greater than their income, are forced to move out
  ; of the housing market and their house is put up for sale

  ask owner-occupiers with [ [for-sale?] of my-house and
                              repayment * TicksPerYear > income ] [
    ask my-house [ set my-owner nobody ]
    die
    ]

  ; some new houses are built, and put up for sale

  repeat count houses * HouseConstructionRate / 100 [
  ; ensure that there are vacant patches before building a house
  ; if there are not, no more houses are built
    if any? patches with [ not any? houses-here ]  [ build-house ]
    ]
  ask houses with [ quality = 0 ] [ ; these are the new houses
      ; calculate quality index as the mean of the qualities of those in the locality
      ; or set to 1 if there aren't any houses around here
      let houses-around-here other houses in-radius Locality
      set quality ifelse-value any? houses-around-here
        [ mean [ quality ] of houses-around-here ]
        [ 1 ]
      if quality > 3 [set quality 3] if quality < 0.3 [set quality 0.3]
      ]

  ; for houses that are newly for sale, get the sale price, which is the highest
  ; valuation offered by local realtors. (Houses that remain for sale,
  ; not having been sold in the previous round, already have a sale price)
  ; Colour the house accordingly.

  let houses-for-sale houses with [ for-sale? ]
  if any? houses-for-sale [
    ask houses-for-sale with [ date-for-sale = ticks ] [
      set my-realtor max-one-of local-realtors [ valuation myself ]
      set sale-price [ valuation myself ] of my-realtor
      ]

    ; update the average selling price of houses in each realtor's territory
    ask realtors [
      let my-houses-for-sale houses-for-sale with [ member? myself local-realtors ]
      if any? my-houses-for-sale [ set average-price median [ sale-price ] of my-houses-for-sale ]
      ]

    set medianPriceOfHousesForSale median [sale-price] of houses-for-sale
    ]

  paint-houses

  ; buyers (new entrants and those wishing to sell) search for a suitable property to buy

  let buyers owners with [ not (is-house? my-house) or ([ for-sale? ] of my-house) ]

  ;; those with nothing to sell get priority in making an offer; i.e. they go first

  ask owners with [ not (is-house? my-house) ] [
    make-offer houses-for-sale
    ]

  ; and now those who do have a house to sell get a chance to make an offer

  ask owners with [ (is-house? my-house) and ([ for-sale? ] of my-house) ] [
    make-offer houses-for-sale
    ]

   ; Check which chains will complete.  A chain of buyers and sellers will complete only
   ;  if the first buyer has nothing to sell, and the last seller has nothing to buy
   ; This means that the first buyer must be a new entrant, and the last house must
   ;  be vacant

   set moves 0
   ask buyers with [ not is-house? my-house and is-house? made-offer-on ] [
     if follow-chain self [
       ; this buyer is the start of a successful chain
       ; call in the removal firm!
       move-house
     ]
   ]

   ; realtors forget any sale records that are too old

   ; kill old records
   ask records [ if date < (ticks - RealtorMemory) [ die ] ]
   ; remove references to outdated records
   ask realtors [ set sales remove nobody sales ]

   ; cancel any outstanding offer

   ask houses with [ is-owner? offered-to ] [
     ask offered-to [ set made-offer-on nobody ]
     set offered-to nobody
     set offer-date 0
     ]

   ; demolish any house that is either at the end of its life or that is no longer
   ;  worth much

   set nDemolished 0
   if any? records [
     let minimum-price min-price-fraction * medianPriceOfHousesForSale

     ask houses with [ (ticks > end-of-life) or
                       (for-sale? and sale-price <  minimum-price )] [ demolish ]
    ]

  ; any house that is still for sale has its price reduced

  ask houses with [ for-sale? ] [
     set sale-price sale-price * (1 - PriceDropRate / 100 )
     ]

  ; owners that have a mortgage have to pay interest and some capital
  ; the mortgage is reduced by the amount of capital repayment
  ask owners with [ is-house? my-house and mortgage > 0 ] [
    set mortgage mortgage - ( repayment - interestPerTick * mortgage )
    ; check if mortgage has now been fully repaid; if so cancel it
    if mortgage <= 0 [
      set mortgage 0
      set repayment 0
      ]
    ]

end

to-report valuation [ property ]    ;; realtor procedure
 ;; A realtor values a property by looking in its records for sales
 ;; that it has made of houses in the locality to use as a guide to the
 ;; value of this property.
 ;; The value of the property is then:
 ;;   the median of the selling prices of these local houses,
 ;;   multiplied by this house's quality index
 ;;   multiplied by an optimism factor
 ;;   multiplied by a normalisation factor.
 ;; If the realtor has no sales in the locality, it bases the price on the
 ;;  median price of all the sale prices of local houses, or if there are
 ;;  none of those either, on the avergae price of all houses in the
 ;;  realtor's territory.

  let multiplier [ quality ] of property *
                  (1 + RealtorOptimism / 100) *
  ;                0.9
 1
  let local-sales (turtle-set sales) with [ ( [distance property ] of the-house ) < Locality ]

  let old-price [sale-price] of property
  let new-price 0
  ifelse any? local-sales
    [ set new-price median [ selling-price ] of local-sales ]
    [ let local-houses houses with [ distance myself <= Locality ]
      ifelse any? local-houses
        [set new-price median [sale-price] of local-houses ]
        [set new-price average-price ]
      ]
  ; if this is a new valuation, return it
  if old-price < 5000 [ report multiplier * new-price ]
  ; otherwise prevent wild changes in price
  let ratio new-price / old-price
  let threshold 2
  ifelse ratio > threshold
    [ set new-price threshold * old-price ]
    [ if ratio < 1 / threshold [  set new-price old-price / threshold ] ]
  report  multiplier * new-price
end

to make-offer [ houses-for-sale ]      ;; owner procedure
  ;;  Search for properties that:
  ;;    is for sale
  ;;    is not already under offer
  ;;    costs no more than my budget
  ;;    is not the house I am already occupying
  ;;  but look at only buyer-search-length number of properties
  ;;  and make an offer on the most expensive of these.
  ;;  But I must have a sufficiently large cash deposit available
  ;;  The realtor notes the interest shown in each of the houses in this subset

  ;; Consider houses costing less than or equal to my budget, but
  ;; not stupidly less
  let upperbound budget

  ; if I am in negative equity, I cannot afford to buy a house and
  ;  will have to remain where I am
  if upperbound < 0 [
    ask my-house [ set for-sale? false ]
    stop
  ]

  let lowerbound upperbound * 0.7
  let current-house my-house

  ;; find the most expensive house I can afford from BuyerSearchLength houses chosen
  ;;  at random from all those on sale
  let most-expensive lowerbound
  let property nobody
  repeat BuyerSearchLength [
    let candidate one-of houses-for-sale
    if not is-owner? [offered-to] of candidate and
    [sale-price] of candidate <= upperbound and
    [sale-price] of candidate > lowerbound and
    candidate != current-house and
    [sale-price] of candidate >= most-expensive [
      set most-expensive [sale-price] of candidate
      set property candidate
    ]
  ]

  ; if I have found a suitable property, place an offer for it
  if is-house? property [
    ask property [
      set offered-to myself
      set offer-date ticks
    ]
    set made-offer-on property
  ]
end

to-report budget
  ;;  My budget for buying a house is the sum of:
 ;;   the value of the mortgage I can get on the new house = affordability * income / interest rate
 ;;   plus the (projected) sale price of my current house
 ;;   minus the amount I need to pay back to the lender for my current mortgage,
 ;;   plus the amount of accumulated capital I have
 ;;   minus any stamp duty payable

  let new-mortgage income * Affordability / ( interestPerTick * ticksPerYear * 100 )
  let mortgage-minus-tax new-mortgage - stamp-duty-land-tax new-mortgage

  let deposit capital
  if is-house? my-house [ set deposit deposit + ([ sale-price ] of my-house - mortgage) ]

  let upperbound mortgage-minus-tax + deposit
  if MaxLoanToValue < 100 [
    set upperbound min ( list (mortgage-minus-tax + deposit ) ( deposit / ( 1 - MaxLoanToValue / 100 )))
  ]
  report upperbound
end

to-report stamp-duty-land-tax [ cost ]
  ;; stamp duty land tax ('stamp duty') is 1% for sales over £150K, 3% over £250K, 4% over
  ;;  £500K,  (see http://www.hmrc.gov.uk/so/rates/index.htm )
  if StampDuty [
    if cost > 500000 [ report 0.04 * cost ]
    if cost > 250000 [ report 0.02 * cost ]
    if cost > 150000 [ report 0.01 * cost ]
    ]
  report 0
end

to-report follow-chain [ first-link ]    ;;  owner procedure
 ;; Find the end of the chain which has my house as a link:
 ;;   find the house I have made an offer for (If none, this chain fails; Stop)
 ;;   find the current owner of that house (If none, this is a successful chain; Stop )
 ;;   find the house they made an offer for ...
 ;; continue until the seller of that house is the first buyer.
 ;;   This is a successful chain; Stop

  if not is-house? made-offer-on [ report false ]
  let seller [ my-owner ] of made-offer-on
  if not (is-owner? seller ) [ report true ]
  if first-link = seller [ report true ]
  report [follow-chain first-link ] of seller
end

to move-house                            ;; owner procedure
 ;; move me to the house I am buying
 ;; then move the seller to their new house etc.

  let new-house made-offer-on
  if not (is-house? new-house) [ stop ]
  let seller [ my-owner ] of new-house
  if is-owner? seller [
    ; seller gets selling price to pay off mortgage or add to capital
    let profit [ sale-price ] of new-house - [ mortgage ] of seller
    ask seller [ set mortgage 0 ]
    if profit > 0 [
      ; seller has made a profit, which is kept as capital
      ask seller [ set capital capital + profit ]
      ]
    ]
  ask new-house [ set my-owner myself ]
  let duty stamp-duty-land-tax [ sale-price ] of new-house
  ifelse [ sale-price ] of new-house > capital
    ; if the owner can't pay for the house in cash, s/he has to have a mortgage
    [
    ; borrow as much as possible, given owner's income and value of house
    set mortgage min (list (income * Affordability /
                                        ( interestPerTick * ticksPerYear * 100 ))
                           ([ sale-price ] of new-house * MaxLoanToValue / 100 ))
    ; pay rest from capital
    set capital capital - int ([ sale-price ] of new-house - mortgage) - duty
    set repayment mortgage * interestPerTick /
            (1 - ( 1 + interestPerTick ) ^ ( - MortgageDuration * TicksPerYear ))
    ]
    ; or if cash buyer, don't need mortgage and use capital
    [
    set mortgage 0
    set repayment 0
    set capital capital - [ sale-price ] of new-house - duty
    ]
  if capital < 0 [ set capital 0 ]
  show-turtle ; new entrants are not visible until now
  move-to new-house ; move owner icon on view
  set homeless 0
  set my-house new-house
  set date-of-purchase ticks
  ask new-house [
    set for-sale? false
    set offered-to nobody
  ]
  set made-offer-on nobody
  ;; update realtor's history with this sale price
  hatch-records 1 [
    hide-turtle
    set date ticks
    set the-house new-house
    set selling-price [sale-price] of new-house
    ask [ my-realtor ] of new-house [ file-record myself ]
    ]
  set moves moves + 1
  if is-owner? seller [ ask seller [ move-house ] ]
end

to file-record [ the-record ]         ;; realtor procedure
  ; push this sales record onto the list of those I keep
  set sales fput the-record sales
end

to unfile-record [ a-house ]          ;; realtor procedure
  ; delete any record that mentions the house
  set sales filter [ ?1 -> [the-house] of ?1 != a-house ] sales
end

to demolish                           ;; house procedure
;; delete the house, but make sure all references to it are dealt with
  ; if anyone lives here, make them homeless
  if is-owner? my-owner [
    ask my-owner [
      set my-house nobody
      ; cancel mortgage
      set mortgage 0
      set repayment 0
      hide-turtle  ; owner is homeless
      ]
    ]
  ; if this house is on a realtor's record, remove the record
  ask realtors [ unfile-record myself ]
  ; turn the land the house was built on back to grass
  set pcolor 57
  ; record the demolition
  set nDemolished nDemolished + 1
  die
end

to-report gini-index [ lst ]
;; reports the gini index of the values in the given list
;; Actually returns the gini coefficient (between 0 and 1) - the
;; gini index is a percentage

  let sorted sort lst
  let total sum sorted
  let items length lst
  let sum-so-far 0
  let index 0
  let gini 0
  repeat items [
    set sum-so-far sum-so-far + item index sorted
    set index index + 1
    set gini  gini + (index / items) - (sum-so-far / total)
  ]
  ; only accurate if items is large
  report 2 * (gini / items)
end



to do-plots
;; draw a range of plots

  let houses-for-sale houses with [ for-sale?  and sale-price > 0 ]
  let houses-sold records

  set-current-plot "Homes"
  set-current-plot-pen "All houses"
  plot count houses
  set-current-plot-pen "Seeking a home"
  plot count owners with [ not is-house? my-house ]
  set-current-plot-pen "Empty houses"
  plot count houses with [ not is-owner? my-owner ]
  set-current-plot-pen "In -ve equity"
  plot count houses with [ is-owner? my-owner and (sale-price  < [mortgage] of my-owner) ]
  set-current-plot-pen "Demolished"
  plot nDemolished

  set-current-plot "People"
  set-current-plot-pen "Population"
  plot count owners
  set-current-plot-pen "10 x Moving up"
  plot 10 * nUpShocked
  set-current-plot-pen "10 x Moving down"
  plot 10 * nDownShocked

  if any? houses-for-sale [
    set-current-plot "House price distribution"
    set-plot-pen-interval 1000
    set-plot-x-range 0 1000000
    set-current-plot-pen "For sale"
    histogram [ sale-price ] of houses-for-sale
    set-current-plot-pen "All"
    histogram [ sale-price ] of houses
    set-current-plot-pen "New sales"
    histogram [ sale-price ] of houses-for-sale with [ date-for-sale = ticks ]
    ]

  if any? owners [
     set-current-plot "Income distribution"
     set-plot-pen-interval 1000
     set-plot-x-range 0 ifelse-value (max [income] of owners > 1E+5) [ 1E+6 ] [ 1E+5 ]
     histogram [ income ] of owners
    ]

  set-current-plot "Median house prices"
  ifelse any? houses-for-sale [
    set-current-plot-pen "For sale"
    plot medianPriceOfHousesForSale
    ]
    [ plot 0 ]
  set-current-plot-pen "Sold"
  let medianSellingPriceOfHouses 0
  if any? houses-sold [ set medianSellingPriceOfHouses median [ selling-price ] of houses-sold ]
  plot medianSellingPriceOfHouses


  set-current-plot "Gini index"
  set-current-plot-pen "Prices"
  if any? houses-sold [ plot gini-index [ selling-price ] of houses-sold ]
  set-current-plot-pen "Incomes"
  if any? owners [ plot gini-index [ income ] of owners ]

  if any? owners [
    set-current-plot "Mortgage repayment / income"
    plot mean [ TicksPerYear * repayment / income ] of owners with [ repayment > 0 ]
    ]

  if any? houses-sold and any? owners[
    set-current-plot "Median house price / Median income"
    plot medianSellingPriceOfHouses / median [ income ] of owners
    ]

  if any? houses-for-sale [
    set-current-plot "Median time on market"
    plot median [ ticks - date-for-sale ] of houses-for-sale
    ]

  set-current-plot "Transactions"
  plot moves

  set-current-plot "Rates"
  set-current-plot-pen "Interest Rate"
  plot interestPerTick * TicksPerYear * 100
  set-current-plot-pen "Inflation Rate"
  plot Inflation

  if any? owners [
     set-current-plot "Capital"
     set-plot-pen-interval 1000
     set-plot-x-range 0 100000
     histogram [ capital ] of owners
     ]
end

;; two procedures to enable large numbers of owners to be added to, or removed from the market
;; for experimentation with the model
;;
;; to use, type into the command centre (for example):  make-owners 500
;;

to make-owners [ n ]
 ;; make some new owners arrive
  create-owners n [
    set color gray
    ; set initial income and savings
    assign-income
    ; new owners are not located anywhere yet
    hide-turtle
    ]
end

to kill-owners [ n ]
 ;; make some owners put their houses on the market and leave town
  ask n-of n owners with [ is-house? my-house ] [
    ask my-house [
      put-on-market
      set my-owner 0
      ]
    die
    ]
end
@#$#@#$#@
GRAPHICS-WINDOW
191
16
683
509
-1
-1
4.0
1
10
1
1
1
0
0
0
1
-60
60
-60
60
0
0
1
ticks
30.0

SLIDER
5
290
175
323
ExitRate
ExitRate
0
10
2.0
1
1
%
HORIZONTAL

SLIDER
5
360
175
393
MeanIncome
MeanIncome
0
100000
37000.0
1000
1
£ pa
HORIZONTAL

SLIDER
5
395
175
428
Shocked
Shocked
0
100
32.0
1
1
%
HORIZONTAL

SLIDER
5
535
175
568
RealtorTerritory
RealtorTerritory
0
50
30.0
1
1
NIL
HORIZONTAL

SLIDER
5
605
177
638
RealtorMemory
RealtorMemory
0
10
10.0
1
1
ticks
HORIZONTAL

SLIDER
180
615
375
648
Density
Density
0
90
70.0
1
1
%
HORIZONTAL

TEXTBOX
18
8
168
36
PwC Housing Market model version 1.63 (for NL 6.3.0)
11
104.0
1

BUTTON
600
570
680
603
Setup
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
600
630
680
663
Go
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

SLIDER
5
325
175
358
EntryRate
EntryRate
0
10
5.0
1
1
%
HORIZONTAL

SLIDER
5
570
175
603
Locality
Locality
0
10
3.0
1
1
NIL
HORIZONTAL

PLOT
695
245
930
370
Median house prices
time
NIL
0.0
10.0
60000.0
80000.0
true
true
"" ""
PENS
"For sale" 1.0 0 -2674135 true "" ""
"Sold" 1.0 0 -13345367 true "" ""

PLOT
930
250
1170
370
Gini index
time
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Incomes" 1.0 0 -16777216 true "" ""
"Prices" 1.0 0 -2674135 true "" ""

PLOT
930
370
1170
490
Median house price / Median income
time
NIL
0.0
10.0
0.0
4.0
true
false
"" ""
PENS
"p/e" 1.0 0 -5825686 true "" ""

PLOT
930
490
1170
610
Transactions
time
Number
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
695
10
930
130
Homes
time
Number
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"All houses" 1.0 0 -13345367 true "" ""
"Empty houses" 1.0 0 -10899396 true "" ""
"Seeking a home" 1.0 0 -2674135 true "" ""
"In -ve equity" 1.0 0 -16777216 true "" ""
"Demolished" 1.0 0 -6459832 true "" ""

SLIDER
5
675
175
708
RealtorOptimism
RealtorOptimism
-10
10
3.0
1
1
%
HORIZONTAL

SLIDER
5
640
175
673
PriceDropRate
PriceDropRate
0
10
3.0
1
1
%
HORIZONTAL

PLOT
930
10
1170
130
People
time
Number
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Population" 1.0 0 -16777216 true "" ""
"10 x Moving up" 1.0 0 -2674135 true "" ""
"10 x Moving down" 1.0 0 -13345367 true "" ""

SLIDER
5
430
175
463
MaxHomelessPeriod
MaxHomelessPeriod
0
10
5.0
1
1
ticks
HORIZONTAL

TEXTBOX
7
463
157
481
0 means no limit
8
0.0
1

SLIDER
5
475
177
508
BuyerSearchLength
BuyerSearchLength
0
100
13.0
1
1
NIL
HORIZONTAL

TEXTBOX
10
515
160
541
---Realtors--
9
0.0
1

TEXTBOX
10
45
160
63
---Macro-economy--
9
0.0
1

TEXTBOX
9
206
159
224
--- Owners--
9
0.0
1

SLIDER
5
95
175
128
InterestRate
InterestRate
1
20
7.0
0.1
1
% pa
HORIZONTAL

SLIDER
5
220
175
253
Affordability
Affordability
0
100
25.0
1
1
%
HORIZONTAL

SLIDER
180
675
442
708
HouseConstructionRate
HouseConstructionRate
0
1
0.3
0.01
1
% per tick
HORIZONTAL

CHOOSER
180
570
375
615
InitialGeography
InitialGeography
"Random" "Gradient" "Clustered"
0

SLIDER
374
569
584
602
HouseMeanLifetime
HouseMeanLifetime
1
500
101.0
1
1
years
HORIZONTAL

SLIDER
5
165
175
198
CycleStrength
CycleStrength
0
80
0.0
5
1
%
HORIZONTAL

PLOT
695
130
930
250
House price distribution
£
Number
0.0
1000000.0
0.0
20.0
true
true
"" ""
PENS
"All" 1.0 1 -16777216 true "" ""
"For sale" 1.0 1 -2674135 true "" ""
"New sales" 1.0 1 -10899396 true "" ""

TEXTBOX
187
550
337
568
---Houses--
11
0.0
1

PLOT
930
130
1170
250
Income distribution
£
Number
0.0
10000.0
0.0
10.0
true
false
"" ""
PENS
"default" 1000.0 1 -16777216 true "" ""

PLOT
695
370
930
490
Mortgage repayment / income
time
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
695
490
930
610
Median time on market
time
ticks
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" ""

SLIDER
375
640
585
673
MortgageDuration
MortgageDuration
0
100
25.0
1
1
years
HORIZONTAL

SLIDER
5
60
175
93
Inflation
Inflation
0
20
0.0
0.1
1
% pa
HORIZONTAL

SLIDER
5
130
175
163
TicksPerYear
TicksPerYear
0
12
4.0
1
1
NIL
HORIZONTAL

PLOT
695
610
930
735
Rates
time
%
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Inflation Rate" 1.0 0 -13345367 true "" ""
"Interest Rate" 1.0 0 -10899396 true "" ""

SLIDER
375
605
585
638
MaxLoanToValue
MaxLoanToValue
0
125
100.0
1
1
%
HORIZONTAL

SWITCH
460
675
584
708
StampDuty
StampDuty
1
1
-1000

BUTTON
600
675
680
708
One Tick
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

PLOT
931
610
1171
735
Capital
£
Number
0.0
100000.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -955883 false "" ""

TEXTBOX
6
198
156
216
10 year exogenous interest rate cycle
8
0.0
1

SLIDER
5
255
175
288
Savings
Savings
0
100
50.0
1
1
%
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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

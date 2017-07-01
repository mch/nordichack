module WorkoutData exposing (workoutListInit)

import Workout exposing (WorkoutListModel)
import Time


{-| Coverts pace in min/km to speed in km/hr
-}
paceToSpeed : Float -> Float
paceToSpeed pace =
    1.0 / pace * 60.0



{- Temporary until this moves to the database -}


workoutListInit : WorkoutListModel
workoutListInit =
    { workoutList =
        [ { title = "Basic"
          , description = Nothing
          , workoutId = 0
          , segments =
                [ { startTime = 0, speed = 4 }
                , { startTime = Time.minute * 2, speed = 8 }
                , { startTime = Time.minute * 28, speed = 4 }
                , { startTime = Time.minute * 30, speed = 0 }
                ]
          }
        , { title = "C5K Week 1"
          , workoutId = 1
          , description = Just "Brisk five-minute warmup walk. Then alternate 60 seconds of jogging and 90 seconds of walking for a total of 20 minutes."
          , segments =
                [ { startTime = 0, speed = 4 }
                , { startTime = Time.minute * 5, speed = 8 }
                , { startTime = Time.minute * 5 + Time.second * 60, speed = 2 }
                , { startTime = Time.minute * 7, speed = 0 }
                ]
          }
        , { title = "Very Short"
          , workoutId = 2
          , description = Just "Test"
          , segments =
                [ { startTime = 0, speed = 4 }
                , { startTime = Time.second * 5, speed = 8 }
                , { startTime = Time.second * 10, speed = 0 }
                ]
          }
          -- NOTE: These workouts are for targeting a 10k time of 00:50
          -- Target race pace is 5 min/km
          -- Easy running pace is 7 km/km
          -- TODO parameterize these runs so that the paces come from the
          -- user profile
        , { title = "Week 1 - Day 2 - Easy Run"
          , workoutId = 3
          , description = Just "Build your endurance for the race"
          , segments =
                [ { startTime = 0, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 40, speed = 0 }
                ]
          }
        , { title = "Week 1 - Day 4 - Fartlek Run"
          , workoutId = 4
          , description = Just "Primary fitness building workout"
          , segments =
                [ { startTime = 0, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 10, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 11, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 12, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 13, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 14, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 15, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 16, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 17, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 18, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 19, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 20, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 21, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 22, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 23, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 24, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 25, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 26, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 27, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 28, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 29, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 45, speed = 0.0 }
                ]
          }
        , { title = "Week 1 - Day 7 - Long Run"
          , workoutId = 5
          , description = Just "Build your endurance for the race"
          , segments =
                [ { startTime = 0, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 60, speed = 0 }
                ]
          }
        , { title = "Week 2 - Day 2 - Easy Run"
          , workoutId = 6
          , description = Just "Build a well of strength"
          , segments =
                [ { startTime = 0, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 40, speed = 0 }
                ]
          }
        , { title = "Week 2 - Day 4 - Fartlek Run"
          , workoutId = 7
          , description = Just "Another pace change workout to build mental toughness"
          , segments =
                [ { startTime = 0, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 15, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 17, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 18, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 20, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 21, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 23, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 24, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 26, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 27, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 29, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 30, speed = paceToSpeed 5.0 }
                , { startTime = Time.minute * 32, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 50, speed = 0.0 }
                ]
          }
        , { title = "Week 2 - Day 7 - Long Run"
          , workoutId = 8
          , description = Just "Build your endurance for the race"
          , segments =
                [ { startTime = 0, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 75, speed = 0 }
                ]
          }
        , { title = "Week 3 - Day 2 - Easy Run"
          , workoutId = 9
          , description = Just "Build your endurance for the race"
          , segments =
                [ { startTime = 0, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 60, speed = 0 }
                ]
          }
        , { title = "Week 3 - Day 4 - Tempo Run"
          , workoutId = 10
          , description = Just "Improve lactate threshold"
          , segments =
                [ { startTime = 0, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 10, speed = paceToSpeed 6.5 }
                , { startTime = Time.minute * 40, speed = 7.0 }
                , { startTime = Time.minute * 55, speed = 7.0 }
                ]
          }
        , { title = "Week 3 - Day 7 - Progression Run"
          , workoutId = 11
          , description = Just "Control effort early to finish strong"
          , segments =
                [ { startTime = 0, speed = paceToSpeed 7.0 }
                , { startTime = Time.minute * 60, speed = paceToSpeed 5.5 }
                , { startTime = Time.minute * 70, speed = 0.0 }
                ]
          }
        ]
    }

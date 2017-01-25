module Common exposing (..)

import Time exposing (Time)


-- Allow for repeating sequences, eg. repeat walk 60 seconds, job 90 seconds, N times.
-- Durations may be better than start times.


type alias WorkoutSegment =
    { startTime : Time
    , speed : Float
    }


type alias WorkoutId =
    Int


type alias Workout =
    -- This might be quite under specified, because it requires the
    -- presence of a sentinal segment with a speed of 0 to know
    -- when the workout is complete, so it's possible to have invalid
    -- workouts. Although, a workout where the user has to explicitly stop
    -- might not be invalid...
    { title : String
    , description : Maybe String
    , workoutId : WorkoutId
    , segments : List WorkoutSegment
    }


type Screen
    = MainMenuScreen
    | ControlPanelScreen
    | WorkoutListScreen


type CommonMsg
    = ChangeScreen Screen

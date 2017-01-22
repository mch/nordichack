module Common exposing (..)

import Time exposing (Time)

type alias WorkoutSegment =
    { startTime : Time
    , speed : Float
    }


type alias Workout =
    { title : String
    , segments : List WorkoutSegment
    }


type Screen
    = MainMenuScreen
    | ControlPanelScreen
    | WorkoutListScreen


type CommonMsg =
    ChangeScreen Screen

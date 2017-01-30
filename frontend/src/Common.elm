module Common exposing (..)

import Time exposing (Time)

type Screen
    = MainMenuScreen
    | ControlPanelScreen
    | WorkoutListScreen


type CommonMsg
    = ChangeScreen Screen

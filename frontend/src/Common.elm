module Common exposing (..)

import Time exposing (Time)

type Screen
    = MainMenuScreen
    | ControlPanelScreen
    | WorkoutListScreen
    | AntScreen


type CommonMsg
    = ChangeScreen Screen

module Main exposing (..)

import ControlPanel
import Html exposing (program)


main =
    Html.program
        { init = ControlPanel.init
        , view = ControlPanel.view
        , update = ControlPanel.update
        , subscriptions = ControlPanel.subscriptions
        }

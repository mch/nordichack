module Ant exposing (init, update, view, subscriptions, Model, Action)

import Html exposing (program, Html, text, div, button)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http exposing (send, request, stringBody, expectString)
import WebSocket exposing (listen)
import FontAwesome
import Color

type alias Model =
    { heartrate : String
    , hostname : String }

type Action
    = Todo
    | Heartrate String

init : String -> (Model, Cmd Action)
init hostname =
    ({ heartrate = "NA", hostname = hostname }, Cmd.none)


subscriptions : Model -> Sub Action
subscriptions model =
    listen ("ws://" ++ model.hostname ++ ":5000/heartrate") Heartrate

update : Action -> Model -> (Model, Cmd Action)
update action model =
    case action of
        Todo -> (model, Cmd.none)
        Heartrate hr -> ({model | heartrate = hr}, Cmd.none)


view : Model -> Html Action
view model =
    div [] [ text "ANT+ Devices..."
           , div [] [ FontAwesome.heartbeat Color.red 20
                    , text ("Current heart rate: " ++ model.heartrate)
                    ]
           ]

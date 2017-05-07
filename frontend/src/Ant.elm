module Ant exposing (init, update, view, subscriptions, Model, Action)

import Html exposing (program, Html, text, div, button)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http exposing (send, request, stringBody, expectString)
import WebSocket exposing (listen)

type alias Model =
    { heartrate : String }

type Action
    = Todo
    | Heartrate String

init : (Model, Cmd Action)
init =
    ({ heartrate = "NA" }, Cmd.none)


subscriptions : Model -> Sub Action
subscriptions model =
    listen "ws://localhost:5000/heartrate" Heartrate

update : Action -> Model -> (Model, Cmd Action)
update action model =
    case action of
        Todo -> (model, Cmd.none)
        Heartrate hr -> ({model | heartrate = hr}, Cmd.none)


view : Model -> Html Action
view model =
    div [] [ text "ANT+ Devices..."
           , text ("Current heart rate: " ++ model.heartrate) ]

module Ant exposing (init, update, view, Model, Action)

import Html exposing (program, Html, text, div, button)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http exposing (send, request, stringBody, expectString)

type alias Model = {}

type Action = Todo

init : (Model, Cmd Action)
init =
    ({}, Cmd.none)

update : Action -> Model -> (Model, Cmd Action)
update action model =
    case action of
        Todo -> (model, Cmd.none)


view : Model -> Html Action
view model =
    text "ANT+ Devices..."

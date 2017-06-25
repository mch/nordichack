module Ant exposing (init, update, view, subscriptions, Model, Action)

import Html exposing (program, Html, text, div, button)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http exposing (send, request, stringBody, expectString)
import Json.Decode exposing (decodeString, maybe, int, field, map3)
import WebSocket exposing (listen)
import FontAwesome
import Color
import Model exposing (HeartData)


type alias Model =
    { heartrate : String
    , hostname : String
    }


type Action
    = Heartrate String


init : String -> ( Model, Cmd Action )
init hostname =
    ( { heartrate = "NA", hostname = hostname }, Cmd.none )


subscriptions : Model -> Sub Action
subscriptions model =
    listen ("ws://" ++ model.hostname ++ ":5000/heartrate") Heartrate


update : Action -> Model -> ( Model, Cmd Action, HeartData )
update action model =
    case action of
        Heartrate hr ->
            ( { model | heartrate = hr }, Cmd.none, decodeHeartData hr )


decodeHeartData : String -> HeartData
decodeHeartData json =
    let
        decoder = map3 HeartData
            (maybe (field "heartrate_bpm" int))
            (maybe (field "rr_interval_ms" int))
            (maybe (field "event_time_ms" int))

        heartdata =
            decodeString decoder json
                |> Result.withDefault { heartrate = Nothing, rrInterval = Nothing, eventTime = Nothing }
    in
        heartdata


view : Model -> Html Action
view model =
    div []
        [ text "ANT+ Devices..."
        , div []
            [ FontAwesome.heartbeat Color.red 20
            , text ("Current heart rate: " ++ model.heartrate)
            ]
        ]

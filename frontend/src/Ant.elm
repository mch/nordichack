module Ant exposing (init, update, view, subscriptions, Model, Action)

import Html exposing (program, Html, text, div, button)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http exposing (send, request, stringBody, expectString)
import Json.Decode exposing (decodeString, maybe, int, float, field, map3)
import WebSocket exposing (listen)
import FontAwesome
import Color
import Model exposing (DataModel, HeartData)
import Plot


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
        decoder =
            map3 HeartData
                (maybe (field "heartrate_bpm" int))
                (maybe (field "rr_interval_ms" int))
                (maybe (field "event_time_s" float))

        heartdata =
            decodeString decoder json
                |> Result.withDefault { heartrate = Nothing, rrInterval = Nothing, eventTime = Nothing }
    in
        heartdata


view : DataModel -> Html Action
view model =
    div []
        [ text "ANT+ Devices..."
        , div []
            [ FontAwesome.heartbeat Color.red 20
            , text ("Current heart rate: " ++ (Maybe.withDefault "--" (Maybe.map toString model.heartdata.heartrate)))
            ]
        , div [ class "rr-plot" ]
            [ Plot.viewSeries [ Plot.line (List.map (\( x, y ) -> Plot.circle x y)) ]
                model.rrIntervalTimeSeries
            ]
        , div [ class "hr-plot" ]
            [ Plot.viewSeries [ Plot.line (List.map (\( x, y ) -> Plot.circle x y)) ]
                model.heartRateSeries
            ]
        ]

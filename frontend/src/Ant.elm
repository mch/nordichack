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

-- This package is no longer available, so the view doesn't work for now.
--import Plot
import Svg exposing (circle)
import Svg.Attributes exposing (color, cx, cy, r, fill, stroke)


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


-- customShortTermRrPlot : Plot.PlotCustomizations msg
-- customShortTermRrPlot =
--     let
--         default =
--             Plot.defaultSeriesPlotCustomizations
--     in
--         { default
--             | width = 640
--             , height = 200
--             --, toDomainLowest = min 700
--             --, toDomainHighest = max 1200
--             , toRangeLowest = \_ -> 0
--             , toRangeHighest = \_ -> 60
--             , margin = { top = 40, right = 40, bottom = 40, left = 80 }
--         }


-- customLongTermRrPlot : Plot.PlotCustomizations msg
-- customLongTermRrPlot =
--     let
--         default =
--             Plot.defaultSeriesPlotCustomizations
--     in
--         { default
--             | width = 640
--             , height = 200
--             --, toDomainLowest = min 700
--             --, toDomainHighest = max 1200
--             , toRangeLowest = \_ -> 0
--             , toRangeHighest = \_ -> 600
--             , margin = { top = 40, right = 40, bottom = 40, left = 80 }
--         }


-- customHrPlot : Plot.PlotCustomizations msg
-- customHrPlot =
--     let
--         default =
--             Plot.defaultSeriesPlotCustomizations
--     in
--         { default
--             | width = 640
--             , height = 200
--             --, toDomainLowest = min 60
--             --, toDomainHighest = max 200
--             , toRangeLowest = \_ -> 0
--             , toRangeHighest = \_ -> 60
--             , margin = { top = 30, right = 40, bottom = 40, left = 80 }
--         }


-- plotPoint : Float -> Float -> Plot.DataPoint msg
-- plotPoint x y =
--     Plot.dot (circle [ r "5", stroke "#a00000", fill "#ff0000" ] []) x y


-- plotSeries : (data -> List (Plot.DataPoint msg)) -> Plot.Series data msg
-- plotSeries f =
--     Plot.customSeries Plot.normalAxis (Plot.Monotone Nothing [ stroke "#a00000" ]) f


-- lastNSeconds : Float -> List ( Float, Float ) -> List (Plot.DataPoint msg)
-- lastNSeconds n data =
--     let
--         (largestTime, _) =
--             List.drop (List.length data - 1) data
--                 |> List.head
--                 |> Maybe.withDefault (0.0, 0.0)


--         offset =
--             if largestTime > n then
--                 largestTime - n
--             else
--                 0.0
--     in
--         List.filter (\( t, v ) -> t > (largestTime - n)) data
--             |> List.map (\( x, y ) -> plotPoint (x - offset) y)


view : DataModel -> Html Action
view model =
    div [] []
--     div []
--         [ text "ANT+ Devices..."
--         , div [ class "hr" ]
--             [ FontAwesome.heartbeat Color.red 20
--             , text (Maybe.withDefault "--" (Maybe.map toString model.heartdata.heartrate))
--             ]
--         , div [ class "rr-plot" ]
--             [ Plot.viewSeriesCustom customShortTermRrPlot
--                 [ plotSeries (lastNSeconds 60) ]
--                 model.rrIntervalTimeSeries
--             ]
--         , div [ class "hr-plot" ]
--             [ Plot.viewSeriesCustom customHrPlot
--                 [ plotSeries (lastNSeconds 60) ]
--                 model.heartRateSeries
--             ]
--         ]

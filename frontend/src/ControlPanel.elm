module ControlPanel exposing (..)

import Html exposing (program, Html, text, div, button)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http exposing (send, request, stringBody, expectString)
import Json.Encode
import Time exposing (Time)
import Workout exposing (..)
import PrintF exposing (..)


speed_increment : Float
speed_increment =
    -- Speed is represented as an integer in increments of 0.2 to avoid
    -- floating point fun.
    0.2


min_speed_increment =
    -- 2 Km/h
    2 * 5


max_speed_increment =
    -- 30 Km/h, 5 increments of 0.2
    30 * 5


initialSpeed =
    2 * 5


controlPanelSubscriptions : ControlPanelModel -> Sub ControlPanelMsg
controlPanelSubscriptions model =
    -- If I used animation timing, I'd be able to display milliseconds
    -- and the distance would be a little more accurate, but at what
    -- cost to power consumption?
    Time.every (Time.second * 0.1) Tick


type alias LogDataPoint =
    { time : Time
    , speed : Int
    }


type alias ControlPanelModel =
    -- This has the possibility of a lot of invalid states. E.g. speed,
    -- currentTime, startTime, and distance are only valid once a workout
    -- has started and the treadmill has responded that it's at a certain speed.
    -- What if start is pressed when it is already running? etc. I've already
    -- had problems with starting a workout when the treadmill is already
    -- running... What if the workout sets the speed to one value, but then
    -- the user overrides? How do we keep track of what the current speed of
    -- the workout is?
    { speed : Int
    , requestedSpeed : Int
    , startTime : Float
    , currentTime : Float
    , distance : Float
    , workout : Maybe Workout
    , nextSegment : Maybe Int
    , error : String
    , log : List LogDataPoint
    }


type ControlPanelMsg
    = Start
    | Stop
    | IncreaseSpeed
    | DecreaseSpeed
    | SetSpeed Int
    | SetSpeedResponse (Result Http.Error String)
    | Tick Time.Time
    | SaveLogResponse (Result Http.Error String)


controlPanelInit : ( ControlPanelModel, Cmd ControlPanelMsg )
controlPanelInit =
    ( { speed = 0
      , requestedSpeed = 0
      , startTime = 0.0
      , currentTime = 0.0
      , distance = 0.0
      , workout = Nothing
      , nextSegment = Nothing
      , error = ""
      , log = []
      }
    , Cmd.none
    )


controlPanelUpdate : ControlPanelMsg -> ControlPanelModel -> ( ControlPanelModel, Cmd ControlPanelMsg )
controlPanelUpdate msg model =
    case msg of
        Start ->
            case model.workout of
                Nothing ->
                    changeSpeed model initialSpeed

                Just w ->
                    getWorkoutSpeed w model
                        |> changeSpeed model

        Stop ->
            changeSpeed model 0

        IncreaseSpeed ->
            increaseSpeed model

        DecreaseSpeed ->
            decreaseSpeed model

        SetSpeed speed ->
            changeSpeed model speed

        SetSpeedResponse result ->
            let
                model2 =
                    updateSpeed model result

                cmd =
                    if model2.speed == 0 then
                        postLog (List.reverse model2.log)
                    else
                        Cmd.none
            in
                ( model2, cmd )

        Tick t ->
            let
                model2 =
                    updateTimeAndDistance model t

                elapsedTime =
                    model.currentTime - model.startTime

                nextSpeed =
                    checkForSpeedChange elapsedTime model.nextSegment model.workout
            in
                Maybe.map (changeSpeed model) nextSpeed
                    |> Maybe.map (\( m, c ) -> ( { m | nextSegment = Maybe.map (\x -> x + 1) m.nextSegment }, c ))
                    |> Maybe.withDefault ( model2, Cmd.none )

        SaveLogResponse result ->
            case result of
                Ok response ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model | error = stringifyError error }, Cmd.none )


updateTimeAndDistance : ControlPanelModel -> Time.Time -> ControlPanelModel
updateTimeAndDistance model t =
    -- This is a rough approximation because the time and speed are both inaccurate.
    -- Speed would have to come from the treadmill, as it takes several seconds for
    -- large changes in speed to occur.
    let
        timeStep =
            if model.startTime > 0 then
                Time.inHours (t - model.currentTime)
            else
                0.0

        startTime =
            if model.startTime == 0 then
                t
            else
                model.startTime
    in
        if model.speed > 0 then
            { model
                | currentTime = t
                , startTime = startTime
                , distance = model.distance + (toFloat model.speed) * speed_increment * timeStep
            }
        else
            model


increaseSpeed : ControlPanelModel -> ( ControlPanelModel, Cmd ControlPanelMsg )
increaseSpeed model =
    let
        requestedSpeed =
            if (model.speed < min_speed_increment) then
                min_speed_increment
            else
                model.speed + 1
    in
        ( { model | requestedSpeed = requestedSpeed }, postSpeedChange requestedSpeed )


decreaseSpeed : ControlPanelModel -> ( ControlPanelModel, Cmd ControlPanelMsg )
decreaseSpeed model =
    let
        requestedSpeed =
            if (model.speed == min_speed_increment) then
                0
            else
                model.speed - 1
    in
        ( { model | requestedSpeed = requestedSpeed }, postSpeedChange requestedSpeed )



{- Did the current workout segment change? If so return the new speed to change to. -}


checkForSpeedChange : Time -> Maybe Int -> Maybe Workout -> Maybe Int
checkForSpeedChange elapsedTime nextSegmentId workout =
    let
        currentSegment =
            Maybe.andThen (getIndex elapsedTime) workout

        computeNextSpeed w =
            getSpeed elapsedTime w
                |> (\x -> x / speed_increment)
                |> round

        nextSpeed =
            Maybe.map computeNextSpeed workout
                |> Maybe.withDefault 0

        compareSegmentIds c n =
            if c >= n then
                Just nextSpeed
            else
                Nothing
    in
        Maybe.map2 compareSegmentIds currentSegment nextSegmentId
            |> Maybe.withDefault Nothing


updateSpeed : ControlPanelModel -> Result Http.Error String -> ControlPanelModel
updateSpeed model result =
    let
        starting =
            model.speed == 0 && model.requestedSpeed /= 0

        stopping =
            model.speed /= 0 && model.requestedSpeed == 0

        updateModel =
            if starting then
                -- Have to check response...
                { model
                    | speed = model.requestedSpeed
                    , startTime = 0.0
                    , currentTime = 0.0
                    , distance = 0.0
                    , error = ""
                    , log = [ LogDataPoint 0.0 model.requestedSpeed ]
                }
            else
                { model
                    | speed = model.requestedSpeed
                    , error = ""
                    , log = LogDataPoint (model.currentTime - model.startTime) model.requestedSpeed :: model.log
                }
    in
        case result of
            Ok response ->
                updateModel

            Err error ->
                { model | requestedSpeed = model.speed, error = stringifyError error }


stringifyError error =
    case error of
        Http.BadUrl s ->
            "Bad URL: " ++ s

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "Network Error"

        Http.BadStatus r ->
            "Bad status"

        Http.BadPayload s r ->
            "Bad payload"


changeSpeed model speed =
    validateRequestedSpeed speed
        |> Maybe.map (\x -> { model | requestedSpeed = x })
        |> Maybe.map (\x -> ( x, postSpeedChange x.requestedSpeed ))
        |> Maybe.withDefault ( { model | error = invalidSpeedErrorMessage initialSpeed }, Cmd.none )


invalidSpeedErrorMessage speed =
    "Invalid speed " ++ (formatSpeed ((toFloat speed) * speed_increment)) ++ " requested."


getWorkoutSpeed w model =
    round (getSpeed (model.currentTime - model.startTime) w / speed_increment)


validateRequestedSpeed : Int -> Maybe Int
validateRequestedSpeed requestedSpeed =
    if
        requestedSpeed
            == 0
            || (requestedSpeed
                    >= min_speed_increment
                    && requestedSpeed
                    <= max_speed_increment
               )
    then
        Just requestedSpeed
    else
        Nothing


postSpeedChange : Int -> Cmd ControlPanelMsg
postSpeedChange requestedSpeed =
    let
        req =
            Http.request
                { method = "POST"
                , headers = []
                , url = "/api/v1/desiredspeed"
                , body = (stringBody "text/plain" (toString ((toFloat requestedSpeed) * speed_increment)))
                , expect = expectString
                , timeout = Just (Time.second * 2.5)
                , withCredentials = False
                }
    in
        Http.send (\r -> SetSpeedResponse r) req


postLog : List LogDataPoint -> Cmd ControlPanelMsg
postLog log =
    let
        encodeEntry e =
            Json.Encode.object
                [ ( "time", Json.Encode.float e.time )
                , ( "speed", Json.Encode.int e.speed )
                ]

        encodedLog =
            Json.Encode.list (List.map encodeEntry log)

        req =
            Http.request
                { method = "POST"
                , headers = []
                , url = "/api/v1/runs"
                , body = Http.jsonBody encodedLog
                , expect = expectString
                , timeout = Just (Time.second * 2.5)
                , withCredentials = False
                }
    in
        Http.send (\r -> SaveLogResponse r) req


controlPanelView : ControlPanelModel -> Html ControlPanelMsg
controlPanelView model =
    div
        [ class "cpanel" ]
        [ viewCpanelReadout model
        , viewCpanelWorkout model.requestedSpeed (model.currentTime - model.startTime) model.workout
        , viewCpanelSpeedButtons
        , viewCpanelPresetButtons
        , viewCpanelStartStopButtons
        , div [] [ text model.error ]
        ]


viewCpanelReadout model =
    div
        [ class "cpanel-readout" ]
        [ div
            [ class "cpanel-readout-speed" ]
            [ text ((formatSpeed ((toFloat model.speed) * speed_increment)) ++ " km/h") ]
        , div
            [ class "cpanel-readout-time" ]
            [ text (formatTime (model.currentTime - model.startTime)) ]
        , div
            [ class "cpanel-readout-distance" ]
            [ text (formatDistance model.distance) ]
        ]


viewCpanelSpeedButtons =
    div
        [ class "cpanel-buttons" ]
        [ button
            [ class "cpanel-button"
            , onClick IncreaseSpeed
            ]
            [ text "+" ]
        , button
            [ class "cpanel-button"
            , onClick DecreaseSpeed
            ]
            [ text "-" ]
        ]


viewCpanelPresetButtons =
    div
        []
        [ button
            [ class "cpanel-preset-button"
            , onClick (SetSpeed 10)
            ]
            [ text "2" ]
        , button
            [ class "cpanel-preset-button"
            , onClick (SetSpeed 20)
            ]
            [ text "4" ]
        , button
            [ class "cpanel-preset-button"
            , onClick (SetSpeed 30)
            ]
            [ text "6" ]
        , button
            [ class "cpanel-preset-button"
            , onClick (SetSpeed 40)
            ]
            [ text "8" ]
        , button
            [ class "cpanel-preset-button"
            , onClick (SetSpeed 50)
            ]
            [ text "10" ]
        , button
            [ class "cpanel-preset-button"
            , onClick (SetSpeed 60)
            ]
            [ text "12" ]
        ]


viewCpanelStartStopButtons =
    div
        []
        [ button
            [ class "cpanel-start-button"
            , onClick Start
            ]
            [ text "Start" ]
        , button
            [ class "cpanel-stop-button"
            , onClick Stop
            ]
            [ text "Stop" ]
        ]


viewCpanelWorkout : Int -> Time -> Maybe Workout -> Html ControlPanelMsg
viewCpanelWorkout speed currentTime workout =
    let
        remainingSegments =
            case workout of
                Nothing ->
                    []

                Just workout ->
                    List.filter (\s -> s.startTime >= currentTime) workout.segments

        nextSegment =
            List.head remainingSegments

        nextSegmentInfo =
            case nextSegment of
                Nothing ->
                    [ div
                        [ class "cpanel-workout" ]
                        [ if speed > 0 then
                            text "Your workout has no end. Touch stop when you get tired."
                          else
                            text "You did it!"
                        ]
                    ]

                Just segment ->
                    if List.length remainingSegments > 1 && segment.speed > 0 then
                        [ div [ class "cpanel-workout" ] [ text ("Next Speed: " ++ ((formatSpeed segment.speed) ++ " km/h")) ]
                        , div [ class "cpanel-workout" ] [ text ("In: " ++ (formatTime (segment.startTime - currentTime))) ]
                        ]
                    else
                        [ div [ class "cpanel-workout" ] [ text "You are almost done!" ]
                        , div [ class "cpanel-workout" ] [ text ((formatTime (segment.startTime - currentTime)) ++ " to go!") ]
                        ]
    in
        case workout of
            Nothing ->
                div [] []

            Just w ->
                div
                    [ class "cpanel-workout" ]
                    ((div [ class "cpanel-workout" ] [ (text w.title) ]) :: nextSegmentInfo)


formatInt : Int -> String
formatInt n =
    -- This needs to be genericized to allow for any number of leading zeros,
    -- and other things.
    if n < 10 then
        "0" ++ (toString n)
    else
        toString n


formatTime : Time.Time -> String
formatTime ms =
    let
        hours =
            floor (Time.inHours ms)

        minutes =
            floor (Time.inMinutes (ms - (toFloat hours) * Time.hour))

        seconds =
            floor (Time.inSeconds (ms - (toFloat hours) * Time.hour - (toFloat minutes) * Time.minute))

        times =
            if hours > 0 then
                [ hours, minutes, seconds ]
            else
                [ minutes, seconds ]
    in
        List.map formatInt times
            |> String.join ":"


formatDistance : Float -> String
formatDistance d =
    formatFloat d 3 ++ " km"


formatSpeed : Float -> String
formatSpeed speed =
    let
        -- My vocabulary is failing me
        firstPart =
            floor speed

        secondPart =
            floor ((speed - (toFloat firstPart)) * 10)
    in
        (toString firstPart) ++ "." ++ (toString secondPart)

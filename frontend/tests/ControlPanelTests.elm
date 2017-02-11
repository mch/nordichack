module ControlPanelTests exposing (..)

import Test exposing (..)
import Expect
import Http
import Fuzz exposing (list, int, tuple, string)
import String


import ControlPanel exposing (..)
import Workout exposing (..)

all : Test
all =
    describe
        "Control Panel Test Suite"
        [ checkForSpeedChangeTests
        , speedChangesAreLogged
        --, endingRunSubmitsLog
        , formatDistanceTests
        ]

fixture =
    let
        title = "Test"
        description = Nothing
        id = 0
        initialSpeed = 2
        workout = fromIntervalDuration title description id initialSpeed [(10, 4), (20, 0)]
        firstSegmentId = getIndex 0 workout
        nextSegmentId = Maybe.map (\x -> x + 1) firstSegmentId
    in
        { title = title
        , description = description
        , id = id
        , initialSpeed = initialSpeed
        , workout = Just workout
        , firstSegmentId = firstSegmentId
        , nextSegmentId = nextSegmentId
        }

checkForSpeedChangeTests : Test
checkForSpeedChangeTests =
    describe "Checking for speed changes works"
        [ test "Change to the inital speed at t = 0" <|
            \_ ->
                checkForSpeedChange 0 (Just 0) fixture.workout
                |> Expect.equal (Just 10)
        , test "No speed change in current segment" <|
            \_ ->
                checkForSpeedChange 5 fixture.nextSegmentId fixture.workout
                |> Expect.equal Nothing
        , test "Change speed entering 2nd segment" <|
            \_ ->
                checkForSpeedChange 10 fixture.nextSegmentId fixture.workout
                |> Expect.equal (Just 20)
        , test "No speed change in 2nd segment" <|
            \_ ->
                checkForSpeedChange 19 (Just 2) fixture.workout
                |> Expect.equal Nothing
        , test "Change speed entering last segment" <|
            \_ ->
                checkForSpeedChange 20 (Just 2) fixture.workout
                |> Expect.equal (Just 0)
        ]

speedChangesAreLogged : Test
speedChangesAreLogged =
    describe "Speed changes are logged for a run"
        [ test "First response logs a speed change" <|
            \_ ->
                let
                    ( model, _ ) = controlPanelInit
                in
                    updateSpeed { model | requestedSpeed = 2 } (Result.Ok "OK")
                    |> .log
                    |> Expect.equalLists [{ time = 0, speed = 2 }]
        , test "Response after start logs a speed change" <|
            \_ ->
                let
                    -- Does Elm have threadable record updates? Or is this what people
                    -- keep complaining about.
                    ( model1, _ ) = controlPanelInit
                    model2 = { model1
                        | log = [ LogDataPoint 0.0 2 ]
                        , startTime = 0
                        , currentTime = 2
                        , requestedSpeed = 4
                        , speed = 2 }
                in
                    updateSpeed model2 (Result.Ok "OK")
                    |> .log
                    |> Expect.equalLists [ {time = 2, speed = 4}, {time = 0, speed = 2} ]
        ]

{-endingRunSubmitsLog : Test
endingRunSubmitsLog =
    describe "Logged data points are submitted to server when run ends."
        [ test "Stop is touched" <|
            \_ ->
                let
                    ( model1, _ ) = controlPanelInit
                    model2 = { model1 | log = [LogDataPoint 3 3, LogDataPoint 2 2, LogDataPoint 1 1, LogDataPoint 0 2] }
                    ( _, cmd ) = controlPanelUpdate Stop model2
                in
                    -- Not sure how to compare Cmd for equality... I guess I have to unit test
                    -- before things turn into Cmd's? So that means that update functions
                    -- can't be tested for returned Cmd's?
                    Expect.equal (SaveLogResponse (Result.Ok "OK")) cmd
        {-, test "Workout ends" <|
            \_ ->
                let
                    ( model1, _ ) = controlPanelInit
                    model2 = { model1 | log = [LogDataPoint 3 3, LogDataPoint 2 2, LogDataPoint 1 1, LogDataPoint 0 2] }
                    ( _, cmd ) = controlPanelUpdate Stop model2
                in
                    Expect.equal Nothing cmd
        -}
        , test "Failure to store log show error message" <|
            \_ ->
                let
                    ( model1, _ ) = controlPanelInit
                    model2 = { model1 | log = [LogDataPoint 3 3, LogDataPoint 2 2, LogDataPoint 1 1, LogDataPoint 0 2] }
                    ( model3, _ ) = controlPanelUpdate (SaveLogResponse (Result.Err Http.Timeout)) model2
                in
                    Expect.equal "Timeout" model3.error
        ]
-}

formatDistanceTests =
    describe "Distances are formatted as strings properly"
        [ test "thousandths" <| \_ -> Expect.equal "0.001 km" <| formatDistance 0.001
        , test "hundredths" <| \_ -> Expect.equal "0.010 km" <| formatDistance 0.01
        , test "tenths" <| \_ -> Expect.equal "0.100 km" <| formatDistance 0.1
        , test "ones" <| \_ -> Expect.equal "1.000 km" <| formatDistance 1.0
        , test "tens" <| \_ -> Expect.equal "10.000 km" <| formatDistance 10.0
        ]

module ControlPanelTests exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String

import ControlPanel exposing (..)
import Workout exposing (..)

all : Test
all =
    describe
        "Control Panel Test Suite"
        [ checkForSpeedChangeTests
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

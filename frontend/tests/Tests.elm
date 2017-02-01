module Tests exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String

import Workout exposing (..)

all : Test
all =
    describe
        "Workout Test Suite"
        [ getIndexTests
        , getSpeedTests
        , getSegmentTests
        ]

getIndexTests : Test
getIndexTests =
    describe "Getting current index works as expected"
        [ test "?? at t = -1" (getIndexTest -1 Nothing)
        , test "first segment at t = 0" (getIndexTest 0 (Just 0))
        , test "first segment at t = 5" (getIndexTest 5 (Just 0))
        , test "2nd segment at t = 10" (getIndexTest 10 (Just 1))
        , test "2nd segment at t = 15" (getIndexTest 15 (Just 1))
        , test "3rd segment at t = 20" (getIndexTest 20 (Just 2))
        , test "3rd segment at t = 21" (getIndexTest 21 (Just 2))
        ]

getSpeedTests : Test
getSpeedTests =
    let
        w = fromIntervalDuration "Test" Nothing 0 2 [(10, 4), (20, 0)]
    in
        describe "Getting current speed works as expected"
            [ test "speed at t = 0" (getSpeedTest w 0 2)
            , test "speed at t = 5" (getSpeedTest w 5 2)
            , test "speed at t = 10" (getSpeedTest w 10 4)
            , test "speed at t = 15" (getSpeedTest w 15 4)
            , test "speed at t = 20" (getSpeedTest w 20 0)
            ]

getSegmentTests : Test
getSegmentTests =
    let
        w = fromIntervalDuration "Test" Nothing 0 2 [(10, 4), (20, 0)]
    in
        describe "Getting a segment works"
            [ test "First segment" (getSegmentTest 0 w (Just { startTime = 0, speed = 2 }))
            , test "Second segment" (getSegmentTest 10 w (Just { startTime = 10, speed = 4 }))
            , test "-1 segement" (getSegmentTest -1 w Nothing)

            ]

getIndexTest : Float -> Maybe Int -> (() -> Expect.Expectation)
getIndexTest t e =
    let
        endSegmentTime = 20
        workout = fromIntervalDuration "Test" Nothing 0 2 [(10, 4), (endSegmentTime, 0)]

        index = getIndex t workout
    in
        \() -> Expect.equal e index

getSpeedTest w t e =
    \() -> Expect.equal e (getSpeed t w)

getSegmentTest w t e =
    \() -> Expect.equal e (getSegment w t)

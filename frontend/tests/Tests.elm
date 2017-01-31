module Tests exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String

import Workout exposing (..)

all : Test
all =
    describe "Workout Test Suite"
        [ test "first segment at t = 0" (getIndexTest 0 0)
        , test "first segment at t = 5" (getIndexTest 5 0)
        , test "2nd segment at t = 10" (getIndexTest 10 1)
        , test "2nd segment at t = 15" (getIndexTest 15 1)
        , test "3rd segment at t = 20" (getIndexTest 20 2)
        , test "speed at t = 0" (getSpeedTest 0 2)
        , test "speed at t = 5" (getSpeedTest 5 2)
        , test "speed at t = 10" (getSpeedTest 10 4)
        , test "speed at t = 15" (getSpeedTest 15 4)
        , test "speed at t = 20" (getSpeedTest 20 0)
        ]

getIndexTest t e =
    let
        endSegmentTime = 20
        workout = fromIntervalDuration "Test" Nothing 0 [(0, 2), (10, 4), (endSegmentTime, 0)]

        index = getIndex t workout
    in
        case index of
            Nothing ->
                \() ->
                    if t >= endSegmentTime then
                        Expect.equal e 0
                    else
                        Expect.fail "Didn't expect nothing!"

            Just i ->
                \() -> Expect.equal e i

getSpeedTest t e =
    let
        workout = fromIntervalDuration "Test" Nothing 0 [(0, 2), (10, 4), (20, 0)]
    in
        \() -> Expect.equal e (getSpeed t workout)

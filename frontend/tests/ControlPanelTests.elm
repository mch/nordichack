module ControlPanelTests exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String

import ControlPanel exposing (..)

all : Test
all =
    describe
        "Control Panel Test Suite"
        [ segmentSpeedChange
        ]

segmentSpeedChange : Test
segmentSpeedChange =
    test "change to next speed" (\() -> Expect.fail "Fail")

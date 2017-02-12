module Tests exposing (..)

import Test exposing (..)

import WorkoutTests
import ControlPanelTests
import PrintFTests

all : Test
all =
    describe
        "NordicHack"
        [ WorkoutTests.all
        , ControlPanelTests.all
        , PrintFTests.all
        ]

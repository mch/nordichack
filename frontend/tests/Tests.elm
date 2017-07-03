module Tests exposing (..)

import Test exposing (..)

import WorkoutTests
import ControlPanelTests
import PrintFTests
import FftTests

all : Test
all =
    describe
        "NordicHack"
        [ WorkoutTests.all
        , ControlPanelTests.all
        , PrintFTests.all
        , FftTests.all
        ]

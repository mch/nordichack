module Tests exposing (..)

import Test exposing (..)

import WorkoutTests
import ControlPanelTests

all : Test
all =
    describe
        "NordicHack"
        [ WorkoutTests.all
        , ControlPanelTests.all
        ]

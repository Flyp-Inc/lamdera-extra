module Col exposing (..)

import Dict
import Task
import Time


type Col a
    = Col ( Time.Posix, a, Dict.Dict Int a )


init : Time.Posix -> a -> Col a
init time value =
    Col ( time, value, Dict.empty )


cons : Time.Posix -> a -> Col a -> Col a
cons t v (Col ( time, value, dict )) =
    Col ( t, v, Dict.insert (Time.posixToMillis time) value dict )

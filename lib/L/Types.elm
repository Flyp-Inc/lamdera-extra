module L.Types exposing (..)

import Time


type TimestampMsg msg
    = GotMsg msg
    | GotMsgWithTimestamp msg Time.Posix

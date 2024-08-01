module L.Types exposing (TimestampMsg(..))

import Time


type TimestampMsg msg
    = GotMsg msg
    | GotMsgWithTimestamp msg Time.Posix

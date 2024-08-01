module L.Types exposing (TimestampMsg(..))

{-| There's not much here, but it's nice to have it in here to keep the API between `lamdera init` and `lamdera-extra` as close as possible.

@docs TimestampMsg

-}

import Time


{-| Wrapper message type that facilitates getting a timestamp for each message that is processed.

In your application's `Types.elm` file, you'll need to update it like so:

    module Types exposing (..)

    import L.Types

    {-| this gives the Lamdera compiler the `Types.FrontendMsg` type that it's expecting
    -}
    type alias FrontendMsg =
        L.Types.TimestampMsg Msg

    {-| This is just your old `Types.FrontendMsg` type, renamed to `Msg`
    -}
    type Msg
        = ...

    type alias BackendMsg =
        L.Types.TimestampMsg Bsg

    type Bsg
        = ...

-}
type TimestampMsg msg
    = GotMsg msg
    | GotMsgWithTimestamp msg Time.Posix

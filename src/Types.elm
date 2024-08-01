module Types exposing (..)

import Browser
import Browser.Navigation
import Counter
import L.Types
import Time
import Url


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , message : String
    , counterModel : Counter.Model
    }


type alias BackendModel =
    { message : String
    , counterBodel : Counter.Bodel
    }


type alias FrontendMsg =
    L.Types.TimestampMsg Msg


type Msg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg
    | GotCounterMsg Counter.Msg


type ToBackend
    = NoOpToBackend
    | CounterToBackend Counter.ToBackend


type alias BackendMsg =
    L.Types.TimestampMsg Bsg


type Bsg
    = NoOp
    | GotCounterBsg Counter.Bsg


type ToFrontend
    = NoOpToFrontend
    | CounterToFrontend Counter.ToFrontend

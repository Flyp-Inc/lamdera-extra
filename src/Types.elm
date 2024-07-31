module Types exposing (..)

import Browser
import Browser.Navigation
import L.Types
import Time
import Url


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , message : String
    }


type alias BackendModel =
    { message : String
    }


type alias FrontendMsg =
    L.Types.TimestampMsg Msg


type Msg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg


type ToBackend
    = NoOpToBackend


type alias BackendMsg =
    L.Types.TimestampMsg Bsg


type Bsg
    = NoOp


type ToFrontend
    = NoOpToFrontend

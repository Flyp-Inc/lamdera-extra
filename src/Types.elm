module Types exposing (..)

import Browser
import Browser.Navigation
import Time
import Url


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , message : String
    }


type alias BackendModel =
    { message : String
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg


type ToBackend
    = NoOpToBackend


type alias BackendMsg =
    ( Bsg, Maybe Time.Posix )


type Bsg
    = NoOp


type ToFrontend
    = NoOpToFrontend

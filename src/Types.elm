module Types exposing (..)

import BirdSighting
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
    , birdSightings : BirdSighting.Table
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg


type ToBackend
    = SawABird { species : String, location : String }


type alias BackendMsg =
    ( Bsg, Maybe Time.Posix )


type Bsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend

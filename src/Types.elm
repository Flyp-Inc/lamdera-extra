module Types exposing (..)

import Browser
import Browser.Navigation
import Counter
import L.Types
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
    | GotCounterMsg Counter.Msg


type ToBackend
    = NoOpToBackend
    | CounterToBackend Counter.ToBackend


type alias BackendMsg =
    L.Types.TimestampMsg Bsg


type Bsg
    = GotCounterBsg Counter.Bsg


type ToFrontend
    = CounterToFrontend Counter.ToFrontend


andUpdate : ( a, Cmd msg ) -> ( a -> b, Cmd msg ) -> ( b, Cmd msg )
andUpdate ( value, cmd2 ) ( func, cmd1 ) =
    ( func value
    , Cmd.batch [ cmd1, cmd2 ]
    )

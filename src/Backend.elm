module Backend exposing (..)

import BirdSighting
import Html
import L
import Lamdera
import Table
import Task
import Time
import Types exposing (..)


type alias Model =
    BackendModel


app =
    L.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = always Sub.none
        }


init : ( Model, Cmd Bsg )
init =
    ( { message = "Hello!"
      , birdSightings = Table.init
      }
    , Cmd.none
    )


update : Time.Posix -> Bsg -> Model -> ( Model, Cmd Bsg )
update timestamp msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )


updateFromFrontend : L.SessionId -> L.ClientId -> ToBackend -> Model -> ( Model, Cmd Bsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        SawABird { species, location } ->
            ( model, Cmd.none )

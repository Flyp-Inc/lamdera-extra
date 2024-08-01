module Backend exposing (..)

import Counter
import Html
import L
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


counter : Counter.Backend Model Bsg
counter =
    Counter.backend
        { toBsg = GotCounterBsg
        , sendToFrontend =
            \clientId toFrontend ->
                L.sendToFrontend clientId (CounterToFrontend toFrontend)
        , toBodel = \bodel counterBodel -> { bodel | counterBodel = counterBodel }
        , fromBodel = .counterBodel
        }


init : ( Model, Cmd Bsg )
init =
    ( { message = "Hello!"
      , counterBodel = Tuple.first counter.binit
      }
    , Cmd.none
    )


update : Time.Posix -> Bsg -> Model -> ( Model, Cmd Bsg )
update timestamp msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotCounterBsg counterMsg ->
            counter.bupdate timestamp counterMsg model


updateFromFrontend : L.SessionId -> L.ClientId -> ToBackend -> Model -> ( Model, Cmd Bsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        NoOpToBackend ->
            ( model, Cmd.none )

        CounterToBackend toB ->
            counter.updateFromFrontend toB sessionId clientId model

module Backend exposing (Bodel, app)

import Counter
import L
import Time
import Types exposing (..)


type alias Bodel =
    BackendModel


app : L.BackendApplication ToBackend Bodel Bsg
app =
    L.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = always Sub.none
        }


counter : Counter.Backend Bodel Bsg
counter =
    Counter.backend
        { toBsg = GotCounterBsg
        , sendToFrontend =
            \clientId toFrontend ->
                L.sendToFrontend clientId (CounterToFrontend toFrontend)
        , toBodel = \bodel counterBodel -> { bodel | counterBodel = counterBodel }
        , fromBodel = .counterBodel
        }


init : ( Bodel, Cmd Bsg )
init =
    ( \counterBodel ->
        { message = "Hello!"
        , counterBodel = counterBodel
        }
    , Cmd.none
    )
        |> Types.andUpdate counter.binit


update : Time.Posix -> Bsg -> Bodel -> ( Bodel, Cmd Bsg )
update timestamp msg model =
    case msg of
        GotCounterBsg counterMsg ->
            counter.bupdate timestamp counterMsg model


updateFromFrontend : L.SessionId -> L.ClientId -> ToBackend -> Bodel -> ( Bodel, Cmd Bsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        NoOpToBackend ->
            ( model, Cmd.none )

        CounterToBackend toB ->
            counter.updateFromFrontend toB sessionId clientId model

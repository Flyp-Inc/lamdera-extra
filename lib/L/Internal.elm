module L.Internal exposing
    ( BackendApplication
    , ClientId
    , ClientSet
    , FrontendApplication
    , SessionDict
    , SessionId
    , backend
    , frontend
    , mapClientSet
    , sendToBackend
    , sendToFrontend
    , toListClientSet
    )

{-| INTERNALS. STAY OUT.

(just kidding. honestly, if you like this, you should probably fork it and customize it for your own application!)

-}

import Browser
import Browser.Navigation
import Dict
import Html
import L.Types
import Lamdera
import Set
import Task
import Time
import Url



-- exposed internals


type alias SessionId =
    { value : Lamdera.SessionId
    , tag : ()
    }


type alias ClientId =
    { value : Lamdera.ClientId
    , tag : {}
    }


sendToBackend =
    Lamdera.sendToBackend


sendToFrontend clientId =
    Lamdera.sendToFrontend clientId.value


type alias FrontendApplication toFrontend model msg =
    { init :
        Lamdera.Url
        -> Browser.Navigation.Key
        -> ( model, Cmd (L.Types.TimestampMsg msg) )
    , onUrlChange : Url.Url -> L.Types.TimestampMsg msg
    , onUrlRequest : Browser.UrlRequest -> L.Types.TimestampMsg msg
    , subscriptions : model -> Sub (L.Types.TimestampMsg msg)
    , update :
        L.Types.TimestampMsg msg
        -> model
        -> ( model, Cmd (L.Types.TimestampMsg msg) )
    , updateFromBackend :
        toFrontend -> model -> ( model, Cmd (L.Types.TimestampMsg msg) )
    , view : model -> Browser.Document (L.Types.TimestampMsg msg)
    }


frontend :
    { init : Url.Url -> Browser.Navigation.Key -> ( model, Cmd msg )
    , view : model -> Browser.Document msg
    , update : Time.Posix -> msg -> model -> ( model, Cmd msg )
    , updateFromBackend : toFrontend -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , onUrlRequest : Browser.UrlRequest -> msg
    , onUrlChange : Url.Url -> msg
    }
    -> FrontendApplication toFrontend model msg
frontend params =
    Lamdera.frontend
        { init =
            \url key ->
                params.init url key
                    |> Tuple.mapSecond (Cmd.map L.Types.GotMsg)
        , view =
            \model ->
                params.view model
                    |> (\{ title, body } ->
                            { title = title
                            , body =
                                List.map
                                    (Html.map L.Types.GotMsg)
                                    body
                            }
                       )
        , update = updateWithTimestamp params.update
        , updateFromBackend =
            \toFrontend model ->
                params.updateFromBackend toFrontend model
                    |> Tuple.mapSecond (Cmd.map L.Types.GotMsg)
        , subscriptions =
            \model ->
                params.subscriptions model
                    |> Sub.map L.Types.GotMsg
        , onUrlRequest =
            \value -> params.onUrlRequest value |> L.Types.GotMsg
        , onUrlChange =
            \value -> params.onUrlChange value |> L.Types.GotMsg
        }


updateWithTimestamp :
    (Time.Posix -> msg -> model -> ( model, Cmd msg ))
    -> L.Types.TimestampMsg msg
    -> model
    -> ( model, Cmd (L.Types.TimestampMsg msg) )
updateWithTimestamp func timestampMsg model =
    case timestampMsg of
        L.Types.GotMsg msg ->
            ( model
            , Task.perform (L.Types.GotMsgWithTimestamp msg) Time.now
            )

        L.Types.GotMsgWithTimestamp msg timestamp ->
            func timestamp msg model
                |> Tuple.mapSecond (Cmd.map L.Types.GotMsg)


type alias BackendApplication toBackend bodel bsg =
    { init : ( bodel, Cmd (L.Types.TimestampMsg bsg) )
    , subscriptions : bodel -> Sub (L.Types.TimestampMsg bsg)
    , update :
        L.Types.TimestampMsg bsg
        -> bodel
        -> ( bodel, Cmd (L.Types.TimestampMsg bsg) )
    , updateFromFrontend :
        Lamdera.SessionId
        -> Lamdera.ClientId
        -> toBackend
        -> bodel
        -> ( bodel, Cmd (L.Types.TimestampMsg bsg) )
    }


backend :
    { init : ( bodel, Cmd bsg )
    , update : Time.Posix -> bsg -> bodel -> ( bodel, Cmd bsg )
    , updateFromFrontend : SessionId -> ClientId -> toBackend -> bodel -> ( bodel, Cmd bsg )
    , subscriptions : bodel -> Sub bsg
    }
    -> BackendApplication toBackend bodel bsg
backend params =
    Lamdera.backend
        { init = params.init |> Tuple.mapSecond (Cmd.map L.Types.GotMsg)
        , update = updateWithTimestamp params.update
        , updateFromFrontend =
            \sessionId clientId toBackend model ->
                params.updateFromFrontend (newSessionId sessionId) (newClientId clientId) toBackend model
                    |> Tuple.mapSecond (Cmd.map L.Types.GotMsg)
        , subscriptions =
            \model ->
                params.subscriptions model
                    |> Sub.map L.Types.GotMsg
        }


type alias SessionDict value =
    Dict.Dict Lamdera.SessionId value


type alias ClientSet =
    Set.Set Lamdera.ClientId


toListClientSet : ClientSet -> List ClientId
toListClientSet clientSet =
    Set.toList clientSet
        |> List.map newClientId


mapClientSet : (ClientId -> a) -> ClientSet -> List a
mapClientSet f value =
    toListClientSet value
        |> List.map f



-- actually-internal internals


newSessionId : Lamdera.SessionId -> SessionId
newSessionId value =
    { value = value
    , tag = ()
    }


newClientId : Lamdera.ClientId -> ClientId
newClientId value =
    { value = value
    , tag = {}
    }

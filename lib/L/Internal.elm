module L.Internal exposing
    ( BackendProgram
    , ClientId
    , ClientSet
    , FrontendProgram
    , SessionDict
    , SessionId
    , backend
    , broadcast
    , frontend
    , mapClientSet
    , newClientId
    , newSessionId
    , onConnect
    , onDisconnect
    , sendToBackend
    , sendToFrontend
    , toListClientSet
    )

import Browser
import Browser.Navigation
import Dict
import Lamdera
import Set
import Task
import Time
import Url


type alias SessionId =
    { value : Lamdera.SessionId
    , tag : ()
    }


newSessionId : Lamdera.SessionId -> SessionId
newSessionId value =
    { value = value
    , tag = ()
    }


type alias ClientId =
    { value : Lamdera.ClientId
    , tag : {}
    }


newClientId : Lamdera.ClientId -> ClientId
newClientId value =
    { value = value
    , tag = {}
    }


onConnect : (SessionId -> ClientId -> toBackend) -> Sub toBackend
onConnect toBackend =
    Lamdera.onConnect
        (\sessionId clientId ->
            toBackend (newSessionId sessionId) (newClientId clientId)
        )


onDisconnect : (SessionId -> ClientId -> toBackend) -> Sub toBackend
onDisconnect toBackend =
    Lamdera.onDisconnect
        (\sessionId clientId ->
            toBackend (newSessionId sessionId) (newClientId clientId)
        )


sendToBackend =
    Lamdera.sendToBackend


sendToFrontend clientId =
    Lamdera.sendToFrontend clientId.value


broadcast =
    Lamdera.broadcast


type alias FrontendProgram model toFrontend frontendMsg =
    { init : Url.Url -> Browser.Navigation.Key -> ( model, Cmd frontendMsg )
    , view : model -> Browser.Document frontendMsg
    , update : frontendMsg -> model -> ( model, Cmd frontendMsg )
    , updateFromBackend : toFrontend -> model -> ( model, Cmd frontendMsg )
    , subscriptions : model -> Sub frontendMsg
    , onUrlRequest : Browser.UrlRequest -> frontendMsg
    , onUrlChange : Url.Url -> frontendMsg
    }


frontend :
    { init : Url.Url -> Browser.Navigation.Key -> ( model, Cmd frontendMsg )
    , view : model -> Browser.Document frontendMsg
    , update : frontendMsg -> model -> ( model, Cmd frontendMsg )
    , updateFromBackend : toFrontend -> model -> ( model, Cmd frontendMsg )
    , subscriptions : model -> Sub frontendMsg
    , onUrlRequest : Browser.UrlRequest -> frontendMsg
    , onUrlChange : Url.Url -> frontendMsg
    }
    -> FrontendProgram model toFrontend frontendMsg
frontend =
    Lamdera.frontend


type alias BackendProgram backendModel toBackend bsg =
    { init : ( backendModel, Cmd ( bsg, Maybe Time.Posix ) )
    , subscriptions : backendModel -> Sub ( bsg, Maybe Time.Posix )
    , update :
        ( bsg, Maybe Time.Posix )
        -> backendModel
        -> ( backendModel, Cmd ( bsg, Maybe Time.Posix ) )
    , updateFromFrontend :
        Lamdera.SessionId
        -> Lamdera.ClientId
        -> toBackend
        -> backendModel
        -> ( backendModel, Cmd ( bsg, Maybe Time.Posix ) )
    }


backend :
    { init : ( backendModel, Cmd bsg )
    , update : Time.Posix -> bsg -> backendModel -> ( backendModel, Cmd bsg )
    , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, Cmd bsg )
    , subscriptions : backendModel -> Sub bsg
    }
    -> BackendProgram backendModel toBackend bsg
backend params =
    let
        mapCmd : ( model, Cmd msg ) -> ( model, Cmd ( msg, Maybe Time.Posix ) )
        mapCmd ( model, cmdMsg ) =
            ( model
            , Cmd.map (\msg_ -> Tuple.pair msg_ Nothing) cmdMsg
            )
    in
    Lamdera.backend
        { init = mapCmd params.init
        , update =
            \( msg, maybeTimestamp ) model ->
                case maybeTimestamp of
                    Nothing ->
                        ( model
                        , Task.perform (Just >> Tuple.pair msg) Time.now
                        )

                    Just timestamp ->
                        params.update timestamp msg model
                            |> mapCmd
        , updateFromFrontend =
            \sessionId clientId toBackend model ->
                params.updateFromFrontend (newSessionId sessionId) (newClientId clientId) toBackend model
                    |> mapCmd
        , subscriptions =
            \model ->
                params.subscriptions model
                    |> Sub.map (\msg_ -> Tuple.pair msg_ Nothing)
        }


type alias SessionDict value =
    Dict.Dict Lamdera.SessionId value


type alias ClientSet =
    Set.Set Lamdera.ClientId


toListClientSet : ClientSet -> List ClientId
toListClientSet =
    Set.toList >> List.map newClientId


mapClientSet : (ClientId -> a) -> ClientSet -> List a
mapClientSet f value =
    toListClientSet value
        |> List.map f

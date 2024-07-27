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


type alias BackendProgram backendModel toBackend backendMsg =
    { init : ( backendModel, Cmd backendMsg )
    , update : backendMsg -> backendModel -> ( backendModel, Cmd backendMsg )
    , updateFromFrontend : Lamdera.SessionId -> Lamdera.ClientId -> toBackend -> backendModel -> ( backendModel, Cmd backendMsg )
    , subscriptions : backendModel -> Sub backendMsg
    }


backend :
    { init : ( backendModel, Cmd backendMsg )
    , update : backendMsg -> backendModel -> ( backendModel, Cmd backendMsg )
    , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, Cmd backendMsg )
    , subscriptions : backendModel -> Sub backendMsg
    }
    -> BackendProgram backendModel toBackend backendMsg
backend { init, update, updateFromFrontend, subscriptions } =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend =
            \sessionId clientId ->
                updateFromFrontend
                    (newSessionId sessionId)
                    (newClientId clientId)
        , subscriptions = subscriptions
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

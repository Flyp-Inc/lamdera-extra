module L exposing
    ( SessionId, ClientId
    , FrontendApplication, frontend
    , BackendApplication, backend
    , sendToBackend, sendToFrontend
    , SessionDict, ClientSet
    )

{-| You don't `import Lamdera` anymore; you just `import L`.

@docs SessionId, ClientId

@docs FrontendApplication, frontend

@docs BackendApplication, backend

@docs sendToBackend, sendToFrontend

@docs SessionDict, ClientSet

-}

import Browser
import Browser.Navigation
import L.Internal
import Time
import Url


type alias SessionId =
    L.Internal.SessionId


type alias ClientId =
    L.Internal.ClientId


sendToBackend =
    L.Internal.sendToBackend


sendToFrontend =
    L.Internal.sendToFrontend


type alias FrontendApplication toFrontend model msg =
    L.Internal.FrontendApplication toFrontend model msg


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
frontend =
    L.Internal.frontend


type alias BackendApplication toBackend bodel bsg =
    L.Internal.BackendApplication toBackend bodel bsg


backend :
    { init : ( bodel, Cmd bsg )
    , update : Time.Posix -> bsg -> bodel -> ( bodel, Cmd bsg )
    , updateFromFrontend : SessionId -> ClientId -> toBackend -> bodel -> ( bodel, Cmd bsg )
    , subscriptions : bodel -> Sub bsg
    }
    -> BackendApplication toBackend bodel bsg
backend =
    L.Internal.backend


type alias SessionDict value =
    L.Internal.SessionDict value


type alias ClientSet =
    L.Internal.ClientSet

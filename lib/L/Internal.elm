module L.Internal exposing
    ( ClientId
    , ClientSet
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
import Html
import L.Types
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

module Counter exposing
    ( Backend
    , Bodel
    , Bsg
    , Frontend
    , Model
    , Msg
    , ToBackend
    , ToFrontend
    , backend
    , frontend
    )

import Html
import Html.Attributes as Attr
import Html.Events
import L
import Task
import Time


type alias Model =
    { count : Int }


type alias Bodel =
    { operations : List ( Operation, Time.Posix ) }


type Operation
    = Incremented
    | Decremented


type Msg
    = GotOperation Operation


type ToFrontend
    = GotUpdated Int


type ToBackend
    = HandledChanged Operation Time.Posix


type Bsg
    = OnSaved L.ClientId


type alias Frontend model msg =
    { view : model -> Html.Html msg
    , updateFromBackend : ToFrontend -> model -> ( model, Cmd msg )
    , update : Time.Posix -> Msg -> model -> ( model, Cmd msg )
    , init : ( Model, Cmd msg )
    }


frontend :
    { toMsg : Msg -> msg
    , sendToBackend : ToBackend -> Cmd msg
    , toModel : model -> Model -> model
    , fromModel : model -> Model
    }
    -> Frontend model msg
frontend { toMsg, sendToBackend, toModel, fromModel } =
    { view =
        \model ->
            view toMsg <|
                fromModel model
    , updateFromBackend =
        \toFrontend model ->
            updateFromBackend toMsg toFrontend (fromModel model)
                |> Tuple.mapFirst (toModel model)
    , update =
        \timestamp msg model ->
            update toMsg sendToBackend timestamp msg (fromModel model)
                |> Tuple.mapFirst (toModel model)
    , init =
        ( { count = 0 }
        , Cmd.none
        )
    }


type alias Backend bodel bsg =
    { updateFromFrontend : ToBackend -> L.SessionId -> L.ClientId -> bodel -> ( bodel, Cmd bsg )
    , bupdate : Time.Posix -> Bsg -> bodel -> ( bodel, Cmd bsg )
    , binit : ( Bodel, Cmd bsg )
    }


backend :
    { toBsg : Bsg -> bsg
    , sendToFrontend : L.ClientId -> ToFrontend -> Cmd bsg
    , toBodel : bodel -> Bodel -> bodel
    , fromBodel : bodel -> Bodel
    }
    -> Backend bodel bsg
backend { toBsg, sendToFrontend, toBodel, fromBodel } =
    { updateFromFrontend =
        \toBackend sessionId clientId bodel ->
            updateFromFrontend toBsg toBackend sessionId clientId (fromBodel bodel)
                |> Tuple.mapFirst (toBodel bodel)
    , bupdate =
        \timestamp bsg bodel ->
            bupdate toBsg sendToFrontend timestamp bsg (fromBodel bodel)
                |> Tuple.mapFirst (toBodel bodel)
    , binit =
        ( { operations = [] }
        , Cmd.none
        )
    }


view : (Msg -> msg) -> Model -> Html.Html msg
view toMsg model =
    Html.map toMsg <|
        Html.div []
            [ Html.button [ Html.Events.onClick <| GotOperation Incremented ] [ Html.text "Increment" ]
            , Html.div [ Attr.style "margin" "8px" ] [ Html.text <| String.fromInt model.count ]
            , Html.button [ Html.Events.onClick <| GotOperation Decremented ] [ Html.text "Decrement" ]
            ]


updateFromBackend : (Msg -> msg) -> ToFrontend -> Model -> ( Model, Cmd msg )
updateFromBackend toMsg toFrontend model =
    case toFrontend of
        GotUpdated count ->
            ( { model | count = count }
            , Cmd.none
            )


update : (Msg -> msg) -> (ToBackend -> Cmd msg) -> Time.Posix -> Msg -> Model -> ( Model, Cmd msg )
update toMsg sendToBackend timestamp msg model =
    case msg of
        GotOperation operation ->
            ( model
            , sendToBackend <| HandledChanged operation timestamp
            )


updateFromFrontend : (Bsg -> bsg) -> ToBackend -> L.SessionId -> L.ClientId -> Bodel -> ( Bodel, Cmd bsg )
updateFromFrontend toBsg toBackend sessionId clientId bodel =
    case toBackend of
        HandledChanged operation timestamp ->
            ( { bodel | operations = ( operation, timestamp ) :: bodel.operations }
            , Cmd.map toBsg <|
                Task.perform identity <|
                    Task.succeed <|
                        OnSaved clientId
            )


bupdate : (Bsg -> bsg) -> (L.ClientId -> ToFrontend -> Cmd bsg) -> Time.Posix -> Bsg -> Bodel -> ( Bodel, Cmd bsg )
bupdate toBsg sendToFrontend timestamp bsg bodel =
    case bsg of
        OnSaved clientId ->
            let
                count : Int
                count =
                    List.foldl
                        (\step acc ->
                            (+) acc <|
                                case step of
                                    Incremented ->
                                        1

                                    Decremented ->
                                        -1
                        )
                        0
                    <|
                        List.map Tuple.first bodel.operations
            in
            ( bodel
            , sendToFrontend clientId (GotUpdated count)
            )

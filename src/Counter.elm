module Counter exposing
    ( Backend
    , Bodel
    , Bsg
    , Frontend
    , Model
    , Msg
    , Operation
    , ToBackend
    , ToFrontend
    , backend
    , frontend
    )

{-| Implementation of ["the module pattern"](https://dev.to/jmpavlick/for-lack-of-a-better-name-im-calling-it-the-module-pattern-5dfi), applied to a Lamdera application.

This isn't actually a part of `lamdera-extra` so much as it is a demonstration of the technique.

"The Module Pattern" allows us to constrain behaviors to a given module and make them opaque to the rest of the application,
while making it extremely clear what information is being processed by the behaviors encapsulated within a given module.

The overall premise is this:

  - Create a record type alias that defines the interfaces for a TEA-like group of functions
  - Create a function that takes any external maps, and applies them to the internal definitions of those functions as arguments, and returns a value of that "interface" type
  - Any other part of the application can "host" that "module" as long as it can satisfy the dependencies created by the type signature of the initialization function

In this file, we define the following TEA / Lamdera application standards:

  - view
  - frontend update
  - backend update
  - update from backend
  - update from frontend
  - frontend model
  - backend model

We treat every message and model type in this module as if it were a top-level type, in its respective `Frontend.elm` or `Backend.elm` file,
and in so doing, we can write 100 of our code within the immediate context of those types, leveraging the `frontend` and `backend` initialization functions
to mediate all of these types and functions' interactions with the rest of the application.

The overall "flow" of events in this module works like this:

  - The frontend displays its model (which contains an integer representing a count), and buttons to increment and decrement that count
  - The frontend update sends a message to the backend's "update from frontend" function that includes the event, as well as client and session information
  - The "update from frontend" function records the message's event payload as an "event" (as in "event sourcing") in the backend model, and sends
    a message to the backend's update, notifying it that a value was persisted and communicating which client was responsible for persisting the change
  - The backend update function aggregates its model into a value representing (number of times incremented) minus (number of times decremented), and sends
    a message to the "update from backend" function on the frontend
  - The "update from backend" function on the frontend persists this new value into the frontend's model, where it can be viewed

Take a look at the call sites in `Frontend.elm` and `Backend.elm` for more insight as to how this all fits together!

-}

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

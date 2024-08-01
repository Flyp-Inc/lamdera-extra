module Frontend exposing (Model, app)

import Browser
import Browser.Navigation
import Counter
import Html
import Html.Attributes as Attr
import L
import Time
import Types exposing (..)
import Url


type alias Model =
    FrontendModel


app =
    L.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \_ -> Sub.none
        , view = view
        }


counter : Counter.Frontend Model Msg
counter =
    Counter.frontend
        { toMsg = GotCounterMsg
        , sendToBackend =
            \toBackend ->
                L.sendToBackend (CounterToBackend toBackend)
        , toModel = \model counterModel -> { model | counterModel = counterModel }
        , fromModel = .counterModel
        }


init : Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init url key =
    ( { key = key
      , message = "Welcome to Lamdera! You're looking at the auto-generated base implementation, with some added topspin from an unhinged community member."
      , counterModel = Tuple.first counter.init
      }
    , Cmd.none
    )


update : Time.Posix -> Msg -> Model -> ( Model, Cmd Msg )
update now msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Browser.Navigation.pushUrl model.key (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Browser.Navigation.load url
                    )

        UrlChanged _ ->
            ( model, Cmd.none )

        GotCounterMsg counterMsg ->
            counter.update now counterMsg model


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd Msg )
updateFromBackend msg model =
    case msg of
        CounterToFrontend toF ->
            counter.updateFromBackend toF model


view : Model -> Browser.Document Msg
view model =
    { title = ""
    , body =
        [ Html.div
            [ Attr.style "font-family" "sans-serif"
            , Attr.style "text-align" "center"
            , Attr.style "padding-top" "40px"
            ]
            [ Html.img [ Attr.src "https://lamdera.app/lamdera-logo-black.png", Attr.width 150 ] []
            , Html.div
                [ Attr.style "padding-top" "40px"
                ]
                [ Html.text model.message ]
            , Html.div
                [ Attr.style "font-family" "sans-serif"
                ]
                [ Html.p []
                    [ Html.text "Submodule this repo into your project, then add the "
                    , Html.code [] [ Html.text "lib/ " ]
                    , Html.text "folder to your Lamdera project's "
                    , Html.code [] [ Html.text "elm.json" ]
                    ]
                ]
            , Html.hr [] []
            , counter.view model
            ]
        ]
    }

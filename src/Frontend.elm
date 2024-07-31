module Frontend exposing (..)

import Browser
import Browser.Navigation
import Html
import Html.Attributes as Attr
import L
import Time
import Types exposing (..)
import Url


type alias Model =
    FrontendModel


app =
    L.frontend2
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \m -> Sub.none
        , view = view
        }


init : Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init url key =
    ( { key = key
      , message = "Welcome to Lamdera! You're looking at the auto-generated base implementation, with some added topspin from an unhinged community member."
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

        UrlChanged url ->
            ( model, Cmd.none )

        NoOpFrontendMsg ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd Msg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )


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
            ]
        ]
    }

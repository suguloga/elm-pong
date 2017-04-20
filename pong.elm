module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Time
import Keyboard.Extra
import AnimationFrame
import Char


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Direction
    = Left
    | Right
    | Still


type Person
    = Player
    | Computer


type alias Model =
    { playerX : Float
    , playerY : Float
    , computerX : Float
    , computerY : Float
    , playerDirection : Direction
    , computerDirection : Direction
    , ballX : Float
    , ballY : Float
    , ballDirectionX : Float
    , ballDirectionY : Float
    , keyboardModel : Keyboard.Extra.State
    , playerScore : Int
    , computerScore : Int
    }


initModel : Model
initModel =
    { playerX = 40
    , playerY = 420
    , computerX = 40
    , computerY = 10
    , playerDirection = Still
    , computerDirection = Still
    , ballX = 250
    , ballY = 250
    , ballDirectionX = -2
    , ballDirectionY = 2
    , playerScore = 0
    , computerScore = 0
    , keyboardModel = Keyboard.Extra.initialState
    }


init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )



-- UPDATE


type Msg
    = KeyboardExtraMsg Keyboard.Extra.Msg
    | Step Time.Time


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        KeyboardExtraMsg keyMsg ->
            onUserInput keyMsg model

        Step time ->
            onFrame time model



{- Step time -> onFrame time game -}


onUserInput : Keyboard.Extra.Msg -> Model -> ( Model, Cmd Msg )
onUserInput keyMsg model =
    let
        keyboardModel =
            Keyboard.Extra.update keyMsg model.keyboardModel

        playerDir =
            if (Keyboard.Extra.arrows keyboardModel).x > 0 then
                Right
            else if (Keyboard.Extra.arrows keyboardModel).x < 0 then
                Left
            else
                Still

        computerDir =
            if (Keyboard.Extra.wasd keyboardModel).x > 0 then
                Right
            else if (Keyboard.Extra.wasd keyboardModel).x < 0 then
                Left
            else
                Still
    in
        ( { model
            | keyboardModel = keyboardModel
            , playerDirection = playerDir
            , computerDirection = computerDir
          }
        , Cmd.none
        )


onFrame : Time.Time -> Model -> ( Model, Cmd Msg )
onFrame time model =
    let
        ( newDirectionX, newDirectionY ) =
            checkCollision model

        ( newPositionX, newPositionY, updateScoreComp, updateScorePlayer ) =
            checkGoalScored model
    in
        ( { model
            | playerX = updatePlayer model.playerDirection model Player
            , computerX = updatePlayer model.computerDirection model Computer
            , ballX = newPositionX
            , ballY = newPositionY
            , ballDirectionX = newDirectionX
            , ballDirectionY = newDirectionY
            , computerScore = model.computerScore + updateScoreComp
            , playerScore = model.playerScore + updateScorePlayer
          }
        , Cmd.none
        )


checkGoalScored : Model -> ( Float, Float, Int, Int )
checkGoalScored model =
    if (model.ballY + model.ballDirectionY) <= -40 then
        ( 250, 250, 0, 1 )
    else if (model.ballY + model.ballDirectionY) >= 470 then
        ( 250, 250, 1, 0 )
    else
        ( model.ballX + model.ballDirectionX, model.ballY + model.ballDirectionY, 0, 0 )


updatePlayer : Direction -> Model -> Person -> Float
updatePlayer direction model person =
    let
        playerPosition =
            if person == Player then
                model.playerX
            else
                model.computerX
    in
        checkBoundaries playerPosition 4 direction


checkBoundaries : Float -> Float -> Direction -> Float
checkBoundaries position change dir =
    let
        ( maxValue, operator, comparison ) =
            if dir == Left then
                ( 0, (-), (>) )
            else if dir == Right then
                ( 400, (+), (<) )
            else
                ( -100, (+), (/=) )

        withChange =
            operator position change
    in
        if comparison maxValue withChange then
            position
        else
            withChange


checkCollision : Model -> ( Float, Float )
checkCollision model =
    if
        (model.ballX + model.ballDirectionX)
            <= 0
            || (model.ballX + model.ballDirectionX)
            >= 490
    then
        ( model.ballDirectionX * -1, model.ballDirectionY )
    else if
        (model.ballY + model.ballDirectionY)
            == 4
            && (model.ballX + model.ballDirectionX)
            >= model.computerX
            && (model.ballX + model.ballDirectionX)
            <= (model.computerX + 100)
    then
        ( model.ballDirectionX, model.ballDirectionY * -1 )
    else if
        (model.ballY + model.ballDirectionY + 15)
            == 439
            && (model.ballX + model.ballDirectionX)
            >= model.playerX
            && (model.ballX + model.ballDirectionX)
            <= (model.playerX + 100)
    then
        ( model.ballDirectionX, model.ballDirectionY * -1 )
    else
        ( model.ballDirectionX, model.ballDirectionY )


moveBall : Float -> Float
moveBall ballPosition =
    ballPosition + 1



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map KeyboardExtraMsg Keyboard.Extra.subscriptions
        , AnimationFrame.times (\time -> Step time)
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "width", "500px" )
            , ( "height", "500px" )
            , ( "margin-left", "auto" )
            , ( "margin-right", "auto" )
            , ( "border-color", "black" )
            , ( "border-width", "3px" )
            , ( "border-style", "solid" )
            , ( "background-color", "black" )
            , ( "color", "white" )
            ]
        ]
        [ paddle_ model Computer
        , ball_ model
        , paddle_ model Player
        , score_ model.playerScore Player
        , score_ model.computerScore Computer
        ]


paddle_ : Model -> Person -> Html Msg
paddle_ model person =
    let
        ( positionX, positionY ) =
            case person of
                Player ->
                    ( model.playerX, model.playerY )

                Computer ->
                    ( model.computerX, model.computerY )
    in
        div
            [ style
                [ ( "background-color", "white" )
                , ( "width", "100px" )
                , ( "height", "25px" )
                , ( "position", "relative" )
                , ( "left", (positionX |> toString) ++ "px" )
                , ( "top", (positionY |> toString) ++ "px" )
                ]
            ]
            []


ball_ : Model -> Html Msg
ball_ model =
    div
        [ style
            [ ( "background-color", "white" )
            , ( "width", "15px" )
            , ( "height", "15px" )
            , ( "position", "relative" )
            , ( "left", (model.ballX |> toString) ++ "px" )
            , ( "top", (model.ballY |> toString) ++ "px" )
            ]
        ]
        []


score_ : Int -> Person -> Html Msg
score_ scoreValue person =
    let
        scorePlacement =
            case person of
                Player ->
                    "20px"

                Computer ->
                    "470px"
    in
        div
            [ style
                [ ( "background-color", "white" )
                , ( "color", "black" )
                , ( "position", "relative" )
                , ( "top", "450px" )
                , ( "left", scorePlacement )
                , ( "display", "inline-block" )
                ]
            ]
            [ text <| toString scoreValue ]
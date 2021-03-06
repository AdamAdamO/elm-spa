module Tests.Generators.Route exposing (suite)

import Expect exposing (Expectation)
import Generators.Route as Route
import Path exposing (Path)
import Test exposing (..)


paths :
    { empty : List Path
    , single : List Path
    , multiple : List Path
    }
paths =
    { empty = []
    , single =
        [ Path.fromFilepath "Top.elm"
        ]
    , multiple =
        [ Path.fromFilepath "Top.elm"
        , Path.fromFilepath "About.elm"
        , Path.fromFilepath "NotFound.elm"
        , Path.fromFilepath "Posts/Top.elm"
        , Path.fromFilepath "Posts/Id_Int.elm"
        , Path.fromFilepath "Authors/Author_String/Posts/PostId_Int.elm"
        ]
    }


suite : Test
suite =
    describe "Generators.Route"
        [ describe "routeCustomType"
            [ test "returns empty for missing variants" <|
                \_ ->
                    paths.empty
                        |> Route.routeCustomType
                        |> Expect.equal ""
            , test "handles single path" <|
                \_ ->
                    paths.single
                        |> Route.routeCustomType
                        |> Expect.equal "type Route = Top"
            , test "handles multiple paths" <|
                \_ ->
                    paths.multiple
                        |> Route.routeCustomType
                        |> Expect.equal (String.trim """
type Route
    = Top
    | About
    | NotFound
    | Posts__Top
    | Posts__Id_Int { id : Int }
    | Authors__Author_String__Posts__PostId_Int { author : String, postId : Int }
""")
            ]
        , describe "routeParsers"
            [ test "handles empty path" <|
                \_ ->
                    paths.empty
                        |> Route.routeParsers
                        |> Expect.equal "        []"
            , test "handles single path" <|
                \_ ->
                    paths.single
                        |> Route.routeParsers
                        |> Expect.equal "        [ Parser.map Top Parser.top ]"
            , test "handles multiple paths" <|
                \_ ->
                    paths.multiple
                        |> Route.routeParsers
                        |> Expect.equal """        [ Parser.map Top Parser.top
        , Parser.map About (Parser.s "about")
        , Parser.map NotFound (Parser.s "not-found")
        , Parser.map Posts__Top (Parser.s "posts")
        , (Parser.s "posts" </> Parser.int)
          |> Parser.map (\\id -> { id = id })
          |> Parser.map Posts__Id_Int
        , (Parser.s "authors" </> Parser.string </> Parser.s "posts" </> Parser.int)
          |> Parser.map (\\author postId -> { author = author, postId = postId })
          |> Parser.map Authors__Author_String__Posts__PostId_Int
        ]"""
            ]
        , describe "routeSegments"
            [ test "handles empty path" <|
                \_ ->
                    paths.empty
                        |> Route.routeSegments
                        |> Expect.equal ""
            , test "handles single path" <|
                \_ ->
                    paths.single
                        |> Route.routeSegments
                        |> Expect.equal """            case route of
                Top ->
                    []"""
            , test "handles multiple paths" <|
                \_ ->
                    paths.multiple
                        |> Route.routeSegments
                        |> Expect.equal """            case route of
                Top ->
                    []
                
                About ->
                    [ "about" ]
                
                NotFound ->
                    [ "not-found" ]
                
                Posts__Top ->
                    [ "posts" ]
                
                Posts__Id_Int { id } ->
                    [ "posts", String.fromInt id ]
                
                Authors__Author_String__Posts__PostId_Int { author, postId } ->
                    [ "authors", author, "posts", String.fromInt postId ]"""
            ]
        ]

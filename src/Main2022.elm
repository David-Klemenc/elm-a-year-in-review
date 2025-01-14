module Main2022 exposing (..)

import Dict
import Element exposing (..)
import Element.Font as Font
import Helpers.MarkdownElmUi
import Html
import Html.Attributes
import Iso8601
import Time
import Year2022.ElmRadio
import Year2022.ElmWeekly
import Year2022.Others
import Year2022.Youtube


type Data
    = DataElmRadio Year2022.ElmRadio.Data
    | DataElmWeekly Year2022.ElmWeekly.Data
    | DataOthers Year2022.Others.Data
    | DataYoutube Year2022.Youtube.Data


type alias ParsedDate =
    { day : Int
    , month : Time.Month
    , year : Int
    , posix : Time.Posix
    }


categorizedData : Dict.Dict Int (List ( Int, Data ))
categorizedData =
    List.foldl
        (\data acc ->
            let
                dataParseed : ParsedDate
                dataParseed =
                    dateParser <|
                        case data of
                            DataElmRadio d ->
                                { dateEvent = "", datePublished = d.date, title = d.title }

                            DataElmWeekly d ->
                                { dateEvent = "", datePublished = d.date, title = d.description }

                            DataOthers d ->
                                { dateEvent = "", datePublished = d.date, title = d.title }

                            DataYoutube d ->
                                { dateEvent = d.dateEvent, datePublished = d.datePublished, title = d.title }

                key1 : Int
                key1 =
                    monthToInt dataParseed.month

                key2 : Int
                key2 =
                    Time.posixToMillis dataParseed.posix
            in
            Dict.update key1
                (\maybeV ->
                    case maybeV of
                        Just v ->
                            Just <| ( key2, data ) :: v

                        Nothing ->
                            Just <| ( key2, data ) :: []
                )
                acc
        )
        Dict.empty
        (List.map DataElmRadio Year2022.ElmRadio.data
            -- ++ List.map DataElmWeekly Year2022.ElmWeekly.data
            ++ List.map DataOthers Year2022.Others.data
            ++ List.map DataYoutube Year2022.Youtube.data
        )


nth : Int -> String
nth n =
    case n of
        1 ->
            "1th"

        2 ->
            "2nd"

        3 ->
            "3rd"

        21 ->
            "21st"

        22 ->
            "22nd"

        23 ->
            "23rd"

        31 ->
            "31st"

        _ ->
            String.fromInt n ++ "th"


main : Html.Html msg
main =
    let
        markdown =
            header
                ++ "\n\n"
                ++ (String.join "\n\n" <|
                        List.map
                            (\index ->
                                let
                                    data : List ( Int, Data )
                                    data =
                                        Maybe.withDefault [] (Dict.get index categorizedData)
                                in
                                "## "
                                    ++ monthToString (intToMonth index)
                                    ++ " 2022\n\n"
                                    ++ String.join "\n\n"
                                        (List.map
                                            (\( posixAsInt, d_ ) ->
                                                let
                                                    day : Int
                                                    day =
                                                        Time.toDay Time.utc (Time.millisToPosix posixAsInt)
                                                in
                                                "* "
                                                    ++ monthToString (intToMonth index)
                                                    ++ " *"
                                                    ++ nth day
                                                    ++ "* - "
                                                    ++ (case d_ of
                                                            DataElmRadio d ->
                                                                dataElmRadioToString d

                                                            DataElmWeekly d ->
                                                                dataElmWeeklyToString d

                                                            DataOthers d ->
                                                                dataOthersToString d

                                                            DataYoutube d ->
                                                                dataYoutubeToString d
                                                       )
                                            )
                                            (List.sortBy Tuple.first data)
                                        )
                            )
                            (List.range 1 12)
                   )

        catData =
            categorizedData
    in
    layout [ padding 20 ] <|
        column [ width (maximum 700 <| fill), centerX, spacing 50 ]
            [ el [ Font.size 30, centerX ] <| text "Draft - Elm 2022, a year in review"
            , Helpers.MarkdownElmUi.stringToElement markdown
            , el [ Font.size 30 ] <| text "Markdown"
            , el [ width fill ] <|
                html <|
                    Html.textarea
                        [ Html.Attributes.value (meta ++ markdown)
                        , Html.Attributes.style "width" "100%"
                        , Html.Attributes.style "height" "400px"
                        ]
                        []
            ]


dataElmRadioToString : Year2022.ElmRadio.Data -> String
dataElmRadioToString data =
    -- { date : String
    -- , guests : List String
    -- , descritpion : String
    -- , episode : Int
    -- , title : String
    -- , id : String
    -- }
    let
        title =
            "Elm Radio episode #" ++ String.fromInt data.episode ++ " - " ++ data.title

        url =
            "https://elm-radio.com/episode/" ++ data.id
    in
    link
        { title = title
        , url = url
        }
        ++ " \""
        ++ data.descritpion
        ++ "\""
        ++ image { image = "images2022/elm-radio.png", title = title, url = url }


dataElmWeeklyToString : Year2022.ElmWeekly.Data -> String
dataElmWeeklyToString data =
    let
        url =
            "https://www.elmweekly.nl/p/elm-weekly-issue-" ++ data.id
    in
    link
        { title =
            "Elm Weekly issue #"
                ++ String.fromInt data.issue
        , url = url
        }
        ++ " \""
        ++ data.description
        ++ "\""


dataOthersToString : Year2022.Others.Data -> String
dataOthersToString data =
    -- { by : String
    -- , date : String
    -- , descriptions : String
    -- , url : String
    -- , image : String
    -- , title : String
    -- , type_ : Type_
    -- }
    typeToString data.type_
        ++ " "
        ++ link { title = data.title, url = data.url }
        ++ addBy data.by data.title
        ++ addDescription data.descriptions
        ++ (if String.isEmpty data.image then
                ""

            else
                image
                    { title = data.title
                    , image = "images2022/" ++ data.image
                    , url = data.url
                    }
           )


addDescription description =
    if String.isEmpty description then
        ""

    else
        " (" ++ description ++ ")"


addBy : String -> String -> String
addBy by title =
    if String.isEmpty by then
        let
            _ =
                Debug.log "By is missing" title
        in
        ""

    else
        " by **"
            ++ by
            ++ "**"


dataYoutubeToString : Year2022.Youtube.Data -> String
dataYoutubeToString data =
    -- { by : String
    -- , datePublished : String
    -- , dateEvent : String
    -- , event : String
    -- , descriptions : String
    -- , id : String
    -- , title : String
    -- }
    let
        img =
            "http://img.youtube.com/vi/" ++ data.id ++ "/mqdefault.jpg"

        url =
            "https://www.youtube.com/watch?v=" ++ data.id
    in
    "Video "
        ++ link { title = data.title, url = url }
        ++ " - A presentation by **"
        ++ data.by
        ++ "**"
        ++ (if String.isEmpty data.event then
                ""

            else
                " at " ++ data.event
           )
        ++ addDescription data.descriptions
        ++ image
            { title = data.title
            , image = img
            , url = url
            }


link : { a | title : String, url : String } -> String
link data =
    "[" ++ data.title ++ "](" ++ data.url ++ ")"


image : { a | title : String, image : String, url : String } -> String
image data =
    "\n\n[!["
        ++ data.title
        ++ "]("
        ++ data.image
        ++ " \""
        ++ data.title
        ++ "\")]("
        ++ data.url
        ++ ")"


monthToInt : Time.Month -> Int
monthToInt month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


monthToString : Time.Month -> String
monthToString month =
    case month of
        Time.Jan ->
            "January"

        Time.Feb ->
            "February"

        Time.Mar ->
            "March"

        Time.Apr ->
            "April"

        Time.May ->
            "May"

        Time.Jun ->
            "June"

        Time.Jul ->
            "July"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "October"

        Time.Nov ->
            "November"

        Time.Dec ->
            "December"


intToMonth : Int -> Time.Month
intToMonth int =
    case int of
        1 ->
            Time.Jan

        2 ->
            Time.Feb

        3 ->
            Time.Mar

        4 ->
            Time.Apr

        5 ->
            Time.May

        6 ->
            Time.Jun

        7 ->
            Time.Jul

        8 ->
            Time.Aug

        9 ->
            Time.Sep

        10 ->
            Time.Oct

        11 ->
            Time.Nov

        _ ->
            Time.Dec


dateToPosix date =
    case Iso8601.toTime date of
        Ok p ->
            p

        Err _ ->
            Time.millisToPosix 0


dateParser :
    { a | dateEvent : String, datePublished : String, title : String }
    -> ParsedDate
dateParser data =
    let
        posixEvent =
            dateToPosix data.dateEvent

        posixPublished =
            dateToPosix data.datePublished

        posix =
            if Time.toYear Time.utc posixEvent == 2022 then
                posixEvent

            else if Time.toYear Time.utc posixPublished == 2022 then
                posixPublished

            else
                let
                    _ =
                        Debug.log "Could not find a right date" data
                in
                Time.millisToPosix 0
    in
    { year = Time.toYear Time.utc posix
    , month = Time.toMonth Time.utc posix
    , day = Time.toDay Time.utc posix
    , posix = posix
    }


typeToString : Year2022.Others.Type_ -> String
typeToString type_ =
    case type_ of
        Year2022.Others.Undecided ->
            ""

        Year2022.Others.Post ->
            "Post"

        Year2022.Others.Game ->
            "Game"

        Year2022.Others.Announcement ->
            "Announcement"

        Year2022.Others.Tutorial ->
            "Tutorial"

        Year2022.Others.Survey ->
            "Survey"

        Year2022.Others.Presentation ->
            "Presentation"

        Year2022.Others.Project ->
            "Project"

        Year2022.Others.Podcast ->
            "Podcast"


meta : String
meta =
    """---
title: Elm 2022, a year in review
published: false
description: A list of contributions made in the year 2022 to the Elm  language. From blog posts to videos, from tutorials to demos.
tags: elm, webdev, frontend
cover_image: https://dev-to-uploads.s3.amazonaws.com/uploads/articles/up22o7o2r2ze68du5zqd.gif
---"""


header : String
header =
    """
    
2022 has been another exciting year for Elm, with many interesting packages, blog posts, videos, podcasts, demos, tutorials, applications, and so on. 

Let's have a look at it in retrospective.

This is a list of relevant material. I am sure there is stuff that I missed. [Send me a DM](https://twitter.com/luca_mug) in case you think there is something that I should add or remove.

If you want to keep up with Elm's related news:

* Subscribe to the [Elm Weekly newsletter](https://www.elmweekly.nl/) or follow it on [Twitter](https://twitter.com/elmweekly)
* Join the [Elm community on Slack](https://elm-lang.org/community/slack)
* Check [discourse.elm-lang.org](https://discourse.elm-lang.org/)
* Follow [@elmlang on Twitter](https://twitter.com/elmlang)
* Listen to the [Elm Radio podcast](https://elm-radio.com/)
* Browse the [Elm-Craft website](https://elmcraft.org/)
* Check [Incremental Elm Discord](https://incrementalelm.com/chat/) for working on Elm open source projects

You can also check the previous [Elm 2021, a year in review](https://dev.to/lucamug/elm-2021-a-year-in-review-4pho).

Here we go 🚀
"""

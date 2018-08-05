module Data.Board exposing (Board, Hashid, stringToHashid, hashidParser, hashidToString)

import UrlParser


type alias Board =
    { id : String, name : String, hashid : Hashid }


type Hashid
    = Hashid String


stringToHashid : String -> Hashid
stringToHashid id =
    Hashid id


hashidParser : UrlParser.Parser (Hashid -> a) a
hashidParser =
    UrlParser.custom "HASHID" (Ok << Hashid)


hashidToString : Hashid -> String
hashidToString (Hashid id) =
    id

module Style exposing (batch, empty)

import Css


empty =
    Css.batch []


batch a se =
    Css.batch [ a, se ]

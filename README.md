# SeraphLabs

helpful libraries for creating starnet contracts

## Install

```
pip install https://github.com/Seraph-Labs/cairo-contracts
```

# Arrays

| libraries                                          |               description               |
| :------------------------------------------------- | :-------------------------------------: |
| [Array](src/SeraphLabs/arrays/Array.cairo)         |     library for manipulating Arrays     |
| [UintArray](src/SeraphLabs/arrays/UintArray.cairo) | library for manipulating Uint256 Arrays |

# Tokens

| libraries                                              |                        description                        |
| :----------------------------------------------------- | :-------------------------------------------------------: |
| [ERC721S](src/SeraphLabs/tokens/ERC721S/library.cairo) | library for ERC721S token standard a variation of ERC721A |
| [ERC3525](src/SeraphLabs/tokens/ERC3525/library.cairo) |            library for ERC3525 token standard             |
| [ERC2114]()                                            |                         :warning:                         |

# Strings

| libraries                                                |                                  description                                  |
| :------------------------------------------------------- | :---------------------------------------------------------------------------: |
| [AsciiArray](src/SeraphLabs/strings/AsciiArray.cairo)    |            used to convert variable into an array of ascii numbers            |
| [JsonString](src/SeraphLabs/strings/JsonString.cairo)    | used to make onchain dynamic json strings to stream line frontend development |
| [StringObject](src/SeraphLabs/models/StringObject.cairo) |                            object used for strings                            |

# Math

| libraries                                                |                          description                          |
| :------------------------------------------------------- | :-----------------------------------------------------------: |
| [Time](src/SeraphLabs/math/Time.cairo)                   | library used to format or calculate felts into time variables |
| [simple_checks](src/SeraphLabs/math/simple_checks.cairo) |            library used for simple math functions             |
| [logicalOpr](src/SeraphLabs/math/logicalOpr.cairo)       |            simple library used for basic operators            |

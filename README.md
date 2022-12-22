# Seraph Labs

Libraries for StarkNet development by Seraph Labs.

## Install

```
pip install https://github.com/Seraph-Labs/cairo-contracts
```

# Tokens

| Libraries                                               |                        Description                        |
| :-----------------------------------------------------  | :-------------------------------------------------------: |
| [ERC-721S](src/SeraphLabs/tokens/ERC721S/library.cairo) | Library for ERC-721S, a variation of Azuki's ERC-721A.    |
| [ERC-3525](src/SeraphLabs/tokens/ERC3525/library.cairo) |                  Library for ERC-3525                     |
| [ERC-2114](src/SeraphLabs/tokens/ERC3525/library.cairo) |                  Library for ERC-2114                     |

### ERC 2114/3525 Usage

> ### ⚠️ WARNING! ⚠️
>
> Since ERC-2114 and ERC-3525 is an extension of ERC-721, some functions have to be implemented when using transfer functions:
>
> **ERC-3525** : Implement the `ERC3525_clearUnitApprovals()` function
> for ERC721S `transferFrom` functon and ERC2114 `scalarTransferFrom`
>
> **ERC-2114** : Implement the `_ERC2114_assert_notOwnedByToken()` function
> for ERC721S `transferFrom` functon

# Arrays

| Libraries                                          |               Description               |
| :------------------------------------------------- | :-------------------------------------: |
| [Array](src/SeraphLabs/arrays/Array.cairo)         |     Library for manipulating Arrays     |
| [UintArray](src/SeraphLabs/arrays/UintArray.cairo) | Library for manipulating uint256 Arrays |

# Strings

| Libraries                                                |                                  Description                                  |
| :------------------------------------------------------- | :---------------------------------------------------------------------------: |
| [ASCIIArray](src/SeraphLabs/strings/AsciiArray.cairo)    |           Used  to convert variables into an array of ASCII numbers            |
| [JSONString](src/SeraphLabs/strings/JsonString.cairo)    | Used to make Onchain Dynamic JSON strings to streamline frontend development |
| [StringObject](src/SeraphLabs/models/StringObject.cairo) |                            Object used for strings                            |

# Math

| Libraries                                                |                          Description                          |
| :------------------------------------------------------- | :-----------------------------------------------------------: |
| [Time](src/SeraphLabs/math/Time.cairo)                   | Library used to format or calculate felts into time variables |
| [simple_checks](src/SeraphLabs/math/simple_checks.cairo) |            Library used for simple math functions             |
| [logicalOpr](src/SeraphLabs/math/logicalOpr.cairo)       |            Simple library used for basic operators            |

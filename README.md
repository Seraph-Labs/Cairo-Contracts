# SeraphLabs

helpful libraries for creating starnet contracts

## Install

```
pip install git+https://github.com/0xKahi/SeraphLabs
```

# Arrays

| libraries                                                |            description             |
| :------------------------------------------------------- | :--------------------------------: |
| [Array](src/SeraphLabs/arrays/Array.cairo)               |  library for manipulating Arrays   |
| [ReverseArray](src/SeraphLabs/arrays/ReverseArray.cairo) | deprecated use Array.cairo instead |
| [ConcatArray](src/SeraphLabs/arrays/ConcatArray.cairo)   | deprecated use Array.cairo instead |

## Array lib functions

### Creating Arrays

| function        | args       | description                                   | example              | output      |
| :-------------- | :--------- | :-------------------------------------------- | :------------------- | :---------- |
| `create()`      | NIL        | creates an empty array with 0 length          | Array.create()       | [ ]         |
| `create_asc()`  | len : felt | creates an array of felts in ascending order  | Array.create_asc(5)  | [1,2,3,4,5] |
| `create_desc()` | len : felt | creates an array of felts in descending order | Array.create_desc(5) | [5,4,3,2,1] |

### Manipulating Arrays

| function                  | args          | description                                                          | example                                          | output        |
| :------------------------ | :------------ | :------------------------------------------------------------------- | :----------------------------------------------- | :------------ |
| `concat()`                | 2 felt arrays | concatenates 2 arrays together                                       | Array.concat([1,2,3],[1,2,3])                    | [1,2,3,1,2,3] |
| `reverse()`               | 1 felt array  | reverses an array                                                    | Array.reverse([1,2,3])                           | [3,2,1]]      |
| `remove_array_of_items()` | 2 felt arrays | takes 2 arrays and removes all items in 2nd Array from the 1st Array | Array.remove_array_of_items([1,2,3,2,4,5],[2,5]) | [1,3,4]       |

# Strings

| libraries                                                |                                  description                                  |
| :------------------------------------------------------- | :---------------------------------------------------------------------------: |
| [AsciiArray](src/SeraphLabs/strings/AsciiArray.cairo)    |            used to convert variable into an array of ascii numbers            |
| [JsonString](src/SeraphLabs/strings/JsonString.cairo)    | used to make onchain dynamic json strings to stream line frontend development |
| [StringObject](src/SeraphLabs/models/StringObject.cairo) |                            object used for strings                            |

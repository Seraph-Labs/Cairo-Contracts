# SeraphLabs

helpful libraries for creating starnet contracts

## Install

```
pip install git+https://github.com/0xKahi/SeraphLabs
```

# Arrays

| libraries                                                |               description               |
| :------------------------------------------------------- | :-------------------------------------: |
| [Array](src/SeraphLabs/arrays/Array.cairo)               |     library for manipulating Arrays     |
| [UintArray](src/SeraphLabs/arrays/UintArray.cairo)       | library for manipulating Uint256 Arrays |
| [ReverseArray](src/SeraphLabs/arrays/ReverseArray.cairo) |   deprecated use Array.cairo instead    |
| [ConcatArray](src/SeraphLabs/arrays/ConcatArray.cairo)   |   deprecated use Array.cairo instead    |

## Array lib functions

### Creating Arrays

| function        | description                                   | example              | output      |
| :-------------- | :-------------------------------------------- | :------------------- | :---------- |
| `create()`      | creates an empty array with 0 length          | Array.create()       | [ ]         |
| `create_asc()`  | creates an array of felts in ascending order  | Array.create_asc(5)  | [1,2,3,4,5] |
| `create_desc()` | creates an array of felts in descending order | Array.create_desc(5) | [5,4,3,2,1] |

### Manipulating Arrays

| function                  | description                                                          | example                                                      | output        |
| :------------------------ | :------------------------------------------------------------------- | :----------------------------------------------------------- | :------------ |
| `concat()`                | concatenates 2 arrays together                                       | Array.concat([1,2,3],[1,2,3])                                | [1,2,3,1,2,3] |
| `reverse()`               | reverses an array                                                    | Array.reverse([1,2,3])                                       | [3,2,1]]      |
| `remove_array_of_items()` | takes 2 arrays and removes all items in 2nd Array from the 1st Array | Array.remove_array_of_items([1,2,3,2,4,5],[2,5])             | [1,3,4]       |
| `remove_array_of_uints()` | same as `remove_array_of_items()` but for Uint256 arrays             | UintArray.remove_array_of_uints([(1,0),(2,0),(1,0)],[(1,0)]) | [(2,0)]       |

### Comparing Arrays

| function         | description                                                          | example                             | output |
| :--------------- | :------------------------------------------------------------------- | :---------------------------------- | :----- |
| `contains()`     | compare 2 arrays if array 1 has elements in array2 return TRUE       | Array.contains([1,2],[2,3])         | TRUE   |
| `contains_all()` | compare 2 arrays if all of array 1 elements is in array2 return TRUE | Array.contains_all([1,2,3],[1,2,3]) | TRUE   |

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

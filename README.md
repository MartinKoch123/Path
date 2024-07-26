# Path
Class for working with filesystem paths in MATLAB with short and readable code.

[Examples](#Examples)  
[Requirements](#Requirements)  
[Installation](#Installation)  
[Reference](#Reference) 

[![View Path on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/87552-path)

 ## Examples
 ### Create
 ```Matlab
>> file = Path("C:\projects") \ "portal_gun.mdl"

    Path("C:\projects\portal_gun.mdl")
```
### Properties
```Matlab
>> file.parent

    Path("C:\projects")

>> file.setExtension(".pew")

    Path("C:\projects\portal_gun.pew")
 ```
### Clean
```Matlab
>> Path("C:/stuff/../moreStuff\\//") \ "\subStuff//" / "./file.txt"

    Path("C:\moreStuff\subStuff\file.txt")
```

 ### Arrays
 ```Matlab
>> sounds = Path("cat_sounds") / ["meow", "prr", "hsss"] + ".mp3"

     Path("cat_sounds\meow.mp3")
     Path("cat_sounds\prr.mp3")
     Path("cat_sounds\hsss.mp3")

>> sounds.copyToDir("dog_triggers")
``` 
### Delete files matching criteria
```Matlab
>> files = Path("C:\Windows").listFiles.where("Stem", "*Virus*").delete
```
### Enter directory of executing file
```Matlab
Path.here.cd
```

## Requirements
MATLAB R2019b or newer

## Installation
Download or clone this repository and add it to your MATLAB search path. 

## Reference

### Constructor

`Path(arg1, arg2, ...)`

Supports `string`, `char` or `Path` vectors or `cell` vectors of said types.

### Type conversions 

| Method | Return type | Description |
|-|-|-|
| `string`| `string `|  Convert to string |
| `char` | `char `|  Convert to char array |
| `cellstr` | `cell `| Convert to cell of char arrays |

### Properties

| Method | Return type | Description |
|-|-|-|
| `name` | `Path` | File or folder name without directory |
| `parent` | `Path` | Parent directory |
| `root` | `Path` | First directory element of absolute paths |
| `stem` | `string` | File name without extension |
| `extension` | `string` | File extension |
| `parts` | `string` | Split path into list comprising root, folders and name |
| `strlength` | `double` | Number of characters in the path string |
| `absolute` | `Path` | Absolute path assuming the current working directory as reference |
| `relative` | `Path` | Path relative to reference directory |
| `is` | `logical` | Whether properties match patterns |
| `isAbsolute` | `logical` | Whether path is absolute |
| `isRelative` | `logical` | Whether path is relative |

### Modify
| Method | Return type | Description |
|-|-|-|
| `/`, `\`, `join` | `Path` | Join paths |
| `+`, `addSuffix` | `Path` | Add string to the end of the path |
| `setName` | `Path` | Set file or folder name without directory |
| `setParent` | `Path` | Set parent directory |
| `setRoot` | `Path` | Set first directory element |
| `setStem` | `Path` | Set file name without extension |
| `setExtension` | `Path` | Set file extension |
| `addStemSuffix` | `Path` | Add string to the end of the file stem |
| `regexprep` | `Path` | Wrapper for built-in [`regexprep`](https://www.mathworks.com/help/matlab/ref/regexprep.html) |
| `tempFileName` | `Path` | Append random unique file name |

### Compare and filter
| Method | Return type | Description |
|-|-|-|
| `==`, `eq` | `logical` | Whether path strings are equal |
| `~=`, `ne` | `logical` | Whether path strings are unequal |
| `where` | `Path` | Select paths where properties match patterns |

### File system interaction
| Method | Return type | Description |
|-|-|-|
| `exists` | `logical` | Whether path exists in filesystem |
| `isFile`| `logical` | Whether path is an existing file |
| `isDir`| `logical` | Whether path is an existing directory |
| `mustExist` | - | Raise error if path does not exist |
| `mustBeFile` | - | Raise error if path is not an existing file |
| `mustBeDir` | - | Raise error if path is not an existing directory |
| `modifiedDate` | `datetime` | Date and time of last modification |
| `bytes` | - | File size in bytes |
| `mkdir` | - | Create directory if it does not already exist |
| `cd` | `Path` | Wrapper for built-in [`cd`](https://www.mathworks.com/help/matlab/ref/cd.html) |
| `createEmptyFile` | - | Create an empty file |
| `delete` | - | Delete files and directories. Remove directories recursively with optional argument `'s'`. |
| `fopen` | `[double, char]` | Wrapper for built-in [`fopen`](https://www.mathworks.com/help/matlab/ref/fopen.html) |
| `open` | `[double, onCleanup]` | Open file and return file ID and `onCleanup` object, which closes the file on destruction. Create parent directory if necessary. Raise error on failure. |
| `readText` | `string` | Read text file |
| `writeText` | - | Write text file |
| `copy` | - | Copy to new path |
| `copyToDir` | - | Copy into target directory preserving the original name |
| `move` | - | Move to new path (rename) |
| `moveToDir` | - | Move into target directory preserving the original name |
| `listFiles` | `Path` | List file paths in directory |
| `listDeepFiles` | `Path` | List files paths in directory and all its subdirectories |
| `listFolders` | `Path` | List directories in directory |
| `listDeepFolders` | `Path` | List directories and subdirectories in directory |

### Array
| Method | Return type | Description |
|-|-|-|
| `isEmpty` | `logical` | Check if array is empty |
| `count` | `double` | Number of elements |
| `sort` | `[Path, double]` | Sort by path string |
| `unique_` | `[Path, double, double]` | Wrapper for built-in [`unique`](https://www.mathworks.com/help/matlab/ref/unique.html) |
| `deal` | `[Path, Path, ...]` | Distribute array objects among output arguments |

### Factories
| Method | Return type | Description |
|-|-|-|
| `Path.current` | `Path` | Current working directory; wrapper for built-in [`pwd`](https://www.mathworks.com/help/matlab/ref/pwd.html) |
| `Path.home` | `Path` | User home directory |
| `Path.tempDir` | `Path` | Temporary directory; wrapper for built-in [`tempdir`](https://www.mathworks.com/help/matlab/ref/tempdir.html) |
| `Path.tempFile` | `Path` | Random unique file in temporary directory; wrapper for built-in [`tempname`](https://www.mathworks.com/help/matlab/ref/tempname.html) |
| `Path.matlab` | `Path` | MATLAB install directory; wrapper for built-in [`matlabroot`](https://www.mathworks.com/help/matlab/ref/matlabroot.html) |
| `Path.searchPath` | `Path` | Folders on MATLAB search path; wrapper for built-in [`path`](https://www.mathworks.com/help/matlab/ref/path.html) |
| `Path.userPath` | `Path` | MATLAB user directory; wrapper for built-in [`userpath`](https://www.mathworks.com/help/matlab/ref/userpath.html) |
| `Path.ofMatlabFile` | `Path` | Path of MATLAB file on the MATLAB search path |
| `Path.this` | `Path` | Path of MATLAB file executing this method |
| `Path.here` | `Path` | Directory of MATLAB file executing this method |
| `Path.empty` | `Path` | Empty object array |

### Other
| Method | Return type | Description |
|-|-|-|
| `disp` | - | Display in console |
| `help` | - | Open documentation web page |

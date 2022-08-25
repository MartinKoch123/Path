# Path
Class for representing filesystem paths in MATLAB and solveing path-related problems with short and readable code.

[Features](#Features)  
[Examples](#Examples)  
[Installation](#Installation)  
[Reference](#Reference) 

[![View Path on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/87552-path)

## Features
 - Get and set path name, parent, root, stem and extension
 - Filter paths by extension, name, etc. using wildcards
 - List files recursively
 - Handle lists of paths
 - Clean and resolve paths
 - Build absolute and relative paths
 - Create, copy, move, delete files and directories
 - Get folder of currently executing MATLAB file

 ## Examples
 ### Path properties
 ```Matlab
>> file = Path("C:\data") \ "model.dat"
    Path("C:\data\model.dat")
>> file.parent
    Path("C:\data")
>> file.stem
    "model"
>> file.extension
    ".dat"
 ```
 ### Arrays of paths
 ```Matlab
>> personalFolders = Path("Astronauts") / ["Arthur", "Trillian", "Zaphod"]
     Path("Astronauts\Andrew")
     Path("Astronauts\Trudy")
     Path("Astronauts\Sniffels")
>> personalFolders.join("DONT_PANIC.txt").createEmptyFile;
``` 
### Filtering and chaining
```Matlab
>> files = Path("Sketchy Folder").listDeepFiles
    Path("Sketchy Folder\DeleteStuffVirus.exe")
    Path("Sketchy Folder\System32\nastyWorm.dll")
    Path("Sketchy Folder\dark_corner\half_a_sandwich.dat")
    Path("Sketchy Folder\WormholeResearch.pdf")
>> files.where("Stem", ["*Virus*", "*Worm*"], "ExtensionNot", ".pdf").moveToDir("D:\Quarantine");
```
### Go to directory of executing file
```Matlab
scriptFile = Path.ofCaller
    Path("C:/projects/SpaceCatapult/simulate.m")
scriptFile.parent.cd;
```
## Installation
Download this repository and add it to your MATLAB search path. 
Requires R2019b or newer.

## Reference

### Constructor

Create `Path` objects by calling `Path(...)` with one or multiple arguments of type `string` vector, `char` vector, `cell` of `string` or `char` vectors.

### Type conversions 

| Method | Description | Return type
|-|-|-|
| `string`|  Convert to string | `string `|
| `char` |  Convert to char array | `char `|
| `cellstr` | Convert to cell of char arrays | `cell `|

### Properties

| Method | Description | Return type
|-|-|-|
| `name` | File or folder name without directory | `Path` |
| `parent` | Parent directory | `Path` |
| `root` | First directory element of absolute paths | `Path` |
| `stem` | File name without extension | `string` |
| `extension` | File extension | `string` |
| `parts` | Split path into list comprising root, folders and name | `string` |
| `strlength` | Number of characters in the path string | `double` |
| `absolute` | Absolute path assuming the current working directory as reference | `Path` |
| `relative` | Path relative to reference directory | `Path` |
| `is` | Whether properties match patterns | `logical` |
| `isAbsolute`, `isRelative` | Whether path is absolute or relative | `logical` |

### Modify
| Method | Description | Return type
|-|-|-|
| `/`, `\`, `join` | Join paths. | `Path` |
| `setName` | Set file or folder name without directory | `Path` |
| `setParent` | Set parent directory | `Path` |
| `setRoot` | Set first directory element | `Path` |
| `setStem` | Set file name without extension | `Path` |
| `setExtension` | Set file extension | `Path` |
| `addSuffix` | Add string to the end of the path | `Path` |
| `addStemSuffix` | Add string to the end of the file stem | `Path` |
| `regexprep` | Wrapper for built-in [`regexprep`](https://www.mathworks.com/help/matlab/ref/regexprep.html) | `Path` |

### Compare and filter
| Method | Description | Return type
|-|-|-|
| `==`, `eq` | Whether path strings are equal | `logical` |
| `~=`, `ne` | Whether path strings are unequal | `logical` |
| `where` | Select paths where properties match patterns | `Path` |

### File system interaction
| Method | Description | Return type
|-|-|-|
| `exists` | Whether path exists in filesystem | `logical` |
| `mustExist` | Raise error if path does not exist | - |
| `modifiedDate` | Date and time of last modification | `datetime` |
| `createEmptyFile` | Create an empty file | - |
| `fopen` | Wrapper for built-in [`fopen`](https://www.mathworks.com/help/matlab/ref/fopen.html) | `double`; `char` |
| `open` | Open file and return file ID and `onCleanup` object, which closes the file on destruction. Create parent folder if necessary. Raise error on failure. | `double`; `onCleanup` |
| `readText` | Read text file | `string` |
| `writeText` | Write text file | - |
| `copy` | Copy to new path | - |
| `copyToDir` | Copy into target directory preserving the original name | - |
| `move` | Move to new path (rename) | - |
| `moveToDir` | Move into target directory preserving the original name | - |
| `delete` | Delete files and directories. Remove directories recursively with optional argument `'s'`. | - |
| `bytes` | File size in bytes | - |
| `cd` | Wrapper for built-in [`cd`](https://www.mathworks.com/help/matlab/ref/cd.html) | `Path` |
| `mkdir` | Create directory if it does not already exist | - |
| `listFiles` | List file paths in directory | `Path` |
| `listDeepFiles` | List files paths in directory and all its subdirectories | `Path` |
| `listFolders` | List directories in directory | `Path` |
| `listDeepFolders` | List directories and subdirectories in directory | `Path` |
| `tempFileName` | Append random unique file name | `Path` |

### Array
| Method | Description | Return type
|-|-|-|
| `isEmpty` | Check if array is empty | `logical` |
| `count` | Number of elements | `double` |
| `sort` | Sort by path string | `Path`; `double` |
| `unique_` | Wrapper for built-in [`unique`](https://www.mathworks.com/help/matlab/ref/unique.html) | `Path`; `double`; `double` |
| `deal` | Distribute array objects among output arguments | `Path`; `Path`; ... |

### Factories
| Method | Description | Return type
|-|-|-|
| `Path.current` | Current working directory; wrapper for built-in [`pwd`](https://www.mathworks.com/help/matlab/ref/pwd.html) | `Path` |
| `Path.home` | User home directory | `Path` |
| `Path.tempDir` | Temporary directory; wrapper for built-in [`tempdir`](https://www.mathworks.com/help/matlab/ref/tempdir.html) | `Path` |
| `Path.tempFile` | Random unique file in temporary directory; wrapper for built-in [`tempname`](https://www.mathworks.com/help/matlab/ref/tempname.html) | `Path` |
| `Path.matlab` | Matlab install directory; wrapper for built-in [`matlabroot`](https://www.mathworks.com/help/matlab/ref/matlabroot.html) | `Path` |
| `Path.searchPath` | Folders on Matlab search path; wrapper for built-in [`path`](https://www.mathworks.com/help/matlab/ref/path.html) | `Path` |
| `Path.userPath` | Matlab user directory; wrapper for built-in [`userpath`](https://www.mathworks.com/help/matlab/ref/userpath.html) | `Path` |
| `Path.ofMatlabElement` | Path of Matlab file on the Matlab search path | `Path` |
| `Path.ofCaller` | Path of Matlab file executing this method | `Path` |
| `Path.empty` | Empty object array | `Path` |

### Other
| Method | Description | Return type
|-|-|-|
| `disp` | Display in console | - |
| `help` | Open documentation web page | - |



 

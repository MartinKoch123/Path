# Path
Classes for handling filesystem paths in MATLAB.

The `File` and `Folder` classes allow you to solve your path-related problems using short and readable code.

[![View Path on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/87552-path)

## Features
 - Get and set path name, parent, root, stem and extension
 - Filter paths by extension, name, etc. using wildcards
 - List files recursively
 - Handle lists of paths
 - Clean and resolve paths
 - Build absolute and relative paths
 - Automatically create folder when writing files and throw error on failure
 - Get folder of currently executing MATLAB file

 ## Examples
 ### Path properties
 ```Matlab
>> file = File("C:\data\model.dat")
    File("C:\data\model.dat")
>> file.parent
    Folder("C:\data")
>> file.stem
    "model"
>> file.extension
    ".dat"
 ```
 ### Arrays of paths
 ```Matlab
>> personalFolders = Folder("astronauts") / ["Andrew", "Trudy", "Sniffels"]
     Folder("astronauts\Andrew")
     Folder("astronauts\Trudy")
     Folder("astronauts\Sniffels")
>> personalFolders.append("DONT_PANIC.txt").createEmptyFile;
``` 
### Filtering and chaining
```Matlab
>> files = Folder("Sketchy Folder").listDeepFiles
    File("Sketchy Folder\DeleteStuffVirus.exe")
    File("Sketchy Folder\System32\nastyworm.dll")
    File("Sketchy Folder\dark_corner\half_a_sandwich.dat")
    File("Sketchy Folder\WormholeResearch.pdf")
>> files.whereStemIs(["*Virus*", "*Worm*"]).whereExtensionIsNot(".pdf").copyToFolder("D:\Quarantine");
```
### Get path of executing file
```Matlab
>> scriptFile = File.ofCaller
    File("/MATLAB Drive/YesIMadeAnExtraScriptToDemonstrateThis.m")
>> scriptFile.parent.cd;
```
## Installation
Download this repository and add it to your MATLAB search path. Requires R2019b or newer.
 
## Documentation
Find the documentation in the [wiki](https://www.github.com/MartinKoch123/Path/wiki).
 


 

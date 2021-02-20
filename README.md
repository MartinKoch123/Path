# Path
 MATLAB Classes for handling filesystem paths

 Path operations in MATLAB tend to be cumbersome. This package aims so make everything you ever needed to do with a path less annoying and produce highly readable code in the process. It consists of the `File` and `Folder` classes, which represents filesystem paths and provide functionality for extracting path properties, manipulate and combine paths and interact with the filesystem. 
 [![View Path on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/87552-path)
  
 ## Examples
 ```Matlab
>> personalFolders = Folder("astronauts") / ["Andrew", "Trudy", "Sniffels"]

     Folder("astronauts\Andrew")
     Folder("astronauts\Trudy")
     Folder("astronauts\Sniffels")
     
>> personalFolders.append("DONT_PANIC.txt").createEmptyFile;
``` 
```Matlab
>> files = Folder("Sketchy Folder").listDeepFiles

    File("Sketchy Folder\DeleteStuffVirus.exe")
    File("Sketchy Folder\System32\nastyworm.dll")
    File("Sketchy Folder\dark_corner\half_a_sandwich.dat")
    File("Sketchy Folder\WormholeResearch.pdf")

>> files.whereStemIs(["*Virus*", "*Worm*"]).whereExtensionIsNot(".pdf").copyToFolder("D:\Quarantine");
```
```Matlab
>> script = File.ofCaller
  
    Folder("C:\Users\marti\MATLAB Drive\YesIMadeAScriptJustToDemonstrateThis.m")
    
>> script.parent.cd;
 ```
 
 ## Requirements
 Code was tested on Windows and Linux with MATLAB R2020b. It will definitely not work with MATLAB versions older than R2019b.
 
 ## Documentation
 Find the documentation in the [wiki](https://www.github.com/MartinKoch123/Path/wiki).
 
 ## Installation
 Download this repository and add it to your MATLAB search path.

 

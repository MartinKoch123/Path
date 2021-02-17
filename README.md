# Path
 MATLAB Classes for handling filesystem paths
 
 The `File` and `Folder` classes represents filesystem paths and provide functionality for extracting path properties, manipulate and combine paths and interact with the filesystem.
 
 ```Matlab
>> launchDataFolders = Folder("LaunchPreparations") / ["Fuel", "Food", "Towels"]

    Folder("LaunchPreparations\Fuel")
    Folder("LaunchPreparations\Food")
    Folder("LaunchPreparations\Towels")
     
>> launchDataFolders.append("DONT_PANIC.txt").createEmptyFile;
 
>> File.ofCaller
  
    Folder("C:\Users\marti\MATLAB Drive\YesIMadeAScriptJustToDemonstrateThis.m")
 
>> Folder("C:").containedFiles.whereStemIs(["*Virus*", "*Worm*"]).whereExtensionIsNot(".pdf").copyToFolder("D:\Quarantine");
 ```
 
 ## Requirements
 Code was tested on Windows and Linux with MATLAB R2020b. It will definitely not work with MATLAB versions older than R2019b.
 
 ## Documentation
 Find the documentation in the [wiki](https://www.github.com/MartinKoch123/Path/wiki).
 
 ## Installation
 Download this repository and add it to your MATLAB search path.
 
 ## Example Usage
 
 ### Construct
 ```Matlab
>> file = File("C:\essentials\WriteJournalPaper.exe")

     File("C:\essentials\WriteJournalPaper.exe")

>> folder = Folder("..\Rocket Science\Data")

     Folder("..\Rocket Science\Data")
```

### Inspect
```
>> file.parent

     Folder("C:\essentials")
     
>> file.extension

    ".exe"
 ```
 
### Concatenate
```
>> folder.parent / "LaunchSchedule.xlsx"

     File("..\Rocket Science\LaunchSchedule.xlsx")
```

### Filter
```
>> File("cats.txt; dogs.dat; donkeys.csv").whereStemIs("do*")

     File("dogs.dat")
     File("donkeys.csv")
```
 
 

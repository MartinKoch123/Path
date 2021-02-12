# Path
 MATLAB Classes for handling filesystem paths
 
 The `File` and `Folder` classes represents filesystem paths and provide functionality for extracting path properties, manipulate and combine paths and interact with the filesystem.
 
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
>> folder.parent / "LauchSchedule.xlsx"

     File("..\Rocket Science\LauchSchedule.xlsx")
```

### Filter
```
>> File("cats.txt; dogs.dat; donkeys.csv").whereStemIs("do*")

     File("dogs.dat")
     File("donkeys.csv")
```
 
 

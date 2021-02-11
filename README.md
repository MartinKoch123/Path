# Path
 MATLAB Class for handling filesystem paths
 
 The `Path` class represents filesystem paths and provides functionality for extracting path properties, manipulate and combine paths and interact with the filesystem.
 
 ## Example Usage
 
 ### Construct
 ```Matlab
>> path = Path("C:\folder\file.txt")

path = 

     Path("C:\folder\file.txt")
```

### Inspect
```
>> path.parent

     Path("C:\folder")

>> path.extension

    ".txt"
 ```
 
### Concatenate
```
>> path.parent / "data.mat"

     Path("C:\folder\data.mat")
```

### Filter
```
>> Path("cats.txt; dogs.dat; donkeys.csv").whereStemIs("do*")

     Path("dogs.dat")
     Path("donkeys.csv")
```
 
 

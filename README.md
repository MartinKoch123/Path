# Path
 MATLAB Class for handling filesystem paths
 
 The `Path` class represents filesystem paths and provides functionality for extracting path properties, manipulate and combine paths and interact with the filesystem.
 
 ## Examples Usage
 
 ### Constructor
 ```Matlab
>> path = Path("C:\folder\file.txt")

path = 

     Path("C:\folder\file.txt")
```

### Path properties
```
>> disp(path.parent)
     Path("C:\folder")

>> disp(path.extension)
.txt
 ```
 
 ### Concatenate
```
>> disp(path.parent \ "data.mat")
     Path("C:\folder\data.mat")
```
    
 
 

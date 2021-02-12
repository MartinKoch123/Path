classdef Folder < Path
    
    methods
        
        %% Name
        function result = name(objects)
            result = objects.selectFolder(@(obj) Folder(obj.stem_ + obj.extension_));
        end
        
        %% Append         
        function result = append(objects, appendage)
            arguments
                objects(1, :)
            end
            arguments (Repeating)
                appendage (1, :) string {mustBeNonmissing}
            end
            
            appendage = [appendage{:}];
            appendage = Path.clean(appendage);
            
            extension = regexp(appendage, "(?<!\.|^)\.[^\.]*$", "once", "match");
            if all(ismissing(extension))
                result = objects.appendFolder(appendage);
            elseif all(~ismissing(extension))
                result = objects.appendFile_(appendage);
            else
                error("Folder:append:Ambiguous", "Could not determine if file or folder. Occurence of extensions is ambiguous. Use methods ""appendFile"" or ""appendFolder"" instead.");
            end
        end
        
        function result = appendFile(objects, appendage)
            arguments
                objects(1, :)
            end
            arguments (Repeating)
                appendage (1, :) string {mustBeNonmissing}
            end            
            appendage = File(appendage{:});            
            result = objects.appendFile_(appendage);
        end
        
        function result = appendFolder(objects, appendage)
            arguments
                objects(1, :)
            end
            arguments (Repeating)
                appendage (1, :) string {mustBeNonmissing}
            end            
            appendage = Folder(appendage{:});      
            result = objects.appendFolder_(appendage);
        end
        
        function result = mrdivide(objects, appendage)
            result = objects.append(appendage);
        end
        
        function result = mldivide(objects, appendage)
            result = objects.append(appendage);
        end
        
        %% File system interaction                
        function result = exists(objects)
            result = arrayfun(@(obj) isfolder(obj.string), objects);
        end            
        
        function mustExist(objects)
            for obj = objects
                if ~obj.exists
                    exception = MException("Folder:mustExist:Failed", "Folder ""%s"" not found.", obj.string);
                    throwAsCaller(exception);
                end
            end
        end 
        
        function mkdir(objects)
            for obj = objects
                if obj.exists
                    return;
                end
                try
                    mkdir(obj.string);
                catch exception
                    handle(exception, "MATLAB:MKDIR", "Error while creating folder ""%s"".", obj);
                end
            end
        end
    end
    
    methods (Static)
        
        function result = ofMatlabElement(elements)
            result = File.ofMatlabElement(elements).parent;
        end

        
        function result = ofCaller
            stack = dbstack;
            if length(stack) == 1
                error("Folder:ofCaller:NoCaller", "This method was not called from another file."); end
            callingFile = stack(2).file;
            result = File.ofMatlabElement(callingFile).parent;
        end 
        

    end
    
    methods (Access = private)
        function result = appendFile_(objects, files)
            if isempty(objects) || isempty(files)
                result = objects;
                return 
            elseif isscalar(objects) || isscalar(files) || length(objects) == length(files)
                result = File(objects.string + filesep + files.string);
            else
                error("Folder:append:LengthMismatch", "Length of object array, %i, and length of appendage array, %i, must either match or one of them must be scalar.", length(objects), length(files));
            end
        end
        
        function result = appendFolder_(objects, folders)
            if isempty(objects) || isempty(folders)
                result = objects;
                return 
            elseif isscalar(objects) || isscalar(folders) || length(objects) == length(folders)
                result = Folder(objects.string + filesep + folders.string);
            else
                error("Folder:append:LengthMismatch", "Length of object array, %i, and length of appendage array, %i, must either match or one of them must be scalar.", length(objects), length(folders));
            end
        end
    end
end
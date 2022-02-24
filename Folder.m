classdef Folder < Path
% Folder Represents a folder path.
% 
% For details, visit the <a href="matlab:
% web('https://github.com/MartinKoch123/Path/wiki')">documentation on GitHub</a>.
    
    methods
        
        %% Name        
        function result = setName(objects, varargin)
            result = objects.parent.appendFolder(varargin{:});
        end
        
        %% Append         
        function varargout = append(objects, appendage)
            arguments
                objects(1, :)
            end
            arguments (Repeating)
                appendage (1, :) string {mustBeNonmissing}
            end
            
            appendage = Path.clean(appendage{:});            
            extension = regexp(appendage, "(?<!\.|^)\.[^\.]*$", "once", "match");
            if all(ismissing(extension))
                result = objects.appendFolder(appendage);
            elseif all(~ismissing(extension))
                result = objects.appendFile_(appendage);
            else
                error("Folder:append:Ambiguous", "Could not determine if file or folder. Occurence of extensions is ambiguous. Use methods ""appendFile"" or ""appendFolder"" instead.");
            end
            varargout = deal_(result, nargout);
        end
        
        function varargout = appendFile(objects, appendage)
            arguments
                objects(1, :)
            end
            arguments (Repeating)
                appendage (1, :) string {mustBeNonmissing}
            end            
            appendage = Path.clean(appendage{:});                  
            result = objects.appendFile_(appendage);
            varargout = deal_(result, nargout);
        end
        
        function varargout = appendFolder(objects, appendage)
            arguments
                objects(1, :)
            end
            arguments (Repeating)
                appendage (1, :) string {mustBeNonmissing}
            end            
            appendage = Path.clean(appendage{:});               
            result = objects.appendFolder_(appendage);
            varargout = deal_(result, nargout);
        end
        
        function varargout = mrdivide(objects, appendage)
            result = objects.append(appendage);
            varargout = deal_(result, nargout);
        end
        
        function varargout = mldivide(objects, appendage)
            result = objects.append(appendage);
            varargout = deal_(result, nargout);
        end
        
        %% File system interaction                
        function result = exists(objects)
            result = arrayfun(@(obj) isfolder(obj.string), objects);
        end            
        
        function result = modifiedDate(objects)
            objects.mustExist
            result(objects.count) = datetime;
            for i = 1 : objects.count
                content = objects(i).dir;
                result(i) = datetime(content({content.name} == ".").datenum, "ConvertFrom", "datenum");
            end
        end
        
        function varargout = cd(obj)
            arguments
                obj (1, 1)
            end
            if nargout == 1
                varargout = {Folder(pwd)};
            end
            try
                cd(obj.string);
            catch exception
                throwAsCaller(exception); 
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
                    extendError(exception, "MATLAB:MKDIR", "Error while creating folder ""%s"".", obj);
                end
            end
        end
        
        function result = listFiles(objects)
            filePaths = strings(1, 0);
            objects.mustExist;
            for obj = objects.unique_
                contentInfo = obj.dir;
                fileInfo = contentInfo(~[contentInfo.isdir]);
                for i = 1 : length(fileInfo)
                    filePaths(end+1) = obj.string + "\" + fileInfo(i).name;
                end
            end
            result = File(filePaths);
        end
        
        function result = listDeepFiles(objects)
            filePaths = strings(1, 0);
            objects.mustExist;
            for obj = objects.unique_
                filePaths = [filePaths, listFiles(obj.string)];
            end
            result = File(filePaths);
        end
        
        function result = tempFile(obj, n)
            arguments
                obj (1, 1)
                n (1, 1) {mustBeInteger, mustBeNonnegative} = 1
            end
            result = File.empty;
            for i = n : -1 : 1
                result(i) = File(tempname(obj.string));
            end
        end
        
        function rmdir(objects, varargin)
            for obj = objects
                rmdir(obj.string, varargin{:});
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
            callingFile = string(stack(2).file);
            if callingFile.startsWith("LiveEditorEvaluationHelper")
                error("Folder:ofCaller:LiveScript", "Calling this method from a live script is not supported. Consider using 'Folder.ofMatlabElement' instead. Example: Folder.ofMatlabElement(""PathExamples.mlx"")."); end
            result = File.ofMatlabElement(callingFile).parent;
        end 
        
        function result = empty
            result = Folder;
            result = result(double.empty(1, 0));
        end
        
        function result = temp
            result = Folder(tempdir);
        end
        
        function result = current
            result = Folder(pwd);
        end
        
        function result = home
            if Path.IS_WINDOWS
                result = Folder(getenv("USERPROFILE"));
            else
                result = Folder(getenv("HOME"));
            end
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
                exception = MException("Folder:append:LengthMismatch", "Length of object array, %i, and length of appendage array, %i, must either match or one of them must be scalar.", length(objects), length(folders));
                throwAsCaller(exception);
            end
        end
    end
    
    
end

function result = listFiles(folder)    
    result = strings(0);    
    folderContents = dir(folder)';    
    for folderContent = folderContents
        path = folder + filesep + folderContent.name;
        if folderContent.isdir
            if folderContent.name == "." || folderContent.name == ".."
                continue; end
            result = [result, listFiles(path)];
        else
            result(end+1) = path;
        end        
    end    
end

function result = deal_(paths, outputCount)
if outputCount > 1
    try
        [result{1:outputCount}] = paths.deal;
    catch exception
        if exception.identifier == "Path:deal:InvalidNumberOfOutputs"
            throwAsCaller(exception)
        end
        rethrow(exception);
    end
else
    result{1} = paths;
end
end
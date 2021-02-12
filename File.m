classdef File < Path
    
    methods
        
        %% Name
        function result = name(objects)
            result = objects.selectFile(@(obj) File(obj.stem_ + obj.extension_));
        end
        
        %% Stem
        function result = stem(objects)
            result = objects.selectString(@(obj) obj.stem_);
        end
        
        function result = hasStem(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.stem_, pattern, true));
        end
        
        function result = whereStemIs(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.stem_, pattern, true));
        end
        
        function result = hasNotStem(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.stem_, pattern, false));
        end
        
        function result = whereStemIsNot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.stem_, pattern, false));
        end
        
        %% Extension
        function result = extension(objects)
            result = objects.selectString(@(obj) obj.extension_);
        end
        
        function result = hasExtension(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.extension_, pattern, true));
        end
        
        function result = whereExtensionIs(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.extension_, pattern, true));
        end
        
        function result = hasNotExtension(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.extension_, pattern, false));
        end
        
        function result = whereExtensionIsNot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.extension_, pattern, false));
        end
        
        %% File system interaction
        function result = exists(objects)
            result = arrayfun(@(obj) isfile(obj.string), objects);
        end
                
        function mustExist(objects)
            for obj = objects
                if ~obj.exists
                    exception = MException("File:mustExist:Failed", "File ""%s"" not found.", obj.string);
                    throwAsCaller(exception);
                end
            end
        end 
        
        function createEmptyFile(objects)
            for obj = objects
                obj.parent.mkdir;
                fileId = fopen(obj.string, 'w');
                fclose(fileId);
            end
        end
        
        function copyToFolder(objects, targetFolder)
            arguments
                objects
                targetFolder (1, 1) Path
            end
            for i = 1 : objects.count
                obj = objects(i);
                obj.mustExist;
                if obj.fileExists
                    sourceType = "file";
                else
                    sourceType = "folder";
                end
                if targetFolder.fileExists
                    error("Path:copyToFolder:TargetFolderIsFile", "The target folder ""%s"" is an existing file.", targetFolder); end
                try                    
                    targetFolder.mkdir;
                    target = targetFolder \ obj.name;
                    copyfile(obj.string, target.string);
                catch exception
                    handle(exception, ["MATLAB:COPYFILE:", "MATLAB:MKDIR:"], "Unable to copy %s ""%s"" to folder ""%s"".", sourceType, obj, targetFolder);
                end
            end
        end
    end
    
    methods (Static)
        
        function result = ofMatlabElement(elements)
            arguments
                elements (1, :) string {mustBeNonmissing}
            end
            result = File.empty;
            for element = elements
                path = string(which(element));
                
                % If the queried element happens to have the name of a
                % variable in this function, temporarily rename that
                % variable.
                if path == "variable"
                    temp = eval(element);
                    clearvars(element);
                    path = string(which(element));
                    eval(element + " = temp");
                end
                
                if path.startsWith("built")
                    
                    % Remove "build in" and brackets.
                    path = regexprep(path, ["^[^\(]*\(", "\)$"], "");
                elseif path == ""
                    error("File:ofMatlabElement:NotFound", "Element ""%s"" is not on the search path.", element);
                end
                result(end+1) = File(path);
            end
        end
        
        function result = ofCaller
            stack = dbstack;
            if length(stack) == 1
                error("File:ofCaller:NoCaller", "This method was not called from another file."); end
            callingFile = stack(2).file;
            result = File.ofMatlabElement(callingFile);
        end 
    end
    
end
classdef File < Path
% File Represents a file path.
%
% For details, visit the <a href="matlab:
% web('https://github.com/MartinKoch123/Path/wiki')">documentation on GitHub</a>.

    
    methods (Static)

        function result = ofMatlabElement(elements)
            arguments
                elements (1, :) string {Path.mustBeNonmissing}
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

        function result = ofCaller(level)
            arguments
                level (1, 1) double {mustBeInteger, mustBePositive} = 1
            end
            stack = dbstack("-completenames");
            if length(stack) < level + 1
                error("File:ofCaller:NoCaller", "This method was not called from another file at the requested stack level."); end
            callingFilePath = string(stack(level + 1).file);
            callingFileBaseName = regexp(callingFilePath.string, "(+[\w\d_]+(\\|/))*[\w\d_\.]+$", "match", "once");
            if callingFileBaseName.startsWith("LiveEditorEvaluationHelper")
                error("File:ofCaller:LiveScript", "Calling this method from a live script is not supported. Consider using 'File.ofMatlabElement' instead. Example: File.ofMatlabElement(""PathExamples.mlx"")."); end
            result = File.ofMatlabElement(callingFileBaseName);
        end

        function result = empty
            result = File;
            result = result(double.empty(1, 0));
        end

        function result = temp(n)
            arguments
                n (1, 1) {mustBeInteger, mustBeNonnegative} = 1
            end
            result = File.empty;
            for i = 1:n
                result(i) = File(tempname);
            end
        end
    end

    methods (Access = protected)
        function onCopying(obj, target)
            if isfolder(target.string)
                error("Path:copy:TargetFileIsFolder", "The target ""%s"" is an existing folder.", target); end
        end
    end

end

function tryToClose(fileId)
try
    fclose(fileId);
catch 
end
end

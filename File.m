classdef File < Path
% File Represents a file path.
%
% For details, visit the <a href="matlab:
% web('https://github.com/MartinKoch123/Path/wiki')">documentation on GitHub</a>.

    methods

        %% Name
        function result = setName(objects, varargin)
            result = objects.parent.appendFile(varargin{:});
        end

        %% Stem
        function result = stem(objects)
            result = objects.selectString(@(obj) obj.stem_);
        end

        function objects = setStem(objects, stems)
            arguments
                objects(1, :)
                stems (1, :) string {Path.mustBeValidName, Path.mustBeEqualSizeOrScalar(stems, objects)}
            end
            if isscalar(stems)
                stems = repmat(stems, 1, objects.count);
            end
            for i = 1 : length(objects)
                objects(i).stem_ = stems(i);
            end
        end

        function objects = addStemSuffix(objects, suffix)
            arguments
                objects(1, :)
                suffix (1, :) string {Path.mustBeValidName, Path.mustBeEqualSizeOrScalar(suffix, objects)}
            end
            if isscalar(suffix)
                suffix = repmat(suffix, 1, objects.count);
            end
            for i = 1 : length(objects)
                objects(i).stem_ = objects(i).stem_ + suffix(i);
            end
        end

        %% Extension
        function result = extension(objects)
            result = objects.selectString(@(obj) obj.extension_);
        end

        function results = setExtension(objects, extension)
            arguments
                objects (1, :)
                extension (1, :) string {File.mustBeValidExtension, Path.mustBeEqualSizeOrScalar(extension, objects)}
            end
            missesDotAndIsNonEmpty = ~extension.startsWith(".") & strlength(extension) > 0;
            extension(missesDotAndIsNonEmpty) = "." + extension(missesDotAndIsNonEmpty);
            results = File([objects.parent_] + [objects.stem_] + extension);
        end
        
        %% Filter
        function result = where(objects, options)
            arguments
                objects
                options.Stem (1, :) string = "*"
                options.StemNot (1, :) string = strings(0);
                options.Extension (1, :) string = "*"
                options.ExtensionNot (1, :) string = strings(0)
                options.Path (1, :) string = "*"
                options.PathNot (1, :) string = strings(0);
                options.Name (1, :) string = "*"
                options.NameNot (1, :) string = strings(0)
                options.Parent (1, :) string = "*"
                options.ParentNot (1, :) string = strings(0)
                options.Root (1, :) string = "*"
                options.RootNot (1, :) string = strings(0)
            end
            
            args = namedargs2cell(options);
            keep =  objects.is(args{:});
            result = objects(keep);
            if isempty(result)
                result = objects.new([]);
            end
        end

        function result = is(objects, options)
            arguments
                objects
                options.Stem (1, :) string = "*"
                options.StemNot (1, :) string = strings(0);
                options.Extension (1, :) string = "*"
                options.ExtensionNot (1, :) string = strings(0)
                options.Path (1, :) string = "*"
                options.PathNot (1, :) string = strings(0);
                options.Name (1, :) string = "*"
                options.NameNot (1, :) string = strings(0)
                options.Parent (1, :) string = "*"
                options.ParentNot (1, :) string = strings(0)
                options.Root (1, :) string = "*"
                options.RootNot (1, :) string = strings(0)
            end
            for option = ["Stem", "StemNot", "Extension", "ExtensionNot"]
                options.(option) = Path.clean(options.(option));
            end
            
            stemStrings = objects.stem;
            extensionStrings = objects.extension;

            result =  ...
                Path.matches2(stemStrings, options.Stem, true) & ...
                Path.matches2(stemStrings, options.StemNot, false) & ...
                Path.matches2(extensionStrings, options.Extension, true) & ...
                Path.matches2(extensionStrings, options.ExtensionNot, false);

            for option = ["Stem", "StemNot", "Extension", "ExtensionNot"]
                options = rmfield(options, option);
            end
            args = namedargs2cell(options);
            result = result & objects.is@Path(args{:});

        end
        
        %% File system interaction
        function result = exists(objects)
            result = objects.selectFile(@(obj) isfile(obj.string));
        end

        function result = modifiedDate(objects)
            objects.mustExist;
            result(objects.count) = datetime;
            for i = 1 : objects.count
                result(i) = datetime(objects(i).dir.datenum, "ConvertFrom", "datenum");
            end
        end

        function createEmptyFile(objects)
            for obj = objects
                [~, autoClose] = obj.openForWriting;
            end
        end

        function varargout = fopen(obj, varargin)
            arguments; obj (1, 1); end
            arguments (Repeating); varargin; end
            [varargout{1:nargout}] = fopen(obj.string, varargin{:});
        end

        function [id, autoClose] = open(obj, permission, varargin)
            arguments
                obj (1, 1)
                permission (1, 1) string = "r";
            end
            arguments (Repeating); varargin; end

            if permission.startsWith("r")
                obj.mustExist;
            else
                obj.parent.mkdir;
            end
            [id, errorMessage] = obj.fopen(permission, varargin{:});
            if id == -1
                error(errorMessage); end
            if nargout == 2
                autoClose = onCleanup(@() tryToClose(id)); end
        end

        function [id, autoClose] = openForReading(obj)
            id = obj.open;
            if nargout == 2
                autoClose = onCleanup(@() tryToClose(id)); end
        end

        function [id, autoClose] = openForWriting(obj)
            id = obj.open("w");
            if nargout == 2
                autoClose = onCleanup(@() tryToClose(id)); end
        end

        function [id, autoClose] = openForWritingText(obj)
            id = obj.open("wt");
            if nargout == 2
                autoClose = onCleanup(@() tryToClose(id)); end
        end

        function [id, autoClose] = openForAppendingText(obj)
            id = obj.open("at");
            if nargout == 2
                autoClose = onCleanup(@() tryToClose(id)); end
        end

        function delete(objects)
            for obj = objects
                if obj.exists
                    delete(obj.string)
                end
            end
        end

        function result = readText(obj)
            arguments
                obj (1, 1)
            end
            obj.mustExist;
            result = string(fileread(obj.string));
            result = result.replace(sprintf("\r\n"), newline);
        end

        function writeText(obj, text)
            arguments
                obj (1, 1)
                text (1, 1) string
            end
            [fileId, autoClose] = obj.openForWritingText;
            fprintf(fileId, "%s", text);
        end

        function result = bytes(objects)
            result = [objects.dir.bytes];
        end

        %% Save and load
        function save(obj, variables)
            arguments
                obj (1, 1)
            end
            arguments (Repeating)
                variables (1, 1) string {File.mustBeValidVariableName}
            end
            if isempty(variables)
                error("Path:load:MissingArgument", "Not enough inputs arguments.");
            end
            for variable = [variables{:}]
                saveStruct.(variable) = evalin("caller", variable);
            end
            obj.parent.mkdir;
            save(obj.string, "-struct", "saveStruct");
        end

        function varargout = load(obj, variables)
            arguments
                obj (1, 1)
            end
            arguments (Repeating)
                variables (1, 1) string {File.mustBeValidVariableName}
            end

            if nargout ~= length(variables)
                error("Path:load:InputOutputMismatch", "The number of outputs, %i, must match the number of variables to load, %i.", nargout, length(variables)); end
            data = load(obj.string, variables{:});
            varargout = {};
            for variable = string(variables)
                if ~isfield(data, variable)
                    error("Path:load:VariableNotFound", "Variable ""%s"" not found in file ""%s"".", variable, obj); end
                varargout{end+1} = data.(variable);
            end
        end

        function result = mrdivide(~, ~)
            error("Not supported for objects of class File");
        end

        function result = mldivide(~, ~)
            error("Not supported for objects of class File");
        end
    end

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

    methods (Static, Access = private)
        function mustBeValidExtension(values)
            if any(values.contains(["\", "/", pathsep]))
                throwAsCaller(MException("Path:Validation:InvalidExtension", "Value must be a valid extension."));
            end
        end

        function mustBeValidVariableName(values)
            if any(arrayfun(@(x) ~isvarname(x), values))
                throwAsCaller(MException("Path:Validation:InvalidVariableName", "Value must be a valid variable name."));
            end
        end
    end

end

function tryToClose(fileId)
try
    fclose(fileId);
catch 
end
end

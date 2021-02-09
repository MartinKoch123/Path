classdef Path
    
    properties
        extension_
        stem_
        parent_
        root_
    end
    
    properties (Constant, Hidden)
        FILE_SEPARATOR_REGEX = regexptranslate("escape", filesep);
        isWindows = true;
    end
    
    methods
        function obj = Path(args)
            arguments (Repeating)
                args (1, :) string {mustBeNonmissing};
            end
            
            % Default constructor
            if isempty(args)
                obj = Path(".");
                return
            end

            % Convert to string vector.
            args = [args{:}];
            
            % Empty constructor
            if isempty(args)
                obj = Path.empty(1, 0);
                return
            end
            
            % Resolve path separators.
            args = args.join(pathsep).split(pathsep);          
            pathCount = length(args);
            
            obj(pathCount) = obj;
            fs = Path.FILE_SEPARATOR_REGEX;
            
            for i = 1 : pathCount
                args(i) = Path.clean(args(i));
                
                % Extract parent directory and name.
                match = regexp(args(i), "^(?<parent>.*?)(?<name>[^"+fs+"]+)$", "names");
                
                % Extract stem and extension from name.
                if match.name == ".." || match.name == "."
                    stem = match.name;
                    extension = "";
                else
                    match2 = regexp(match.name, "^(?<stem>.*?)(?<extension>(\.[^\.]*|))$", "names");
                    extension = match2.extension;
                    stem = match2.stem;
                end
                

                obj(i).parent_ = match.parent;
                obj(i).stem_ = stem;
                obj(i).extension_ = extension;
            end
        end
        
        function disp(objects)        
            if isscalar(objects)
                fprintf("     Path(""%s"")\n", objects.string);
                return
            end
            fprintf("  %i×%i Path array\n\n", size(objects, 1), size(objects, 2));            
            if isempty(objects)
                return; end
            for obj = objects
                fprintf("     Path(""%s"")\n", obj.string);
            end
            fprintf("\n");
        end
        
        
        %% Conversion
        function result = string(objects)
            result = [objects.parent_] + [objects.stem_] + [objects.extension_];
        end
        
        function result = char(obj)
            arguments
                obj (1, 1)
            end
            result = char(obj.string);
        end
        
        function result = charCell(objects)
            result = arrayfun(@char, objects, 'UniformOutput', false);
        end
        
        %% Properties        
        function result = name(objects)
            result = Path([objects.stem_] + [objects.extension_]);
        end
        
        function result = extension(objects)
            result = [objects.extension_];
        end
        
        function result = stem(objects)
            result = [objects.stem_];
        end
        
        function result = parent(objects)
            result = Path([objects.parent_]);
        end
        
        function result = root(objects)
            if Path.isWindows
                expression = "^(\\\\[^\\]+|[A-Za-z]:|)";
            else
                error("Not implemented.");
            end
            result = string(regexp(objects.string, expression, "match", "emptymatch"));
        end
        
        function result = isRelative(objects)
            result = [objects.root] == "";
        end
        
        function result = isAbsolute(objects)
            result = ~objects.isRelative;
        end
        
        %% Manipulation
        function result = append(objects, appendage)
            arguments
                objects(1, :)
            end
            arguments (Repeating)
                appendage
            end
            
            appendagePath = Path(appendage{:});
            
            if isempty(objects) || isempty(appendagePath)
                result = objects;
                return 
            elseif isscalar(objects) || isscalar(appendagePath) || length(objects) == length(appendagePath)
                result = Path(objects.string + filesep + appendagePath.string);
            else
                error("Path:append:LengthMismatch", "Length of object array, %i, and length of appendage array, %i, must either match or one of them must be scalar.", length(objects), length(appendage));
            end
        end
        
        function result = mrdivide(objects, appendage)
            result = objects.append(appendage);
        end
        
        function result = mldivide(objects, appendage)
            result = objects.append(appendage);
        end
        
        %% Filter
        function result = where(objects, filters)
            arguments
                objects
                filters.Name (1, :) string = missing;
                filters.Stem(1, :) string = missing;
                filters.Extension (1, :) string = missing;
                filters.Parent(1, :) string = missing;
                filters.NameNot (1, :) string = missing;
                filters.StemNot (1, :) string = missing;
                filters.ExtensionNot (1, :) string = missing;
                filters.ParentNot (1, :) string = missing;
            end
            
            keep = true(size(objects));
            for i = 1 : length(objects)
                if ~ismissing(filters.Name)
                    keep(i) = keep(i) & any(objects(i).name.string == filters.Name); end
                if ~ismissing(filters.Stem)
                    keep(i) = keep(i) & any(objects(i).stem == filters.Stem); end
                if ~ismissing(filters.Extension)
                    keep(i) = keep(i) & any(objects(i).extension == filters.Extension); end
                if ~ismissing(filters.Parent)
                    keep(i) = keep(i) & any(objects(i).parent.string == filters.Parent); end
                if ~ismissing(filters.NameNot)
                    keep(i) = keep(i) & all(objects(i).name.string ~= filters.NameNot); end
                if ~ismissing(filters.StemNot)
                    keep(i) = keep(i) & all(objects(i).stem ~= filters.StemNot); end
                if ~ismissing(filters.ExtensionNot)
                    keep(i) = keep(i) & all(objects(i).extension ~= filters.ExtensionNot); end                
                if ~ismissing(filters.ParentNot)
                    keep(i) = keep(i) & all(objects(i).parent.string ~= filters.ParentNot); end       
            end
            result = objects(keep);
        end
        
        %% File system interaction        
        function result = exists(objects)
            result = objects.fileExists & objects.folderExists;
        end
        
        function result = fileExists(objects)
            result = arrayfun(@(obj) isfile(obj.string), objects);
        end
        
        function result = folderExists(objects)
            result = arrayfun(@(obj) isfolder(obj.string), objects);
        end            
        
        function mkdir(objects)
            for obj = objects
                if obj.folderExists
                    return;
                end
                try
                    mkdir(obj.string);
                catch exception
                    if startsWith(string(exception.identifier), 'MATLAB:MKDIR')
                        error(exception.identifier, "Error while creating folder ""%s"".\n%s", obj, exception.message); end
                end
            end
        end
        
        function writeEmptyFile(objects)
            for obj = objects
                obj.parent.mkdir;
                fileId = fopen(obj.string, 'w');
                fclose(fileId);
            end
        end
        
        %% Save and load        
        function save(obj, variables)
            arguments
                obj (1, 1)
            end
            arguments (Repeating)
                variables (1, 1) string {mustBeValidVariableName}
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
                variables (1, 1) string {mustBeValidVariableName}
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
    end
    
    methods (Static)
        function result = ofMatlabElement(elements)
            arguments
                elements (1, :) string {mustBeNonmissing}
            end
            result = Path.empty;
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
                    error("Path:ofMatlabElement:NotFound", "Element ""%s"" is not on the search path.", element);
                end
                result(end+1) = Path(path);
            end
        end
        
        function result = ofCaller
            stack = dbstack;
            if length(stack) == 1
                error("Path:ofCaller:NoCaller", "This method was not called from another file."); end
            callingFile = stack(2).file;
            result = Path.ofMatlabElement(callingFile);
        end 
    end
    
    methods (Static, Access = private)
        function s = clean(s)
            fs = Path.FILE_SEPARATOR_REGEX;
            
            s = s.strip;
            
            % Replace / and \ with correct separator.
            s = s.replace(["\", "/"], filesep);
            
            % Remove repeating separators.
            if Path.isWindows
                s = regexprep(s, "(?<!^)" + fs + "+", fs);
            else
                s = regexprep(s, fs + "+", fs);
            end
            
            % Remove leading and trailing separators.
            if Path.isWindows
                expression = ["^"+fs+"(?!"+fs+")", fs+"+$"];
            else
                expression = fs+"+$";
            end
            s = regexprep(s, expression, "");
            
            % Remove current-directory-dots.
            s = regexprep(s, ["(?<=(^|"+fs+"))(\."+fs+")", "("+fs+"\.)$"], "");
            
            % Resolve folder-up-dots.
            expression = "("+fs+"|^)[^"+fs+":]+(?<!\.\.)"+fs+"\.\."; % Folder name folled by folder-up dots.
            while ~isempty(regexp(s, expression, 'once'))
                s = regexprep(s, expression, "");
            end
            
            if s == ""
                s = ".";
            end
        end
    end
end
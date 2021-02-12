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
        function obj = Path(paths)
            arguments (Repeating)
                paths (1, :) string {mustBeNonmissing};
            end
            
            % Default constructor
            if isempty(paths)
                paths = ".";
            else
                paths = [paths{:}];
            end
            
            % Empty constructor
            if isempty(paths)
                obj = obj.empty(1, 0);
                return
            end
            
            % Resolve path separators.
            paths = Path.clean(paths);
            pathCount = length(paths);
            
            obj(pathCount) = obj;
            fs = Path.FILE_SEPARATOR_REGEX;
            
            for i = 1 : pathCount
                
                % Extract parent directory and name.
                match = regexp(paths(i), "^(?<parent>.*?)(?<name>[^"+fs+"]+)$", "names");
                
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
                fprintf("     %s(""%s"")\n", class(objects), objects.string);
                return
            end
            fprintf("  %i×%i %s array\n\n", size(objects, 1), size(objects, 2), class(objects));
            if isempty(objects)
                return; end
            for obj = objects
                fprintf("     %s(""%s"")\n", class(objects), obj.string);
            end
            fprintf("\n");
        end
        
        
        %% Conversion
        function result = string(objects)
            result = objects.selectString(@(obj) obj.parent_ + obj.stem_ + obj.extension_);
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
        
        %% Name
        function result = hasName(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.stem_ + obj.extension_, pattern, true));
        end
        
        function result = whereName(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.stem_ + obj.extension_, pattern, true));
        end
        
        function result = hasNotName(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.stem_ + obj.extension_, pattern, false));
        end
        
        function result = whereNameNot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.stem_ + obj.extension_, pattern, false));
        end
        
        %% Parent
        function result = parent(objects)
            result = objects.selectFolder(@(obj) Folder(obj.parent_));
        end
        
        function result = hasParent(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern) + "\";
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.parent_, pattern, true));
        end
        
        function result = whereParentIs(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern) + "\";
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.parent_, pattern, true));
        end
        
        function result = hasNotParent(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern) + "\";
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.parent_, pattern, false));
        end
        
        function result = whereParentIsNot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern) + "\";
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.parent_, pattern, false));
        end
        
        %% Root
        function result = root(objects)
            if Path.isWindows
                expression = "^(\\\\[^\\]+|[A-Za-z]:|)";
            else
                error("Not implemented.");
            end
            result = objects.selectString(@(obj) regexp(obj.string, expression, "match", "emptymatch"));
        end
        
        function result = hasRoot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern);
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.root, pattern, true));
        end
        
        function result = whereRootIs(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern);
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.root, pattern, true));
        end
        
        function result = hasNotRoot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern);
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.root, pattern, false));
        end
        
        function result = whereRootIsNot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern);
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.root, pattern, false));
        end
        
        %% Properties
        function result = isRelative(objects)
            result = [objects.root] == "";
        end
        
        function result = isAbsolute(objects)
            result = ~objects.isRelative;
        end
        
        function result = eq(objects, others)
            result = objects.string == others.string;
        end
        
        function result = ne(objects, others)
            result = ~objects.eq(others);
        end
        
        %% List
        function result = count(objects)
            result = numel(objects);
        end
        
        %% Manipulation
        
        
        %% File system interaction
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
    
    methods (Access = protected)
        function result = selectString(objects, fun)
            result = strings(size(objects));
            for i = 1 : numel(objects)
                result(i) = fun(objects(i));
            end
        end
        
        function result = selectLogical(objects, fun)
            result = true(size(objects));
            for i = 1 : numel(objects)
                result(i) = fun(objects(i));
            end
        end
        
        function result = selectFolder(objects, fun)
            if ~isempty(objects)
                for i = numel(objects) : -1 : 1
                    result(i) = fun(objects(i));
                end
            else
                result = Folder.empty(size(objects));
            end
        end
        
        function result = selectFile(objects, fun)
            if ~isempty(objects)
                for i = numel(objects) : -1 : 1
                    result(i) = fun(objects(i));
                end
            else
                result = File.empty(size(objects));
            end
        end
        
        function result = where(objects, filterFun)
            keep = true(1, length(objects));
            for iObject = 1:length(objects)
                keep(iObject) = filterFun(objects(iObject));
            end
            result = objects(keep);
        end
    end
    
    methods (Static, Access = protected)
        function result = clean(paths)
            fs = Path.FILE_SEPARATOR_REGEX;
            result = paths;
            if ~isempty(paths)
                paths = paths.join(pathsep).split(pathsep);
            end
            for i = 1 : length(paths)
                s = paths(i);
                
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
                result(i) = s;
            end
        end
        
        function handle(exception, identifiers, messageFormat, messageArguments)
            arguments
                exception
                identifiers
                messageFormat (1, 1) string
            end
            arguments (Repeating)
                messageArguments
            end
            if any(startsWith(exception.identifier, identifiers))
                messageFormat = messageFormat + "\nCaused by: %s";
                messageArguments{end+1} = exception.message;
                message = sprintf(messageFormat, messageArguments{:});
                exception = MException(exception.identifier, "%s", message);
                throwAsCaller(exception);
            else
                exception.rethrow;
            end
        end
        
        
        function result = matchesWildcardPattern(s, patterns, mode)
            result = ~mode;
            for pattern = regexptranslate("wildcard", patterns)
                if ~isempty(regexp(s, "^"+pattern+"$", 'once'))
                    result = mode;
                    return
                end
            end
        end
        
        
    end
    
    methods (Abstract)
        result = exists(objects);
        mustExist(objects);
    end
end


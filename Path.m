classdef Path < matlab.mixin.CustomDisplay
    % Path Base class for representing filesystem paths.
    %       Type 'Path.help' to see the documentation.
    
    properties (Access = protected)
        extension_
        stem_
        parent_
        root_
    end
    
    properties (Constant, Access = protected, Hidden)
        FILE_SEPARATOR_REGEX = regexptranslate("escape", filesep);
        DOCUMENTATION_WEB_PAGE = "https://github.com/MartinKoch123/Path/wiki";
        ROOT_REGEX_WINDOWS = "^(\\\\[^\\]+|[A-Za-z]:|)";
        ROOT_REGEX_LINUX = "^(/[^/]*|)";
        isWindows = ispc;
    end
    
    methods
        function obj = Path(paths)
            arguments (Repeating)
                paths (1, :) string {mustBeNonmissing};
            end
            
            % Default constructor
            if isempty(paths)
                paths = {"."};
            end
            
            paths = Path.clean(paths{:});
            pathCount = length(paths);
            
            % Empty constructor
            if isempty(paths)
                obj = obj.empty;
                return
            end
            
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
        
        function result = whereNameIs(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.stem_ + obj.extension_, pattern, true));
        end
        
        function result = hasNotName(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.stem_ + obj.extension_, pattern, false));
        end
        
        function result = whereNameIsNot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.stem_ + obj.extension_, pattern, false));
        end
        
        
        %% Parent
        function result = parent(objects)
            result = objects.selectFolder(@(obj) Folder(obj.parent_));
        end
        
        function objects = setParent(objects, parents)
            arguments
                objects(1, :)
                parents (1, :) Folder {Path.mustBeEqualSizeOrScalar(parents, objects)}
            end
            if isscalar(parents)
                parents = repmat(parents, 1, objects.count);
            end
            for i = 1 : length(objects)
                objects(i).parent_ = parents(i).string + filesep;
            end
            
        end
        
        function result = hasParent(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern) + filesep;
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.parent_, pattern, true));
        end
        
        function result = whereParentIs(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern) + filesep;
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.parent_, pattern, true));
        end
        
        function result = hasNotParent(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern) + filesep;
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.parent_, pattern, false));
        end
        
        function result = whereParentIsNot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern) + filesep;
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.parent_, pattern, false));
        end
        
        %% Root
        function result = root(objects)
            if Path.isWindows
                expression = Path.ROOT_REGEX_WINDOWS;
            else
                expression = Path.ROOT_REGEX_LINUX;
            end
            result = objects.selectFolder(@(obj) Folder(regexp(obj.string, expression, "match", "emptymatch")));
        end
        
        function result = setRoot(objects, root)
            arguments
                objects
                root (1, 1) string
            end
            if Path.isWindows
                expression = Path.ROOT_REGEX_WINDOWS;
            else
                expression = Path.ROOT_REGEX_LINUX;
            end
            root = root + filesep;
            result = objects.selectPath(@(obj) objects.new(regexprep(obj.string, expression, root, "emptymatch")), objects.empty);
        end
        
        function result = hasRoot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern);
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.root.string, pattern, true));
        end
        
        function result = whereRootIs(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern);
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.root.string, pattern, true));
        end
        
        function result = hasNotRoot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern);
            result = objects.selectLogical(@(obj) Path.matchesWildcardPattern(obj.root.string, pattern, false));
        end
        
        function result = whereRootIsNot(objects, pattern)
            arguments; objects; pattern (1, :) string = strings(0); end
            pattern = Path.clean(pattern);
            result = objects.where(@(obj) Path.matchesWildcardPattern(obj.root.string, pattern, false));
        end
        
        %% Properties
        function result = isRelative(objects)
            result = [objects.root] == ".";
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
        
        function result = parts(obj)
            arguments
                obj (1, 1)
            end
            result = regexp(obj.string, Path.FILE_SEPARATOR_REGEX, "split");
            result(strlength(result) == 0) = [];
        end
        
        %% Absolute/Relative  
        
        function result = absolute(objects)
            result = objects;
            isRelative = result.isRelative;
            result(isRelative) = objects.new(string(pwd) + filesep + objects(isRelative).string);
        end
        
        function result = relative(objects, referenceFolder)
            arguments
                objects
                referenceFolder (1, 1) Folder = Folder(pwd)
            end
            paths = objects.absolute;            
            referenceFolder = referenceFolder.absolute;
            referenceParts = referenceFolder.parts;
            nReferenceParts = length(referenceParts);
            result = objects.new(strings(0));
            for path = paths
                parts = path.parts;
                nParts = length(parts);
                nLower = min([nParts, nReferenceParts]);
                nEqualParts = find([parts(1:nLower) ~= referenceParts(1:nLower), true], 1) - 1;
                if nEqualParts == 0
                    error("Path:relative:RootsDiffer", "Roots of path ""%s"" and reference folder ""%s"" differ.", path, referenceFolder); end
                folderUps = join([repmat("..", 1, nReferenceParts - nEqualParts), "."], filesep);
                keptTail = join([".", parts(nEqualParts+1 : end)], filesep);
                result(end+1) = objects.new(folderUps + filesep + keptTail);
            end
            
        end
                
        %% File systen interaction
        function result = dir(objects)
            result = struct("name", {}, "folder", {}, "date", {}, "bytes", {}, "isdir", {}, "datenum", {});
            for obj = objects
                result = [result; dir(obj.string)];
            end
        end
        

                
        %% Array
        function result = count(objects)
            result = numel(objects);
        end
        
        function [result, indices] = sort(objects, varargin)
            [~, indices] = sort(objects.string, varargin{:});
            result = objects(indices);
        end
        
        function varargout = unique_(objects, varargin)
            [varargout{1:nargout}] = unique(objects, varargin{:});
        end
        
        function varargout = deal(objects)
            if nargout ~= objects.count
                error("Path:deal:InvalidNumberOfOutputs", "Object array length does not match the number of output arguments."); end
            for i = 1:nargout
                varargout{i} = objects(i);
            end
        end        
        
        function result = vertcat(obj, varargin)
            error("Path:vertcat:NotAllowed", "Vertical concatenation is not allowed. This is necessary to guarentee the functionality of the class methods. Consider using horizontal concatenation instead.");
        end
        
        function result = subsasgn(obj, s, varargin)
            indices = s(end).subs;
            if (length(indices) == 2 && indices{1} ~= 1) || length(indices) > 2
                error("Path:subsasgn:MultiRowsNotAllowed", "Arrays with multiple rows and arrays with more than two dimensions are not allowed. This is necessary to guarentee the functionality of the class methods. Consider using only one indexing dimension instead (""linear indexing""). Example: ""a(2:4) = b""."); end
            result = builtin("subsasgn", obj, s, varargin{:});
        end
        
    end
    
    methods (Static)
        function help
            web(Path.DOCUMENTATION_WEB_PAGE);
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
                result = Folder.empty;
            end
        end
        
        function result = selectFile(objects, fun)
            if ~isempty(objects)
                for i = numel(objects) : -1 : 1
                    result(i) = fun(objects(i));
                end
            else
                result = File.empty;
            end
        end
        
        function result = selectPath(objects, fun, emptyValue)
            result = emptyValue;
            for i = numel(objects) : -1 : 1
                result(i) = fun(objects(i));
            end
        end
        
        function result = where(objects, filterFun)
            keep = true(1, length(objects));
            for iObject = 1:length(objects)
                keep(iObject) = filterFun(objects(iObject));
            end
            result = objects(keep);
        end
        
        function result = new(obj, varargin)
            result = eval(class(obj) + "(varargin{:});");
        end
        
        function displayScalarObject(obj)
            fprintf("    %s(""%s"")\n\n", class(obj), obj.string);
        end
        
        function displayNonScalarObject(objects)
            fprintf("  %s <a href=""matlab:Path.help"">%s</a> array\n\n", matlab.mixin.CustomDisplay.convertDimensionsToString(objects), class(objects));
            if isempty(objects)
                return; end
            for obj = objects
                fprintf("     %s(""%s"")\n", class(obj), obj.string);
            end
            fprintf("\n");
        end
        
        function displayEmptyObject(obj)
            obj.displayNonScalarObject;
        end
    end
    
    methods (Static, Access = protected)
        function result = clean(varargin)
            fs = Path.FILE_SEPARATOR_REGEX;
            paths = [varargin{:}];
            result = paths;
            if isempty(paths)
                return
            end            
            paths = paths.join(pathsep).split(pathsep);
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
        
        function extendError(exception, identifiers, messageFormat, messageArguments)
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
        
        function mustBeEqualSizeOrScalar(value, objects)
            if ~isscalar(value) && ~isequal(numel(value), numel(objects))
                throwAsCaller(MException("Path:Validation:InvalidSize", "Value must be scalar or size must equal size of the object array."));
            end
        end
        
        function mustBeValidName(values)
            if any(values.strlength == 0) || any(values.contains(["\", "/", pathsep]))
                throwAsCaller(MException("Path:Validation:InvalidName", "Value must be a valid file name."));
            end
        end
    end
    
    methods (Abstract)
        result = exists(objects);
        mustExist(objects);
        result = name(objects);
        result = setName(objects, names)        
    end
end


classdef Path < matlab.mixin.CustomDisplay
% Path Base class for representing filesystem paths.
%
% For details, visit the <a href="matlab:
% web('https://github.com/MartinKoch123/Path/wiki')">documentation on GitHub</a>.

    properties (Access = protected)
        extension_
        stem_
        parent_
    end

    properties (Constant, Access=protected, Hidden)
        FILE_SEPARATOR_REGEX = regexptranslate("escape", filesep);
        DOCUMENTATION_WEB_PAGE = "https://github.com/MartinKoch123/Path/wiki";
        ROOT_REGEX_WINDOWS = "^(\\\\[^\\]+|[A-Za-z]:|)";
        ROOT_REGEX_POSIX = "^(/[^/]*|)";
        IS_WINDOWS = ispc;
        ROOT_REGEX = tern(Path.IS_WINDOWS, Path.ROOT_REGEX_WINDOWS, Path.ROOT_REGEX_POSIX)
    end

    methods
        function obj = Path(paths)
            arguments (Repeating)
                paths (1, :) string {Path.mustBeNonmissing};
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
            if isempty(objects)
                result = strings(1, 0);
                return
            end
            result = [objects.parent_] + [objects.stem_] + [objects.extension_];
        end

        function result = char(obj)
            arguments
                obj (1, 1)
            end
            result = char(obj.string);
        end

        function result = cellstr(objects)
            result = cellstr(objects.string);
        end

        function result = quote(objects)
            result = """" + string(objects) + """";
        end

        %% Name
        function result = name(objects)
            result = objects.new(objects.nameString);
        end

        function result = nameString(objects)
            if isempty(objects)
                result = strings(1, 0);
                return
            end
            result = [objects.stem_] + [objects.extension_];
        end

        function result = addSuffix(objects, suffix)
            arguments
                objects(1, :)
                suffix (1, :) string {Path.mustBeValidName, Path.mustBeEqualSizeOrScalar(suffix, objects)}
            end
            result = objects.new(objects.string + suffix);
        end

        %% Parent
        function result = parent(objects)
            result = Folder(objects.parentString);
        end

        function result = parentString(objects)
            if isempty(objects)
                result = strings(1, 0);
                return
            end
            result = [objects.parent_];
            result = regexprep(result, Path.FILE_SEPARATOR_REGEX + "$", "");
            result(result == "") = ".";
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

        function result = hasParent(objects)
            result = objects.is("ParentNot", ".");
        end

        %% Root
        function result = root(objects)
            result = Folder(objects.rootString);
        end
        
        function result = rootString(objects)
            if isempty(objects)
                result = strings(1, 0);
                return
            end
            result = regexp(objects.string, Path.ROOT_REGEX, "match", "emptymatch", "once");
            result(result == "") = ".";
        end

        function result = setRoot(objects, root)
            arguments
                objects
                root (1, 1) string {Path.mustNotContainPathSeparator}
            end
            root = root + filesep;
            result = objects.selectPath(@(obj) objects.new(regexprep(obj.string, Path.ROOT_REGEX, root, "emptymatch")), objects.empty);
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

        function result = strlength(obj)
            result = obj.string.strlength;
        end

        %% Filter
        function result = where(objects, options)
            arguments
                objects
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
            keep = objects.is(args{:});
            result = objects(keep);
            if isempty(result)
                result = objects.new([]);
            end
        end

        function result = is(objects, options)
            arguments
                objects
                options.Path (1, :) string = "*"
                options.PathNot (1, :) string = strings(0);
                options.Name (1, :) string = "*"
                options.NameNot (1, :) string = strings(0)
                options.Parent (1, :) string = "*"
                options.ParentNot (1, :) string = strings(0)
                options.Root (1, :) string = "*"
                options.RootNot (1, :) string = strings(0)
            end
            path        = Path.clean(options.Path);
            pathNot     = Path.clean(options.PathNot);
            name        = Path.clean(options.Name);
            nameNot     = Path.clean(options.NameNot);
            parent      = Path.clean(options.Parent);
            parentNot   = Path.clean(options.ParentNot);
            root        = Path.clean(options.Root);
            rootNot     = Path.clean(options.RootNot);

            pathStrings = objects.string;
            parentStrings = objects.parentString;
            rootStrings = objects.rootString;
            nameStrings = objects.nameString;

            result =  ...
                Path.matches2(pathStrings, path, true) & ...
                Path.matches2(pathStrings, pathNot, false) & ...
                Path.matches2(nameStrings, name, true) & ...
                Path.matches2(nameStrings, nameNot, false) & ...
                Path.matches2(parentStrings, parent, true) & ...
                Path.matches2(parentStrings, parentNot, false) & ...
                Path.matches2(rootStrings, root, true) & ...
                Path.matches2(rootStrings, rootNot, false);
        end

        %% Absolute/Relative
        function result = absolute(objects, referenceFolder)
            arguments
                objects
                referenceFolder (1, 1) Folder = Folder(pwd)
            end
            if referenceFolder.isRelative
                referenceFolder = referenceFolder.absolute;
            end
            isRelative = objects.isRelative;
            result = objects;
            result(isRelative) = objects.new(referenceFolder.string + filesep + objects(isRelative).string);
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

        function mustExist(objects)
            for obj = objects
                if ~obj.exists
                    throwAsCaller(obj.notFoundException);
                end
            end
        end

        function copy(objects, targets)
            arguments
                objects
                targets (1, :) Folder
            end
            objects.copyOrMove(targets, true, false)
        end

        function move(objects, targets)
            arguments
                objects
                targets (1, :) Folder
            end
            objects.copyOrMove(targets, false, false);
        end

        function copyToFolder(objects, targets)
            arguments
                objects
                targets (1, :) Folder
            end
            objects.copyOrMove(targets, true, true);
        end

        function moveToFolder(objects, targets)
            arguments
                objects
                targets (1, :) Folder
            end
            objects.copyOrMove(targets, false, true);
        end

        %% Array
        function result = isEmpty(objects)
            result = isempty(objects);
        end

        function result = count(objects)
            result = numel(objects);
        end

        function [result, indices] = sort(objects, varargin)
            [~, indices] = sort(objects.string, varargin{:});
            result = objects(indices);
        end

        function varargout = unique_(objects, varargin)
            [varargout{1:nargout}] = unique(objects.string, varargin{:});
            varargout{1} = objects.new(varargout{1});
        end

        function varargout = deal(objects)
            if nargout ~= objects.count
                error("Path:deal:InvalidNumberOfOutputs", "Object array length does not match the number of output arguments."); end
            for i = 1:nargout
                varargout{i} = objects(i);
            end
        end

        function result = vertcat(obj, varargin)
            result = horzcat(obj, varargin);
        end

        function result = subsasgn(obj, s, varargin)
            indices = s(end).subs;
            if (length(indices) == 2 && indices{1} ~= 1) || length(indices) > 2
                e = MException("Path:subsasgn:MultiRowsNotSupported", "Column vectors and 2D arrays are not supported. Use only one indexing dimension instead (""linear indexing""). Example: ""a(2:4) = b""."); 
                e.throwAsCaller;
            end
            result = builtin("subsasgn", obj, s, varargin{:});
        end

        function transpose(~)
            MException("Path:transpose:NotSupported", "Transpose operation is not supported.").throwAsCaller;
        end

        function ctranspose(~)
            MException("Path:transpose:NotSupported", "Transpose operation is not supported.").throwAsCaller;
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

        function result = where_(objects, filterFun)
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

        function result = notFoundException(obj)

            result = MException("Path:mustExist:Failed", "%s ""%s"" not found. ", class(obj), obj.string);

            if ~obj.hasParent || obj.parent.exists
                return; end

            currentFolder = obj;
            while true
                if ~currentFolder.hasParent || currentFolder.parent.exists
                    causeException = currentFolder.notFoundException;
                    result = Path.extendError(causeException, missing, "%s", result.message);
                    return
                end
                currentFolder = currentFolder.parent;
            end
        end

        function onCopying(obj, target)
        end

        function copyOrMove(objects, targets, copy, toFolderMode)
            if objects.count == 1 && copy
                objects = repmat(objects, 1, length(targets));
            end
            if targets.count == 1 && toFolderMode
                targets = repmat(targets, 1, length(objects));
            end
            if objects.count ~= length(targets)
                error("Path:copyOrMove:InvalidNumberOfTargets", "Number of target paths must be equal the number of source paths.")
            end
            for i = 1 : objects.count
                obj = objects(i);
                obj.mustExist;
                if toFolderMode
                    target = targets(i) / obj.name;
                else
                    target = targets(i);
                end
                obj.onCopying(target)
                try
                    target.parent.mkdir;
                    if copy
                        copyfile(obj.string, target.string);
                    else
                        movefile(obj.string, target.string);
                    end
                catch exception
                    if copy; operationName = "copy"; else; operationName = "move"; end
                    Path.extendError(exception, ["MATLAB:COPYFILE:", "MATLAB:MOVEFILE:", "MATLAB:MKDIR:"], "Unable to %s %s ""%s"" to ""%s"".", operationName, lower(class(obj)), obj, target);
                end
            end
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
                if Path.IS_WINDOWS
                    s = regexprep(s, "(?<!^)" + fs + "+", fs);
                else
                    s = regexprep(s, fs + "+", fs);
                end

                % Remove current-directory-dots.
                s = regexprep(s, ["(?<=(^|"+fs+"))(\."+fs+")", "("+fs+"\.)$"], "");

                % Resolve folder-up-dots.
                expression = "("+fs+"|^)[^"+fs+":]+(?<!\.\.)"+fs+"\.\."; % Folder name followed by folder-up dots.
                while ~isempty(regexp(s, expression, 'once'))
                    s = regexprep(s, expression, "");
                end

                % Remove leading and trailing separators.
                if Path.IS_WINDOWS
                    expression = ["^"+fs+"(?!"+fs+")", fs+"+$"];
                else
                    expression = fs+"+$";
                end
                s = regexprep(s, expression, "");

                if s == ""
                    s = ".";
                end
                result(i) = s;
            end
        end

        function exception = extendError(exception, identifiers, messageFormat, messageArguments)
            arguments
                exception
                identifiers
                messageFormat (1, 1) string
            end
            arguments (Repeating)
                messageArguments
            end
            if (isscalar(identifiers) && ismissing(identifiers)) || any(startsWith(exception.identifier, identifiers))
                messageFormat = messageFormat + "\nCaused by: %s";
                messageArguments{end+1} = exception.message;
                message = sprintf(messageFormat, messageArguments{:});
                exception = MException(exception.identifier, "%s", message);
                if nargout == 0
                    throwAsCaller(exception);
                end
            else
                exception.rethrow;
            end
        end

        function result = matches(s, patterns, mode)
            result = ~mode;
            for pattern = regexptranslate("wildcard", patterns)
                if ~isempty(regexp(s, "^"+pattern+"$", 'once'))
                    result = mode;
                    return
                end
            end
        end

        function result = matches2(s, patterns, mode)
            pattern = "^(" + regexptranslate("wildcard", patterns).join("|") + ")$";
            indices = regexp(s, pattern, "once", "emptymatch");
            if isscalar(s)
                result = isempty(indices);
            else
                result = cellfun(@isempty, indices);
            end
            if mode 
                result = ~result;
            end

        end

        function mustBeEqualSizeOrScalar(value, objects)
            if ~isscalar(value) && ~isequal(numel(value), numel(objects))
                throwAsCaller(MException("Path:Validation:InvalidSize", "Value must be scalar or size must equal size of the object array."));
            end
        end

        function mustBeValidName(values)
            if any(ismissing(values)) || any(values.contains(["\", "/", pathsep]))
                throwAsCaller(MException("Path:Validation:InvalidName", "Value must be a valid file name."));
            end
        end

        function mustNotContainPathSeparator(values)
            if any(values.contains(pathsep))
                throwAsCaller(MException("Path:Validation:ContainsPathsep", "Value must not contain a path separator character."));
            end
        end

        function mustBeNonmissing(values)
            if any(ismissing(values))
                throwAsCaller(MException("Path:Validation:InvalidName", "Value must be non-missing."));
            end
        end
    end

    methods (Abstract)
        result = exists(objects);
        result = setName(objects, names)
    end
end

function result = tern(condition, a, b)
if condition
    result = a;
else
    result = b;
end
end
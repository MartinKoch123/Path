classdef Path < matlab.mixin.CustomDisplay
    % Path Represents file system paths
    %
    % For details, visit the <a href="matlab:
    % web('https://github.com/MartinKoch123/Path')">documentation on GitHub</a>.

    properties (Access = private)
        extension_
        stem_
        parent_
    end

    properties (Constant, Access=private, Hidden)
        FILE_SEPARATOR_REGEX = regexptranslate("escape", filesep);
        DOCUMENTATION_WEB_PAGE = "https://github.com/MartinKoch123/Path";
        ROOT_REGEX_WINDOWS = "^(\\\\[^\\]+|[A-Za-z]:|)";
        ROOT_REGEX_POSIX = "^(/[^/]*|)";
        IS_WINDOWS = ispc;
        ROOT_REGEX = ifThenElse(Path.IS_WINDOWS, Path.ROOT_REGEX_WINDOWS, Path.ROOT_REGEX_POSIX)
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
            n = length(paths);

            % Empty constructor
            if isempty(paths)
                obj = obj.empty;
                return
            end

            obj(n) = obj;
            fs = Path.FILE_SEPARATOR_REGEX;

            for i = 1 : n

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
            result = Path(objects.nameString);
        end

        function result = setName(objects, varargin)
            result = objects.parent.join(varargin{:});
        end

        function result = nameString(objects)
            if isempty(objects)
                result = strings(1, 0);
                return
            end
            result = [objects.stem_] + [objects.extension_];
        end

        %% Stem
        function result = stem(objects)
            result = objects.selectString(@(obj) obj.stem_);
        end

        function results = setStem(objects, stem)
            arguments
                objects(1, :)
                stem (1, :) string {Path.mustBeValidName, Path.mustBeEqualSizeOrScalar(stem, objects)}
            end
            if isscalar(stem)
                stem = repmat(stem, 1, objects.count);
            end
            results = Path([objects.parent_] + stem + [objects.extension_]);
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
                extension (1, :) string {Path.mustBeValidExtension, Path.mustBeEqualSizeOrScalar(extension, objects)}
            end
            missesDotAndIsNonEmpty = ~extension.startsWith(".") & strlength(extension) > 0;
            extension(missesDotAndIsNonEmpty) = "." + extension(missesDotAndIsNonEmpty);
            results = Path([objects.parent_] + [objects.stem_] + extension);
        end

        %% Parent
        function result = parent(objects)
            result = Path(objects.parentString);
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

        function objects = setParent(objects, parent)
            arguments
                objects(1, :)
                parent (1, :) Path {Path.mustBeEqualSizeOrScalar(parent, objects)}
            end
            if isscalar(parent)
                parent = repmat(parent, 1, objects.count);
            end
            for i = 1 : length(objects)
                objects(i).parent_ = parent(i).string + filesep;
            end
        end

        function result = hasParent(objects)
            result = objects.is("ParentNot", ".");
        end

        %% Root
        function result = root(objects)
            result = Path(objects.rootString);
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
            result = objects.selectPath( ...
                @(obj) Path(regexprep(obj.string, Path.ROOT_REGEX, root, "emptymatch")), ...
                objects.empty);
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

        %% Join
        function varargout = join(objects, other)
            arguments
                objects(1, :)
            end
            arguments (Repeating)
                other (1, :) string {Path.mustBeNonmissing}
            end

            other = Path.clean(other{:});
            if isempty(objects) || isempty(other)
                result = objects;
            elseif isscalar(objects) || isscalar(other) || length(objects) == length(other)
                result = Path(objects.string + filesep + other.string);
            else
                error("Path:join:LengthMismatch", "Length of Path array, %i, and length of joined array, %i, must either match or one of them must be scalar.", length(objects), length(other));
            end
            varargout = deal_(result, nargout);
        end

        function varargout = mrdivide(objects, other)
            result = objects.join(other);
            varargout = deal_(result, nargout);
        end

        function varargout = mldivide(objects, other)
            result = objects.join(other);
            varargout = deal_(result, nargout);
        end

        function result = addSuffix(objects, suffix)
            arguments
                objects(1, :) string
                suffix (1, :) string {Path.mustBeNonmissing, Path.mustBeEqualSizeOrScalar(suffix, objects)}
            end
            result = Path(objects + suffix);
        end

        function result = plus(objects, suffix)
            arguments 
                objects (1, :) string
                suffix (1, :) string {Path.mustBeNonmissing, Path.mustBeEqualSizeOrScalar(suffix, objects)}
            end
            result = Path(objects + suffix);
        end

        %% Filter
        function result = where(objects, options)
            arguments
                objects
                options.Path (1, :) string = "*"
                options.PathNot (1, :) string = strings(0);
                options.Name (1, :) string = "*"
                options.NameNot (1, :) string = strings(0)
                options.Stem (1, :) string = "*"
                options.StemNot (1, :) string = strings(0);
                options.Extension (1, :) string = "*"
                options.ExtensionNot (1, :) string = strings(0)
                options.Parent (1, :) string = "*"
                options.ParentNot (1, :) string = strings(0)
                options.Root (1, :) string = "*"
                options.RootNot (1, :) string = strings(0)
            end

            args = namedargs2cell(options);
            keep = objects.is(args{:});
            result = objects(keep);
            if isempty(result)
                result = Path.empty;
            end
        end

        function result = is(objects, options)
            arguments
                objects
                options.Path (1, :) string = "*"
                options.PathNot (1, :) string = strings(0);
                options.Name (1, :) string = "*"
                options.NameNot (1, :) string = strings(0)
                options.Stem (1, :) string = "*"
                options.StemNot (1, :) string = strings(0);
                options.Extension (1, :) string = "*"
                options.ExtensionNot (1, :) string = strings(0)
                options.Parent (1, :) string = "*"
                options.ParentNot (1, :) string = strings(0)
                options.Root (1, :) string = "*"
                options.RootNot (1, :) string = strings(0)
            end

            for option = ["Path", "PathNot", "Name", "NameNot", "Stem", "StemNot", ...
                    "Extension", "ExtensionNot", "Parent", "ParentNot", "Root", "RootNot"]
                options.(option) = Path.clean(options.(option));
            end

            paths = objects.string;
            names = objects.nameString;
            stems = objects.stem;
            extensions = objects.extension;
            parents = objects.parentString;
            roots = objects.rootString;

            result =  ...
                Path.matches(paths, options.Path, true) & ...
                Path.matches(paths, options.PathNot, false) & ...
                Path.matches(names, options.Name, true) & ...
                Path.matches(names, options.NameNot, false) & ...
                Path.matches(stems, options.Stem, true) & ...
                Path.matches(stems, options.StemNot, false) & ...
                Path.matches(extensions, options.Extension, true) & ...
                Path.matches(extensions, options.ExtensionNot, false) & ...
                Path.matches(parents, options.Parent, true) & ...
                Path.matches(parents, options.ParentNot, false) & ...
                Path.matches(roots, options.Root, true) & ...
                Path.matches(roots, options.RootNot, false);
        end

        %% Absolute/Relative
        function result = absolute(objects, referenceDir)
            arguments
                objects
                referenceDir (1, 1) Path = Path(pwd)
            end
            if referenceDir.isRelative
                referenceDir = referenceDir.absolute;
            end
            isRelative = objects.isRelative;
            result = objects;
            result(isRelative) = Path(referenceDir.string + filesep + objects(isRelative).string);
        end

        function result = relative(objects, referenceDir)
            arguments
                objects
                referenceDir (1, 1) Path = Path(pwd)
            end
            paths = objects.absolute;
            referenceDir = referenceDir.absolute;
            referenceParts = referenceDir.parts;
            nReferenceParts = length(referenceParts);
            result = Path(strings(0));
            for path = paths
                parts = path.parts;
                nParts = length(parts);
                nLower = min([nParts, nReferenceParts]);
                nEqualParts = find([parts(1:nLower) ~= referenceParts(1:nLower), true], 1) - 1;
                if nEqualParts == 0
                    error("Path:relative:RootsDiffer", "Roots of path ""%s"" and reference directory ""%s"" differ.", path, referenceDir); end
                dirUps = join([repmat("..", 1, nReferenceParts - nEqualParts), "."], filesep);
                keptTail = join([".", parts(nEqualParts+1 : end)], filesep);
                result(end+1) = Path(dirUps + filesep + keptTail);
            end

        end

        %% Regex
        function result = regexprep(objects, expression, replace, varargin)
            arguments
                objects (1, :)
                expression
                replace
            end
            arguments (Repeating)
                varargin
            end
            result = Path(regexprep(objects.string, expression, replace, varargin{:}));
        end

        %% File systen interaction
        function result = exists(objects)
            result = objects.selectLogical(@(obj) isfile(obj.string) || isfolder(obj.string));
        end

        function result = isFile(objects)
            result = objects.selectLogical(@(obj) isfile(obj.string));
        end

        function result = isDir(objects)
            result = objects.selectLogical(@(obj) isfolder(obj.string));
        end

        function mustExist(objects)
            for obj = objects
                if ~obj.exists
                    throwAsCaller(obj.notFoundException);
                end
            end
        end

        function mustBeDir(objects)
            objects.mustExist;
            for obj = objects
                if ~obj.isDir
                    MException("Path:NotADir", "Path '%s' exists but is not a directory.", obj.string).throwAsCaller;
                end
            end
        end

        function mustBeFile(objects)
            objects.mustExist;
            for obj = objects
                if ~obj.isFile
                    MException("Path:NotAFile", "Path '%s' exists but is not a file.", obj.string).throwAsCaller;
                end
            end
        end

        function result = modifiedDate(objects)
            result(objects.count) = datetime;
            for i = 1 : objects.count
                content = dir(objects(i).string);
                if objects(i).isFile
                    datenum = content.datenum;
                else
                    objects(i).mustBeDir
                    datenum = content({content.name} == ".").datenum;
                end
                result(i) = datetime(datenum, "ConvertFrom", "datenum");
            end
        end

        function varargout = fopen(obj, varargin)
            arguments
                obj (1, 1)
            end
            arguments (Repeating)
                varargin
            end
            [varargout{1:nargout}] = fopen(obj.string, varargin{:});
        end

        function [id, autoClose] = open(obj, permission, varargin)
            arguments
                obj (1, 1)
                permission (1, 1) string = "r";
            end
            arguments (Repeating); varargin; end

            if permission.startsWith("r")
                obj.mustBeFile;
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

        function createEmptyFile(objects)
            for obj = objects
                [~, autoClose] = obj.openForWriting;
            end
        end

        function varargout = cd(obj)
            arguments
                obj (1, 1)
            end
            if nargout == 1
                varargout = {Path.pwd};
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
                    Path.extendError(exception, "MATLAB:MKDIR", "Error while creating directory ""%s"".", obj);
                end
            end
        end

        function result = listFiles(objects)
            files = strings(1, 0);
            objects.mustBeDir;
            for obj = objects.unique_
                contentInfo = dir(obj.string);
                fileInfoList = contentInfo(~[contentInfo.isdir]);
                for fileInfo = fileInfoList'
                    files(end+1) = obj.string + "\" + fileInfo.name;
                end
            end
            result = Path(files);
        end

        function result = listDeepFiles(objects)
            files = strings(1, 0);
            objects.mustBeDir;
            for obj = objects.unique_
                files = [files, listDeepPaths(obj.string, true)];
            end
            result = Path(files);
        end

        function result = listDirs(objects)
            dirs = strings(1, 0);
            objects.mustBeDir;
            for obj = objects.unique_
                contentInfo = dir(obj.string);
                dirInfoList = contentInfo([contentInfo.isdir]);
                for dirInfo = dirInfoList'
                    if ismember(dirInfo.name, [".", ".."])
                        continue; end
                    dirs(end+1) = obj.string + "\" + dirInfo.name;
                end
            end
            result = Path(dirs);
        end

        function result = listDeepDirs(objects)
            dirs = strings(1, 0);
            objects.mustBeDir;
            for obj = objects.unique_
                dirs = [dirs, listDeepPaths(obj.string, false)];
            end
            result = Path(dirs);
        end

        function delete(objects, varargin)
            for obj = objects
                if obj.isFile
                    delete(obj.string)
                elseif obj.isDir
                    rmdir(obj.string, varargin{:});
                end
            end
        end

        function result = readText(obj)
            arguments
                obj (1, 1)
            end
            obj.mustBeFile;
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
            objects.mustBeFile;
            result = zeros(1, objects.count);
            for i = 1:objects.count
                result(i) = dir(objects(i).string).bytes;
            end
        end

        %% Copy and move
        function copy(objects, targets)
            arguments
                objects
                targets (1, :) Path
            end
            objects.copyOrMove(targets, true, false)
        end

        function move(objects, targets)
            arguments
                objects
                targets (1, :) Path
            end
            objects.copyOrMove(targets, false, false);
        end

        function copyToDir(objects, targets)
            arguments
                objects
                targets (1, :) Path
            end
            objects.copyOrMove(targets, true, true);
        end

        function moveToDir(objects, targets)
            arguments
                objects
                targets (1, :) Path
            end
            objects.copyOrMove(targets, false, true);
        end

        %% Save and load
        function save(obj, variables)
            arguments
                obj (1, 1)
            end
            arguments (Repeating)
                variables (1, 1) string {Path.mustBeValidVariableName}
            end
            saveStruct = struct();
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
                variables (1, 1) string {Path.mustBeValidVariableName}
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
            varargout{1} = Path(varargout{1});
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

        function result = tempFileName(obj, n)
            arguments
                obj (1, 1)
                n (1, 1) {mustBeNonnegative, mustBeInteger} = 1
            end
            result = Path.empty;
            for i = 1:n
                result(i) = tempname(obj.string);
            end
        end
    end

    methods (Static)

        function result = ofMatlabFile(elements)
            arguments
                elements (1, :) string {Path.mustBeNonmissing}
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
                    eval(element + " = temp;");
                end

                if path.startsWith("built-in (")
                    path = path.extractBetween("(", ")");
                elseif path == ""
                    error("Path:ofMatlabFile:NotFound", "Element ""%s"" is not on the search path.", element);
                end
                result(end+1) = Path(path);
            end
        end

        function result = this(level)
            arguments
                level (1, 1) double {mustBeInteger, mustBePositive} = 1
            end
            stack = dbstack("-completenames");
            if length(stack) < level + 1
                error("Path:this:NotAFile", "This method was not called from another file" + ifThenElse(level == 1, "", " at the requested stack level") + "."); end
            callingFilePath = string(stack(level + 1).file);
            callingFileBaseName = regexp(callingFilePath.string, "(+[\w\d_]+(\\|/))*[\w\d_\.]+$", "match", "once");
            if callingFileBaseName.startsWith("LiveEditorEvaluationHelper")
                error("Path:this:LiveScript", "Calling this method from a live script is not supported. Consider using 'Path.ofMatlabFile' instead. Example: Path.ofMatlabFile(""PathExamples.mlx"")."); end
            result = Path.ofMatlabFile(callingFileBaseName);
        end

        function result = here(level)
            arguments
                level (1, 1) double {mustBeInteger, mustBePositive} = 1
            end
            result = Path.this(level + 1).parent;
        end

        function result = empty
            result = Path;
            result = result(double.empty(1, 0));
        end

        function result = pwd
            result = Path(pwd);
        end

        function result = home
            if Path.IS_WINDOWS
                result = Path(getenv("USERPROFILE"));
            else
                result = Path(getenv("HOME"));
            end
        end

        function result = matlab
            result = Path(matlabroot);
        end

        function result = searchPath
            result = Path(path);
        end

        function result = userPath
            result = Path(userpath);
        end

        function result = tempFile(n)
            arguments
                n (1, 1) {mustBeNonnegative, mustBeInteger} = 1
            end
            result = Path.empty;
            for i = 1:n
                result(i) = Path(tempname);
            end
        end

        function result = tempDir
            result = Path(tempdir);
        end

        function help
            web(Path.DOCUMENTATION_WEB_PAGE);
        end
    end

    methods (Access = private)
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

        function result = selectPath(objects, fun, emptyValue)
            result = emptyValue;
            for i = numel(objects) : -1 : 1
                result(i) = fun(objects(i));
            end
        end

        function result = notFoundException(obj)

            result = MException("Path:NotFound", "Path ""%s"" not found. ", obj.string);

            if ~obj.hasParent || obj.parent.exists
                return; end

            dir_ = obj;
            while true
                if ~dir_.hasParent || dir_.parent.exists
                    causeException = dir_.notFoundException;
                    result = Path.extendError(causeException, missing, "%s", result.message);
                    return
                end
                dir_ = dir_.parent;
            end
        end

        function copyOrMove(objects, targets, isCopyMode, isToDirMode)
            if objects.count == 1 && isCopyMode
                objects = repelem(objects, length(targets));
            end
            if targets.count == 1 && isToDirMode
                targets = repelem(targets, length(objects));
            end
            if objects.count ~= length(targets)
                MException("Path:copyOrMove:InvalidNumberOfTargets", "The number of target paths must equal the number of source paths.").throwAsCaller;
            end
            operation = ifThenElse(isCopyMode, @copyfile, @movefile);
            operationName = ifThenElse(isCopyMode, "copy", "move");
            for i = 1 : objects.count
                obj = objects(i);
                obj.mustExist;
                if isToDirMode
                    target = targets(i) / obj.name;
                else
                    target = targets(i);
                end
                if obj.isFile && target.isDir
                    MException( ...
                        "Path:copyOrMove:TargetIsDir", ...
                        "The source ""%s"" is a file but the target ""%s"" is an existing directory. Consider using method ""%sToDir"" instead.", ...
                        obj.string, target.string, operationName ...
                    ).throwAsCaller;
                end
                try
                    target.parent.mkdir;
                    operation(obj.string, target.string);
                catch exception
                    Path.extendError( ...
                        exception, ...
                        "MATLAB:" + ["COPYFILE:", "MOVEFILE:", "MKDIR:"], ...
                        "Unable to %s %s ""%s"" to ""%s"".", ...
                        operationName, lower(class(obj)), obj, target ...
                    );
                end
            end
        end
    end

    methods (Access = protected)
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

    methods (Static, Access = private)
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

                % Resolve dir-up-dots.
                expression = "("+fs+"|^)[^"+fs+":]+(?<!\.\.)"+fs+"\.\."; % Directory name followed by dir-up dots.
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
                messageFormat = messageFormat + "\nCause: %s";
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

        %% Validator functions
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

function result = ifThenElse(condition, a, b)
if condition
    result = a;
else
    result = b;
end
end

function tryToClose(fileId)
try
    fclose(fileId);
catch
end
end

function result = listDeepPaths(dir_, fileMode)
result = strings(0);
dirContents = dir(dir_)';
for dirContent = dirContents
    path = dir_ + filesep + dirContent.name;
    if dirContent.isdir
        if ismember(dirContent.name, [".", ".."])
            continue; end
        if ~fileMode
            result(end+1) = path; end
        result = [result, listDeepPaths(path, fileMode)];
    elseif fileMode
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

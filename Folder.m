classdef Folder < Path
% Folder Represents a folder path.
%
% For details, visit the <a href="matlab:
% web('https://github.com/MartinKoch123/Path/wiki')">documentation on GitHub</a>.

    
    methods (Static)

        %% Factory methods

        function result = ofMatlabElement(elements)
            result = File.ofMatlabElement(elements).parent;
        end

        function result = ofCaller(level)
            arguments
                level (1, 1) double {mustBeInteger, mustBePositive} = 1
            end
            result = File.ofCaller(level + 1).parent;
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

        function result = matlab
            result = Folder(matlabroot);
        end

        function result = searchPath
            result = Folder(path);
        end

        function result = userPath
            result = Folder(userpath);
        end

    end

end

function result = listDeepPaths(folder, fileMode)
result = strings(0);
folderContents = dir(folder)';
for folderContent = folderContents
    path = folder + filesep + folderContent.name;
    if folderContent.isdir
        if ismember(folderContent.name, [".", ".."])
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

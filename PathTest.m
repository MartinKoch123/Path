classdef PathTest < matlab.unittest.TestCase
    
    properties (Constant)
        testFolder = Path.ofMatlabElement("PathTest").parent / "test";
    end
    
    methods 
        function assertFileExists(obj, files)
            for file = files
                obj.assertTrue(isfile(string(file)));
            end
        end
        
        function assertFileDoesNotExists(obj, files)
            for file = files
                obj.assertFalse(isfile(string(file)))
            end
        end
        
        function assertFolderExists(obj, folders)
            for folder = folders
                obj.assertTrue(isfolder(string(folder)));
            end
        end
        
        function assertFolderDoesNotExist(obj, folders)
            for folder = folders
                obj.assertFalse(isfolder(string(folder)));
            end
        end
    end
    
    methods(TestMethodTeardown)
        function removeTestFolder(testCase)
            if testCase.testFolder.folderExists
                rmdir(testCase.testFolder.string, "s");
            end
        end
    end
        
    
    methods (Test)
        
        %% Constructor
        function constructWithStringVector(obj)
            actual = Path(["one", "two"]);
            expected = Path(["one", "two"]);
            obj.assertEqual(actual, expected);
        end
        
        function constructWithChars(obj)
            obj.assertEqual(Path("test"), Path('test'))
        end
        
        function constructWithCharCell(obj)
            actual = Path({'one', 'two'});
            expected = Path(["one", "two"]);
            obj.assertEqual(actual, expected);
        end
        
        function constructWithStringCell(obj)
            actual = Path({"one", "two"});
            expected = Path(["one", "two"]);
            obj.assertEqual(actual, expected);
        end
        
        function constructWithPathSeparator(obj)
            obj.assertEqual(Path("one; two"), Path(["one", "two"]));
            obj.assertEqual(Path(" ; "), Path([".", "."]));
        end
        
        function constructDefault(obj)
            obj.assertEqual(Path().string, ".");
        end
        
        function constructEmpty(obj)
            obj.assertEmpty(Path(string.empty));
            obj.assertEmpty(Path({}));
        end
        
        function constructWithMultipleArguments(obj)
            actual = Path('a', "b; c", {'d', "e; f"}, ["g", "h"]);
            expected = Path(["a" "b" "c" "d" "e" "f" "g", "h"]);
            obj.assertEqual(actual, expected);
        end
        
        %% Conversion
        function string(obj)
            obj.assertEqual(Path(["one", "two"]).string, ["one", "two"]);
        end
        
        function char(obj)
            obj.assertEqual('test', Path("test").char);
        end
        
        function charCell(obj)
            obj.assertEqual(Path("one").charCell, {'one'});
            obj.assertEqual(Path(["one", "two"]).charCell, {'one', 'two'});
        end
        
        %% Clean
        function assertStripsWhitespace(obj)
            obj.assertEqual("test", Path(sprintf("\n \ttest  \r")).string);
        end
        
        function assertRemovesRepeatingSeparators(obj)
            s = filesep;
            actual = Path("one" + s + s + s + "two" + s + s + "three").string;
            expected = adjustSeparators("one/two/three");
            obj.assertEqual(actual, expected);
        end
        
        function assertRemovesOuterSeparators(obj)
            s = filesep;
            actual = Path([s 'one/two/three' s]).string;
            expected = adjustSeparators("one/two/three");
            obj.assertEqual(actual, expected);
        end
        
        function assertRemovesCurrentDirDots(obj)
            actual = Path("\.\.\one\.\two.three\.\.four\.\.\").string;
            expected = adjustSeparators("one\two.three\.four");
            obj.assertEqual(actual, expected);
        end
        
        function assertReplacesSeparatorVariations(obj)
            actual = Path("one/two\three").string;
            expected = adjustSeparators("one/two/three");
            obj.assertEqual(actual, expected);
        end
        
        function assertResolvesParentDirDots(obj)
            actual = Path("one/two/three/../../four");
            expected = Path("one/four");
            obj.assertEqual(actual, expected);
        end
        
        %% Properties
        function name(obj)
            obj.assertEqual(Path("C:/one/two/three.ext").name.string, "three.ext");
            obj.assertEqual(Path("one.two.three.ext").name.string, "one.two.three.ext");
            obj.assertEqual(Path("one").name.string, "one");
            obj.assertEqual(Path("..").name.string, "..");
            obj.assertEqual(Path(".").name.string, ".");
        end
        
        function stem(obj)
            obj.assertEqual(Path("C:/one/two/three.ext").stem, "three");
            obj.assertEqual(Path("one.two.three.ext").stem, "one.two.three");
            obj.assertEqual(Path("one").stem, "one");
            obj.assertEqual(Path("..").stem, "..");
            obj.assertEqual(Path(".").stem, ".");
        end
        
        function extension(obj)
            obj.assertEqual(Path("C:/one/two/three.ext").extension, ".ext");
            obj.assertEqual(Path("one.two.three.ext").extension, ".ext");
            obj.assertEqual(Path("one.").extension, ".");
            obj.assertEqual(Path("one").extension, "");
            obj.assertEqual(Path("..").extension, "");
            obj.assertEqual(Path(".").extension, "");
        end
        
        function parent(obj)
            obj.assertEqual(Path("C:/one/two/three.ext").parent, Path("C:/one/two"));
            obj.assertEqual(Path("../../one/three.ext").parent, Path("../../one"));
            obj.assertEqual(Path("one").parent, Path("."));
            obj.assertEqual(Path("..").parent, Path("."));
            obj.assertEqual(Path(".").parent, Path("."));
        end
        
        function root(obj)
            error()
        end
        
        function isRelative(obj)
            obj.assertTrue(all(Path(".; ..; a/b.c; ../../a/b/c").isRelative));
            obj.assertFalse(any(Path("C:\; D:\a\b.c; \\test\; \\test\a\b").isRelative));
%             obj.assertTrue(Path("one").isRelative);
        end
        
        %% Manipulation
        function append(obj)
            obj.assertEqual(Path("one").append(""), Path("one"));
            obj.assertEqual(Path("one").append(["one", "two"]), Path("one/one", "one/two"));
            obj.assertEqual(Path("one", "two").append("one"), Path("one/one", "two/one"));
            obj.assertEmpty(Path.empty.append("one"), Path);
            obj.assertEqual(Path("one").append(strings(0)), Path("one"));
            obj.assertError(@() Path("one", "two", "three").append(["one", "two"]), "Path:append:LengthMismatch");
            obj.assertEqual(Path("a").append("b", 'c', {'d', "e; f"}), Path("a/b", "a/c", "a/d", "a/e", "a/f"));
        end
        
        function mrdivide(obj)
            obj.assertEqual(Path("one") / "two", Path("one/two"));
        end
        
        function mldivide(obj)
            obj.assertEqual(Path("one") \ "two", Path("one/two"));
        end
        
        
        %% Filter
        function where(obj)
            paths = Path([
                "C:\one\two.txt"        % 1
                "two.txt"               % 2
                "one\two.csv"           % 3
                "C:\three\four.txt"     % 4
                "three.txt"             % 5
                "one\three.dat"         % 6
                "five"                  % 7
                ".."                    % 8
                ]);
            obj.assertEqual(paths([1, 2, 7]), paths.where("Name", ["two.txt", "five", "six"]));
            obj.assertEqual(paths([3, 4, 5, 7]), paths.where("NameNot", ["two.txt", "three.dat", "six", ".."]));
            
            obj.assertEqual(paths([1, 2, 3, 4, 8]), paths.where("Stem", ["one", "two", "four", ".."]));
            obj.assertEqual(paths([4, 7, 8]), paths.where("StemNot", ["two", "three", "six"]));
            
            obj.assertEqual(paths([1, 2, 4, 5, 7, 8]), paths.where("Extension", [".txt", ".mat", ""]));
            obj.assertEqual(paths([3, 6]), paths.where("ExtensionNot", [".txt", ".mat", ""]));
            
            obj.assertEqual(paths([1, 3, 6]), paths.where("Parent", ["one", "C:\one", "D:\"]));
            obj.assertEqual(paths([1, 4]), paths.where("ParentNot", ["one", ".", "D:\"]));
            
            obj.assertEqual(paths([2]), paths.where( ...
                "NameNot", ["six", "three.txt"], ...
                "Extension", [".txt", ".mat"], ...
                "StemNot", ["four", "five"], ...
                "ParentNot", ["C:\one", "D:\"] ...
            ));
        end
        
        %% File system interaction
        function mkdir(obj)
            obj.testFolder.append(["a", "b/a"]).mkdir;
            obj.assertFolderExists(obj.testFolder / "a; b/a");
        end
        
        function writeEmptyFile(obj)
            obj.testFolder.append("a.b; c/d").writeEmptyFile;
            obj.assertFileExists(obj.testFolder / "a.b; c/d");
        end
        
        function fileExistsAndFolderExists(obj)
            paths = obj.testFolder / "a.b; c/d";
            obj.assertFalse(any(paths.fileExists));
            paths.writeEmptyFile;
            obj.assertFalse(any(paths.folderExists));
            obj.assertTrue(all(paths.fileExists));   
            
            delete(paths(1).string, paths(2).string);
            
            obj.assertFalse(any(paths.folderExists));
            paths.mkdir;
            obj.assertFalse(any(paths.fileExists));
            obj.assertTrue(all(paths.folderExists));
        end
        
        %% Matlab files
        function ofMatlabElement(obj)
            actual = Path.ofMatlabElement(["mean", "PathTest"]).string;
            expected = string({which("mean") which("PathTest")});
            obj.assertEqual(actual, expected);
            obj.assertError(@() Path.ofMatlabElement("npofas&/"), "Path:ofMatlabElement:NotFound");
        end
        
        function ofCaller(obj)
            obj.assertEqual(Path.ofCaller, Path(which("PathTest")));
        end
        
        %% Save and load
        function save(obj)
            a = 1;
            b = "test";
            file = obj.testFolder / "data.mat";
            file.save("a", "b");
            clearvars("a", "b");
            load(file.string, "a", "b");
            obj.assertEqual(a, 1);
            obj.assertEqual(b, "test"); 
        end
        
        function load(obj)
            a = 1;
            b = "test";
            file = obj.testFolder / "data.mat";
            obj.testFolder.mkdir;
            save(file.string, "a", "b");
            clearvars("a", "b");
            [a, b] = file.load("a", "b");
            obj.assertEqual(a, 1);
            obj.assertEqual(b, "test"); 
            
            raisedError = false;
            try 
                a = file.load("a", "b");
            catch exception
                obj.assertEqual(string(exception.identifier), "Path:load:InputOutputMismatch");
                raisedError = true;
            end
            obj.assertTrue(raisedError);
            raisedError = false;
            try
                c = file.load("c");
            catch exception
                obj.assertEqual(string(exception.identifier), "Path:load:VariableNotFound");
                raisedError = true;
            end
            obj.assertTrue(raisedError);
        end
    end
end

function s = adjustSeparators(s)
    s = s.replace(["/", "\"], filesep);
end
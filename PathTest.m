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
            obj.assertEqual(Path.empty.string, strings(0));
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
        
        %% Name
        function name(obj)
            obj.assertEqual(Path("C:/one/two/three.ext").name.string, "three.ext");
            obj.assertEqual(Path("one.two.three.ext").name.string, "one.two.three.ext");
            obj.assertEqual(Path("one").name.string, "one");
            obj.assertEqual(Path("..").name.string, "..");
            obj.assertEqual(Path(".").name.string, ".");
            obj.assertEmpty(Path.empty.name);
            obj.assertInstanceOf(Path.empty.name, "Path")
        end
        
        function hasName(obj)
            obj.assertEqual(Path("one.two; three/four").hasName(["hree*", "*.two"]), [true, false]);
            obj.assertEqual(Path("one.two; three/four").hasName(), [false, false]);
            obj.assertEqual(Path.empty.hasName(["hree*", "*.two"]), logical.empty);
        end
        
        function hasNotName(obj)
            obj.assertEqual(Path("one.two; three/four").hasNotName(["hree*", "*.two"]), [false, true]);
            obj.assertEqual(Path("one.two; three/four").hasNotName(), [true, true]);
            obj.assertEqual(Path.empty.hasName(["hree*", "*.two"]), logical.empty);
        end
        
        function whereName(obj)
            obj.assertEqual(Path("one.two; three/four").whereName(["hree*", "*.two"]), Path("one.two"));
            obj.assertEqual(Path("one.two; three/four").whereName(), Path.empty(1, 0));
            obj.assertEqual(Path.empty.whereName(["hree*", "*.two"]), Path.empty(1, 0));
        end
        
        function whereNameNot(obj)
            obj.assertEqual(Path("one.two; three/four").whereNameNot(["hree*", "*.two"]), Path("three/four"));
            obj.assertEqual(Path("one.two; three/four").whereNameNot(), Path("one.two; three/four"));
            obj.assertEqual(Path.empty.whereNameNot(["hree*", "*.two"]), Path.empty(1, 0));
        end
        
        %% Extension
        function extension(obj)
            obj.assertEqual(Path("C:/one/two/three.ext").extension, ".ext");
            obj.assertEqual(Path("one.two.three.ext").extension, ".ext");
            obj.assertEqual(Path("one.").extension, ".");
            obj.assertEqual(Path("one").extension, "");
            obj.assertEqual(Path("..").extension, "");
            obj.assertEqual(Path(".").extension, "");
        end
        
        function hasExtension(obj)
            obj.assertEqual(Path("one.two; three.four").hasExtension([".fo*", "asf"]), [false, true]);
            obj.assertEqual(Path("one.two; three.four").hasExtension(), [false, false]);
            obj.assertEqual(Path.empty.hasExtension([".fo*", "asf"]), logical.empty);
        end
        
        function hasNotExtension(obj)
            obj.assertEqual(Path("one.two; three.four").hasNotExtension([".fo*", "asf"]), [true, false]);
            obj.assertEqual(Path("one.two; three.four").hasNotExtension(), [true, true]);
            obj.assertEqual(Path.empty.hasNotExtension([".fo*", "asf"]), logical.empty);
        end
        
        function whereExtensionIs(obj)
            paths = Path("one.two; three.four");
            obj.assertEqual(paths.whereExtensionIs([".fo*", "asf"]), paths(2));
            obj.assertEqual(paths.whereExtensionIs(), Path.empty(1, 0));
            obj.assertEqual(Path.empty.whereExtensionIs([".fo*", "asf"]), Path.empty(1, 0));
        end 
        
        function whereExtensionIsNot(obj)
            paths = Path("one.two; three.four");
            obj.assertEqual(paths.whereExtensionIsNot([".fo*", "asf"]), paths(1));
            obj.assertEqual(paths.whereExtensionIsNot(), paths);
            obj.assertEqual(Path.empty.whereExtensionIsNot([".fo*", "asf"]), Path.empty(1, 0));
        end
        
        %% Stem
        function stem(obj)
            obj.assertEqual(Path("C:/one/two/three.ext").stem, "three");
            obj.assertEqual(Path("one.two.three.ext").stem, "one.two.three");
            obj.assertEqual(Path("one").stem, "one");
            obj.assertEqual(Path("..").stem, "..");
            obj.assertEqual(Path(".").stem, ".");
            obj.assertEmpty(Path.empty.stem);
            obj.assertInstanceOf(Path.empty.stem, "string")
        end
        
        function hasStem(obj)
            obj.assertEqual(Path("one.two; three.four").hasStem(["t*ee", "asf"]), [false, true]);
            obj.assertEqual(Path("one.two; three.four").hasStem(), [false, false]);
            obj.assertEqual(Path.empty.hasStem(["t*ee", "asf"]), logical.empty);
        end
        
        function hasNotStem(obj)
            obj.assertEqual(Path("one.two; three.four").hasNotStem(["t*ee", "asf"]), [true, false]);
            obj.assertEqual(Path("one.two; three.four").hasNotStem(), [true, true]);
            obj.assertEqual(Path.empty.hasNotStem(["t*ee", "asf"]), logical.empty);
        end
        
        function whereStemIs(obj)
            paths = Path("one.two; three.four");
            obj.assertEqual(paths.whereStemIs(["t*ee", "asf"]), paths(2));
            obj.assertEqual(paths.whereStemIs(), Path.empty(1, 0));
            obj.assertEqual(Path.empty.whereStemIs(["t*ee", "asf"]), Path.empty(1, 0));
        end 
        
        function whereStemIsNot(obj)
            paths = Path("one.two; three.four");
            obj.assertEqual(paths.whereStemIsNot(["t*ee", "asf"]), paths(1));
            obj.assertEqual(paths.whereStemIsNot(), paths);
            obj.assertEqual(Path.empty.whereStemIsNot(["t*ee", "asf"]), Path.empty(1, 0));
        end
        
        %% Parent
        function parent(obj)
            obj.assertEqual(Path("C:/one/two/three.ext").parent, Path("C:/one/two"));
            obj.assertEqual(Path("../../one/three.ext").parent, Path("../../one"));
            obj.assertEqual(Path("one").parent, Path("."));
            obj.assertEqual(Path("..").parent, Path("."));
            obj.assertEqual(Path(".").parent, Path("."));
        end
        
        function hasParent(obj)
            obj.assertEqual(Path("a/b/c; C:/d/e").hasParent(["*d", "asf"]), [false, true]);
            obj.assertEqual(Path("a/b/c; C:/d/e").hasParent(), [false, false]);
            obj.assertEqual(Path.empty.hasParent(["*d", "asf"]), logical.empty);
        end
        
        function hasNotParent(obj)
            obj.assertEqual(Path("a/b/c; C:/d/e").hasNotParent(["*d", "asf"]), [true, false]);
            obj.assertEqual(Path("a/b/c; C:/d/e").hasNotParent(), [true, true]);
            obj.assertEqual(Path.empty.hasNotParent(["*d", "asf"]), logical.empty);
        end
        
        function whereParentIs(obj)
            paths = Path("a/b/c; C:/d/e");
            obj.assertEqual(paths.whereParentIs(["*d", "asf"]), paths(2));
            obj.assertEqual(paths.whereParentIs(), Path.empty(1, 0));
            obj.assertEqual(Path.empty.whereParentIs(["*d", "asf"]), Path.empty(1, 0));
        end 
        
        function whereParentIsNot(obj)
            paths = Path("a/b/c; C:/d/e");
            obj.assertEqual(paths.whereParentIsNot(["*d", "asf"]), paths(1));
            obj.assertEqual(paths.whereParentIsNot(), paths);
            obj.assertEqual(Path.empty.whereParentIsNot(["*d", "asf"]), Path.empty(1, 0));
        end
        
        %% Root
        function root(obj)
            obj.assertEqual(Path("C:/one/two.ext").root, "C:");
            obj.assertEqual(Path("one/two").root, "");
        end
        
        function hasRoot(obj)
            obj.assertEqual(Path("a/b/c; C:/d/e").hasRoot(["C*", "asf"]), [false, true]);
            obj.assertEqual(Path("a/b/c; C:/d/e").hasRoot(), [false, false]);
            obj.assertEqual(Path.empty.hasRoot(["C*", "asf"]), logical.empty);
        end
        
        function hasNotRoot(obj)
            obj.assertEqual(Path("a/b/c; C:/d/e").hasNotRoot(["C*", "asf"]), [true, false]);
            obj.assertEqual(Path("a/b/c; C:/d/e").hasNotRoot(), [true, true]);
            obj.assertEqual(Path.empty.hasNotRoot(["C*", "asf"]), logical.empty);
        end
        
        function whereRootIs(obj)
            paths = Path("a/b/c; C:/d/e");
            obj.assertEqual(paths.whereRootIs(["C*", "asf"]), paths(2));
            obj.assertEqual(paths.whereRootIs(), Path.empty(1, 0));
            obj.assertEqual(Path.empty.whereRootIs(["C*", "asf"]), Path.empty(1, 0));
        end 
        
        function whereRootNot(obj)
            paths = Path("a/b/c; C:/d/e");
            obj.assertEqual(paths.whereRootIsNot(["C*", "asf"]), paths(1));
            obj.assertEqual(paths.whereRootIsNot(), paths);
            obj.assertEqual(Path.empty.whereRootIsNot(["C*", "asf"]), Path.empty(1, 0));
        end
        
        %% Properties   
        function isRelative(obj)
            obj.assertTrue(all(Path(".; ..; a/b.c; ../../a/b/c").isRelative));
            obj.assertFalse(any(Path("C:\; D:\a\b.c; \\test\; \\test\a\b").isRelative));
        end
        
        function isAbsolute(obj)            
            obj.assertFalse(any(Path(".; ..; a/b.c; ../../a/b/c").isAbsolute));
            obj.assertTrue(any(Path("C:\; D:\a\b.c; \\test\; \\test\a\b").isAbsolute));
        end
        
        function equalAndNotEqual(obj)
            paths = Path("one/two; C:\a\b.c; three/four; C:\a\b.c");
            obj.assertEqual(paths(1:2) == paths(3:4), [false, true]);
            obj.assertEqual(paths(1:2) ~= paths(3:4), [true, false]);
            obj.assertEqual(paths(2) == paths(3:4), [false, true]);
            obj.assertEqual(paths(3:4) ~= paths(2), [true, false]);
        end
        
        %% List 
        function count(obj)
            obj.assertEqual(Path("a; b").count, 2);
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

        
        %% File system interaction
        function mkdir(obj)
            obj.testFolder.append(["a", "b/a"]).mkdir;
            obj.assertFolderExists(obj.testFolder / "a; b/a");
        end
        
        function createEmptyFile(obj)
            obj.testFolder.append("a.b; c/d").createEmptyFile;
            obj.assertFileExists(obj.testFolder / "a.b; c/d");
        end
        
        function fileExistsAndFolderExists(obj)
            
            paths = obj.testFolder / "a.b; c/d";
            obj.assertFalse(any(paths.fileExists));
            obj.assertFalse(any(paths.folderExists));
            obj.assertError(@() paths.mustExist, "Path:mustExist:Failed");            
            obj.assertError(@() paths.fileMustExist, "Path:fileMustExist:Failed");            
            obj.assertError(@() paths.folderMustExist, "Path:folderMustExist:Failed");
            
            paths.createEmptyFile;
            obj.assertFalse(any(paths.folderExists));
            obj.assertTrue(all(paths.fileExists));   
            paths.mustExist;
            paths.fileMustExist;
            obj.assertError(@() paths.folderMustExist, "Path:folderMustExist:Failed");
            
            delete(paths(1).string, paths(2).string);            
            paths.mkdir;
            
            obj.assertFalse(any(paths.fileExists));
            obj.assertTrue(all(paths.folderExists));
            paths.mustExist;
            paths.folderMustExist;
            obj.assertError(@() paths.fileMustExist, "Path:fileMustExist:Failed");
        end
        
        function copyFile(obj)
            sources = obj.testFolder / "a.b; c/d.e";
            targets = obj.testFolder / "f/g.h; i.j";
            sources.createEmptyFile;
            sources.copyFile(targets);
            targets.fileMustExist;
            
            Path.empty.copyFile(Path.empty);
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
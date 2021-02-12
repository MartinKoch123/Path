classdef PathTest < matlab.unittest.TestCase
    
    properties (Constant)
        testFolder = Folder.ofMatlabElement("PathTest") / "test";
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
            if testCase.testFolder.exists
                rmdir(testCase.testFolder.string, "s");
            end
        end
    end
        
    
    methods (Test)
        
        %% Constructor
        function constructWithStringVector(obj)
            obj.assertEqual(File(["one", "two"]).string, ["one", "two"]);
            obj.assertEqual(Folder(["one", "two"]).string, ["one", "two"]);
        end
        
        function constructWithChars(obj)
            obj.assertEqual(File("test"), File('test'))
        end
        
        function constructWithCharCell(obj)
            actual = File({'one', 'two'});
            expected = File(["one", "two"]);
            obj.assertEqual(actual, expected);
        end
        
        function constructWithStringCell(obj)
            actual = Folder({"one", "two"});
            expected = Folder(["one", "two"]);
            obj.assertEqual(actual, expected);
        end
        
        function constructWithPathSeparator(obj)
            obj.assertEqual(File("one; two"), File(["one", "two"]));
            obj.assertEqual(Folder(" ; "), Folder([".", "."]));
        end
        
        function constructDefault(obj)
            obj.assertEqual(File().string, ".");
            obj.assertEqual(Folder().string, ".");
        end
        
        function constructEmpty(obj)
            obj.assertSize(File(string.empty), [1, 0]);
            obj.assertSize(Folder({}), [1, 0]);
        end
        
        function constructWithMultipleArguments(obj)
            actual = File('a', "b; c", {'d', "e; f"}, ["g", "h"]);
            expected = File(["a" "b" "c" "d" "e" "f" "g", "h"]);
            obj.assertEqual(actual, expected);
        end
        
        %% Conversion
        function string(obj)
            obj.assertEqual(File(["one", "two"]).string, ["one", "two"]);
            obj.assertEqual(File.empty.string, strings(0));
        end
        
        function char(obj)
            obj.assertEqual('test', File("test").char);
        end
        
        function charCell(obj)
            obj.assertEqual(File("one").charCell, {'one'});
            obj.assertEqual(Folder(["one", "two"]).charCell, {'one', 'two'});
        end
        
        %% Clean
        function assertStripsWhitespace(obj)
            obj.assertEqual("test", File(sprintf("\n \ttest  \r")).string);
        end
        
        function assertRemovesRepeatingSeparators(obj)
            s = filesep;
            actual = Folder("one" + s + s + s + "two" + s + s + "three").string;
            expected = adjustSeparators("one/two/three");
            obj.assertEqual(actual, expected);
        end
        
        function assertRemovesOuterSeparators(obj)
            s = filesep;
            actual = File([s 'one/two/three' s]).string;
            expected = adjustSeparators("one/two/three");
            obj.assertEqual(actual, expected);
        end
        
        function assertRemovesCurrentDirDots(obj)
            actual = Folder("\.\.\one\.\two.three\.\.four\.\.\").string;
            expected = adjustSeparators("one\two.three\.four");
            obj.assertEqual(actual, expected);
        end
        
        function assertReplacesSeparatorVariations(obj)
            actual = File("one/two\three").string;
            expected = adjustSeparators("one/two/three");
            obj.assertEqual(actual, expected);
        end
        
        function assertResolvesParentDirDots(obj)
            actual = File("one/two/three/../../four");
            expected = File("one/four");
            obj.assertEqual(actual, expected);
        end
        
        %% Name
        function name(obj)
            obj.assertEqual(File("C:/one/two/three.ext").name.string, "three.ext");
            obj.assertEqual(Folder("one.two.three.ext").name.string, "one.two.three.ext");
            obj.assertEqual(File("one").name.string, "one");
            obj.assertEqual(Folder("..").name.string, "..");
            obj.assertEqual(File(".").name.string, ".");
            obj.assertEmpty(File.empty.name);
            obj.assertInstanceOf(Folder.empty.name, "Folder")
            obj.assertInstanceOf(File.empty.name, "File")
        end
        
        function hasName(obj)
            obj.assertEqual(File("one.two; three/four").hasName(["hree*", "*.two"]), [true, false]);
            obj.assertEqual(Folder("one.two; three/four").hasName(), [false, false]);
            obj.assertEqual(File.empty.hasName(["hree*", "*.two"]), logical.empty);
        end
        
        function hasNotName(obj)
            obj.assertEqual(Folder("one.two; three/four").hasNotName(["hree*", "*.two"]), [false, true]);
            obj.assertEqual(File("one.two; three/four").hasNotName(), [true, true]);
            obj.assertEqual(Folder.empty.hasName(["hree*", "*.two"]), logical.empty);
        end
        
        function whereName(obj)
            obj.assertEqual(File("one.two; three/four").whereName(["hree*", "*.two"]), File("one.two"));
            obj.assertEqual(Folder("one.two; three/four").whereName(), Folder.empty(1, 0));
            obj.assertEqual(File.empty.whereName(["hree*", "*.two"]), File.empty(1, 0));
        end
        
        function whereNameNot(obj)
            obj.assertEqual(Folder("one.two; three/four").whereNameNot(["hree*", "*.two"]), Folder("three/four"));
            obj.assertEqual(File("one.two; three/four").whereNameNot(), File("one.two; three/four"));
            obj.assertEqual(Folder.empty.whereNameNot(["hree*", "*.two"]), Folder.empty(1, 0));
        end
        
        %% Extension
        function extension(obj)
            obj.assertEqual(File("C:/one/two/three.ext").extension, ".ext");
            obj.assertEqual(File("one.two.three.ext").extension, ".ext");
            obj.assertEqual(File("one.").extension, ".");
            obj.assertEqual(File("one").extension, "");
            obj.assertEqual(File("..").extension, "");
            obj.assertEqual(File(".").extension, "");
        end
        
        function hasExtension(obj)
            obj.assertEqual(File("one.two; three.four").hasExtension([".fo*", "asf"]), [false, true]);
            obj.assertEqual(File("one.two; three.four").hasExtension(), [false, false]);
            obj.assertEqual(File.empty.hasExtension([".fo*", "asf"]), logical.empty);
        end
        
        function hasNotExtension(obj)
            obj.assertEqual(File("one.two; three.four").hasNotExtension([".fo*", "asf"]), [true, false]);
            obj.assertEqual(File("one.two; three.four").hasNotExtension(), [true, true]);
            obj.assertEqual(File.empty.hasNotExtension([".fo*", "asf"]), logical.empty);
        end
        
        function whereExtensionIs(obj)
            files = File("one.two; three.four");
            obj.assertEqual(files.whereExtensionIs([".fo*", "asf"]), files(2));
            obj.assertEqual(files.whereExtensionIs(), File.empty(1, 0));
            obj.assertEqual(File.empty.whereExtensionIs([".fo*", "asf"]), File.empty(1, 0));
        end 
        
        function whereExtensionIsNot(obj)
            files = File("one.two; three.four");
            obj.assertEqual(files.whereExtensionIsNot([".fo*", "asf"]), files(1));
            obj.assertEqual(files.whereExtensionIsNot(), files);
            obj.assertEqual(File.empty.whereExtensionIsNot([".fo*", "asf"]), File.empty(1, 0));
        end
        
        %% Stem
        function stem(obj)
            obj.assertEqual(File("C:/one/two/three.ext").stem, "three");
            obj.assertEqual(File("one.two.three.ext").stem, "one.two.three");
            obj.assertEqual(File("one").stem, "one");
            obj.assertEqual(File("..").stem, "..");
            obj.assertEqual(File(".").stem, ".");
            obj.assertEmpty(File.empty.stem);
            obj.assertInstanceOf(File.empty.stem, "string")
        end
        
        function hasStem(obj)
            obj.assertEqual(File("one.two; three.four").hasStem(["t*ee", "asf"]), [false, true]);
            obj.assertEqual(File("one.two; three.four").hasStem(), [false, false]);
            obj.assertEqual(File.empty.hasStem(["t*ee", "asf"]), logical.empty);
        end
        
        function hasNotStem(obj)
            obj.assertEqual(File("one.two; three.four").hasNotStem(["t*ee", "asf"]), [true, false]);
            obj.assertEqual(File("one.two; three.four").hasNotStem(), [true, true]);
            obj.assertEqual(File.empty.hasNotStem(["t*ee", "asf"]), logical.empty);
        end
        
        function whereStemIs(obj)
            files = File("one.two; three.four");
            obj.assertEqual(files.whereStemIs(["t*ee", "asf"]), files(2));
            obj.assertSize(files.whereStemIs(), [1, 0]);
            obj.assertSize(File.empty.whereStemIs(["t*ee", "asf"]), [1, 0]);
        end 
        
        function whereStemIsNot(obj)
            files = File("one.two; three.four");
            obj.assertEqual(files.whereStemIsNot(["t*ee", "asf"]), files(1));
            obj.assertEqual(files.whereStemIsNot(), files);
            obj.assertSize(File.empty.whereStemIsNot(["t*ee", "asf"]), [1, 0]);
        end
        
        %% Parent
        function parent(obj)
            obj.assertEqual(File("C:/one/two/three.ext").parent, Folder("C:/one/two"));
            obj.assertEqual(Folder("../../one/three.ext").parent, Folder("../../one"));
            obj.assertEqual(File("one").parent, Folder("."));
            obj.assertEqual(Folder("..").parent, Folder("."));
            obj.assertEqual(File(".").parent, Folder("."));
        end
        
        function hasParent(obj)
            obj.assertEqual(File("a/b/c; C:/d/e").hasParent(["*d", "asf"]), [false, true]);
            obj.assertEqual(Folder("a/b/c; C:/d/e").hasParent(), [false, false]);
            obj.assertEqual(File.empty.hasParent(["*d", "asf"]), logical.empty);
        end
        
        function hasNotParent(obj)
            obj.assertEqual(Folder("a/b/c; C:/d/e").hasNotParent(["*d", "asf"]), [true, false]);
            obj.assertEqual(File("a/b/c; C:/d/e").hasNotParent(), [true, true]);
            obj.assertEqual(Folder.empty.hasNotParent(["*d", "asf"]), logical.empty);
        end
        
        function whereParentIs(obj)
            files = File("a/b/c; C:/d/e");
            obj.assertEqual(files.whereParentIs(["*d", "asf"]), files(2));
            obj.assertEqual(files.whereParentIs(), File.empty(1, 0));
            obj.assertEqual(File.empty.whereParentIs(["*d", "asf"]), File.empty(1, 0));
        end 
        
        function whereParentIsNot(obj)
            folders = Folder("a/b/c; C:/d/e");
            obj.assertEqual(folders.whereParentIsNot(["*d", "asf"]), folders(1));
            obj.assertEqual(folders.whereParentIsNot(), folders);
            obj.assertEqual(Folder.empty.whereParentIsNot(["*d", "asf"]), Folder.empty(1, 0));
        end
        
        %% Root
        function root(obj)
            obj.assertEqual(File("C:/one/two.ext").root, "C:");
            obj.assertEqual(Folder("one/two").root, "");
        end
        
        function hasRoot(obj)
            obj.assertEqual(File("a/b/c; C:/d/e").hasRoot(["C*", "asf"]), [false, true]);
            obj.assertEqual(Folder("a/b/c; C:/d/e").hasRoot(), [false, false]);
            obj.assertEqual(File.empty.hasRoot(["C*", "asf"]), logical.empty);
        end
        
        function hasNotRoot(obj)
            obj.assertEqual(Folder("a/b/c; C:/d/e").hasNotRoot(["C*", "asf"]), [true, false]);
            obj.assertEqual(File("a/b/c; C:/d/e").hasNotRoot(), [true, true]);
            obj.assertEqual(Folder.empty.hasNotRoot(["C*", "asf"]), logical.empty);
        end
        
        function whereRootIs(obj)
            files = File("a/b/c; C:/d/e");
            obj.assertEqual(files.whereRootIs(["C*", "asf"]), files(2));
            obj.assertEqual(files.whereRootIs(), File.empty(1, 0));
            obj.assertEqual(File.empty.whereRootIs(["C*", "asf"]), File.empty(1, 0));
        end 
        
        function whereRootNot(obj)
            folder = Folder("a/b/c; C:/d/e");
            obj.assertEqual(folder.whereRootIsNot(["C*", "asf"]), folder(1));
            obj.assertEqual(folder.whereRootIsNot(), folder);
            obj.assertEqual(Folder.empty.whereRootIsNot(["C*", "asf"]), Folder.empty(1, 0));
        end
        
        %% Properties   
        function isRelative(obj)
            obj.assertTrue(all(File(".; ..; a/b.c; ../../a/b/c").isRelative));
            obj.assertFalse(any(File("C:\; D:\a\b.c; \\test\; \\test\a\b").isRelative));
        end
        
        function isAbsolute(obj)            
            obj.assertFalse(any(Folder(".; ..; a/b.c; ../../a/b/c").isAbsolute));
            obj.assertTrue(any(Folder("C:\; D:\a\b.c; \\test\; \\test\a\b").isAbsolute));
        end
        
        function equalAndNotEqual(obj)
            files = File("one/two; C:\a\b.c; three/four; C:\a\b.c");
            obj.assertEqual(files(1:2) == files(3:4), [false, true]);
            obj.assertEqual(files(1:2) ~= files(3:4), [true, false]);
            obj.assertEqual(files(2) == files(3:4), [false, true]);
            obj.assertEqual(files(3:4) ~= files(2), [true, false]);
            obj.assertTrue(File("one/two") == Folder("one/two"));
        end
        
        %% List 
        function count(obj)
            obj.assertEqual(File("a; b").count, 2);
        end
        
        %% Manipulation
        function append(obj)
            obj.assertEqual(Folder("one").append(""), Folder("one"));
            obj.assertEqual(Folder("one").append(["one", "two"]), Folder("one/one", "one/two"));
            obj.assertEqual(Folder("one", "two").append("one"), Folder("one/one", "two/one"));
            obj.assertEmpty(Folder.empty.append("one"), Folder);
            obj.assertEqual(Folder("one").append(strings(0)), Folder("one"));
            obj.assertError(@() Folder("one", "two", "three").append(["one", "two"]), "Folder:append:LengthMismatch");
            obj.assertEqual(Folder("a").append("b", 'c', {'d', "e; f"}), Folder("a/b", "a/c", "a/d", "a/e", "a/f"));
        end
        
        function mrdivide(obj)
            obj.assertEqual(Folder("one") / "two", Folder("one/two"));
        end
        
        function mldivide(obj)
            obj.assertEqual(Folder("one") \ "two", Folder("one/two"));
        end

        
        %% File system interaction
        function mkdir(obj)
            obj.testFolder.append(["a", "b/a"]).mkdir;
            obj.assertFolderExists(obj.testFolder / "a; b/a");
        end
        
        function createEmptyFile(obj)
            obj.testFolder.append("a.b; c/d.e").createEmptyFile;
            obj.assertFileExists(obj.testFolder / "a.b; c/d.e");
        end
        
        function fileExistsAndFolderExists(obj)
            
            files = obj.testFolder / "a.b; c/d.e";
            folders = Folder(files);
            obj.assertEqual(files.exists, [false, false]);
            obj.assertEqual(folders.exists, [false, false]);
            obj.assertError(@() files.mustExist, "File:mustExist:Failed");            
            obj.assertError(@() folders.mustExist, "Folder:mustExist:Failed");            
            
            files.createEmptyFile;
            obj.assertEqual(files.exists, [true, true]);
            obj.assertEqual(folders.exists, [false, false]);
            files.mustExist;
            obj.assertError(@() folders.mustExist, "Folder:mustExist:Failed");
            
            delete(files(1).string, files(2).string);            
            folders.mkdir;
            
            obj.assertEqual(files.exists, [false, false]);
            obj.assertEqual(folders.exists, [true, true]);
            folders.mustExist;
            obj.assertError(@() files.mustExist, "File:mustExist:Failed");
        end
        
%         function copyFile(obj)
%             sources = obj.testFolder / "a.b; c/d.e";
%             targets = obj.testFolder / "f/g.h; i.j";
%             sources.createEmptyFile;
%             sources.copyFile(targets);
%             targets.fileMustExist;
%             
%             Path.empty.copyFile(Path.empty);
%         end
        
        %% Matlab files
        function fileOfMatlabElement(obj)
            actual = File.ofMatlabElement(["mean", "PathTest"]).string;
            expected = string({which("mean") which("PathTest")});
            obj.assertEqual(actual, expected);
            obj.assertError(@() File.ofMatlabElement("npofas&/"), "File:ofMatlabElement:NotFound");
        end
        
        function folderOfMatlabElement(obj)
            actual = Folder.ofMatlabElement(["mean", "PathTest"]);
            expected = File.ofMatlabElement(["mean", "PathTest"]).parent;
            obj.assertEqual(actual, expected);
            obj.assertError(@() Folder.ofMatlabElement("npofas&/"), "File:ofMatlabElement:NotFound");
        end
        
        function fileOfCaller(obj)
            obj.assertEqual(File.ofCaller, File(which("PathTest")));
        end
        
        function folderOfCaller(obj)
            obj.assertEqual(Folder.ofCaller, File(which("PathTest")).parent);
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
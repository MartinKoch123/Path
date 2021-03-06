classdef PathTest < matlab.unittest.TestCase
    
    properties (Constant)
        testFolder = Folder.ofMatlabElement("PathTest") / "test";
    end
    
    methods
        function assertAllFalse(obj, values)
            obj.assertFalse(any(values));
        end
        
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
        
        function result = testRoot(obj)
            if ispc
                result = "C:";
            else
                result = "/tmp";
            end
        end
        
        function result = testRoot2(obj)
            if ispc
                result = "D:";
            else
                result = "/tmp2";
            end
        end
        
        function result = testRootPattern(obj)
            if ispc
                result = "C*";
            else
                result = "/t*";
            end
        end
    end
    
    methods(TestMethodTeardown)
        function removeTestFolder(testCase)
            if testCase.testFolder.exists
                rmdir(testCase.testFolder.string, "s");
            end
        end
        
        function closeFiles(testCase)
            fclose all;
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
            obj.assertEqual(File("one"+pathsep+" two"), File(["one", "two"]));
            obj.assertEqual(Folder(" "+pathsep+" "), Folder([".", "."]));
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
            actual = File('a', "b"+pathsep+" c", {'d', "e"+pathsep+" f"}, ["g", "h"]);
            expected = File(["a" "b" "c" "d" "e" "f" "g", "h"]);
            obj.assertEqual(actual, expected);
        end
        
        %% Factories
        
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
        
        function current(obj)
            obj.assertEqual(Folder.current, Folder(pwd));
        end
        
        function home(obj)
            if ispc
                obj.assertEqual(Folder.home, Folder(getenv("USERPROFILE")));
            else
                obj.assertEqual(Folder.home, Folder(getenv("HOME")));
            end
        end
                
        %% Conversion
        function string(obj)
            obj.assertEqual(File(["one", "two"]).string, ["one", "two"]);
            obj.assertEqual(File.empty.string, strings(1, 0));
        end
        
        function char(obj)
            obj.assertEqual('test', File("test").char);
        end
        
        function cellstr(obj)
            obj.assertEqual(File("one").cellstr, {'one'});
            obj.assertEqual(Folder(["one", "two"]).cellstr, {'one', 'two'});
        end
        
        %% Clean
        function clean_stripWhitespace(obj)
            obj.assertEqual("test", File(sprintf("\n \ttest  \r")).string);
        end
        
        function clean_removesRepeatingSeparators(obj)
            s = filesep;
            actual = Folder("one" + s + s + s + "two" + s + s + "three").string;
            expected = adjustSeparators("one/two/three");
            obj.assertEqual(actual, expected);
        end
        
        function clean_removesOuterSeparators(obj)
            s = filesep;
            actual = File([s 'one/two/three' s]).string;
            if ispc
                expected = "one\two\three";
            else
                expected = "/one/two/three";
            end
            obj.assertEqual(actual, expected);
        end
        
        function clean_removesCurrentDirDots(obj)
            actual = Folder("\.\.\one\.\two.three\.\.four\.\.\").string;
            if ispc
                expected = "one\two.three\.four";
            else
                expected = "/one/two.three/.four";
            end
            obj.assertEqual(actual, expected);
        end
        
        function clean_replacesSeparatorVariations(obj)
            actual = File("one/two\three").string;
            expected = adjustSeparators("one/two/three");
            obj.assertEqual(actual, expected);
        end
        
        function clean_resolvesParentDirDots(obj)
            actual = File("one/two/three/../../four");
            expected = File("one/four");
            obj.assertEqual(actual, expected);
        end
        
        %% Name
        function name(obj)
            obj.assertEqual(File(obj.testRoot + "/one/two/three.ext").name.string, "three.ext");
            obj.assertEqual(Folder("one.two.three.ext").name.string, "one.two.three.ext");
            obj.assertEqual(File("one").name.string, "one");
            obj.assertEqual(Folder("..").name.string, "..");
            obj.assertEqual(File(".").name.string, ".");
            obj.assertEmpty(File.empty.name);
            obj.assertInstanceOf(Folder.empty.name, "Folder")
            obj.assertInstanceOf(File.empty.name, "File")
        end
        
        function setName(obj)
            files = File("a.b", "c/d");
            obj.assertEqual(files.setName("f.g"), File("f.g", "c/f.g"));
            obj.assertEqual(files.setName("f.g", "h/i"), File("f.g", "c/h/i"));
            obj.assertError(@() files.setName("f", "g", "h"), "Folder:append:LengthMismatch");
            folders = Folder("a.b", "c/d");
            obj.assertEqual(folders.setName("f.g"), Folder("f.g", "c/f.g"));
            obj.assertEqual(folders.setName("f.g", "h/i"), Folder("f.g", "c/h/i"));
            obj.assertError(@() folders.setName("f", "g", "h"), "Folder:append:LengthMismatch");
        end
        
        function hasName(obj)
            obj.assertEqual(File("one.two", "three/four").hasName(["hree*", "*.two"]), [true, false]);
            obj.assertEqual(Folder("one.two", "three/four").hasName(), [false, false]);
            obj.assertEqual(File.empty.hasName(["hree*", "*.two"]), logical.empty(1, 0));
        end
        
        function hasNotName(obj)
            obj.assertEqual(Folder("one.two", "three/four").hasNotName(["hree*", "*.two"]), [false, true]);
            obj.assertEqual(File("one.two", "three/four").hasNotName(), [true, true]);
            obj.assertEqual(Folder.empty.hasName(["hree*", "*.two"]), logical.empty(1, 0));
        end
        
        function whereNameIs(obj)
            obj.assertEqual(File("one.two", "three/four").whereNameIs(["hree*", "*.two"]), File("one.two"));
            obj.assertEqual(Folder("one.two", "three/four").whereNameIs(), Folder.empty);
            obj.assertEqual(File.empty.whereNameIs(["hree*", "*.two"]), File.empty);
        end
        
        function whereNameIsNot(obj)
            obj.assertEqual(Folder("one.two", "three/four").whereNameIsNot(["hree*", "*.two"]), Folder("three/four"));
            obj.assertEqual(File("one.two", "three/four").whereNameIsNot(), File("one.two", "three/four"));
            obj.assertEqual(Folder.empty.whereNameIsNot(["hree*", "*.two"]), Folder.empty);
        end
        
        function addSuffix(obj)
            obj.assertEqual(File("a/b.c").addSuffix("_s"), File("a/b.c_s"))
            obj.assertEqual(Folder("a/b.c", "d/e").addSuffix("_s"), Folder("a/b.c_s", "d/e_s"));
            obj.assertEqual(File("a/b.c", "d/e").addSuffix(["_s1", "_s2"]), File("a/b.c_s1", "d/e_s2"));
            obj.assertEqual(Folder.empty.addSuffix("s"), Folder.empty);
            obj.assertError(@() Folder("a/b.c", "d/e").addSuffix(["_s1", "_s2", "_s3"]), "Path:Validation:InvalidSize");
            obj.assertError(@() File("a/b.c", "d/e").addSuffix("/"), "Path:Validation:InvalidName");
        end
        
        %% Extension
        function extension(obj)
            obj.assertEqual(File(obj.testRoot + "/one/two/three.ext").extension, ".ext");
            obj.assertEqual(File("one.two.three.ext").extension, ".ext");
            obj.assertEqual(File("one.").extension, ".");
            obj.assertEqual(File("one").extension, "");
            obj.assertEqual(File("..").extension, "");
            obj.assertEqual(File(".").extension, "");
        end
        
        function setExtension(obj)
            obj.assertEqual(File("a.b", "c.d", "e").setExtension(".f"), File("a.f", "c.f", "e.f"));
            obj.assertEqual(File("a.b", "c.d", "e").setExtension([".f", "", "g"]), File("a.f", "c", "e.g"));
            obj.assertEqual(File.empty.setExtension(".a"), File.empty);
        end
        
        function hasExtension(obj)
            obj.assertEqual(File("one.two", "three.four").hasExtension([".fo*", "asf"]), [false, true]);
            obj.assertEqual(File("one.two", "three.four").hasExtension(), [false, false]);
            obj.assertEqual(File.empty.hasExtension([".fo*", "asf"]), logical.empty(1, 0));
        end
        
        function hasNotExtension(obj)
            obj.assertEqual(File("one.two", "three.four").hasNotExtension([".fo*", "asf"]), [true, false]);
            obj.assertEqual(File("one.two", "three.four").hasNotExtension(), [true, true]);
            obj.assertEqual(File.empty.hasNotExtension([".fo*", "asf"]), logical.empty(1, 0));
        end
        
        function whereExtensionIs(obj)
            files = File("one.two", "three.four");
            obj.assertEqual(files.whereExtensionIs([".fo*", "asf"]), files(2));
            obj.assertEqual(files.whereExtensionIs(), File.empty);
            obj.assertEqual(File.empty.whereExtensionIs([".fo*", "asf"]), File.empty);
        end
        
        function whereExtensionIsNot(obj)
            files = File("one.two", "three.four");
            obj.assertEqual(files.whereExtensionIsNot([".fo*", "asf"]), files(1));
            obj.assertEqual(files.whereExtensionIsNot(), files);
            obj.assertEqual(File.empty.whereExtensionIsNot([".fo*", "asf"]), File.empty);
        end
        
        %% Stem
        function stem(obj)
            obj.assertEqual(File(obj.testRoot + "/one/two/three.ext").stem, "three");
            obj.assertEqual(File("one.two.three.ext").stem, "one.two.three");
            obj.assertEqual(File("one").stem, "one");
            obj.assertEqual(File("..").stem, "..");
            obj.assertEqual(File(".").stem, ".");
            obj.assertEmpty(File.empty.stem);
            obj.assertInstanceOf(File.empty.stem, "string")
        end
        
        function setStem(obj)
            files = File("a.b", "c/d");
            obj.assertEqual(files.setStem("e"), File("e.b", "c/e"));
            obj.assertEqual(files.setStem(["e", "f"]), File("e.b", "c/f"));
            obj.assertError(@() files.setStem(""), "Path:Validation:InvalidName");
            obj.assertError(@() files.setStem("a/\b"), "Path:Validation:InvalidName");
            obj.assertError(@() files.setStem(["a", "b", "c"]), "Path:Validation:InvalidSize");
        end
        
        function hasStem(obj)
            obj.assertEqual(File("one.two", "three.four").hasStem(["t*ee", "asf"]), [false, true]);
            obj.assertEqual(File("one.two", "three.four").hasStem(), [false, false]);
            obj.assertEqual(File.empty.hasStem(["t*ee", "asf"]), logical.empty(1, 0));
        end
        
        function hasNotStem(obj)
            obj.assertEqual(File("one.two", "three.four").hasNotStem(["t*ee", "asf"]), [true, false]);
            obj.assertEqual(File("one.two", "three.four").hasNotStem(), [true, true]);
            obj.assertEqual(File.empty.hasNotStem(["t*ee", "asf"]), logical.empty(1, 0));
        end
        
        function whereStemIs(obj)
            files = File("one.two", "three.four");
            obj.assertEqual(files.whereStemIs(["t*ee", "asf"]), files(2));
            obj.assertSize(files.whereStemIs(), [1, 0]);
            obj.assertSize(File.empty.whereStemIs(["t*ee", "asf"]), [1, 0]);
        end
        
        function whereStemIsNot(obj)
            files = File("one.two", "three.four");
            obj.assertEqual(files.whereStemIsNot(["t*ee", "asf"]), files(1));
            obj.assertEqual(files.whereStemIsNot(), files);
            obj.assertSize(File.empty.whereStemIsNot(["t*ee", "asf"]), [1, 0]);
        end
        
        function addStemSuffix(obj)
            obj.assertEqual(File("a/b.c").addStemSuffix("_s"), File("a/b_s.c"))
            obj.assertEqual(File("a/b.c", "d/e").addStemSuffix("_s"), File("a/b_s.c", "d/e_s"));
            obj.assertEqual(File("a/b.c", "d/e").addStemSuffix(["_s1", "_s2"]), File("a/b_s1.c", "d/e_s2"));
            obj.assertEqual(File.empty.addStemSuffix("s"), File.empty);
            obj.assertError(@() File("a/b.c", "d/e").addStemSuffix(["_s1", "_s2", "_s3"]), "Path:Validation:InvalidSize");
            obj.assertError(@() File("a/b.c", "d/e").addStemSuffix("/"), "Path:Validation:InvalidName");
        end
        
        %% Parent
        function parent(obj)
            obj.assertEqual(File(obj.testRoot + "/one/two/three.ext").parent, Folder(obj.testRoot + "/one/two"));
            obj.assertEqual(Folder("../../one/three.ext").parent, Folder("../../one"));
            obj.assertEqual(File("one").parent, Folder("."));
            obj.assertEqual(Folder("..").parent, Folder("."));
            obj.assertEqual(File(".").parent, Folder("."));
        end
        
        function setParent(obj)
            files = File("a.b", "c/d", "e/f/g");
            obj.assertEqual(files.setParent("h"), File("h/a.b", "h/d", "h/g"))
        end
        
        function hasParent(obj)
            obj.assertEqual(File("a/b/c", obj.testRoot + "/d/e").hasParent(["*d", "asf"]), [false, true]);
            obj.assertEqual(Folder("a/b/c", obj.testRoot + "/d/e", "f").hasParent(), [true, true, false]);
            obj.assertEqual(File.empty.hasParent(["*d", "asf"]), logical.empty(1, 0));
        end
        
        function hasNotParent(obj)
            obj.assertEqual(Folder("a/b/c", obj.testRoot + "/d/e").hasNotParent(["*d", "asf"]), [true, false]);
            obj.assertEqual(File("a/b/c", obj.testRoot + "/d/e", "f").hasNotParent(), [false, false, true]);
            obj.assertEqual(Folder.empty.hasNotParent(["*d", "asf"]), logical.empty(1, 0));
        end
        
        function whereParentIs(obj)
            files = File("a/b/c", obj.testRoot + "/d/e", "f");
            obj.assertEqual(files.whereParentIs(["*d", "asf"]), files(2));
            obj.assertEqual(files.whereParentIs(), files(1:2));
            obj.assertEqual(File.empty.whereParentIs(["*d", "asf"]), File.empty);
        end
        
        function whereParentIsNot(obj)
            folders = Folder("a/b/c", obj.testRoot + "/d/e", "f");
            obj.assertEqual(folders.whereParentIsNot(["*d", "asf"]), folders([1, 3]));
            obj.assertEqual(folders.whereParentIsNot(), folders(3));
            obj.assertEqual(Folder.empty.whereParentIsNot(["*d", "asf"]), Folder.empty);
        end
        
        %% Root
        function root(obj)
            obj.assertEqual(File(obj.testRoot + "/one/two.ext").root, Folder(obj.testRoot));
            obj.assertEqual(Folder("one/two").root, Folder("."));
        end
        
        function setRoot(obj)
            obj.assertEqual(File(obj.testRoot + "/a/b.c", "e/f.g").setRoot(obj.testRoot2), File(obj.testRoot2 + "/a/b.c", obj.testRoot2 + "/e/f.g"));
            obj.assertEqual(Folder.empty.setRoot(obj.testRoot), Folder.empty);
            obj.assertEqual(Folder(obj.testRoot + "/a/b").setRoot("../c/d"), Folder("../c/d/a/b"));
            obj.assertError(@() File("a").setRoot(pathsep), "Path:Validation:ContainsPathsep");
        end
        
        function hasRoot(obj)
            obj.assertEqual(File("a/b/c", obj.testRoot + "/d/e").hasRoot([obj.testRootPattern, "asf"]), [false, true]);
            obj.assertEqual(Folder("a/b/c", obj.testRoot + "/d/e").hasRoot(), [false, false]);
            obj.assertEqual(File.empty.hasRoot([obj.testRootPattern, "asf"]), logical.empty(1, 0));
        end
        
        function hasNotRoot(obj)
            obj.assertEqual(Folder("a/b/c", obj.testRoot + "/d/e").hasNotRoot([obj.testRootPattern, "asf"]), [true, false]);
            obj.assertEqual(File("a/b/c", obj.testRoot + "/d/e").hasNotRoot(), [true, true]);
            obj.assertEqual(Folder.empty.hasNotRoot([obj.testRootPattern, "asf"]), logical.empty(1, 0));
        end
        
        function whereRootIs(obj)
            files = File("a/b/c", obj.testRoot + "/d/e");
            obj.assertEqual(files.whereRootIs([obj.testRootPattern, "asf"]), files(2));
            obj.assertEqual(files.whereRootIs(), File.empty);
            obj.assertEqual(File.empty.whereRootIs([obj.testRootPattern, "asf"]), File.empty);
        end
        
        function whereRootNot(obj)
            folder = Folder("a/b/c", obj.testRoot + "/d/e");
            obj.assertEqual(folder.whereRootIsNot([obj.testRootPattern, "asf"]), folder(1));
            obj.assertEqual(folder.whereRootIsNot(), folder);
            obj.assertEqual(Folder.empty.whereRootIsNot([obj.testRootPattern, "asf"]), Folder.empty);
        end
        
        
        %% Properties
        function isRelative(obj)
            obj.assertTrue(all(File(".", "..", "a/b.c", "../../a/b/c").isRelative));
            obj.assertFalse(any(File(obj.testRoot+"\", obj.testRoot+"\a\b.c", "\\test\", "\\test\a\b").isRelative));
        end
        
        function isAbsolute(obj)
            obj.assertFalse(any(Folder(".", "..", "a/b.c", "../../a/b/c").isAbsolute));
            obj.assertTrue(any(Folder(obj.testRoot+"\", obj.testRoot+"\a\b.c", "\\test\", "\\test\a\b").isAbsolute));
        end
        
        function equalAndNotEqual(obj)
            files = File("one/two", "a\b.c", "three/four", "a\b.c");
            obj.assertEqual(files(1:2) == files(3:4), [false, true]);
            obj.assertEqual(files(1:2) ~= files(3:4), [true, false]);
            obj.assertEqual(files(2) == files(3:4), [false, true]);
            obj.assertEqual(files(3:4) ~= files(2), [true, false]);
            obj.assertTrue(File("one/two") == Folder("one/two"));
        end
        
        function parts(obj)
            testRootWithoutLeadingSeparator = regexprep(obj.testRoot, "^" + regexptranslate("escape", filesep), "");
            obj.assertEqual(File(obj.testRoot + "/a/b\\c.e\").parts, [testRootWithoutLeadingSeparator, "a", "b", "c.e"]);
            obj.assertEqual(Folder(".\..\/\../a/b\\c.e\").parts, ["..", "..", "a", "b", "c.e"]);
            obj.assertEqual(File().parts, ".");
            obj.assertError(@() Folder.empty.parts, "MATLAB:validation:IncompatibleSize");
            obj.assertError(@() File("a", "b").parts, "MATLAB:validation:IncompatibleSize");
            
        end
        
        function strlength(obj)
            obj.assertEqual(File("a/b.c", "d.e").strlength, [5, 3])
            obj.assertEmpty(Folder.empty.strlength)
        end
        
        %% Absolute/Relative        
        function absolute(obj)
            obj.assertEqual(File("a.b", obj.testRoot + "/c/d.e").absolute, [Folder(pwd).appendFile("a.b"), File(obj.testRoot + "/c/d.e")]);
            obj.assertEqual(Folder("a.b", obj.testRoot + "/c/d.e").absolute, [Folder(pwd).appendFolder("a.b"), Folder(obj.testRoot + "/c/d.e")]);
            obj.assertEqual(File(obj.testRoot).absolute, File(obj.testRoot));
            obj.assertEqual(File.empty.absolute, File.empty);
            obj.assertEqual(Folder.empty.absolute, Folder.empty);
        end
        
        function relative(obj)
            referencePath = Folder(obj.testRoot + "/a/b/c");
            file1 = File(obj.testRoot + "/a/d/e.f");
            obj.assertEqual(file1.relative(referencePath), File("..\..\d\e.f"));
            
            folder1 = Folder(obj.testRoot);
            obj.assertEqual(folder1.relative(referencePath), Folder("..\..\.."));
            
            obj.assertEqual(referencePath.relative(referencePath), Folder("."));
            
            obj.assertEqual(File.empty.relative(referencePath), File.empty);
            obj.assertEqual(Folder.empty.relative(referencePath), Folder.empty);
            
            file2 = File(obj.testRoot2 + "/a.b");
            obj.assertError(@() file2.relative(referencePath), "Path:relative:RootsDiffer"); 
            
            folder2 = Folder("a/b");
            obj.assertEqual(folder2.relative, folder2.relative(pwd));
            
            file3 = File("a.b");
            referenceFolder2 = Folder("b/c").absolute;
            obj.assertEqual(file3.relative(referenceFolder2), File("..\..\a.b"));
            
            obj.assertError(@() file3.relative([Folder, Folder]), "MATLAB:validation:IncompatibleSize");
            
            obj.assertEqual(file3.relative("."), file3);
            obj.assertEqual(File("a.b", "c/d").relative, File("a.b", "c/d"));
        end
        
        %% Array
        function count(obj)
            obj.assertEqual(File("a", "b").count, 2);
        end
        
        function sort(obj)
            [sortedFiles, indices] = File("a", "c", "b").sort;
            obj.assertEqual(sortedFiles, File("a", "b", "c"));
            obj.assertEqual(indices, [1, 3, 2]);
            
            [sortedFiles, indices] = File("a", "c", "b").sort("descend");
            obj.assertEqual(sortedFiles, File("c", "b", "a"));
            obj.assertEqual(indices, [2, 3, 1]);
        end
        
        function unique(obj)
            obj.assertEqual(File("a", "b", "a").unique_, File("a", "b"));
            obj.assertEqual(File.empty.unique_, File.empty);
        end
        
        function deal(obj)
            files = File("a.b", "c.d");
            [file1, file2] = files.deal;
            obj.assertEqual(file1, files(1));
            obj.assertEqual(file2, files(2));
            
            obj.assertError(@testFun, "Path:deal:InvalidNumberOfOutputs");            
            function testFun
                [file1, file2, file3] = files.deal;
            end
        end
        
        function vertcat_(obj)
            obj.assertError(@() [File("a"); File("b")], "Path:vertcat:NotAllowed");
            [File, File];
        end
        
        function subsasgn_(obj)
            
            obj.assertError(@() makeColumn, "Path:subsasgn:MultiRowsNotAllowed");
            obj.assertError(@() make3dArray, "Path:subsasgn:MultiRowsNotAllowed");
            files = File;
            files(2) = File;
            files(1, 3) = File;
            
            function makeColumn()
                files = File("a");
                files(2, 1) = File("b");
            end
            
            function make3dArray()
                files = File("a");
                files(1, 1, 1) = File("b");
            end
        end
        
        %% Join
        function append(obj)
            obj.assertEqual(Folder("one").append(""), Folder("one"));
            obj.assertEqual(Folder("one").append(["one", "two"]), Folder("one/one", "one/two"));
            obj.assertEqual(Folder("one", "two").append("one"), Folder("one/one", "two/one"));
            obj.assertEmpty(Folder.empty.append("one"), Folder);
            obj.assertEqual(Folder("one").append(strings(0)), Folder("one"));
            obj.assertError(@() Folder("one", "two", "three").append(["one", "two"]), "Folder:append:LengthMismatch");
            obj.assertEqual(Folder("a").append("b", 'c', {'d', "e", "f"}), Folder("a/b", "a/c", "a/d", "a/e", "a/f"));
            obj.assertEqual(Folder("one").append(["one.a", "two.b"]), File("one/one.a", "one/two.b"));
            obj.assertError(@() Folder("one").append(["one.a", "two"]), "Folder:append:Ambiguous");
            
            [file1, file2] = Folder("a").append("b.c", "d.e");
            obj.assertEqual(file1, File("a/b.c"));
            obj.assertEqual(file2, File("a/d.e"));
            
            obj.assertError(@testFun, "Path:deal:InvalidNumberOfOutputs");            
            function testFun
                [file1, file2, file3] = Folder("a").append("b.c", "d.e");
            end
        end
        
        function appendFile(obj)
            obj.assertEqual(Folder("a").appendFile("b.c", "d"), File("a/b.c", "a/d"));
        end
        
        function appendFolder(obj)
            obj.assertEqual(Folder("a").appendFolder("b.c", "d"), Folder("a/b.c", "a/d"));
        end
        
        function mrdivide(obj)
            obj.assertEqual(Folder("one") / "two", Folder("one/two"));
            [file1, file2] = Folder("a") / ["b.c", "d.e"];
            obj.assertEqual(file1, File("a/b.c"));
            obj.assertEqual(file2, File("a/d.e"));
            
            obj.assertError(@testFun, "Path:deal:InvalidNumberOfOutputs");            
            function testFun
                [file1, file2, file3] = Folder("a") / ["b.c", "d.e"];
            end
        end
        
        function mldivide(obj)
            obj.assertEqual(Folder("one") \ "two", Folder("one/two"));
            [file1, file2] = Folder("a") \ ["b.c", "d.e"];
            obj.assertEqual(file1, File("a/b.c"));
            obj.assertEqual(file2, File("a/d.e"));
            
            obj.assertError(@testFun, "Path:deal:InvalidNumberOfOutputs");            
            function testFun
                [file1, file2, file3] = Folder("a") \ ["b.c", "d.e"];
            end
        end
        
        %% File system interaction
        function cd(obj)
            obj.testFolder.mkdir;
            actual = pwd;
            expected = obj.testFolder.cd.char;
            obj.assertEqual(actual, expected);
            obj.assertEqual(pwd, obj.testFolder.char);
            cd(actual);
        end
        
        function mkdir(obj)
            obj.testFolder.append(["a", "b/a"]).mkdir;
            obj.assertFolderExists(obj.testFolder / ["a", "b/a"]);
        end
        
        function dir(obj)
            obj.assertEqual(Folder("sadfs(/%634ihsfd").dir, dir("sadfs(/%634ihsfd"));
            obj.testFolder.append("a.b", "a2.b", "c/d.e").createEmptyFile;
            obj.assertEqual(obj.testFolder.dir, dir(obj.testFolder.string));
            obj.assertEqual(obj.testFolder.appendFile("c/d.e").dir, dir(obj.testFolder.string + filesep+"c"+filesep+"d.e"));
        end
        
        function createEmptyFile(obj)
            obj.testFolder.append("a.b", "c/d.e").createEmptyFile;
            obj.assertFileExists(obj.testFolder / ["a.b", "c/d.e"]);
        end
        
        function fileExistsAndFolderExists(obj)
            
            files = obj.testFolder / ["a.b", "c/d.e"];
            folders = Folder(files);
            obj.assertEqual(files.exists, [false, false]);
            obj.assertEqual(folders.exists, [false, false]);
            obj.assertError(@() files.mustExist, "Path:mustExist:Failed");
            obj.assertError(@() folders.mustExist, "Path:mustExist:Failed");
            
            files.createEmptyFile;
            obj.assertEqual(files.exists, [true, true]);
            obj.assertEqual(folders.exists, [false, false]);
            files.mustExist;
            obj.assertError(@() folders.mustExist, "Path:mustExist:Failed");
            
            delete(files(1).string, files(2).string);
            folders.mkdir;
            
            obj.assertEqual(files.exists, [false, false]);
            obj.assertEqual(folders.exists, [true, true]);
            folders.mustExist;
            obj.assertError(@() files.mustExist, "Path:mustExist:Failed");
        end
        
        function fopen(obj)
            file = obj.testFolder / "a.b";
            file.parent.mkdir;
            [id, errorMessage] = file.fopen("w", "n", "UTF-8");
            obj.assertFalse(id == -1);
            obj.assertEqual(errorMessage, '');
            fclose(id);
            obj.assertError(@() fopen([file, file]), "MATLAB:validation:IncompatibleSize");
        end
        
        function open(obj)
            file = obj.testFolder / "a.b";
            obj.assertError(@() open([file, file]), "MATLAB:validation:IncompatibleSize");
            obj.assertError(@() file.open, "Path:mustExist:Failed");
            id = file.open("w");
            obj.assertFalse(id == -1);
            fclose(id);
            
            % Assert that auto clean closes the file.
            id = openWithCleaner(file);
            obj.assertFalse(id == -1);
            obj.assertError(@() fclose(id), "MATLAB:badfid_mx");
            
            % Assert that auto clean does not raise an error if the file
            % has already been closed.
            openWithCleaner(file);
                        
            function id = openWithCleaner(file)
                [id, autoClean] = file.openForReading;
            end
            
            function openWithCleaner2(file)
                [id, autoClean] = file.openForReading;
                fclose(id);
            end
            
        end
        
        function copyToFolder(obj)
            sources = obj.testFolder / ["a.b", "c/d.e"];
            target = obj.testFolder / "target";
            sources.createEmptyFile;
            sources.copyToFolder(target);
            target.append(sources.name).mustExist;
            sources.mustExist;
            
            File.empty.copyToFolder(target);
        end
        
        function moveToFolder(obj)
            sources = obj.testFolder / ["a.b", "c/d.e"];
            target = obj.testFolder / "target";
            sources.createEmptyFile;
            sources.moveToFolder(target);
            target.append(sources.name).mustExist;
            obj.assertAllFalse(sources.exists);
            
            File.empty.moveToFolder(target);
        end
        
        function listFiles(obj)
            files = obj.testFolder / ["a.b", "c.d", "e/f.g"];
            files.createEmptyFile;
            folders = [obj.testFolder, obj.testFolder];
            obj.assertEqual(folders.listFiles, obj.testFolder / ["a.b", "c.d"]);
            obj.assertError(@() Folder("klajsdfoi67w3pi47n").listFiles, "Path:mustExist:Failed");
            emptyFolder = obj.testFolder.appendFolder("empty");
            emptyFolder.mkdir;
            obj.assertEqual(emptyFolder.listFiles, File.empty);
        end
        
        function listDeepFiles(obj)
            files = obj.testFolder.appendFile("a.b", "c.d", "e/f/g.h");
            files.createEmptyFile;
            folders = [obj.testFolder, obj.testFolder];
            obj.assertEqual(folders.listDeepFiles, obj.testFolder.appendFile("a.b", "c.d", "e/f/g.h"));
            obj.assertError(@() Folder("klajsdfoi67w3pi47n").listDeepFiles, "Path:mustExist:Failed");
            emptyFolder = obj.testFolder.appendFolder("empty");
            emptyFolder.mkdir;
            obj.assertEqual(emptyFolder.listDeepFiles, File.empty);
        end
        
        function delete_(obj)
            files = obj.testFolder / ["a.b", "c/d.e"];
            files.createEmptyFile;
            files(3) = obj.testFolder / "e/f";
            files.delete;
            obj.assertFalse(any(files.exists));
            
            File(obj.testFolder.string).delete;
            obj.assertTrue(obj.testFolder.exists);
        end
        
        function readText(obj)
            expected = sprintf("line1\nline2\n");
            file = obj.testFolder / "a.txt";
            fileId = file.openForWritingText;
            fprintf(fileId, "%s", expected);
            fclose(fileId);            
            actual = file.readText;            
            obj.assertEqual(actual, expected);
        end
        
        function writeText(obj)
            expected = sprintf("line1\nline2\n");
            file = obj.testFolder / "a.txt";
            file.writeText(expected);
            actual = string(fileread(file.string));
            actual = actual.replace(sprintf("\r\n"), newline);
            obj.assertEqual(actual, expected);
        end
        
        function bytes(obj)
            oldDir = Folder.ofCaller.cd;
            fileInfo(1) = dir("File.m");
            fileInfo(2) = dir("Folder.m");
            obj.assertEqual(File("File.m", "Folder.m").bytes, [fileInfo(1).bytes, fileInfo(2).bytes]);
            obj.assertEqual(File.empty.bytes, []);
            oldDir.cd;
        end
        
        function modifiedDate(obj)
            files = obj.testFolder.append("a.b", "c.d");
            files.createEmptyFile;
            content = dir(obj.testFolder.string);
            actual(1) = datetime(content({content.name} == "a.b").datenum, "ConvertFrom", "datenum");
            actual(2) = datetime(content({content.name} == "c.d").datenum, "ConvertFrom", "datenum");
            obj.assertEqual(actual, files.modifiedDate);
            
            actual = datetime(content({content.name} == ".").datenum, "ConvertFrom", "datenum");
            obj.assertEqual(actual, obj.testFolder.modifiedDate)
        end
        
        function File_temp(obj)
            obj.assertEqual(File.temp(0), File.empty);
            obj.assertLength(File.temp(3), 3);
            obj.assertEqual(File.temp.parent, Folder(tempdir));
        end
        
        function Folder_temp(obj)
            obj.assertEqual(Folder.temp, Folder(tempdir));
        end
        
        function tempFile(obj)
            obj.assertEqual(Folder("a").tempFile(0), File.empty);
            files = Folder("a").tempFile(2);
            obj.assertLength(files, 2);
            obj.assertNotEqual(files(1), files(2));
            obj.assertEqual(files(1).parent, Folder("a"));
            
        end
        
        function rmdir(obj)
            folders = obj.testFolder / ["a", "b"];
            folders.mkdir;
            folders(1).append("c.d").createEmptyFile;
            obj.assertError(@() folders(1).rmdir, "MATLAB:RMDIR:NoDirectoriesRemoved");
            folders.rmdir("s");
            obj.assertFolderDoesNotExist(folders);
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
            warning("off", "MATLAB:load:variableNotFound");
            try
                c = file.load("c");
            catch exception
                obj.assertEqual(string(exception.identifier), "Path:load:VariableNotFound");
                raisedError = true;
            end
            warning("on", "MATLAB:load:variableNotFound");
            obj.assertTrue(raisedError);
        end
        
    end
end

function s = adjustSeparators(s)
    s = s.replace(["/", "\"], filesep);
end
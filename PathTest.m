classdef PathTest < matlab.unittest.TestCase

    properties (Constant)
        testFolder = Path.ofMatlabElement("PathTest").parent / "test";
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

        function assertError2(obj, func, expected)
            % Version of assertError which allows expecting one of multiple
            % error IDs.
            actual = "";
            try
                func()
            catch exc
                actual = exc.identifier;
            end
            obj.assertTrue(ismember(actual, expected));
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
            obj.assertEqual(Path(["one", "two"]).string, ["one", "two"]);
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
            obj.assertEqual(Path("one"+pathsep+" two"), Path(["one", "two"]));
            obj.assertEqual(Path(" "+pathsep+" "), Path([".", "."]));
        end

        function constructDefault(obj)
            obj.assertEqual(Path().string, ".");
        end

        function constructEmpty(obj)
            obj.assertSize(Path(string.empty), [1, 0]);
            obj.assertSize(Path({}), [1, 0]);
        end

        function constructWithMultipleArguments(obj)
            actual = Path('a', "b"+pathsep+" c", {'d', "e"+pathsep+" f"}, ["g", "h"]);
            expected = Path(["a" "b" "c" "d" "e" "f" "g", "h"]);
            obj.assertEqual(actual, expected);
        end

        %% Factories
        function ofMatlabElement(obj)
            actual = Path.ofMatlabElement(["mean", "PathTest"]).string;
            expected = string({which("mean") which("PathTest")});
            obj.assertEqual(actual, expected);
            obj.assertError(@() Path.ofMatlabElement("npofas&/"), "Path:ofMatlabElement:NotFound");
        end

        function ofCaller(obj)
            obj.assertEqual(Path.ofCaller, Path(which("PathTest")));
            obj.assertEqual(Path.ofCaller(2), Path(which(adjustSeparators("+matlab\+unittest\TestRunner.m"))));
        end

        function pwd(obj)
            obj.assertEqual(Path.pwd, Path(pwd));
        end

        function home(obj)
            if ispc
                obj.assertEqual(Path.home, Path(getenv("USERPROFILE")));
            else
                obj.assertEqual(Path.home, Path(getenv("HOME")));
            end
        end

        function matlab(obj)
            obj.assertEqual(Path.matlab, Path(matlabroot));
        end

        function searchPath(obj)
            obj.assertEqual(Path.searchPath, Path(path));
        end

        function userPath(obj)
            obj.assertEqual(Path.userPath, Path(userpath));
        end

        %% Conversion
        function string(obj)
            obj.assertEqual(Path(["one", "two"]).string, ["one", "two"]);
            obj.assertEqual(Path.empty.string, strings(1, 0));
        end

        function char(obj)
            obj.assertEqual('test', Path("test").char);
        end

        function cellstr(obj)
            obj.assertEqual(Path("one").cellstr, {'one'});
            obj.assertEqual(Path(["one", "two"]).cellstr, {'one', 'two'});
        end

        function quote(obj)
            obj.assertEqual(Path(["a/b.c", "d.e"]).quote, adjustSeparators(["""a/b.c""", """d.e"""]))
            obj.assertEqual(Path.empty.quote, strings(1, 0))
        end

        %% Clean
        function clean_stripWhitespace(obj)
            obj.assertEqual("test", Path(sprintf("\n \ttest  \r")).string);
        end

        function clean_removesRepeatingSeparators(obj)
            s = filesep;
            actual = Path("one" + s + s + s + "two" + s + s + "three").string;
            expected = adjustSeparators("one/two/three");
            obj.assertEqual(actual, expected);
        end

        function clean_removesOuterSeparators(obj)
            s = filesep;
            actual = Path([s 'one/two/three' s]).string;
            if ispc
                expected = "one\two\three";
            else
                expected = "/one/two/three";
            end
            obj.assertEqual(actual, expected);
        end

        function clean_removesCurrentDirDots(obj)
            actual = Path("\.\.\one\.\two.three\.\.four\.\.\").string;
            if ispc
                expected = "one\two.three\.four";
            else
                expected = "/one/two.three/.four";
            end
            obj.assertEqual(actual, expected);
        end

        function clean_replacesSeparatorVariations(obj)
            actual = Path("one/two\three").string;
            expected = adjustSeparators("one/two/three");
            obj.assertEqual(actual, expected);
        end

        function clean_resolvesParentDirDots(obj)
            tests = {
                % Input / Expected (Windows) / Expected (Linux)
                "one/two/three/../../four", "one/four", "one/four"
                "a\..\b", "b", "/b"
                };
            for test = tests'
                actual = Path(test{1}).string;
                if ispc 
                    expected = Path(test{2}).string;
                else
                    expected = Path(test{3}).string;
                end
                obj.assertEqual(actual, expected);
            end
        end

        %% Name
        function name(obj)
            obj.assertEqual(Path(obj.testRoot + "/one/two/three.ext").name.string, "three.ext");
            obj.assertEqual(Path("one.two.three.ext").name.string, "one.two.three.ext");
            obj.assertEqual(Path("one").name.string, "one");
            obj.assertEqual(Path("..").name.string, "..");
            obj.assertEqual(Path(".").name.string, ".");
            obj.assertEmpty(Path.empty.name);
        end

        function setName(obj)
            files = Path("a.b", "c/d");
            obj.assertEqual(files.setName("f.g"), Path("f.g", "c/f.g"));
            obj.assertEqual(files.setName("f.g", "h/i"), Path("f.g", "c/h/i"));
            obj.assertError(@() files.setName("f", "g", "h"), "Path:join:LengthMismatch");
        end

        function nameString(obj)
            testPaths = {
                Path(obj.testRoot + "/one/two/three.ext")
                Path("../../one/three.ext")
                Path("one")
                Path("..")
                Path(".")
                };

            for testPath = testPaths'
                obj.assertEqual(testPath{1}.name.string, testPath{1}.nameString);
            end

            obj.assertEqual(Path.empty.nameString, strings(1, 0));
            obj.assertEqual(Path("a", "b").nameString, ["a", "b"]);
        end

        function addSuffix(obj)
            obj.assertEqual(Path("a/b.c").addSuffix("_s"), Path("a/b.c_s"))
            obj.assertEqual(Path("a/b.c", "d/e").addSuffix("_s"), Path("a/b.c_s", "d/e_s"));
            obj.assertEqual(Path("a/b.c", "d/e").addSuffix(["_s1", "_s2"]), Path("a/b.c_s1", "d/e_s2"));
            obj.assertEqual(Path.empty.addSuffix("s"), Path.empty);
            obj.assertError(@() Path("a/b.c", "d/e").addSuffix(["_s1", "_s2", "_s3"]), "Path:Validation:InvalidSize");
            obj.assertError(@() Path("a/b.c", "d/e").addSuffix("/"), "Path:Validation:InvalidName");
        end

        %% Extension
        function extension(obj)
            obj.assertEqual(Path(obj.testRoot + "/one/two/three.ext").extension, ".ext");
            obj.assertEqual(Path("one.two.three.ext").extension, ".ext");
            obj.assertEqual(Path("one.").extension, ".");
            obj.assertEqual(Path("one").extension, "");
            obj.assertEqual(Path("..").extension, "");
            obj.assertEqual(Path(".").extension, "");
        end

        function setExtension(obj)
            obj.assertEqual(Path("a.b", "c.d", "e").setExtension(".f"), Path("a.f", "c.f", "e.f"));
            obj.assertEqual(Path("a.b", "c.d", "e").setExtension([".f", "", "g"]), Path("a.f", "c", "e.g"));
            obj.assertEqual(Path.empty.setExtension(".a"), Path.empty);
        end

        %% Stem
        function stem(obj)
            obj.assertEqual(Path(obj.testRoot + "/one/two/three.ext").stem, "three");
            obj.assertEqual(Path("one.two.three.ext").stem, "one.two.three");
            obj.assertEqual(Path("one").stem, "one");
            obj.assertEqual(Path("..").stem, "..");
            obj.assertEqual(Path(".").stem, ".");
            obj.assertEmpty(Path.empty.stem);
            obj.assertInstanceOf(Path.empty.stem, "string")
        end

        function setStem(obj)
            files = Path("a.b", "c/d");
            obj.assertEqual(files.setStem("e"), Path("e.b", "c/e"));
            obj.assertEqual(files.setStem(["e", "f"]), Path("e.b", "c/f"));
            obj.assertEqual(files.setStem(""), Path(".b", "c"));
            obj.assertError(@() files.setStem("a/\b"), "Path:Validation:InvalidName");
            obj.assertError(@() files.setStem(["a", "b", "c"]), "Path:Validation:InvalidSize");
        end

        function addStemSuffix(obj)
            obj.assertEqual(Path("a/b.c").addStemSuffix("_s"), Path("a/b_s.c"))
            obj.assertEqual(Path("a/b.c", "d/e").addStemSuffix("_s"), Path("a/b_s.c", "d/e_s"));
            obj.assertEqual(Path("a/b.c", "d/e").addStemSuffix(["_s1", "_s2"]), Path("a/b_s1.c", "d/e_s2"));
            obj.assertEqual(Path("a/b.c").addStemSuffix(""), Path("a/b.c"))
            obj.assertEqual(Path.empty.addStemSuffix("s"), Path.empty);
            obj.assertError(@() Path("a/b.c", "d/e").addStemSuffix(["_s1", "_s2", "_s3"]), "Path:Validation:InvalidSize");
            obj.assertError(@() Path("a/b.c", "d/e").addStemSuffix("/"), "Path:Validation:InvalidName");
        end

        %% Parent
        function parent(obj)
            obj.assertEqual(Path(obj.testRoot + "/one/two/three.ext").parent, Path(obj.testRoot + "/one/two"));
            obj.assertEqual(Path("../../one/three.ext").parent, Path("../../one"));
            obj.assertEqual(Path("one").parent, Path("."));
            obj.assertEqual(Path("..").parent, Path("."));
            obj.assertEqual(Path(".").parent, Path("."));
        end

        function parentString(obj)
            testPaths = {
                Path(obj.testRoot + "/one/two/three.ext")
                Path("../../one/three.ext")
                Path("one")
                Path("..")
                Path(".")
                };

            for testPath = testPaths'
                obj.assertEqual(testPath{1}.parent.string, testPath{1}.parentString);
            end

            obj.assertEqual(Path.empty.parentString, strings(1, 0));
            obj.assertEqual(Path("a/b", "c/d").parentString, ["a", "c"]);
        end

        function setParent(obj)
            files = Path("a.b", "c/d", "e/f/g");
            obj.assertEqual(files.setParent("h"), Path("h/a.b", "h/d", "h/g"))
        end

        function hasParent(obj)
            obj.assertEqual(Path("a/b/c", obj.testRoot + "/d/e", "hello.txt").hasParent, [true, true, false]);
            obj.assertEqual(Path.empty.hasParent(), logical.empty(1, 0));
        end

        %% Root
        function root(obj)
            tests = {
                Path(obj.testRoot + "/one/two.ext").root, Path(obj.testRoot)
                Path("one/two").root, Path(".")
                Path(obj.testRoot + "/a", "b.txt").root, Path(obj.testRoot, ".")
                };

            for test = tests'
                [actual, expected] = test{:};
                obj.assertEqual(actual, expected);
            end
        end

        function rootString(obj)
            tests = {
                Path(obj.testRoot + "/one/two.ext")
                Path("one/two").root
                Path.empty
                Path("C:\a", "b")
                };

            for test = tests'
                path = test{1};
                obj.assertEqual(path.root.string, path.rootString);
            end
        end

        function setRoot(obj)
            obj.assertEqual(Path(obj.testRoot + "/a/b.c", "e/f.g").setRoot(obj.testRoot2), Path(obj.testRoot2 + "/a/b.c", obj.testRoot2 + "/e/f.g"));
            obj.assertEqual(Path.empty.setRoot(obj.testRoot), Path.empty);
            obj.assertEqual(Path(obj.testRoot + "/a/b").setRoot("../c/d"), Path("../c/d/a/b"));
            obj.assertError(@() Path("a").setRoot(pathsep), "Path:Validation:ContainsPathsep");
        end

        %% Regex
        function regexprep(obj)
            testPaths = {strings(0), "a.b", ["test01\two.txt", "1\2\3.x"]};
            expression = {'\w', '\d\d'};
            replace = {'letter', 'numbers'};
            for testPath = testPaths
                expected = Path(regexprep(testPath{1}, expression, replace));
                actual = Path(testPath{1}).regexprep(expression, replace);
                obj.assertEqual(actual, expected);
            end
        end

        %% Properties
        function isRelative(obj)
            obj.assertTrue(all(Path(".", "..", "a/b.c", "../../a/b/c").isRelative));
            obj.assertFalse(any(Path(obj.testRoot+"\", obj.testRoot+"\a\b.c", "\\test\", "\\test\a\b").isRelative));
        end

        function isAbsolute(obj)
            obj.assertFalse(any(Path(".", "..", "a/b.c", "../../a/b/c").isAbsolute));
            obj.assertTrue(any(Path(obj.testRoot+"\", obj.testRoot+"\a\b.c", "\\test\", "\\test\a\b").isAbsolute));
        end

        function equalAndNotEqual(obj)
            files = Path("one/two", "a\b.c", "three/four", "a\b.c");
            obj.assertEqual(files(1:2) == files(3:4), [false, true]);
            obj.assertEqual(files(1:2) ~= files(3:4), [true, false]);
            obj.assertEqual(files(2) == files(3:4), [false, true]);
            obj.assertEqual(files(3:4) ~= files(2), [true, false]);
            obj.assertTrue(Path("one/two") == Path("one/two"));
        end

        function parts(obj)
            testRootWithoutLeadingSeparator = regexprep(obj.testRoot, "^" + regexptranslate("escape", filesep), "");
            obj.assertEqual(Path(obj.testRoot + "/a/b\\c.e\").parts, [testRootWithoutLeadingSeparator, "a", "b", "c.e"]);
            obj.assertEqual(Path(".\..\/\../a/b\\c.e\").parts, ["..", "..", "a", "b", "c.e"]);
            obj.assertEqual(Path().parts, ".");

            obj.assertError2(@() Path.empty.parts, ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);
            obj.assertError2(@() Path("a", "b").parts, ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);
        end

        function strlength(obj)
            obj.assertEqual(Path("a/b.c", "d.e").strlength, [5, 3])
            obj.assertEmpty(Path.empty.strlength)
        end

        %% Filter
        function where_and_is(obj)
            files = Path(obj.testRoot + "\on.e/t=wo.ab.txt");

            tests = {
                {"Parent", obj.testRoot + "\o*"}, 1
                {"ParentNot", obj.testRoot + "\o*"}, []
                {"Parent", "*a*"}, []
                {"ParentNot", "*a*"}, 1
                
                {"Name", "*.ab.txt"}, 1
                {"NameNot", "*.ab.txt"}, []
                {"Name", "test"}, []
                {"NameNot", "test"}, 1

                {"Root", "*:"}, 1
                {"RootNot", "*:"}, []
                {"Root", "*hello*"}, []
                {"RootNot", "*hello"}, 1
                
                {"Stem", "*o.a*"}, 1
                {"StemNot", "*o.a*"}, []
                {"Stem", "*wa*"}, []
                {"StemNot", "*wa*"}, 1

                {"Extension", ".txt"}, 1
                {"ExtensionNot", ".txt"}, []
                {"Extension", ".c"} []
                {"ExtensionNot", ".c"}, 1
                };

            for test = tests'
                [args, indices] = test{:};

                % Test 'where'
                actual = files.where(args{:});
                if isempty(indices)
                    expected = Path.empty;
                else
                    expected = files(indices);
                end
                obj.assertEqual(actual, expected);

                % Test 'is'
                actual = files.is(args{:});
                expected = ~isempty(indices);
                obj.assertEqual(actual, expected);
            end
        end
        
        function where_and_is2(obj)

            files = Path([ ...
                obj.testRoot + "/on.e/t=wo.ab.txt"
                "=.23f/asdf.%43"
                "..\..\p"
                "folder\file"
                ] ...
                );

            tests = {
                {"Parent", "*o*", "RootNot", obj.testRoot, "Name", ["file", "t=wo.ab.txt"]}, logical([0, 0, 0, 1])
                {"NameNot", "*f*", "Name", ["p", "file"]}, logical([0, 0, 1, 0])
                {"Root", [".", obj.testRoot]}, logical([1, 1, 1, 1])
                {"ParentNot", "*"}, logical([0, 0, 0, 0])
                {"ExtensionNot", ".txt", "Parent", "*e*"}, logical([0, 0, 0, 1])
                };

            for test = tests'
                [args, expectedIndices] = test{:};

                % Test 'where'
                expected = files(expectedIndices);
                actual = files.where(args{:});
                obj.assertEqual(actual, expected);

                % Test 'is'
                expected = expectedIndices;
                actual = files.is(args{:});
                obj.assertEqual(actual, expected);

            end

            % Test Folder and empty 
            obj.assertEqual(Path.empty.where("Name", "*"), Path.empty)
            obj.assertEqual(Path(["a/b", "c/d"]).where("Name", "*b*"), Path("a/b"))

            obj.assertEqual(Path.empty.is("Name", "*"), logical.empty(1, 0))
            obj.assertEqual(Path(["a/b", "c/d"]).is("Name", "*b*"), [true, false])
        end

        %% Absolute/Relative
        function absolute(obj)
            obj.assertEqual(...
                Path("a.b", obj.testRoot + "/c/d.e").absolute, ...
                [Path.pwd / "a.b", Path(obj.testRoot + "/c/d.e")] ...
            );
            obj.assertEqual(...
                Path("a.b", obj.testRoot + "/c/d.e").absolute(obj.testRoot + "\x\y"), ...
                [Path(obj.testRoot + "\x\y\a.b"), Path(obj.testRoot + "/c/d.e")] ...
            );

            obj.assertEqual(...
                Path("a.b").absolute("x\y"), ...
                Path.pwd / "x\y\a.b" ...
            );

            obj.assertEqual(Path(obj.testRoot).absolute, Path(obj.testRoot));
            obj.assertEqual(Path.empty.absolute, Path.empty);
        end

        function relative(obj)
            referencePath = Path(obj.testRoot + "/a/b/c");
            file1 = Path(obj.testRoot + "/a/d/e.f");
            obj.assertEqual(file1.relative(referencePath), Path("..\..\d\e.f"));

            folder1 = Path(obj.testRoot);
            obj.assertEqual(folder1.relative(referencePath), Path("..\..\.."));

            obj.assertEqual(referencePath.relative(referencePath), Path("."));

            obj.assertEqual(Path.empty.relative(referencePath), Path.empty);

            file2 = Path(obj.testRoot2 + "/a.b");
            obj.assertError(@() file2.relative(referencePath), "Path:relative:RootsDiffer");

            folder2 = Path("a/b");
            obj.assertEqual(folder2.relative, folder2.relative(pwd));

            file3 = Path("a.b");
            referenceFolder2 = Path("b/c").absolute;
            obj.assertEqual(file3.relative(referenceFolder2), Path("..\..\a.b"));

            obj.assertError2(@() file3.relative([Path, Path]), ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);

            obj.assertEqual(file3.relative("."), file3);
            obj.assertEqual(Path("a.b", "c/d").relative, Path("a.b", "c/d"));
        end

        %% Array
        function isEmpty(obj)
            obj.assertFalse(Path("a", "b").isEmpty)
            obj.assertTrue(Path.empty.isEmpty)
        end

        function count(obj)
            obj.assertEqual(Path("a", "b").count, 2);
        end

        function sort(obj)
            [sortedFiles, indices] = Path("a", "c", "b").sort;
            obj.assertEqual(sortedFiles, Path("a", "b", "c"));
            obj.assertEqual(indices, [1, 3, 2]);

            [sortedFiles, indices] = Path("a", "c", "b").sort("descend");
            obj.assertEqual(sortedFiles, Path("c", "b", "a"));
            obj.assertEqual(indices, [2, 3, 1]);
        end

        function unique(obj)
            obj.assertEqual(Path("a", "b", "a").unique_, Path("a", "b"));
            obj.assertEqual(Path.empty.unique_, Path.empty);
        end

        function deal(obj)
            files = Path("a.b", "c.d");
            [file1, file2] = files.deal;
            obj.assertEqual(file1, files(1));
            obj.assertEqual(file2, files(2));

            obj.assertError(@testFun, "Path:deal:InvalidNumberOfOutputs");
            function testFun
                [file1, file2, file3] = files.deal;
            end
        end

        function vertcat_(obj)
            actual = [Path("a"); Path("b")];
            expected = Path("a", "b");
            obj.assertEqual(actual, expected);
        end

        function transpose(obj)
            obj.assertError(@() Path("a")', "Path:transpose:NotSupported");
            obj.assertError(@() Path("a").', "Path:transpose:NotSupported");
        end

        function subsasgn_(obj)

            obj.assertError(@() makeColumn, "Path:subsasgn:MultiRowsNotSupported");
            obj.assertError(@() make3dArray, "Path:subsasgn:MultiRowsNotSupported");
            files = Path;
            files(2) = Path;
            files(1, 3) = Path;

            function makeColumn()
                files = Path("a");
                files(2, 1) = Path("b");
            end

            function make3dArray()
                files = Path("a");
                files(1, 1, 1) = Path("b");
            end
        end

        %% Join
        function join(obj)
            obj.assertEqual(Path("one").join(""), Path("one"));
            obj.assertEqual(Path("one").join(["one", "two"]), Path("one/one", "one/two"));
            obj.assertEqual(Path("one", "two").join("one"), Path("one/one", "two/one"));
            obj.assertEmpty(Path.empty.join("one"), Path);
            obj.assertEqual(Path("one").join(strings(0)), Path("one"));
            obj.assertError(@() Path("one", "two", "three").join(["one", "two"]), "Path:join:LengthMismatch");
            obj.assertEqual(Path("a").join("b", 'c', {'d', "e", "f"}), Path("a/b", "a/c", "a/d", "a/e", "a/f"));
            obj.assertEqual(Path("one").join(["one.a", "two.b"]), Path("one/one.a", "one/two.b"));

            [file1, file2] = Path("a").join("b.c", "d.e");
            obj.assertEqual(file1, Path("a/b.c"));
            obj.assertEqual(file2, Path("a/d.e"));

            obj.assertError(@testFun, "Path:deal:InvalidNumberOfOutputs");
            function testFun
                [file1, file2, file3] = Path("a").join("b.c", "d.e");
            end
        end

        function mrdivide(obj)
            obj.assertEqual(Path("one") / "two", Path("one/two"));
            [file1, file2] = Path("a") / ["b.c", "d.e"];
            obj.assertEqual(file1, Path("a/b.c"));
            obj.assertEqual(file2, Path("a/d.e"));

            obj.assertError(@testFun, "Path:deal:InvalidNumberOfOutputs");
            function testFun
                [file1, file2, file3] = Path("a") / ["b.c", "d.e"];
            end
        end

        function mldivide(obj)
            obj.assertEqual(Path("one") \ "two", Path("one/two"));
            [file1, file2] = Path("a") \ ["b.c", "d.e"];
            obj.assertEqual(file1, Path("a/b.c"));
            obj.assertEqual(file2, Path("a/d.e"));

            obj.assertError(@testFun, "Path:deal:InvalidNumberOfOutputs");
            function testFun
                [file1, file2, file3] = Path("a") \ ["b.c", "d.e"];
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
            obj.testFolder.join(["a", "b/a"]).mkdir;
            obj.assertFolderExists(obj.testFolder / ["a", "b/a"]);
        end

        function createEmptyFile(obj)
            obj.testFolder.join("a.b", "c/d.e").createEmptyFile;
            obj.assertFileExists(obj.testFolder / ["a.b", "c/d.e"]);
        end

        function isFileAndIsFolder(obj)
            paths = obj.testFolder / ["a.b", "c/d.e"];
            obj.assertEqual(paths.exists, [false, false]);
            obj.assertEqual(paths.isDir, [false, false]);
            obj.assertEqual(paths.isFile, [false, false]);
            obj.assertError(@() paths.mustExist, "Path:mustExist:Failed");
            obj.assertError(@() paths.mustBeDir, "Path:mustExist:Failed");
            obj.assertError(@() paths.mustBeFile, "Path:mustExist:Failed");

            paths.createEmptyFile;
            obj.assertEqual(paths.exists, [true, true]);
            obj.assertEqual(paths.isFile, [true, true]);
            obj.assertEqual(paths.isDir, [false, false]);
            paths.mustExist;
            paths.mustBeFile;
            obj.assertError(@() paths.mustBeDir, "Path:mustExist:Failed");

            delete(paths(1).string, paths(2).string);
            paths.mkdir;

            obj.assertEqual(paths.exists, [true, true]);
            obj.assertEqual(paths.isDir, [true, true]);
            obj.assertEqual(paths.isFile, [false, false]);
            paths.mustExist;
            paths.mustBeDir
            obj.assertError(@() paths.mustBeFile, "Path:mustExist:Failed");
        end

        function fopen(obj)
            file = obj.testFolder / "a.b";
            file.parent.mkdir;
            [id, errorMessage] = file.fopen("w", "n", "UTF-8");
            obj.assertFalse(id == -1);
            obj.assertEqual(errorMessage, '');
            fclose(id);
            obj.assertError2(@() fopen([file, file]), ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);
        end

        function open(obj)
            file = obj.testFolder / "a.b";
            obj.assertError2(@() open([file, file]), ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);
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

        function listFiles(obj)
            files = obj.testFolder / ["a.b", "c.d", "e/f.g"];
            files.createEmptyFile;
            folders = [obj.testFolder, obj.testFolder];
            obj.assertEqual(folders.listFiles, obj.testFolder / ["a.b", "c.d"]);
            obj.assertError(@() Path("klajsdfoi67w3pi47n").listFiles, "Path:mustExist:Failed");
        end

        function listDeepFiles(obj)
            files = obj.testFolder.join("a.b", "c.d", "e/f/g.h");
            files.createEmptyFile;
            folders = [obj.testFolder, obj.testFolder];
            obj.assertEqual(folders.listDeepFiles, obj.testFolder.join("a.b", "c.d", "e/f/g.h"));
            obj.assertError(@() Path("klajsdfoi67w3pi47n").listDeepFiles, "Path:mustExist:Failed");
            emptyFolder = obj.testFolder.join("empty");
            emptyFolder.mkdir;
            obj.assertEqual(emptyFolder.listDeepFiles, Path.empty);
        end

        function listFolders(obj)
            files = obj.testFolder / ["a.b", "c/d.e", "e/f/g.h", "i/j.k"];
            files.createEmptyFile;
            folders = [obj.testFolder, obj.testFolder];
            obj.assertEqual(folders.listFolders, obj.testFolder / ["c", "e", "i"]);
            obj.assertError(@() Path("klajsdfoi67w3pi47n").listFolders, "Path:mustExist:Failed");
        end

        function listDeepDirs(obj)
            files = obj.testFolder / ["a.b", "c/d.e", "e/f/g.h", "i/j.k"];
            files.createEmptyFile;
            folders = [obj.testFolder, obj.testFolder];
            obj.assertEqual(folders.listDeepDirs, obj.testFolder / ["c", "e", "e/f", "i"]);
            obj.assertError(@() Path("klajsdfoi67w3pi47n").listDeepDirs, "Path:mustExist:Failed");
        end

        function delete_(obj)

            % Delete files
            files = obj.testFolder / ["a.b", "c/d.e", "e/f"];
            files(1:2).createEmptyFile;
            obj.assertTrue(all(files(1:2).isFile));
            files.delete;
            obj.assertFalse(any(files.isFile));

            folders = obj.testFolder / ["a", "b"];
            folders.mkdir;
            folders(1).join("c.d").createEmptyFile;
            obj.assertError(@() folders(1).delete, "MATLAB:RMDIR:NoDirectoriesRemoved");
            folders.delete("s");
            obj.assertFolderDoesNotExist(folders);
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
            oldDir = Path.ofCaller.parent.cd;
            fileInfo(1) = dir("Path.m");
            fileInfo(2) = dir("PathTest.m");
            obj.assertEqual(Path("Path.m", "PathTest.m").bytes, [fileInfo(1).bytes, fileInfo(2).bytes]);
            obj.assertEqual(Path.empty.bytes, zeros(1, 0));
            oldDir.cd;

            obj.testFolder.mkdir;
            obj.assertError(@() obj.testFolder.bytes, "Path:mustExist:Failed");
        end

        function modifiedDate(obj)
            files = obj.testFolder.join("a.b", "c.d");
            files.createEmptyFile;
            content = dir(obj.testFolder.string);
            actual(1) = datetime(content({content.name} == "a.b").datenum, "ConvertFrom", "datenum");
            actual(2) = datetime(content({content.name} == "c.d").datenum, "ConvertFrom", "datenum");
            obj.assertEqual(actual, files.modifiedDate);

            actual = datetime(content({content.name} == ".").datenum, "ConvertFrom", "datenum");
            obj.assertEqual(actual, obj.testFolder.modifiedDate)
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

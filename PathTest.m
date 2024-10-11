classdef PathTest < matlab.unittest.TestCase

    properties (Constant)
        testDir = Path.ofMatlabFile("PathTest").parent / "test";
    end

    methods
        function verifyAllFalse(obj, values)
            obj.verifyFalse(any(values));
        end

        function verifyFileExists(obj, files)
            for file = files
                obj.verifyTrue(isfile(string(file)));
            end
        end

        function verifyFileDoesNotExists(obj, files)
            for file = files
                obj.verifyFalse(isfile(string(file)))
            end
        end

        function verifyDirExists(obj, dirs)
            for dir = dirs
                obj.verifyTrue(isfolder(string(dir)));
            end
        end

        function verifyDirDoesNotExist(obj, dirs)
            for dir = dirs
                obj.verifyFalse(isfolder(string(dir)));
            end
        end

        function verifyError2(obj, func, expected)
            % Version of verifyError which allows expecting one of multiple
            % error IDs.
            actual = "";
            try
                func()
            catch exc
                actual = exc.identifier;
            end
            obj.verifyTrue(ismember(actual, expected));
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
        function removeTestDir(testCase)
            if testCase.testDir.exists
                rmdir(testCase.testDir.string, "s");
            end
        end

        function closeFiles(testCase)
            fclose all;
        end
    end

    methods (Test)

        %% Constructor
        function constructWithStringVector(obj)
            obj.verifyEqual(Path(["one", "two"]).string, ["one", "two"]);
        end

        function constructWithChars(obj)
            obj.verifyEqual(Path("test"), Path('test'))
        end

        function constructWithCharCell(obj)
            actual = Path({'one', 'two'});
            expected = Path(["one", "two"]);
            obj.verifyEqual(actual, expected);
        end

        function constructWithStringCell(obj)
            actual = Path({"one", "two"});
            expected = Path(["one", "two"]);
            obj.verifyEqual(actual, expected);
        end

        function constructWithPathSeparator(obj)
            obj.verifyEqual(Path("one"+pathsep+" two"), Path(["one", "two"]));
            obj.verifyEqual(Path(" "+pathsep+" "), Path([".", "."]));
        end

        function constructDefault(obj)
            obj.verifyEqual(Path().string, ".");
        end

        function constructEmpty(obj)
            obj.verifySize(Path(string.empty), [1, 0]);
            obj.verifySize(Path({}), [1, 0]);
        end

        function constructWithMultipleArguments(obj)
            actual = Path('a', "b"+pathsep+" c", {'d', "e"+pathsep+" f"}, ["g", "h"]);
            expected = Path(["a" "b" "c" "d" "e" "f" "g", "h"]);
            obj.verifyEqual(actual, expected);
        end

        %% Factories
        function ofMatlabFile(obj)
            actual = Path.ofMatlabFile(["mean", "PathTest"]).string;
            expected = string({which("mean") which("PathTest")});
            obj.verifyEqual(actual, expected);
            obj.verifyError(@() Path.ofMatlabFile("npofas&/"), "Path:ofMatlabFile:NotFound");
        end

        function this(obj)

            % Write test function which calls 'Path.this()'.
            code = "function p = testPathThis(varargin);      p = Path.this(varargin{:});";
            testFuncPath = obj.testDir / "testPathThis.m";
            testFuncPath.writeText(code);

            addpath(obj.testDir.string);
            obj.verifyEqual(testPathThis(), testFuncPath);
            obj.verifyEqual(testPathThis(2), Path(which("PathTest.m")));
            rmpath(obj.testDir.string);
        end

        function here(obj)
            obj.verifyEqual(Path.here, Path.this.parent);
            obj.verifyEqual(Path.here(2), Path.this(2).parent);
        end

        function pwd(obj)
            obj.verifyEqual(Path.pwd, Path(pwd));
        end

        function home(obj)
            if ispc
                obj.verifyEqual(Path.home, Path(getenv("USERPROFILE")));
            else
                obj.verifyEqual(Path.home, Path(getenv("HOME")));
            end
        end

        function matlab(obj)
            obj.verifyEqual(Path.matlab, Path(matlabroot));
        end

        function searchPath(obj)
            obj.verifyEqual(Path.searchPath, Path(path));
        end

        function userPath(obj)
            obj.verifyEqual(Path.userPath, Path(userpath));
        end

        function tempFile(obj)
            obj.verifyEqual(Path.tempFile(0), Path.empty)
            files = Path.tempFile(2);
            obj.verifyEqual(files.count, 2);
            obj.verifyEqual(files.parent, Path(tempdir, tempdir));
            obj.verifyNotEqual(files(1).nameString, files(2).nameString);
        end

        function tempDir(obj)
            obj.verifyEqual(Path.tempDir, Path(tempdir));
        end

        %% Conversion
        function string(obj)
            obj.verifyEqual(Path(["one", "two"]).string, ["one", "two"]);
            obj.verifyEqual(Path.empty.string, strings(1, 0));
        end

        function char(obj)
            obj.verifyEqual('test', Path("test").char);
        end

        function cellstr(obj)
            obj.verifyEqual(Path("one").cellstr, {'one'});
            obj.verifyEqual(Path(["one", "two"]).cellstr, {'one', 'two'});
        end

        function quote(obj)
            obj.verifyEqual(Path(["a/b.c", "d.e"]).quote, adjustSeparators(["""a/b.c""", """d.e"""]))
            obj.verifyEqual(Path.empty.quote, strings(1, 0))
        end

        %% Clean
        function clean_stripWhitespace(obj)
            obj.verifyEqual("test", Path(sprintf("\n \ttest  \r")).string);
        end

        function clean_removesRepeatingSeparators(obj)
            s = filesep;
            actual = Path("one" + s + s + s + "two" + s + s + "three").string;
            expected = adjustSeparators("one/two/three");
            obj.verifyEqual(actual, expected);
        end

        function clean_removesOuterSeparators(obj)
            s = filesep;
            actual = Path([s 'one/two/three' s]).string;
            if ispc
                expected = "one\two\three";
            else
                expected = "/one/two/three";
            end
            obj.verifyEqual(actual, expected);
        end

        function clean_removesCurrentDirDots(obj)
            actual = Path("\.\.\one\.\two.three\.\.four\.\.\").string;
            if ispc
                expected = "one\two.three\.four";
            else
                expected = "/one/two.three/.four";
            end
            obj.verifyEqual(actual, expected);
        end

        function clean_replacesSeparatorVariations(obj)
            actual = Path("one/two\three").string;
            expected = adjustSeparators("one/two/three");
            obj.verifyEqual(actual, expected);
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
                obj.verifyEqual(actual, expected);
            end
        end

        %% Name
        function name(obj)
            obj.verifyEqual(Path(obj.testRoot + "/one/two/three.ext").name.string, "three.ext");
            obj.verifyEqual(Path("one.two.three.ext").name.string, "one.two.three.ext");
            obj.verifyEqual(Path("one").name.string, "one");
            obj.verifyEqual(Path("..").name.string, "..");
            obj.verifyEqual(Path(".").name.string, ".");
            obj.verifyEmpty(Path.empty.name);
        end

        function setName(obj)
            files = Path("a.b", "c/d");
            obj.verifyEqual(files.setName("f.g"), Path("f.g", "c/f.g"));
            obj.verifyEqual(files.setName("h.i", "j/k"), Path("h.i", "c/j/k"));
            obj.verifyError(@() files.setName("f", "g", "h"), "Path:join:LengthMismatch");
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
                obj.verifyEqual(testPath{1}.name.string, testPath{1}.nameString);
            end

            obj.verifyEqual(Path.empty.nameString, strings(1, 0));
            obj.verifyEqual(Path("a", "b").nameString, ["a", "b"]);
        end

        %% Extension
        function extension(obj)
            obj.verifyEqual(Path(obj.testRoot + "/one/two/three.ext").extension, ".ext");
            obj.verifyEqual(Path("one.two.three.ext").extension, ".ext");
            obj.verifyEqual(Path("one.").extension, ".");
            obj.verifyEqual(Path("one").extension, "");
            obj.verifyEqual(Path("..").extension, "");
            obj.verifyEqual(Path(".").extension, "");
        end

        function setExtension(obj)
            obj.verifyEqual(Path("a.b", "c.d", "e").setExtension(".f"), Path("a.f", "c.f", "e.f"));
            obj.verifyEqual(Path("a.b", "c.d", "e").setExtension([".f", "", "g"]), Path("a.f", "c", "e.g"));
            obj.verifyEqual(Path.empty.setExtension(".a"), Path.empty);
        end

        %% Stem
        function stem(obj)
            obj.verifyEqual(Path(obj.testRoot + "/one/two/three.ext").stem, "three");
            obj.verifyEqual(Path("one.two.three.ext").stem, "one.two.three");
            obj.verifyEqual(Path("one").stem, "one");
            obj.verifyEqual(Path("..").stem, "..");
            obj.verifyEqual(Path(".").stem, ".");
            obj.verifyEmpty(Path.empty.stem);
            obj.verifyInstanceOf(Path.empty.stem, "string")
        end

        function setStem(obj)
            files = Path("a.b", "c/d");
            obj.verifyEqual(files.setStem("e"), Path("e.b", "c/e"));
            obj.verifyEqual(files.setStem(["f", "g"]), Path("f.b", "c/g"));
            obj.verifyEqual(files.setStem(""), Path(".b", "c"));
            obj.verifyError(@() files.setStem("a/\b"), "Path:Validation:InvalidName");
            obj.verifyError(@() files.setStem(["a", "b", "c"]), "Path:Validation:InvalidSize");
        end

        function addStemSuffix(obj)
            obj.verifyEqual(Path("a/b.c").addStemSuffix("_s"), Path("a/b_s.c"))
            obj.verifyEqual(Path("a/b.c", "d/e").addStemSuffix("_s"), Path("a/b_s.c", "d/e_s"));
            obj.verifyEqual(Path("a/b.c", "d/e").addStemSuffix(["_s1", "_s2"]), Path("a/b_s1.c", "d/e_s2"));
            obj.verifyEqual(Path("a/b.c").addStemSuffix(""), Path("a/b.c"))
            obj.verifyEqual(Path.empty.addStemSuffix("s"), Path.empty);
            obj.verifyError(@() Path("a/b.c", "d/e").addStemSuffix(["_s1", "_s2", "_s3"]), "Path:Validation:InvalidSize");
            obj.verifyError(@() Path("a/b.c", "d/e").addStemSuffix("/"), "Path:Validation:InvalidName");
        end

        %% Parent
        function parent(obj)
            obj.verifyEqual(Path(obj.testRoot + "/one/two/three.ext").parent, Path(obj.testRoot + "/one/two"));
            obj.verifyEqual(Path("../../one/three.ext").parent, Path("../../one"));
            obj.verifyEqual(Path("one").parent, Path("."));
            obj.verifyEqual(Path("..").parent, Path("."));
            obj.verifyEqual(Path(".").parent, Path("."));
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
                obj.verifyEqual(testPath{1}.parent.string, testPath{1}.parentString);
            end

            obj.verifyEqual(Path.empty.parentString, strings(1, 0));
            obj.verifyEqual(Path("a/b", "c/d").parentString, ["a", "c"]);
        end

        function setParent(obj)
            files = Path("a.b", "c/d", "e/f/g");
            obj.verifyEqual(files.setParent("h"), Path("h/a.b", "h/d", "h/g"))
        end

        function hasParent(obj)
            obj.verifyEqual(Path("a/b/c", obj.testRoot + "/d/e", "hello.txt").hasParent, [true, true, false]);
            obj.verifyEqual(Path.empty.hasParent(), logical.empty(1, 0));
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
                obj.verifyEqual(actual, expected);
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
                obj.verifyEqual(path.root.string, path.rootString);
            end
        end

        function setRoot(obj)
            obj.verifyEqual(Path(obj.testRoot + "/a/b.c", "e/f.g").setRoot(obj.testRoot2), Path(obj.testRoot2 + "/a/b.c", obj.testRoot2 + "/e/f.g"));
            obj.verifyEqual(Path.empty.setRoot(obj.testRoot), Path.empty);
            obj.verifyEqual(Path(obj.testRoot + "/a/b").setRoot("../c/d"), Path("../c/d/a/b"));
            obj.verifyError(@() Path("a").setRoot(pathsep), "Path:Validation:ContainsPathsep");
        end

        %% Regex
        function regexprep(obj)
            testPaths = {strings(0), "a.b", ["test01\two.txt", "1\2\3.x"]};
            expression = {'\w', '\d\d'};
            replace = {'letter', 'numbers'};
            for testPath = testPaths
                expected = Path(regexprep(testPath{1}, expression, replace));
                actual = Path(testPath{1}).regexprep(expression, replace);
                obj.verifyEqual(actual, expected);
            end
        end

        %% Properties
        function isRelative(obj)
            obj.verifyTrue(all(Path(".", "..", "a/b.c", "../../a/b/c").isRelative));
            obj.verifyFalse(any(Path(obj.testRoot+"\", obj.testRoot+"\a\b.c", "\\test\", "\\test\a\b").isRelative));
        end

        function isAbsolute(obj)
            obj.verifyFalse(any(Path(".", "..", "a/b.c", "../../a/b/c").isAbsolute));
            obj.verifyTrue(any(Path(obj.testRoot+"\", obj.testRoot+"\a\b.c", "\\test\", "\\test\a\b").isAbsolute));
        end

        function equalAndNotEqual(obj)
            files = Path("one/two", "a\b.c", "three/four", "a\b.c");
            obj.verifyEqual(files(1:2) == files(3:4), [false, true]);
            obj.verifyEqual(files(1:2) ~= files(3:4), [true, false]);
            obj.verifyEqual(files(2) == files(3:4), [false, true]);
            obj.verifyEqual(files(3:4) ~= files(2), [true, false]);
            obj.verifyTrue(Path("one/two") == Path("one/two"));
        end

        function parts(obj)
            testRootWithoutLeadingSeparator = regexprep(obj.testRoot, "^" + regexptranslate("escape", filesep), "");
            obj.verifyEqual(Path(obj.testRoot + "/a/b\\c.e\").parts, [testRootWithoutLeadingSeparator, "a", "b", "c.e"]);
            obj.verifyEqual(Path(".\..\/\../a/b\\c.e\").parts, ["..", "..", "a", "b", "c.e"]);
            obj.verifyEqual(Path().parts, ".");

            obj.verifyError2(@() Path.empty.parts, ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);
            obj.verifyError2(@() Path("a", "b").parts, ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);
        end

        function strlength(obj)
            obj.verifyEqual(Path("a/b.c", "d.e").strlength, [5, 3])
            obj.verifyEmpty(Path.empty.strlength)
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
                obj.verifyEqual(actual, expected);

                % Test 'is'
                actual = files.is(args{:});
                expected = ~isempty(indices);
                obj.verifyEqual(actual, expected);
            end
        end

        function where_and_is2(obj)

            files = Path([ ...
                obj.testRoot + "/on.e/t=wo.ab.txt"
                "=.23f/asdf.%43"
                "..\..\p"
                "dir\file"
                ] ...
                );

            tests = {
                {"Parent", "*i*", "RootNot", obj.testRoot, "Name", ["file", "t=wo.ab.txt"]}, logical([0, 0, 0, 1])
                {"NameNot", "*f*", "Name", ["p", "file"]}, logical([0, 0, 1, 0])
                {"Root", [".", obj.testRoot]}, logical([1, 1, 1, 1])
                {"ParentNot", "*"}, logical([0, 0, 0, 0])
                {"ExtensionNot", ".txt", "Parent", "*i*"}, logical([0, 0, 0, 1])
                };

            for test = tests'
                [args, expectedIndices] = test{:};

                % Test 'where'
                expected = files(expectedIndices);
                actual = files.where(args{:});
                obj.verifyEqual(actual, expected);

                % Test 'is'
                expected = expectedIndices;
                actual = files.is(args{:});
                obj.verifyEqual(actual, expected);

            end

            % Test dirs and empty
            obj.verifyEqual(Path.empty.where("Name", "*"), Path.empty)
            obj.verifyEqual(Path(["a/b", "c/d"]).where("Name", "*b*"), Path("a/b"))

            obj.verifyEqual(Path.empty.is("Name", "*"), logical.empty(1, 0))
            obj.verifyEqual(Path(["a/b", "c/d"]).is("Name", "*b*"), [true, false])
        end

        %% Absolute/Relative
        function absolute(obj)
            obj.verifyEqual(...
                Path("a.b", obj.testRoot + "/c/d.e").absolute, ...
                [Path.pwd / "a.b", Path(obj.testRoot + "/c/d.e")] ...
                );
            obj.verifyEqual(...
                Path("a.b", obj.testRoot + "/c/d.e").absolute(obj.testRoot + "\x\y"), ...
                [Path(obj.testRoot + "\x\y\a.b"), Path(obj.testRoot + "/c/d.e")] ...
                );

            obj.verifyEqual(...
                Path("a.b").absolute("x\y"), ...
                Path.pwd / "x\y\a.b" ...
                );

            obj.verifyEqual(Path(obj.testRoot).absolute, Path(obj.testRoot));
            obj.verifyEqual(Path.empty.absolute, Path.empty);
        end

        function relative(obj)
            referencePath = Path(obj.testRoot + "/a/b/c");
            file1 = Path(obj.testRoot + "/a/d/e.f");
            obj.verifyEqual(file1.relative(referencePath), Path("..\..\d\e.f"));

            dir1 = Path(obj.testRoot);
            obj.verifyEqual(dir1.relative(referencePath), Path("..\..\.."));

            obj.verifyEqual(referencePath.relative(referencePath), Path("."));

            obj.verifyEqual(Path.empty.relative(referencePath), Path.empty);

            file2 = Path(obj.testRoot2 + "/a.b");
            obj.verifyError(@() file2.relative(referencePath), "Path:relative:RootsDiffer");

            dir2 = Path("a/b");
            obj.verifyEqual(dir2.relative, dir2.relative(pwd));

            file3 = Path("a.b");
            referenceDir2 = Path("b/c").absolute;
            obj.verifyEqual(file3.relative(referenceDir2), Path("..\..\a.b"));

            obj.verifyError2(@() file3.relative([Path, Path]), ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);

            obj.verifyEqual(file3.relative("."), file3);
            obj.verifyEqual(Path("a.b", "c/d").relative, Path("a.b", "c/d"));
        end

        %% Array
        function isEmpty(obj)
            obj.verifyFalse(Path("a", "b").isEmpty)
            obj.verifyTrue(Path.empty.isEmpty)
        end

        function count(obj)
            obj.verifyEqual(Path("a", "b").count, 2);
        end

        function sort(obj)
            [sortedFiles, indices] = Path("a", "c", "b").sort;
            obj.verifyEqual(sortedFiles, Path("a", "b", "c"));
            obj.verifyEqual(indices, [1, 3, 2]);

            [sortedFiles, indices] = Path("a", "c", "b").sort("descend");
            obj.verifyEqual(sortedFiles, Path("c", "b", "a"));
            obj.verifyEqual(indices, [2, 3, 1]);
        end

        function unique(obj)
            obj.verifyEqual(Path("a", "b", "a").unique_, Path("a", "b"));
            obj.verifyEqual(Path.empty.unique_, Path.empty);
        end

        function deal(obj)
            files = Path("a.b", "c.d");
            [file1, file2] = files.deal;
            obj.verifyEqual(file1, files(1));
            obj.verifyEqual(file2, files(2));

            obj.verifyError(@testFun, "Path:deal:InvalidNumberOfOutputs");
            function testFun
                [file1, file2, file3] = files.deal;
            end
        end

        function vertcat_(obj)
            actual = [Path("a"); Path("b")];
            expected = Path("a", "b");
            obj.verifyEqual(actual, expected);
        end

        function transpose(obj)
            obj.verifyError(@() Path("a")', "Path:transpose:NotSupported");
            obj.verifyError(@() Path("a").', "Path:transpose:NotSupported");
        end

        function subsasgn_(obj)

            obj.verifyError(@() makeColumn, "Path:subsasgn:MultiRowsNotSupported");
            obj.verifyError(@() make3dArray, "Path:subsasgn:MultiRowsNotSupported");
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
            obj.verifyEqual(Path("one").join(""), Path("one"));
            obj.verifyEqual(Path("one").join(["one", "two"]), Path("one/one", "one/two"));
            obj.verifyEqual(Path("one", "two").join("one"), Path("one/one", "two/one"));
            obj.verifyEmpty(Path.empty.join("one"), Path);
            obj.verifyEqual(Path("one").join(strings(0)), Path("one"));
            obj.verifyError(@() Path("one", "two", "three").join(["one", "two"]), "Path:join:LengthMismatch");
            obj.verifyEqual(Path("a").join("b", 'c', {'d', "e", "f"}), Path("a/b", "a/c", "a/d", "a/e", "a/f"));
            obj.verifyEqual(Path("one").join(["one.a", "two.b"]), Path("one/one.a", "one/two.b"));

            [file1, file2] = Path("a").join("b.c", "d.e");
            obj.verifyEqual(file1, Path("a/b.c"));
            obj.verifyEqual(file2, Path("a/d.e"));

            obj.verifyError(@testFun, "Path:deal:InvalidNumberOfOutputs");
            function testFun
                [file1, file2, file3] = Path("a").join("b.c", "d.e");
            end
        end

        function mrdivide(obj)
            obj.verifyEqual(Path("one") / "two", Path("one/two"));
            [file1, file2] = Path("a") / ["b.c", "d.e"];
            obj.verifyEqual(file1, Path("a/b.c"));
            obj.verifyEqual(file2, Path("a/d.e"));

            obj.verifyError(@testFun, "Path:deal:InvalidNumberOfOutputs");
            function testFun
                [file1, file2, file3] = Path("a") / ["b.c", "d.e"];
            end
        end

        function mldivide(obj)
            obj.verifyEqual(Path("one") \ "two", Path("one/two"));
            [file1, file2] = Path("a") \ ["b.c", "d.e"];
            obj.verifyEqual(file1, Path("a/b.c"));
            obj.verifyEqual(file2, Path("a/d.e"));

            obj.verifyError(@testFun, "Path:deal:InvalidNumberOfOutputs");
            function testFun
                [file1, file2, file3] = Path("a") \ ["b.c", "d.e"];
            end
        end

        function addSuffix(obj)
            obj.verifyEqual(Path("a/b.c").addSuffix("_s"), Path("a/b.c_s"))
            obj.verifyEqual(Path("a/b.c", "d/e").addSuffix("_s"), Path("a/b.c_s", "d/e_s"));
            obj.verifyEqual(Path("a/b.c", "d/e").addSuffix(["d\e.f", "g\h\i.j"]), Path("a/b.cd\e.f", "d/eg\h\i.j"));
            obj.verifyEqual(Path.empty.addSuffix("s"), Path.empty);
            obj.verifyError(@() Path("a/b.c", "d/e").addSuffix(["_s1", "_s2", "_s3"]), "Path:Validation:InvalidSize");
        end

        function plus_left(obj)
            obj.verifyEqual(Path("a/b.c") + "_s", Path("a/b.c_s"))
            obj.verifyEqual(Path("a/b.c", "d/e") + "_s", Path("a/b.c_s", "d/e_s"));
            obj.verifyEqual(Path("a/b.c", "d/e") + ["d\e.f", "g\h\i.j"], Path("a/b.cd\e.f", "d/eg\h\i.j"));
            obj.verifyEqual(Path.empty + "s", Path.empty);
            obj.verifyError(@() Path("a/b.c", "d/e") + ["_s1", "_s2", "_s3"], "Path:Validation:InvalidSize");
        end

        function plus_right(obj)
            obj.verifyEqual("a/b.c" + Path("_s"), Path("a/b.c_s"))
            obj.verifyEqual(["a/b.c", "d/e"] + Path("_s"), Path("a/b.c_s", "d/e_s"));
            obj.verifyEqual(["a/b.c", "d/e"] + Path(["d\e.f", "g\h\i.j"]), Path("a/b.cd\e.f", "d/eg\h\i.j"));
            obj.verifyEqual(strings(0) + Path("s"), Path.empty);
            obj.verifyError(@() ["a/b.c", "d/e"] + Path(["_s1", "_s2", "_s3"]), "Path:Validation:InvalidSize");
        end

        function tempFileName(obj)
            obj.verifyEqual(Path("a").tempFileName(0), Path.empty);
            files = Path("a").tempFileName(2);
            obj.verifyLength(files, 2);
            obj.verifyNotEqual(files(1), files(2));
            obj.verifyEqual(files(1).parent, Path("a"));
        end

        %% File system interaction
        function cd(obj)
            obj.testDir.mkdir;
            actual = pwd;
            expected = obj.testDir.cd.char;
            obj.verifyEqual(actual, expected);
            obj.verifyEqual(pwd, obj.testDir.char);
            cd(actual);
        end

        function mkdir(obj)
            obj.testDir.join(["a", "b/a"]).mkdir;
            obj.verifyDirExists(obj.testDir / ["a", "b/a"]);
        end

        function createEmptyFile(obj)
            obj.testDir.join("a.b", "c/d.e").createEmptyFile;
            obj.verifyFileExists(obj.testDir / ["a.b", "c/d.e"]);
        end

        function isFileAndIsDir(obj)
            paths = obj.testDir / ["a.b", "c/d.e"];
            obj.verifyEqual(paths.exists, [false, false]);
            obj.verifyEqual(paths.isDir, [false, false]);
            obj.verifyEqual(paths.isFile, [false, false]);
            obj.verifyError(@() paths.mustExist, "Path:NotFound");
            obj.verifyError(@() paths.mustBeDir, "Path:NotFound");
            obj.verifyError(@() paths.mustBeFile, "Path:NotFound");

            paths.createEmptyFile;
            obj.verifyEqual(paths.exists, [true, true]);
            obj.verifyEqual(paths.isFile, [true, true]);
            obj.verifyEqual(paths.isDir, [false, false]);
            paths.mustExist;
            paths.mustBeFile;
            obj.verifyError(@() paths.mustBeDir, "Path:NotADir");

            delete(paths(1).string, paths(2).string);
            paths.mkdir;

            obj.verifyEqual(paths.exists, [true, true]);
            obj.verifyEqual(paths.isDir, [true, true]);
            obj.verifyEqual(paths.isFile, [false, false]);
            paths.mustExist;
            paths.mustBeDir
            obj.verifyError(@() paths.mustBeFile, "Path:NotAFile");
        end

        function fopen(obj)
            file = obj.testDir / "a.b";
            file.parent.mkdir;
            [id, errorMessage] = file.fopen("w", "n", "UTF-8");
            obj.verifyFalse(id == -1);
            obj.verifyEqual(errorMessage, '');
            fclose(id);
            obj.verifyError2(@() fopen([file, file]), ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);
        end

        function open(obj)
            file = obj.testDir / "a.b";
            obj.verifyError2(@() open([file, file]), ["MATLAB:validation:IncompatibleSize", "MATLAB:functionValidation:NotScalar"]);
            obj.verifyError(@() file.open, "Path:NotFound");
            id = file.open("w");
            obj.verifyFalse(id == -1);
            fclose(id);

            % Assert that auto clean closes the file.
            id = openWithCleaner(file);
            obj.verifyFalse(id == -1);
            obj.verifyError(@() fclose(id), "MATLAB:badfid_mx");

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
            files = obj.testDir / ["a.b", "c.d", "e/f.g"];
            files.createEmptyFile;
            dirs = [obj.testDir, obj.testDir];
            obj.verifyEqual(dirs.listFiles, obj.testDir / ["a.b", "c.d"]);
            obj.verifyError(@() Path("klajsdfoi67w3pi47n").listFiles, "Path:NotFound");
        end

        function listDeepFiles(obj)
            files = obj.testDir.join("a.b", "c.d", "e/f/g.h");
            files.createEmptyFile;
            dirs = [obj.testDir, obj.testDir];
            obj.verifyEqual(dirs.listDeepFiles, obj.testDir.join("a.b", "c.d", "e/f/g.h"));
            obj.verifyError(@() Path("klajsdfoi67w3pi47n").listDeepFiles, "Path:NotFound");
            emptyDir = obj.testDir.join("empty");
            emptyDir.mkdir;
            obj.verifyEqual(emptyDir.listDeepFiles, Path.empty);
        end

        function listDirs(obj)
            files = obj.testDir / ["a.b", "c/d.e", "e/f/g.h", "i/j.k"];
            files.createEmptyFile;
            dirs = [obj.testDir, obj.testDir];
            obj.verifyEqual(dirs.listDirs, obj.testDir / ["c", "e", "i"]);
            obj.verifyError(@() Path("klajsdfoi67w3pi47n").listDirs, "Path:NotFound");
        end

        function listDeepDirs(obj)
            files = obj.testDir / ["a.b", "c/d.e", "e/f/g.h", "i/j.k"];
            files.createEmptyFile;
            dirs = [obj.testDir, obj.testDir];
            obj.verifyEqual(dirs.listDeepDirs, obj.testDir / ["c", "e", "e/f", "i"]);
            obj.verifyError(@() Path("klajsdfoi67w3pi47n").listDeepDirs, "Path:NotFound");
        end

        function delete_(obj)

            % Delete files
            files = obj.testDir / ["a.b", "c/d.e", "e/f"];
            files(1:2).createEmptyFile;
            obj.verifyTrue(all(files(1:2).isFile));
            files.delete;
            obj.verifyFalse(any(files.isFile));

            dirs = obj.testDir / ["a", "b"];
            dirs.mkdir;
            dirs(1).join("c.d").createEmptyFile;
            obj.verifyError(@() dirs(1).delete, "MATLAB:RMDIR:NoDirectoriesRemoved");
            dirs.delete("s");
            obj.verifyDirDoesNotExist(dirs);
        end

        function readText(obj)
            expected = sprintf("line1\nline2\n");
            file = obj.testDir / "a.txt";
            fileId = file.openForWritingText;
            fprintf(fileId, "%s", expected);
            fclose(fileId);
            actual = file.readText;
            obj.verifyEqual(actual, expected);
        end

        function writeText(obj)
            expected = sprintf("line1\nline2\n");
            file = obj.testDir / "a.txt";
            file.writeText(expected);
            actual = string(fileread(file.string));
            actual = actual.replace(sprintf("\r\n"), newline);
            obj.verifyEqual(actual, expected);
        end

        function bytes(obj)
            testFiles = obj.testDir / ["f1.txt", "f2.txt"];
            testFiles(1).writeText("asdf");
            testFiles(2).writeText("asdfasdfasdf");
            actual = testFiles.bytes;
            expected = arrayfun(@(testFile) dir(testFile.string).bytes, testFiles);
            obj.verifyEqual(actual, expected);

            obj.verifyEqual(Path.empty.bytes, zeros(1, 0));
            obj.verifyError(@() obj.testDir.bytes, "Path:NotAFile");
        end

        function modifiedDate(obj)
            files = obj.testDir.join("a.b", "c.d");
            files.createEmptyFile;
            content = dir(obj.testDir.string);
            actual(1) = datetime(content({content.name} == "a.b").datenum, "ConvertFrom", "datenum");
            actual(2) = datetime(content({content.name} == "c.d").datenum, "ConvertFrom", "datenum");
            obj.verifyEqual(actual, files.modifiedDate);

            actual = datetime(content({content.name} == ".").datenum, "ConvertFrom", "datenum");
            obj.verifyEqual(actual, obj.testDir.modifiedDate)
        end

        %% Copy and move
        function copy_n_to_n(obj)
            sourceFiles = obj.testDir / ["a.b", "c/d.e"];
            sourceDirs = obj.testDir / ["f", "g"];
            targets = obj.testDir / ["f.g", "h/i.j", "k", "l/m"];

            files = obj.testDir / ["f/b.c", "g/e/f.h"];
            files.createEmptyFile;
            sourceFiles.createEmptyFile;

            sources = [sourceFiles, sourceDirs];
            sources.copy(targets);

            expectedNewFiles = obj.testDir / ["k/b.c", "l/m/e/f.h"];
            expectedNewFiles.mustBeFile;
            targets(1:2).mustBeFile;
            targets(3:4).mustBeDir;
            sourceFiles.mustBeFile;
            sourceDirs.mustBeDir;
        end

        function copy_File_1_to_n(obj)
            source = obj.testDir / "k.l";
            targets = obj.testDir / ["m.n", "o/p.q"];

            source.createEmptyFile;
            source.copy(targets);

            source.mustBeFile;
            targets.mustBeFile;
        end

        function copy_Dir_1_to_n(obj)
            files = obj.testDir / "a/b.c";
            files.createEmptyFile;

            sources = obj.testDir / "a";
            targets = obj.testDir / ["i", "j/k"];

            sources.copy(targets);

            targets.mustBeDir;
            newFiles = obj.testDir / ["i/b.c", "j/k/b.c"];
            newFiles.mustBeFile;
            sources.mustBeDir;
        end

        function copy_n_to_1(obj)
            sources = obj.testDir / ["a.b", "c/d.e"];
            targets = obj.testDir / "f.g";

            obj.verifyError2(@() sources.copy(targets), "Path:copyOrMove:InvalidNumberOfTargets")
        end

        function copyToDir_n_to_1(obj)
            sources = obj.testDir / ["a.b", "c/d.e", "f/g"];
            obj.testDir.join("f/g/h/i.j").createEmptyFile;
            sources(1:2).createEmptyFile;
            sources(3).mkdir;
            target = obj.testDir / "target";

            sources.copyToDir(target);

            target.join(sources(1:2).name).mustBeFile;
            target.join(sources(3).name).mustBeDir;
            target.join("g/h/i.j").mustBeFile;
            sources.mustExist;
        end

        function copyToDir_File_1_to_n(obj)
            source = obj.testDir / "a.b";
            targets = obj.testDir / ["t1", "t2"];
            source.createEmptyFile;

            source.copyToDir(targets);

            targets.join(source.name).mustBeFile;
            source.mustBeFile;
        end

        function copyToDir_Dir_1_to_n(obj)
            source = obj.testDir / "a";
            source.join("b/d.c").createEmptyFile;
            targets = obj.testDir / ["t1", "t2"];

            source.copyToDir(targets);

            targets.join("a/b/d.c").mustBeFile;
            source.mustExist;
        end

        function copyToDir_n_to_n(obj)
            sources = obj.testDir / ["a.b", "c/d.e", "f/g"];
            obj.testDir.join("f/g/h/i.j").createEmptyFile;
            sources(1:2).createEmptyFile;
            sources(3).mkdir;

            targets = obj.testDir / ["t1", "t2", "t3"];

            sources.copyToDir(targets);
            targets(1:2).join(sources(1:2).name).mustBeFile;
            targets(3).join("g/h/i.j").mustBeFile;
            sources.mustExist;
        end

        function move_n_to_n(obj)
            sources = obj.testDir / ["a", "d/e.f"];
            targets = obj.testDir / ["f", "h/i.j"];
            sources(2).createEmptyFile;
            sources(1).join("b.c").createEmptyFile;

            sources.move(targets);
            targets(1).join("b.c").mustBeFile;
            targets(2).mustBeFile;
            obj.verifyAllFalse(sources.exists);
        end

        function move_1_to_n(obj)
            source = obj.testDir / "a.b";
            targets = obj.testDir / ["f.g", "h/i.j"];
            obj.verifyError2(@() source.move(targets), "Path:copyOrMove:InvalidNumberOfTargets")
        end

        function move_n_to_1(obj)
            source = obj.testDir / ["a.b", "c.d"];
            targets = obj.testDir / "e.g";
            obj.verifyError2(@() source.move(targets), "Path:copyOrMove:InvalidNumberOfTargets")
        end

        function moveToDir_n_to_1(obj)
            sources = obj.testDir / ["a.b", "c"];
            target = obj.testDir / "t";
            sources(1).createEmptyFile;
            sources(2).join("d.e").createEmptyFile;

            sources.moveToDir(target);

            target.join(sources(1).name).mustBeFile;
            target.join("c/d.e").mustBeFile
            obj.verifyAllFalse(sources.exists);

            Path.empty.moveToDir(target);
        end

        function moveToDir_n_to_n(obj)
            sources = obj.testDir / ["a.b", "c"];
            targets = obj.testDir / ["t", "t2"];
            sources(1).createEmptyFile;
            sources(2).join("d.e").createEmptyFile;

            sources.moveToDir(targets);

            targets(1).join(sources(1).name).mustBeFile;
            targets(2).join("c/d.e").mustBeFile;
            obj.verifyAllFalse(sources.exists);
        end

        function moveToDir_1_to_n(obj)
            source = obj.testDir / "a.b";
            targets = obj.testDir / ["t1", "t2"];
            obj.verifyError2(@() source.moveToDir(targets), "Path:copyOrMove:InvalidNumberOfTargets")
        end

        %% Save and load
        function save(obj)
            a = 1;
            b = "test";
            file = obj.testDir / "data.mat";
            file.save("a", "b");
            clearvars("a", "b");
            load(file.string, "a", "b");
            obj.verifyEqual(a, 1);
            obj.verifyEqual(b, "test");
        end

        function load(obj)
            a = 1;
            b = "test";
            file = obj.testDir / "data.mat";
            obj.testDir.mkdir;
            save(file.string, "a", "b");
            clearvars("a", "b");
            [a, b] = file.load("a", "b");
            obj.verifyEqual(a, 1);
            obj.verifyEqual(b, "test");

            raisedError = false;
            try
                a = file.load("a", "b");
            catch exception
                obj.verifyEqual(string(exception.identifier), "Path:load:InputOutputMismatch");
                raisedError = true;
            end
            obj.verifyTrue(raisedError);
            raisedError = false;
            warning("off", "MATLAB:load:variableNotFound");
            try
                c = file.load("c");
            catch exception
                obj.verifyEqual(string(exception.identifier), "Path:load:VariableNotFound");
                raisedError = true;
            end
            warning("on", "MATLAB:load:variableNotFound");
            obj.verifyTrue(raisedError);
        end

    end
end

function s = adjustSeparators(s)
    s = s.replace(["/", "\"], filesep);
end

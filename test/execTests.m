function result = execTests(tests)
% EXECTESTS runs all of the tests for StateSpace. 
% Pass a cell array of strings containing the shortcuts to run subsets of
% the tests. Subsets include 'mex', 'gradient', and 'ml'.

% David Kelley, 2016 

defaultTests = {'basic', 'mex', 'Accumulator', 'gradient', 'ThetaMap', 'ml'};
if nargin == 0
  tests = defaultTests;
end

baseDir = fileparts(fileparts(mfilename('fullpath')));
srcDir = fullfile(baseDir, 'src');
addpath(srcDir);

import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import matlab.unittest.plugins.CodeCoveragePlugin

%% Run tests
testDir = fullfile(baseDir, 'test');

basicTests = TestSuite.fromFile(fullfile(testDir, 'AbstractSystem_test.m'));
mexTests = [TestSuite.fromFile(fullfile(testDir, 'mex_univariate_test.m')), ...
            TestSuite.fromFile(fullfile(testDir, 'mex_multivariate_test.m'))];
accumulatorTests = [TestSuite.fromFile(fullfile(testDir, 'Accumulator_test.m')), ...
                    TestSuite.fromFile(fullfile(testDir, 'Accumulator_IntegrationTest.m'))];
gradientTests = TestSuite.fromFile(fullfile(testDir, 'gradient_test.m'));
thetaMapTests = TestSuite.fromFile(fullfile(testDir, 'ThetaMap_test.m'));
mlTests = TestSuite.fromFile(fullfile(testDir, 'estimate_test.m'));
          
alltests = {basicTests mexTests accumulatorTests gradientTests thetaMapTests mlTests};
selectedTests = alltests(ismember(defaultTests, tests));
suite = [selectedTests{:}];

runner = TestRunner.withTextOutput;
runner.addPlugin(CodeCoveragePlugin.forFolder(srcDir));
result = runner.run(suite);

display(result);
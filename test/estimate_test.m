% Test univariate mex filter with an AR model.
% Assumes that the Matlab version of the univariate filter/smoother are
% correct.

% David Kelley, 2016

classdef estimate_test < matlab.unittest.TestCase
  
  properties
    data = struct;
  end
  
  methods(TestClassSetup)
    function setupOnce(testCase)
      % Load data
      baseDir = fileparts(fileparts(mfilename('fullpath')));
      addpath(baseDir);
      addpath(fullfile(baseDir, 'examples'));

      data_load = load(fullfile(baseDir, 'examples', 'data', 'dk.mat'));
      testCase.data.nile = data_load.nile;
    end
  end
  
  methods(TestClassTeardown)
    function closeFigs(testCase) %#ok<MANU>
      close all;
    end
  end
  
  methods (Test)
    function testNile(testCase)
      nile = testCase.data.nile';
      
      Z = 1;
      H = nan;
      T = 1;
      Q = nan;
      
      ss = StateSpaceEstimation(Z, H, T, Q);
      
      H0 = 1000;
      P0 = 1000;
      ss0 = StateSpace(Z, H0, T, P0);
      
      ssE = ss.estimate(nile, ss0);
      
      % Using values from Dubrin & Koopman (2012), p. 37
      testCase.verifyEqual(ssE.H, 15099, 'RelTol', 1e-2);
      testCase.verifyEqual(ssE.Q, 1469.1, 'RelTol', 1e-2);
    end
    
    function testNile_noInit(testCase)
      nile = testCase.data.nile';
      
      Z = 1;
      H = nan;
      T = 1;
      Q = nan;
      
      ss = StateSpaceEstimation(Z, H, T, Q);
      ssE = ss.estimate(nile);
      
      % Using values from Dubrin & Koopman (2012), p. 37
      testCase.verifyEqual(ssE.H, 15099, 'RelTol', 1e-2);
      testCase.verifyEqual(ssE.Q, 1469.1, 'RelTol', 1e-2);
    end
    
    function testNileKappa(testCase)
      nile = testCase.data.nile';
      
      Z = 1;
      H = nan;
      T = 1;
      Q = nan;
      
      ss = StateSpaceEstimation(Z, H, T, Q);
      ss.a0 = 0;
      ss.P0 = 1e6;
      
      H0 = 1000;
      P0 = 1000;
      ss0 = StateSpace(Z, H0, T, P0);
      ss0.a0 = 0;
      ss0.P0 = 1e6;
      
      ssE = ss.estimate(nile, ss0);
      
      % Using values from Dubrin & Koopman (2012), p. 37
      testCase.verifyEqual(ssE.H, 15099, 'RelTol', 1e-2);
      testCase.verifyEqual(ssE.Q, 1469.1, 'RelTol', 1e-2);
    end
    
    function testMatlab(testCase)
      % Test against Matlab's native implementation of state space models
      nile = testCase.data.nile;
      
      Z = 1;
      H = nan;
      T = 1;
      Q = nan;
      
      ss = StateSpaceEstimation(Z, H, T, Q);
      
      H0 = 1000;
      Q0 = 1000;
      ss0 = StateSpace(Z, H0, T, Q0);
      
      ssE = ss.estimate(nile, ss0);
      
      A = T; B = nan; C = Z; D = nan;
      mdl = ssm(A, B, C, D);
      estmdl = estimate(mdl, nile, [1000; 1000], 'display', 'off');

      testCase.verifyEqual(ssE.H, estmdl.D^2, 'RelTol', 1e-2);
      testCase.verifyEqual(ssE.Q, estmdl.B^2, 'RelTol',  1e-2);
    end
    
    function testGeneratedSmallGradientZero(testCase)
      % Make sure that the gradient at the estimated parameters is close to zero
      p = 2; m = 1; timeDim = 500;
      rng(100753)
      ssTrue = generateARmodel(p, m-1, false);
      ssTrue.T = 1;
      y = generateData(ssTrue, timeDim);
      
      % Estimated system
      Z = [[1; nan(p-1, 1)] zeros(p, m-1)];
      H = nan(p, p);
      
      T = [nan(1, m); [eye(m-1) zeros(m-1, 1)]];
      R = zeros(m, 1); R(1, 1) = 1;
      Q = nan;
      
      ssE = StateSpaceEstimation(Z, H, T, Q, 'R', R);
      
      % Initialization
      pcaWeight = pca(y');
      Z0 = ssE.Z;
      Z0(:,1) = pcaWeight(:, 1);
      res = pcares(y', 1);      
      H0 = cov(res);
      T0 = ssE.T;
      T0(isnan(T0)) = 0.5./m;
      Q0 = 1;
      ss0 = StateSpace(Z0, H0, T0, Q0, 'R', R);
      
      ssML = ssE.estimate(y, ss0);
      [~, grad] = ssML.gradient(y, [], ssE.ThetaMapping);
      testCase.verifyLessThanOrEqual(abs(grad), 1e-4);
    end
    
    function testGenerated_noInit(testCase)
      % Make sure that we get close to a tough model to estimate. 
      % This test is sensitive to the actual generated values, thus the random seed. 
      p = 4; m = 2; timeDim = 500;
      rng(1001)
      ssTrue = generateARmodel(p, m-1, true);
      y = generateData(ssTrue, timeDim);
      
      % Estimated system
      Z = [[1; nan(p-1, 1)] zeros(p, m-1)];
      H = diag(nan(p, 1));
      
      T = [nan(1, m); [eye(m-1) zeros(m-1, 1)]];
      R = zeros(m, 1); R(1, 1) = 1;
      Q = nan;
      
      ssE = StateSpaceEstimation(Z, H, T, Q, 'R', R);
      
      ssML = ssE.estimate(y);
      testCase.verifyEqual(ssTrue.T, ssML.T, 'AbsTol', 0.1);
    end   
    
    function testBounds(testCase)
      p = 2; m = 1; timeDim = 500;
      ssTrue = generateARmodel(p, m-1, false);
      ssTrue.T = 1;
      y = generateData(ssTrue, timeDim);
      
      % Estimated system
      Z = [[1; nan(p-1, 1)] zeros(p, m-1)];
      H = nan(p, p);
      
      T = [nan(1, m); [eye(m-1) zeros(m-1, 1)]];
      R = zeros(m, 1); R(1, 1) = 1;
      Q = nan;
      
      ssE = StateSpaceEstimation(Z, H, T, Q, 'R', R);
     
      % Bounds: constrain 0 < T < 1
      ssLB = ssE.ThetaMapping.LowerBound;
      ssLB.T = -1;
      
      ssUB = ssE.ThetaMapping.UpperBound;
      ssUB.T = 1;
      ssE.ThetaMapping = ssE.ThetaMapping.addRestrictions(ssLB, ssUB);
      
      ss0 = ssTrue;
      ss0.T = 0.2;
      
      % The warnings thrown in this example don't worry me but I don't know how to
      % addresse them right now, so they stay.
      [ssE, ~, ~] = ssE.estimate(y, ss0);
      testCase.verifyLessThanOrEqual(ssE.T, 1);
      testCase.verifyGreaterThanOrEqual(ssE.T, -1);
    end
  end
end
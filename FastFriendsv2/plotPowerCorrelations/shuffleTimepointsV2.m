function shuffleTimepointsV2(subA_pnPower,subB_pnPower)

    foundSigs = 0;

    while foundSigs < 1000

    rhoDist = zeros(1,1000); 
    pvalDist = zeros(1,1000);
    
    subA_pnPowerShuffled = subA_pnPower(:,:,randperm(ne));
    subB_pnPowerShuffled = subB_pnPower(:,:,randperm(ne));

    [rho,pval,corrVect]=calcSpearmanRhoCorr(subA_pnPowerShuffled,...
                                            subB_pnPowerShuffled,F);
    rhoDist(:,:,i) = rho;
    pvalDist(:,:,i) = pval;
    corrVectAll(:,:,i) = corrVect;
end
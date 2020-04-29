function EEG = interpolateBadChans(EEG,toInterp)

% Re-interpolate channels after removing bad components
if ~isempty(toInterp)
    for xi=1:size(toInterp,2)
        for ei=1:EEG.nbchan
            if strmatch(EEG.chanlocs(ei).labels,toInterp{xi})
                badChans(xi)=ei;
            end
        end
    end
    EEG.data=double(EEG.data);
    EEG = pop_interp(EEG,badChans,'spherical');
end

disp(['Interpolated these channels: ',toInterp]);

end
function y = dopplerChannel(x,fs,chanParams)
    % 形成一个输出向量y，包含了不同路径的时延、多普勒和复增益
    numPaths = length(chanParams.pathDelays);
    maxPathDelay = max(chanParams.pathDelays);
    txOutSize = length(x);
    
    y = zeros(txOutSize+maxPathDelay,1);
    
    for k = 1:numPaths
        pathOut = zeros(txOutSize+maxPathDelay,1);

        % 多普勒频移，考虑分数多普勒值
        t = (0:txOutSize-1)'/fs; % 时间向量
        dopplerShift = exp(1j*2*pi*chanParams.pathDopplerFreqs(k)*t);
        pathShift = x .* dopplerShift;
    
        % 时延和增益
        pathOut(1+chanParams.pathDelays(k):chanParams.pathDelays(k)+txOutSize) = ...
            pathShift * chanParams.pathGains(k);
            
        y = y + pathOut;
    end
end

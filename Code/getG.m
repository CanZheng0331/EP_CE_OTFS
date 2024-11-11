function G = getG(M,N,chanParams,padLen,padType)
    % 根据检测到的DD路径生成时域信道矩阵
    if strcmp(padType,'ZP') || strcmp(padType,'CP')
        Meff = M + padLen;  % 考虑子符号填充长度形成信道
        lmax = padLen;      % 最大时延
    else
        Meff = M;
        lmax = max(chanParams.pathDelays);  % 最大时延
    end
    MN = Meff*N;
    P = length(chanParams.pathDelays);  % 路径数量
    
    % 为每条路径生成信道响应数组
    g = zeros(lmax+1,MN);
    for p = 1:P
        gp = chanParams.pathGains(p);
        lp = chanParams.pathDelays(p);
        vp = chanParams.pathDopplers(p); 

        % 对每个DD路径计算信道响应。
        % 每条路径是多普勒频率的复正弦（kp），
        % 通过一个延迟（lp）偏移并通过路径增益（gp）缩放
        g(lp+1,:) = g(lp+1,:) + gp*exp(1i*2*pi/MN * vp*((0:MN-1)-lp));
    end    

    % 形成MN x MN的信道矩阵G
    G = zeros(MN,MN);
    % 每个DD路径都是G中的对角线，偏移量为其路径时延 l
    for l = unique(chanParams.pathDelays).'
        G = G + diag(g(l+1,l+1:end),-l);
    end
end

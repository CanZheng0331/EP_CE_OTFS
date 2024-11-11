clear;
clc;
close all;

% 设置蒙特卡洛模拟次数
numTrials = 10;  % 每个SNR点上的仿真次数

% 初始化参数
M = 64;          % 子载波数
N = 30;          % 每帧符号数
df = 15e3;       % 频率间隔
fc = 2e9;        % 载波频率，单位Hz
padLen = 10;     % 填充长度，取大于信道延迟扩展的采样数
padType = 'ZP';  % 使用零填充（ZP）

% 导频生成和网格填充
pilotBin = floor(N/2)+1;
Pdd = zeros(M,N);
Pdd(1,pilotBin) = exp(1i*pi/4); % 仅填充一个网格

% OTFS调制
txOut = helperOTFSmod(Pdd, padLen, padType);

% 配置信道参数，考虑分数多普勒值
chanParams.pathDelays      = [0  5   8  ];    % 各路径的时延（采样点数）
chanParams.pathGains       = [1  0.7 0.5];    % 各路径的复增益
chanParams.pathDopplers    = [0 -3.5 5.25];   % 多普勒索引，可以是小数

fsamp = M*df;            % 采样频率
Meff = M + padLen;       % 每个OTFS子符号的采样数
numSamps = Meff * N;     % 每个OTFS符号的采样数
T = ((M+padLen)/(M*df)); % 符号持续时间（秒）

% 计算路径的实际多普勒频率，包括分数部分
chanParams.pathDopplerFreqs = chanParams.pathDopplers / (N*T); % 以Hz为单位

% 定义导频SNR的范围
pilotSNRdB = 0:5:40;  % 从0dB到40dB，每隔5dB取一个点
Es = mean(abs(pskmod(0:3,4,pi/4).^ 2));
nmse = zeros(size(pilotSNRdB));  % 存储每个SNR下的NMSE

% 原始信道响应，用于计算 NMSE
dopplerOut_pilot = dopplerChannel(txOut, fsamp, chanParams);
chOut_pilot = awgn(dopplerOut_pilot, 30, 'measured');  % 使用固定导频SNR生成真实信道
rxIn_pilot = chOut_pilot(1:numSamps);
Ydd_pilot = helperOTFSdemod(rxIn_pilot, M, padLen, 0, padType);
H_true = Ydd_pilot * conj(Pdd(1, pilotBin)) / (abs(Pdd(1, pilotBin))^2);

for idx = 1:length(pilotSNRdB)

    pilotSNR = pilotSNRdB(idx);
    n0_pilot = Es / (10^(pilotSNR / 10));

    nmse_trials = zeros(1, numTrials);
    for trial = 1:numTrials
        dopplerOut_pilot = dopplerChannel(txOut, fsamp, chanParams);
        chOut_pilot = awgn(dopplerOut_pilot, pilotSNR, 'measured');
        rxIn_pilot = chOut_pilot(1:numSamps);
        Ydd_pilot = helperOTFSdemod(rxIn_pilot, M, padLen, 0, padType);
        H_est = Ydd_pilot * conj(Pdd(1, pilotBin)) / (abs(Pdd(1, pilotBin))^2 + n0_pilot);
        nmse_trials(trial) = sum(sum(abs(H_est - H_true).^2)) / sum(sum(abs(H_true).^2));
    end
    nmse(idx) = mean(nmse_trials); 
end

% 绘制NMSE曲线
figure;
plot(pilotSNRdB, 10*log10(nmse), '-o');
grid on;
xlabel('导频SNR (dB)');
ylabel('NMSE (dB)');
title('信道估计的NMSE随导频SNR变化曲线');

% 提取信道路径信息
[lp, vp] = find(abs(H_true) >= 0.05);
chanEst.pathGains = diag(H_true(lp, vp));   
chanEst.pathDelays = lp - 1;            
chanEst.pathDopplers = vp - pilotBin;   

% 生成数据
Xgrid = zeros(M, N);
Xdata = randi([0, 1], 2*M, N);
Xgrid(1:M, :) = pskmod(Xdata, 4, pi/4, InputType="bit");

% OTFS 调制
txOut_data = helperOTFSmod(Xgrid, padLen, padType);

% 定义数据SNR的范围
dataSNRdB = 0:5:20;  % 从0dB到40dB，每隔5dB取一个点
berOTFS = zeros(size(dataSNRdB));  % 存储OTFS的BER

for idx = 1:length(dataSNRdB)
    dataSNR = dataSNRdB(idx);
    n0_data = Es / (10^(dataSNR / 10));

    berOTFS_trials = zeros(1, numTrials);
    
    for trial = 1:numTrials
        % OTFS 信号通过信道和噪声
        dopplerOut_otfs = dopplerChannel(txOut_data, fsamp, chanParams);
        chOut_otfs = awgn(dopplerOut_otfs, dataSNR, 'measured');
        
        % OTFS 接收和解调
        rxWindow_otfs = chOut_otfs(1:numSamps);
        G = getG(M, N, chanEst, padLen, padType);
        y_otfs = ((G'*G) + n0_data * eye(Meff * N)) \ (G' * rxWindow_otfs); % LMMSE
        Xhat_otfs = helperOTFSdemod(y_otfs, M, padLen, 0, padType); % OTFS 解调
        XhatDataOTFS = pskdemod(Xhat_otfs, 4, pi/4, OutputType="bit", OutputDataType="logical");
        [~, berOTFS_trials(trial)] = biterr(Xdata, XhatDataOTFS);
    end
    
    % 计算平均BER
    berOTFS(idx) = mean(berOTFS_trials);
end

% 绘制BER曲线
figure;
semilogy(dataSNRdB, berOTFS, '-s');
grid on;
xlabel('数据SNR (dB)');
ylabel('BER');
title(['OTFS的BER性能 (', num2str(numTrials), '次蒙特卡洛模拟平均)']);

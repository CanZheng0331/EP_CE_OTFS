M = 64;          % 子载波数
N = 30;          % 每帧符号数
df = 15e3;       % 频率间隔，设置为LTE的频率间隔
fc = 5e9;        % 载波频率，单位Hz
padLen = 10;     % 填充长度，取大于信道延迟扩展的采样数
padType = 'ZP';  % 使用零填充（ZP）以抑制符号间干扰
SNRdB = 40;

% 导频生成和网格填充
pilotBin = floor(N/2)+1;
Pdd = zeros(M,N);
Pdd(1,pilotBin) = exp(1i*pi/4); % 仅填充一个网格以观察其在信道中的效果

% OTFS调制
txOut = helperOTFSmod(Pdd,padLen,padType);

% 配置信道参数
chanParams.pathDelays      = [0  5   8  ]; % 各路径的时延（采样点数）
chanParams.pathGains       = [1  0.7 0.5]; % 各路径的复增益
chanParams.pathDopplers    = [0 -3 5];   % 多普勒索引，可以是小数

assert(strcmp(padType,'ZP'),'本示例必须使用ZP填充类型');

fsamp = M*df;            % 采样频率，满足奈奎斯特率
Meff = M + padLen;       % 每个OTFS子符号的采样数
numSamps = Meff * N;     % 每个OTFS符号的采样数
T = ((M+padLen)/(M*df)); % 符号持续时间（秒）

% 计算路径的实际多普勒频率
chanParams.pathDopplerFreqs = chanParams.pathDopplers * 1/(N*T); % 以Hz为单位

% 发送OTFS调制信号通过信道
dopplerOut = dopplerChannel(txOut,fsamp,chanParams);

% 添加加性高斯白噪声
Es = mean(abs(pskmod(0:3,4,pi/4).^ 2));
n0 = Es/(10^(SNRdB/10));
chOut = awgn(dopplerOut,SNRdB,'measured');

for k = 1:length(chanParams.pathDelays)
    fprintf('散射器 %d\n',k);
    fprintf('\t时延 = %5.2f 微秒\n', 1e6*chanParams.pathDelays(k)/(Meff*df));
    fprintf('\t相对多普勒频移 = %5.0f Hz (%5.0f km/h)\n', ...
        chanParams.pathDopplerFreqs(k), (physconst('LightSpeed')*chanParams.pathDopplerFreqs(k)/fc)*(3600/1000));
end

% 获取一个采样窗口
rxIn = chOut(1:numSamps);

% OTFS解调
Ydd = helperOTFSdemod(rxIn,M,padLen,0,padType);

% 延迟-多普勒域的LMMSE信道估计
Hdd = Ydd * conj(Pdd(1,pilotBin)) / (abs(Pdd(1,pilotBin))^2 + n0);

figure;
xa = 0:1:N-1;
ya = 0:1:M-1;
mesh(xa,ya,abs(Hdd));
view([-9.441 62.412]);
title('通过信道测量的延迟-多普勒信道响应 H_{dd}');
xlabel('归一化多普勒');
ylabel('归一化时延');
zlabel('幅度');

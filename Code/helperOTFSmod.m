function [y,isfftout] = helperOTFSmod(x,padlen,varargin)
%HELPEROTFSMOD 对延迟-多普勒域输入信号进行调制
%
%   [Y,ISFFT] = HELPEROTFSMOD(X,PADLEN,PADTYPE) 使用矩形脉冲成形窗口对输入
%   信号X进行OTFS调制，并输出结果Y。X是一个 M x N 大小的实数或复数值数组。
%   M为子载波数，N为OTFS子符号数。
%
%   参数：
%   X - OTFS网格 (M x N)
%   PADLEN - CP或ZP长度（以采样数计）
%   PADTYPE（可选）:
%     'CP'   = 循环前缀（默认）
%     'RCP'  = 减少的循环前缀
%     'ZP'   = 零填充
%     'RZP'  = 减少的零填充
%     'NONE' = 无 CP/ZP
%   返回：
%   Y - 带有选定循环前缀的时域输出向量

M = size(x,1);
if isempty(varargin)
    padtype = 'CP';
else
    padtype = varargin{1};
end

% 逆Zak变换
y = ifft(x.').' / M;

% ISFFT以生成TF网格输出
isfftout = fft(y);

% 根据padtype添加循环前缀/零填充
switch padtype
    case 'CP'
        % % 在每个OTFS列之前添加CP（类似OFDM），然后串行化
        y = [y(end-padlen+1:end,:); y];  % 循环前缀
        y = y(:);                        % 串行化
    case 'ZP'
        % 每个OTFS列后添加零填充，然后串行化
        N = size(x,2);
        y = [y; zeros(padlen,N)];    % 零填充
        y = y(:);                    % 串行化
    case 'RZP'
        % 串行化后附加OTFS符号的零填充
        y = y(:);                    % 串行化
        y = [y; zeros(padlen,1)];    % 零填充
    case 'RCP'
        % 减少的循环前缀
        % 串行化后附加循环前缀
        y = y(:);                        % 串行化
        y = [y(end-padlen+1:end); y];    % 循环前缀
    case 'NONE'
        y = y(:);                   % 无 CP/ZP
    otherwise
        error('无效的填充类型');
end
end

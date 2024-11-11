function [y,tfout] = helperOTFSdemod(x,M,padlen,offset,varargin)
%HELPEROTFSDEMOD OTFS解调接收的时域输入信号
%
%   [Y,TFOUT] = HELPEROTFSDEMOD(X,M,PADLEN,SYMOFFSET,PADTYPE) 对输入信号X
%   进行OTFS解调，使用矩形脉冲成形窗口，输出结果为Y。X为实数或复数
%   值向量。M为子载波数。OTFS子符号数从输入大小、PADTYPE和PADLEN推断。
%
%   参数：
%   X - 时域输入，包括长度为 M*N+PADLEN 的 CP，如果 PADTYPE 是 RCP 或 RZP；
%       或者长度为 (M+PADLEN)*N 的 CP，如果 PADTYPE 是 CP 或 ZP。
%   M - 子载波数
%   PADLEN - CP或ZP长度（以采样数计）
%   OFFSET - 从OTFS符号/子符号开头或结尾的采样偏移量
%   PADTYPE（可选）:
%     'CP'   = 循环前缀（默认）
%     'RCP'  = 减少的循环前缀
%     'ZP'   = 零填充
%     'RZP'  = 减少的零填充
%     'NONE' = 无 CP/ZP
%   返回：
%   Y - DD域输出，大小为 M x N
%   TFOUT - 两步OTFS解调过程中生成的TF域输出，大小为 M x N

    if isempty(varargin)
        padtype = 'CP';
    else
        padtype = varargin{1};
    end

    % 去除CP并形成延迟-多普勒网格
    if strcmp(padtype,'CP') || strcmp(padtype,'ZP')
        % 完整CP (offset = padlen) 或 零填充 (offset = 0)
        N = size(x,1)/(M+padlen);
        assert((N - round(N)) < sqrt(eps)); % 检查M*N是否为整数
        
        rx = reshape(x,M+padlen,N);
        Y = rx(1+offset:M+offset,:); % 去除CP
    elseif strcmp(padtype,'NONE')
        N = size(x,1)/M;
        assert((N - round(N)) < sqrt(eps)); % 检查M*N是否为整数
        
        Y = reshape(x,M,N);
    elseif strcmp(padtype,'RCP') || strcmp(padtype,'RZP')
        % 减少CP (offset = padlen) 或减少的零填充 (offset = 0)
        N = (size(x,1)-padlen)/M;
        assert((N - round(N)) < sqrt(eps)); % 检查M*N是否为整数

        rx = x(1+offset:M*N+offset); % 去除CP
        Y = reshape(rx,M,N);
    else
        error('无效的填充类型');
    end

    % 该段代码显示SFFT/OFDM解调表示
    % 使用矩形窗口的维格纳变换（OFDM解调器）
    tfout = fft(Y);

    % 该段代码显示更简单的Zak变换表示
    y = fft(Y.').' * M;
end

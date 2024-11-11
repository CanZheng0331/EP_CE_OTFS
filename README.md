###  代码解释 Function Explanation ###

一个简单的 demo，实现了 “Embedded Pilot-Aided Channel Estimation for OTFS in Delay–Doppler Channels” 的基于阈值的嵌入式导频信道估计;

参考了 Mathworks 官网的 OTFS 模块： https://www.mathworks.com/help/comm/ug/otfs-modulation.html;

运行 OTFS_performance.m 即可输出随着导频 SNR 变化的 NMSE 曲线和随着数据信息 SNR 变化的 BER 曲线;

可按需修改为更复杂的信道模型，可参考 Viterbo 教授的开源代码；

如果代码有误，请及时告知。

A simple demo that implements "Embedded Pilot-Aided Channel Estimation for OTFS in Delay–Doppler Channels";

Refer to the OTFS part on the Mathworks official website: https://www.mathworks.com/help/comm/ug/otfs-modulation.html;

Run OTFS_performance.m to get NMSE curve (SNR_pilot as the x-axis) and BER curve (SNR_data as the y-axis);

Can be modified to a more complex channel model as needed, refer to Prof. Viterbo's open source code;

If there're any problems in the code, please let me know.

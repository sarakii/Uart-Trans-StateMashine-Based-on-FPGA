# 一个基于FPGA的串口收发实验(状态机版本)
使用的硬件：正点原子MPSOC4EV芯片开发板。<br>
实现的功能：使用串口助手往开发板发送数据，开发板接收到数据后把数据发回串口助手。<br>
相比于非状态机版本，<br>
1. 使用了三段式状态机来实现串口功能。
2. 优化了串口发送的逻辑：uart发出脉冲信号而不是持续使能信号启动串口发送。
3. 优化了代码风格：减少begin-end的使用，减少了if嵌套。
4. 简化了代码：把原本用时序逻辑写的always块改成一句assign。
PS：写完以后，师兄跟我说他平时写串口都不用状态机写的，因为串口比较简单，状态少，用状态机的写法反而会浪费电路资源。
![image](https://github.com/user-attachments/assets/68d9ab20-1772-4fd1-ac4f-0d577d43a810)

## 实验截图：<br>
### 串口文本收发<br>
![image](https://github.com/user-attachments/assets/29c689b0-ff4b-4619-867e-85091ddeae5d)<br>
### 收发文件比对<br>
![image](https://github.com/user-attachments/assets/80b60c9b-3d1f-40f9-bbac-dbd7906e4583)<br>

## 下一个计划<br>
1. 入门嵌入式linux
2. 学一下FIFO的实现
3. AXI协议代码实现
4. 啃一下FPGA的入门书籍
5. 啃一下简单的数字信号处理
6. 啃一下数字电路网课

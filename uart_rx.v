`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/11 14:36:22
// Design Name: 
// Module Name: uart_rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_rx(
    input clk,
    input rst_n,

    input [2:0] Baud_Set,
    input rx, // 串行接收数据线，接收发送方的串行数据
    output reg [7:0] data, // 并行输出数据
    output rx_busy, // 接收状态
    output rx_done_tx // 接收完成通知发送
    );

    // *状态空间*
    parameter IDLE = 1'b0, RECV = 1'b1;
    reg state, next;

    // 检测数据线的下降沿（还可以直接判断低电平实现）
    reg rx_d0, rx_d1;
    wire rx_en;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            rx_d0 <= 1'b0;
            rx_d1 <= 1'b0;
        end else begin
            rx_d0 <= rx;
            rx_d1 <= rx_d0;
        end
    end
    // 这里用边沿跳变来定位接收的开始位置，是为了方便精确地定位开始位置
    assign rx_en = (state == IDLE)? (rx_d1) & (~rx_d0) : 1'b0; 

    // *转换*
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            state <= IDLE;
        else 
            state <= next;
    end

    // *转换逻辑*
    always @(*)begin
        if(!rst_n)
            next = IDLE;
        else begin
            case(state)
                IDLE: next = (rx_en)? RECV : IDLE;
                RECV: next = (rx_done)? IDLE : RECV;
                default: next = state;
            endcase
        end
    end

    // *输出*
    // 分频计数器
    parameter CLK_FREQ = 100000000;
    reg [15:0] BPS_CNT;
    always @(*)begin
        case(Baud_Set)
            0:BPS_CNT = CLK_FREQ/9600;
            1:BPS_CNT = CLK_FREQ/19200;
            2:BPS_CNT = CLK_FREQ/38400;
            3:BPS_CNT = CLK_FREQ/57600;
            4:BPS_CNT = CLK_FREQ/115200;
        endcase
    end

    reg [15:0] div_cnt; // BPS_CNT计数变量
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            div_cnt <= 0;
        else if(state == RECV && div_cnt == BPS_CNT - 1 || state == IDLE)
            div_cnt <= 0;
        else if(state == RECV && div_cnt < BPS_CNT - 1)
            div_cnt <= div_cnt + 1;
    end

    // 接收位数计数器
    reg [3:0] bit_cnt;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            bit_cnt <= 0;
        else if((state == RECV && bit_cnt == 10) || state == IDLE)
            bit_cnt <= 0;
        else if(state == RECV && div_cnt == BPS_CNT - 1)
            bit_cnt <= bit_cnt + 1;
    end

    // 串行接收逻辑
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            data <= 8'b0;
        else if(state == RECV)begin
            if(div_cnt == BPS_CNT/2)begin
                case(bit_cnt)
                    1: data[0] <= rx; // 接收数据的第1位
                    2: data[1] <= rx;
                    3: data[2] <= rx;
                    4: data[3] <= rx;
                    5: data[4] <= rx;
                    6: data[5] <= rx;
                    7: data[6] <= rx;
                    8: data[7] <= rx; // 接收数据的第8位
                    default:data <= data;
                endcase
            end
        end else if(state == IDLE)
            data <= 8'b0;
    end

    // 串口状态
    assign rx_busy = (state == RECV);

    // 接收完成逻辑，提前表示接收完毕，**不是说现在就空闲了**，只是通知发送模块可以把接收到的数据发送出去了
    assign rx_done_tx = (bit_cnt==9 && div_cnt==1);
    // 接收完成逻辑，**现在就真空闲了**
    assign rx_done = (bit_cnt==9 && div_cnt==BPS_CNT/2);

endmodule

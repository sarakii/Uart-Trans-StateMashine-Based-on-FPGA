`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/07 12:17:31
// Design Name: 
// Module Name: uart_tx
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


module uart_tx(
    input clk,
    input rst_n,

    input [2:0] Baud_Set,
    input [7:0] data, // 发送数据
    output reg tx, // 串行发送线
    input send_en, // 发送使能
    output tx_busy,
    output tx_done // 发送完成
    );
    
    // 分频参数
    parameter CLK_FREQ = 100000000; // 硬件时钟频率
    reg [15:0] BPS_CNT; // 传输一位数据所需要的时钟周期，BPS_CNT倍频
    reg [15:0] div_cnt;
    // 发送位计数
    reg [3:0] bit_cnt; 

    // *状态空间*
    parameter IDLE = 1'b0, SEND = 1'b1;
    reg state, next;

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
                IDLE: next = (send_en)? SEND : IDLE; // IDLE状态下，来脉冲就切SEND，没脉冲就呆在IDLE
                SEND: next = (tx_done)? IDLE : SEND; // SEND状态下，发完就切IDLE，没发完就呆在SEND
                default:next = state;
            endcase
        end
    end

    // *输出*
    // 分频计数器
    always @(*) begin
        case(Baud_Set) // 波特率选择
            0:BPS_CNT = CLK_FREQ/9600;
            1:BPS_CNT = CLK_FREQ/19200;
            2:BPS_CNT = CLK_FREQ/38400;
            3:BPS_CNT = CLK_FREQ/57600;
            4:BPS_CNT = CLK_FREQ/115200;
        endcase
    end

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            div_cnt <= 0;
        else if((state == SEND && div_cnt == BPS_CNT - 1) || state == IDLE) // 在传输过程中才进行分频计数
            div_cnt <= 0;
        else if(state == SEND && div_cnt < BPS_CNT - 1)
            div_cnt <= div_cnt + 1;
    end

    // 发送位计数
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            bit_cnt <= 0;
        else if((state == SEND && bit_cnt == 10) || state == IDLE)
            bit_cnt <= 0;
        else if(state == SEND && div_cnt == BPS_CNT - 1) 
            bit_cnt <= bit_cnt + 1;
    end

    // 帧发送控制块
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            tx <= 1'b1; // 空闲
        else if(state == SEND) begin
            case(bit_cnt)
                0:tx <= 1'b0; // 发送起始位
                1:tx <= data[0];
                2:tx <= data[1];
                3:tx <= data[2];
                4:tx <= data[3];
                5:tx <= data[4];
                6:tx <= data[5];
                7:tx <= data[6];
                8:tx <= data[7];
                9:begin // 发送停止位
                    tx <= 1'b1;
                    if(div_cnt == BPS_CNT-(BPS_CNT/16)) // 提前1/16周期进入空闲状态（tx=1）
                        tx <= 1'b1;
                end
                default:tx <= tx;
            endcase
        end else if(state == IDLE) // 空闲
            tx <= 1'b1; 
    end

    // 输出完成标志位，提前1/16个周期表示已发送完毕（好让上层模块控制send_en）
    assign tx_done = (bit_cnt == 9 && div_cnt == BPS_CNT-(BPS_CNT/16));

    // 发送忙线标志（好让上层模块控制send_en）
    assign tx_busy = (state == SEND);

endmodule

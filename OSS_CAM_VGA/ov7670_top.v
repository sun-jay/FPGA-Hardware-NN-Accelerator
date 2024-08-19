module topMod(
    input clk100_extern,
    input reset_in, 
    input [0:0] oneOrZed,
    output [7:0] Anode_Activate,
    output [6:0] LED_out,
    
    
    output[3:0] vga_red,
    output[3:0] vga_green,
    output[3:0] vga_blue,
    output vga_hsync, //��ֱͬ��
    output vga_vsync, //��ͬ��
    
    
    input  OV7670_VSYNC, //SCCBЭ��ʵ�ֳ�ͬ���ź�����
    input  OV7670_HREF,  //SCCBЭ��ʵ����ͬ���ź�����
    input  OV7670_PCLK,  //����ʱ������
    output OV7670_XCLK,  //����ͷ����ʱ��
    output OV7670_SIOC, 
    inout  OV7670_SIOD,
    input [7:0] OV7670_D, //���ݴ����
    output pwdn,
    output reset_out,
    
    output[3:0] LED,
    input btn
    

);

// wires for NN
wire dataA;
wire [15:0] addrA;
wire [31:0] addrA_mapped;
wire [3:0] digit_out;

assign addrA_mapped = addrA>=784 ? 76801 : ((8 + (addrA / 28) * 8) * 320 + (48 + (addrA % 28) * 8));

  blk_mem_gen_NN inputs(
		.clka (OV7670_PCLK),
		.wea  (1), // for simulation, disable write to the inputs (REMEMEBR TO SWITCH BACK ON BEFORE SYNTH)
		.addra (camera_in_addr),
		.dina  (camera_in_data),

		.clkb   (clk100_intern),
		.addrb (addrA_mapped),
		.doutb (dataA)
 );
 
 wire data_in_mod;
 assign data_in_mod = oneOrZed? 1 - dataA : dataA;
 
  NN nn (
        .clk(clk100_intern),
        .reset(reset_in),
        
        .addrA(addrA),
        .dataA(data_in_mod),
        
        .digit_out(digit_out)
        
    );
    
wire [15:0] zero_extend;
assign zero_extend = digit_out;
segDisp disp (.clock_100Mhz(clk100_intern), .reset(reset_in), .number(zero_extend), .LED_out(LED_out), .Anode_Activate(Anode_Activate));




wire clk100_intern;
wire  clk25; 
wire  clk50;  

wire [16:0] vga_addr_out;
wire [16:0] camera_in_addr;   
//wire  capture_we;  
wire  config_finished;  
wire  resend;        
wire [11:0] vga_data_in;  
wire [11:0]  camera_in_data;
  
assign pwdn = 0; //0Ϊ����������1Ϊ�͹���ģʽ
assign reset_out = 1;


assign LED = {3'b0,config_finished};
assign  	OV7670_XCLK = clk25;  
debounce   btn_debounce(
		.clk(clk50),
		.i(btn),
		.o(resend)
);

wire zeroSig;
assign zeroSig = 0;

 blk_mem_gen_NN u_frame_buffer(
		.clka (OV7670_PCLK),
		.wea  (1),
		.addra (camera_in_addr),
		.dina  (camera_in_data),

		.clkb   (clk25),
		.addrb (vga_addr_out),
		.doutb (vga_data_in)
 );
 

 vga   vga_display (
		.clk25       (clk25),
		.vga_red    (vga_red),
		.vga_green   (vga_green),
		.vga_blue    (vga_blue),
		.vga_hsync   (vga_hsync),
		.vga_vsync  (vga_vsync),
		.HCnt       (),
		.VCnt       (),

		.frame_addr   (vga_addr_out),
		.frame_pixel  (vga_data_in)
 );
 

 ov7670_capture capture(         //����ov7670����ͷ����
 		.pclk  (OV7670_PCLK),    //�������ʱ��
 		.vsync (OV7670_VSYNC),   //��ͬ��
 		.href  (OV7670_HREF),    //��ֱͬ�� 
 		.d     ( OV7670_D),      //ͼ���������
 		.addr  (camera_in_addr),   //�洢��ĵ�ַ
 		.dout( camera_in_data),         //12λ�������
 		.we   ()
 	);
 
I2C_AV_Config IIC(                 //����ͷSCCBЭ���ʵ��
 		.iCLK   ( clk25),          //����25MHzʱ��
 		.iRST_N (! resend),        //��λ
 		.Config_Done ( config_finished),    //��ov7670�ļĴ�������������ɺ󣬷���config_finished�ź�
 		.I2C_SDAT  ( OV7670_SIOD),   //�������� 
 		.I2C_SCLK  ( OV7670_SIOC),   //����ʱ������
 		.LUT_INDEX (),
 		.I2C_RDATA ()
 		); 
		
clk_wiz_1 clk_div(
		.clk_in1 (clk100_extern),
		.clk_out1  (clk50),
		.clk_out2 (clk25),
		.clk_out3 (clk100_intern)
);



endmodule






//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: SYSU
//// Engineer: liuzs
//// 
//// Create Date: 2018/12/03 21:37:38
//// Design Name: 
//// Module Name: ov7670_top
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////


//module ov7670_top(
//input  clk100,
//input  OV7670_VSYNC, //SCCBЭ��ʵ�ֳ�ͬ���ź�����
//input  OV7670_HREF,  //SCCBЭ��ʵ����ͬ���ź�����
//input  OV7670_PCLK,  //����ʱ������
//output OV7670_XCLK,  //����ͷ����ʱ��
//output OV7670_SIOC, 
//inout  OV7670_SIOD,
//input [7:0] OV7670_D, //���ݴ�����

//output[3:0] LED,
//output[3:0] vga_red,
//output[3:0] vga_green,
//output[3:0] vga_blue,
//output vga_hsync, //��ֱͬ��
//output vga_vsync, //��ͬ��
//input btn,
//output pwdn,
//output reset,

//output [3:0] Anode_Activate,
//output [6:0] LED_out,
//output nn_status


//);
//wire clk100_intern;

//wire [16:0] frame_addr;
//wire [16:0] capture_addr;   
////wire  capture_we;  
//wire  config_finished;  
//wire  clk25; 
//wire  clk50;     
//wire  resend;        
//wire [11:0] frame_pixel;  
//wire [11:0]  data_16;
  
//assign pwdn = 0; //0Ϊ����������1Ϊ�͹���ģʽ
//assign reset = 1;
  

//assign LED = {3'b0,config_finished};
//assign  	OV7670_XCLK = clk25;  
//debounce   btn_debounce(
//		.clk(clk50),
//		.i(btn),
//		.o(resend)
//);

//wire dataA;
//wire [15:0] addrA;
//wire [31:0] addrA_mapped;
//wire [3:0] digit_out;


//assign nn_status = digit_out==4?0:1;

//assign addrA_mapped = addrA>=784 ? 76801 : ((8 + (addrA / 28) * 8) * 320 + (48 + (addrA % 28) * 8));

// NN nn (
//        .clk(clk100_intern),
//        .reset(reset),
        
//        .addrA(addrA),
//        .dataA(dataA),
        
//        .digit_out(digit_out)
        
//    );
    
//  blk_mem_gen_NN u_frame_buffer_NN(
//		.clka (OV7670_PCLK),
//		.wea  (1'b0),
//		.addra (capture_addr),
//		.dina  (data_16),

//		.clkb   (clk100_intern),
//		.addrb (addrA_mapped),
//		.doutb (dataA)
// );
 
//segDisp disp (.clock_100Mhz(clk100_intern), .reset(reset), .number(~dataA), .LED_out(LED_out), .Anode_Activate(Anode_Activate));
 
// vga   vga_display (
//		.clk25       (clk25),
//		.vga_red    (vga_red),
//		.vga_green   (vga_green),
//		.vga_blue    (vga_blue),
//		.vga_hsync   (vga_hsync),
//		.vga_vsync  (vga_vsync),
//		.HCnt       (),
//		.VCnt       (),

//		.frame_addr   (frame_addr),
//		.frame_pixel  (frame_pixel)
// );
 
// blk_mem_gen_0 u_frame_buffer(
//		.clka (OV7670_PCLK),
//		.wea  (1'b1),
//		.addra (capture_addr),
//		.dina  (data_16),

//		.clkb   (clk25),
//		.addrb (frame_addr),
//		.doutb (frame_pixel)
// );
 

 

// ov7670_capture capture(         //����ov7670����ͷ����
// 		.pclk  (OV7670_PCLK),    //�������ʱ��
// 		.vsync (OV7670_VSYNC),   //��ͬ��
// 		.href  (OV7670_HREF),    //��ֱͬ�� 
// 		.d     ( OV7670_D),      //ͼ���������
// 		.addr  (capture_addr),   //�洢��ĵ�ַ
// 		.dout( data_16),         //12λ�������
// 		.we   ()
// 	);
 
//I2C_AV_Config IIC(                 //����ͷSCCBЭ���ʵ��
// 		.iCLK   ( clk25),          //����25MHzʱ��
// 		.iRST_N (! resend),        //��λ
// 		.Config_Done ( config_finished),    //��ov7670�ļĴ�������������ɺ󣬷���config_finished�ź�
// 		.I2C_SDAT  ( OV7670_SIOD),   //�������� 
// 		.I2C_SCLK  ( OV7670_SIOC),   //����ʱ������
// 		.LUT_INDEX (),
// 		.I2C_RDATA ()
// 		); 
		
//clk_wiz_1 clk_div(
//		.clk_in1 (clk100),
//		.clk_out1  (clk50),
//		.clk_out2 (clk25),
//		.clk_out3 (clk100_intern)
//);

//endmodule
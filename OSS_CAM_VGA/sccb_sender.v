`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/03 21:49:57
// Design Name: 
// Module Name: sccb_sender
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


module I2C_Controller 
(
	//Global iCLK
	input				iCLK,		
	input				iRST_N,		
	
	//I2C transfer
	input				I2C_CLK,	//DATA Transfer Enable
	input				I2C_EN,		//I2C DATA ENABLE
	input		[23:0]	I2C_WDATA,	//DATA:[SLAVE_ADDR, SUB_ADDR, DATA]
	output				I2C_SCLK,	//I2C iCLK
 	inout				I2C_SDAT,	//I2C DATA
	input				WR,     	//Write | Read
	input				GO,      	//GO transfor
	output				ACK,      	//ACK
	output	reg			END,     	//END transfor 
	output	reg	[7:0]	I2C_RDATA	//I2C Data read
);

//------------------------------------
//I2C Signal
reg		I2C_BIT;
reg 	SCLK;	//I2C Free Clock
reg	[5:0]	SD_COUNTER;

//Write: ID-Address + SUB-Address + W-Data
wire 	I2C_SCLK1 = 	(GO == 1 &&
						((SD_COUNTER >= 5 && SD_COUNTER <=12 || SD_COUNTER == 14) ||	
						(SD_COUNTER >= 16 && SD_COUNTER <=23 || SD_COUNTER == 25) ||
						(SD_COUNTER >= 27 && SD_COUNTER <=34 || SD_COUNTER == 36))) ? I2C_CLK : SCLK;

//I2C Read: {ID-Address + SUB-Address} + {ID-Address + R-Data}						
wire 	I2C_SCLK2 = 	(GO == 1 &&
						((SD_COUNTER >= 5 && SD_COUNTER <=12 || SD_COUNTER == 14) ||
						(SD_COUNTER >= 16 && SD_COUNTER <=23 || SD_COUNTER == 25) ||
						(SD_COUNTER >= 33 && SD_COUNTER <=40 || SD_COUNTER == 42) ||
						(SD_COUNTER >= 45 && SD_COUNTER <=52 || SD_COUNTER == 54))) ? I2C_CLK : SCLK;						
assign	I2C_SCLK = WR ? I2C_SCLK1 : I2C_SCLK2;	

wire	SDO1	=		((SD_COUNTER == 13 || SD_COUNTER == 14)|| 
						(SD_COUNTER == 24 || SD_COUNTER == 25) || 
						(SD_COUNTER == 35 || SD_COUNTER == 36)) ? 1'b0 : 1'b1;		//input | output
						
wire	SDO2	=		((SD_COUNTER == 13 || SD_COUNTER == 14)|| 
						(SD_COUNTER == 24 || SD_COUNTER == 25) || 
						(SD_COUNTER == 41 || SD_COUNTER == 42) ||
						(SD_COUNTER >= 44 && SD_COUNTER <= 52)) ? 1'b0 : 1'b1;		//input | output
wire	SDO = WR ? SDO1 : SDO2;
assign	I2C_SDAT = SDO ? I2C_BIT : 1'bz;



//------------------------------------
//Write ACK | Read ACK
reg		ACKW1, ACKW2, ACKW3;		//0 AVTIVE
reg 	ACKR1, ACKR2, ACKR3;		//0 ACTIVE
assign	ACK = WR ? (ACKW1 | ACKW2 | ACKW3) : (ACKR1 | ACKR2 | ACKR3);


//------------------------------------
//I2C COUNTER
always @(posedge iCLK or negedge iRST_N) 
begin
	if (!iRST_N) 
		SD_COUNTER <= 6'b0;
	else if(I2C_EN)
		begin
		if (GO == 0 || END == 1) 
			SD_COUNTER <= 6'b0;
		else if (SD_COUNTER < 6'd63) 
			SD_COUNTER <= SD_COUNTER + 6'd1;	
		end
	else
		SD_COUNTER <= SD_COUNTER;
end

//------------------------------------
//I2C Transfer
always @(posedge iCLK or negedge iRST_N) 
begin
    if(!iRST_N) 
		begin 
		SCLK <= 1;
		I2C_BIT <= 1; 
		ACKW1 <= 1; ACKW2 <= 1; ACKW3 <= 1; 
		ACKR1 <= 1; ACKR2 <= 1; ACKR3 <= 1;
		END <= 0;
		I2C_RDATA <= 8'h0;	
		end
	else if(I2C_EN)		//data change enable
		begin
		if(GO)
			begin
			if(WR)		//I2C Write: ID-Address + SUB-Address + W-Data
				begin
				case(SD_COUNTER)
				//IDLE
				6'd0 :	begin
						SCLK <= 1;
						I2C_BIT <= 1;
						ACKW1 <= 1; ACKW2 <= 1; ACKW3 <= 1;
						ACKR1 <= 1; ACKR2 <= 1; ACKR3 <= 1;
						END <= 0;
						end
				//Start
				6'd1 :	begin 
						SCLK <= 1;
						I2C_BIT <= 1;
						ACKW1 <= 1; ACKW2 <= 1; ACKW3 <= 1; 
						END <= 0;
						end
				6'd2  : I2C_BIT <= 0;		//I2C_SDAT = 0
				6'd3  : SCLK <= 0;			//I2C_SCLK = 0
				
				//SLAVE ADDR--ACK1
				6'd4  : I2C_BIT <= I2C_WDATA[23];	//Bit8
				6'd5  : I2C_BIT <= I2C_WDATA[22];	//Bit7
				6'd6  : I2C_BIT <= I2C_WDATA[21];	//Bit6
				6'd7  : I2C_BIT <= I2C_WDATA[20];	//Bit5
				6'd8  : I2C_BIT <= I2C_WDATA[19];	//Bit4
				6'd9  : I2C_BIT <= I2C_WDATA[18];	//Bit3
				6'd10 : I2C_BIT <= I2C_WDATA[17];	//Bit2
				6'd11 : I2C_BIT <= I2C_WDATA[16];	//Bit1
				6'd12 : I2C_BIT <= 0;				//High-Z, Input
				6'd13 : ACKW1 	<= I2C_SDAT;		//ACK1
				6'd14 : I2C_BIT <= 0;				//Delay
				
				//SUB ADDR--ACK2
				6'd15 : I2C_BIT <= I2C_WDATA[15];	//Bit8
				6'd16 : I2C_BIT <= I2C_WDATA[14];	//Bit7
				6'd17 : I2C_BIT <= I2C_WDATA[13];	//Bit6
				6'd18 : I2C_BIT <= I2C_WDATA[12];	//Bit5
				6'd19 : I2C_BIT <= I2C_WDATA[11];	//Bit4
				6'd20 : I2C_BIT <= I2C_WDATA[10];	//Bit3
				6'd21 : I2C_BIT <= I2C_WDATA[9];   //Bit2
				6'd22 : I2C_BIT <= I2C_WDATA[8];	//Bit1
				6'd23 : I2C_BIT <= 0;				//High-Z, Input
				6'd24 : ACKW2 	<= I2C_SDAT;		//ACK2
				6'd25 : I2C_BIT <= 0;				//Delay
				
				//Write DATA--ACK3
				6'd26 : I2C_BIT <= I2C_WDATA[7];	//Bit8 
				6'd27 : I2C_BIT <= I2C_WDATA[6];	//Bit7
				6'd28 : I2C_BIT <= I2C_WDATA[5];	//Bit6
				6'd29 : I2C_BIT <= I2C_WDATA[4];	//Bit5
				6'd30 : I2C_BIT <= I2C_WDATA[3];	//Bit4
				6'd31 : I2C_BIT <= I2C_WDATA[2];	//Bit3
				6'd32 : I2C_BIT <= I2C_WDATA[1];	//Bit2
				6'd33 : I2C_BIT <= I2C_WDATA[0];	//Bit1
				6'd34 : I2C_BIT <= 0;				//High-Z, Input
				6'd35 : ACKW3 	<= I2C_SDAT;		//ACK3
				6'd36 : I2C_BIT <= 0;				//Delay

				//Stop
				6'd37 : begin	SCLK <= 0; I2C_BIT <= 0; end
				6'd38 : SCLK <= 1;	
				6'd39 : begin I2C_BIT <= 1; END <= 1; end 
				default : begin I2C_BIT <= 1; SCLK <= 1; end
				endcase
				end
			else		//I2C Read: {ID-Address + SUB-Address} + {ID-Address + R-Data}
				begin
				case(SD_COUNTER)
				//IDLE
				6'd0 :	begin
						SCLK <= 1;
						I2C_BIT <= 1;
						ACKW1 <= 1; ACKW2 <= 1; ACKW3 <= 1;
						ACKR1 <= 1; ACKR2 <= 1; ACKR3 <= 1; 
						END <= 0;
						end
				//I2C Read1: {ID-Address + SUB-Address}
				//Start
				6'd1 :	begin 
						SCLK <= 1;
						I2C_BIT <= 1;
						ACKR1 <= 1; ACKR2 <= 1; ACKR3 <= 1; 
						END <= 0;
						end
				6'd2  : I2C_BIT <= 0;		//I2C_SDAT = 0
				6'd3  : SCLK <= 0;			//I2C_SCLK = 0
				
				//SLAVE ADDR--ACK1
				6'd4  : I2C_BIT <= I2C_WDATA[23];	//Bit8
				6'd5  : I2C_BIT <= I2C_WDATA[22];	//Bit7
				6'd6  : I2C_BIT <= I2C_WDATA[21];	//Bit6
				6'd7  : I2C_BIT <= I2C_WDATA[20];	//Bit5
				6'd8  : I2C_BIT <= I2C_WDATA[19];	//Bit4
				6'd9  : I2C_BIT <= I2C_WDATA[18];	//Bit3
				6'd10 : I2C_BIT <= I2C_WDATA[17];	//Bit2
				6'd11 : I2C_BIT <= I2C_WDATA[16];	//Bit1
				6'd12 : I2C_BIT <= 0;				//High-Z, Input
				6'd13 : ACKR1 	<= I2C_SDAT;		//ACK1
				6'd14 : I2C_BIT <= 0;				//Delay
				
				//SUB ADDR--ACK2
				6'd15 : I2C_BIT <= I2C_WDATA[15];	//Bit8
				6'd16 : I2C_BIT <= I2C_WDATA[14];	//Bit7
				6'd17 : I2C_BIT <= I2C_WDATA[13];	//Bit6
				6'd18 : I2C_BIT <= I2C_WDATA[12];	//Bit5
				6'd19 : I2C_BIT <= I2C_WDATA[11];	//Bit4
				6'd20 : I2C_BIT <= I2C_WDATA[10];	//Bit3
				6'd21 : I2C_BIT <= I2C_WDATA[9];    //Bit2
				6'd22 : I2C_BIT <= I2C_WDATA[8];	//Bit1
				6'd23 : I2C_BIT <= 0;				//High-Z, Input
				6'd24 : ACKR2 	<= I2C_SDAT;		//ACK2
				6'd25 : I2C_BIT <= 0;				//Delay

				//Stop
				6'd26 : begin	SCLK <= 0; I2C_BIT <= 0; end
				6'd27 : SCLK <= 1;	
				6'd28 : begin I2C_BIT <= 1; /*END <= 1;*/end 

				//I2C Read2: {ID-Address + R-Data}
				//Start
				6'd29 :	begin 
						SCLK <= 1;
						I2C_BIT <= 1;
						end
				6'd30 : I2C_BIT <= 0;		//I2C_SDAT = 0
				6'd31 : SCLK <= 0;			//I2C_SCLK = 0
				
				//SLAVE ADDR--ACK3
				6'd32 : I2C_BIT <= I2C_WDATA[23];	//Bit8
				6'd33 : I2C_BIT <= I2C_WDATA[22];	//Bit7
				6'd34 : I2C_BIT <= I2C_WDATA[21];	//Bit6
				6'd35 : I2C_BIT <= I2C_WDATA[20];	//Bit5
				6'd36 : I2C_BIT <= I2C_WDATA[19];	//Bit4
				6'd37 : I2C_BIT <= I2C_WDATA[18];	//Bit3
				6'd38 : I2C_BIT <= I2C_WDATA[17];	//Bit2
				6'd39 : I2C_BIT <= 1'b1;			//Bit1	Read Data Flag
				6'd40 : I2C_BIT <= 0;				//High-Z, Input
				6'd41 : ACKR3 	<= I2C_SDAT;		//ACK3
				6'd42 : I2C_BIT <= 0;				//Delay
				
				//Read DATA--ACK4
				6'd43 : I2C_BIT 	<= 0;			//Delay
				6'd44 : I2C_BIT 	<= 0;			//High-Z, Input
				6'd45 : I2C_RDATA[7] <= I2C_SDAT;	//Bit8	, Input
				6'd46 : I2C_RDATA[6] <= I2C_SDAT;	//Bit7	, Input 
				6'd47 : I2C_RDATA[5] <= I2C_SDAT;	//Bit6	, Input 
				6'd48 : I2C_RDATA[4] <= I2C_SDAT;	//Bit5	, Input 
				6'd49 : I2C_RDATA[3] <= I2C_SDAT;	//Bit4	, Input 
				6'd50 : I2C_RDATA[2] <= I2C_SDAT;	//Bit3	, Input 
				6'd51 : I2C_RDATA[1] <= I2C_SDAT;	//Bit2	, Input 
				6'd52 : I2C_RDATA[0] <= I2C_SDAT;	//Bit1	, Input 	
				6'd53 : I2C_BIT 	<= 1;			//Output //ACK4 NACK
				6'd54 : I2C_BIT 	<= 0;			//Delay
				
				//Stop
				6'd55 : begin	SCLK <= 0; I2C_BIT <= 0; end
				6'd56 : SCLK <= 1;	
				6'd57 : begin I2C_BIT <= 1; END <= 1; end 
				default : begin I2C_BIT <= 1; SCLK <= 1; end
				endcase
				end
			end
		else
			begin
			SCLK <= 1;
			I2C_BIT <= 1; 
			ACKW1 <= 1; ACKW2 <= 1; ACKW3 <= 1; 
			ACKR1 <= 1; ACKR2 <= 1; ACKR3 <= 1;
			END <= 0;
			I2C_RDATA <= I2C_RDATA;
			end
		end
end
		
endmodule



module	I2C_OV7670_RGB565_Config
(
	input		[7:0]	LUT_INDEX,
	output	reg	[15:0]	LUT_DATA)
;


parameter	Read_DATA	=	0;			//Read data LUT Address
parameter	SET_OV7670	=	2;			//SET_OV LUT Adderss
/////////////////////	Config Data LUT	  //////////////////////////	
always@(*)
begin
	case(LUT_INDEX)
	
    SET_OV7670 + 0 	: 	LUT_DATA	= 	16'h1214;	
    	SET_OV7670 + 1 	: 	LUT_DATA	= 	16'h40d0;	
    	SET_OV7670 + 2 	: 	LUT_DATA	= 	16'h3a04;	
    	SET_OV7670 + 3 	: 	LUT_DATA	=	16'h3dc8;
    	SET_OV7670 + 4 	: 	LUT_DATA	= 	16'h1e31;	
    	SET_OV7670 + 5 	: 	LUT_DATA	= 	16'h6b00;	
    	SET_OV7670 + 6 	: 	LUT_DATA	= 	16'h32b6;	
    	SET_OV7670 + 7 	: 	LUT_DATA	= 	16'h1713;	 
    	SET_OV7670 + 8 	: 	LUT_DATA	= 	16'h1801;	
    	SET_OV7670 + 9 	: 	LUT_DATA	= 	16'h1902;	
    	SET_OV7670 + 10	: 	LUT_DATA	= 	16'h1a7a;	
    	SET_OV7670 + 11	: 	LUT_DATA	= 	16'h030a;	
    	SET_OV7670 + 12 : 	LUT_DATA	= 	16'h0c00;
    	SET_OV7670 + 13 : 	LUT_DATA	= 	16'h3e00;
    	SET_OV7670 + 14 : 	LUT_DATA	= 	16'h7000;	
    	SET_OV7670 + 15 : 	LUT_DATA	= 	16'h7100;
    	SET_OV7670 + 16 : 	LUT_DATA	= 	16'h7211;	        
    	SET_OV7670 + 17 : 	LUT_DATA	= 	16'h7300;	
    	SET_OV7670 + 18 : 	LUT_DATA	= 	16'ha202;	
    	SET_OV7670 + 19 : 	LUT_DATA	= 	16'h1180;	
    	SET_OV7670 + 20 : 	LUT_DATA	= 	16'h7a20;
    	SET_OV7670 + 21 : 	LUT_DATA	= 	16'h7b1c;
    	SET_OV7670 + 22 : 	LUT_DATA	= 	16'h7c28;
    	SET_OV7670 + 23 : 	LUT_DATA	= 	16'h7d3c;
    	SET_OV7670 + 24 : 	LUT_DATA	= 	16'h7e55;
    	SET_OV7670 + 25 : 	LUT_DATA	= 	16'h7f68;
    	SET_OV7670 + 26 : 	LUT_DATA	= 	16'h8076;
    	SET_OV7670 + 27 : 	LUT_DATA	= 	16'h8180;
    	SET_OV7670 + 28 : 	LUT_DATA	= 	16'h8288;
    	SET_OV7670 + 29 : 	LUT_DATA	= 	16'h838f;
    	SET_OV7670 + 30 : 	LUT_DATA	= 	16'h8496;
    	SET_OV7670 + 31 : 	LUT_DATA	= 	16'h85a3;
    	SET_OV7670 + 32 : 	LUT_DATA	= 	16'h86af;
    	SET_OV7670 + 33 : 	LUT_DATA	= 	16'h87c4;
    	SET_OV7670 + 34 : 	LUT_DATA	= 	16'h88d7;
    	SET_OV7670 + 35 : 	LUT_DATA	= 	16'h89e8;
    	SET_OV7670 + 36 : 	LUT_DATA	= 	16'h13e0;
    	SET_OV7670 + 37 : 	LUT_DATA	= 	16'h0000;
    	SET_OV7670 + 38 : 	LUT_DATA	= 	16'h1000;
    	SET_OV7670 + 39 : 	LUT_DATA	= 	16'h0d00;
    	SET_OV7670 + 40 : 	LUT_DATA	= 	16'h1428;	
    	SET_OV7670 + 41 : 	LUT_DATA	= 	16'ha505;
    	SET_OV7670 + 42 : 	LUT_DATA	= 	16'hab07;
    	SET_OV7670 + 43 : 	LUT_DATA	= 	16'h2475;
    	SET_OV7670 + 44 : 	LUT_DATA	= 	16'h2563;
    	SET_OV7670 + 45 : 	LUT_DATA	= 	16'h26a5;
    	SET_OV7670 + 46 : 	LUT_DATA	= 	16'h9f78;
    	SET_OV7670 + 47 : 	LUT_DATA	= 	16'ha068;
    	SET_OV7670 + 48 : 	LUT_DATA	= 	16'ha103;
    	SET_OV7670 + 49 : 	LUT_DATA	= 	16'ha6df;
    	SET_OV7670 + 50 : 	LUT_DATA	= 	16'ha7df;
    	SET_OV7670 + 51 : 	LUT_DATA	= 	16'ha8f0;
    	SET_OV7670 + 52 : 	LUT_DATA	= 	16'ha990;
    	SET_OV7670 + 53 : 	LUT_DATA	= 	16'haa94;
    	SET_OV7670 + 54 : 	LUT_DATA	= 	16'h13ef;	
    	SET_OV7670 + 55	: 	LUT_DATA	= 	16'h0e61;
    	SET_OV7670 + 56	: 	LUT_DATA	= 	16'h0f4b;
    	SET_OV7670 + 57	: 	LUT_DATA	= 	16'h1602;
    
    	
    	SET_OV7670 + 58 : 	LUT_DATA	= 	16'h2102;
    	SET_OV7670 + 59 : 	LUT_DATA	= 	16'h2291;
    	SET_OV7670 + 60 : 	LUT_DATA	= 	16'h2907;
    	SET_OV7670 + 61 : 	LUT_DATA	= 	16'h330b;
    	SET_OV7670 + 62 : 	LUT_DATA	= 	16'h350b;
    	SET_OV7670 + 63 : 	LUT_DATA	= 	16'h371d;
    	SET_OV7670 + 64 : 	LUT_DATA	= 	16'h3871;
    	SET_OV7670 + 65 : 	LUT_DATA	= 	16'h392a;
    	SET_OV7670 + 66 : 	LUT_DATA	= 	16'h3c78;
    	SET_OV7670 + 67 : 	LUT_DATA	= 	16'h4d40;
    	SET_OV7670 + 68	: 	LUT_DATA	= 	16'h4e20;
    	SET_OV7670 + 69	: 	LUT_DATA	= 	16'h6900;
    	
    	SET_OV7670 + 70 : 	LUT_DATA	= 	16'h7419;
    	SET_OV7670 + 71 : 	LUT_DATA	= 	16'h8d4f;
    	SET_OV7670 + 72 : 	LUT_DATA	= 	16'h8e00;
    	SET_OV7670 + 73 : 	LUT_DATA	= 	16'h8f00;
    	SET_OV7670 + 74 : 	LUT_DATA	= 	16'h9000;
    	SET_OV7670 + 75 : 	LUT_DATA	= 	16'h9100;
    	SET_OV7670 + 76 : 	LUT_DATA	= 	16'h9200;
    	SET_OV7670 + 77 : 	LUT_DATA	= 	16'h9600;
    	SET_OV7670 + 78 : 	LUT_DATA	= 	16'h9a80;
    	SET_OV7670 + 79 : 	LUT_DATA	= 	16'hb084;
    	SET_OV7670 + 80 : 	LUT_DATA	= 	16'hb10c;
    	SET_OV7670 + 81 : 	LUT_DATA	= 	16'hb20e;
    	SET_OV7670 + 82 : 	LUT_DATA	= 	16'hb382;
    	SET_OV7670 + 83	: 	LUT_DATA	= 	16'hb80a;
    
    	SET_OV7670 + 84  :	LUT_DATA	=	16'h4314;
    	SET_OV7670 + 85  :	LUT_DATA	=	16'h44f0;
    	SET_OV7670 + 86  :	LUT_DATA	=	16'h4534;
    	SET_OV7670 + 87  :	LUT_DATA	=	16'h4658;
    	SET_OV7670 + 88  :	LUT_DATA	=	16'h4728;
    	SET_OV7670 + 89  :	LUT_DATA	=	16'h483a;
    	SET_OV7670 + 90  :	LUT_DATA	=	16'h5988;
    	SET_OV7670 + 91  :	LUT_DATA	=	16'h5a88;
    	SET_OV7670 + 92  :	LUT_DATA	=	16'h5b44;
    	SET_OV7670 + 93  :	LUT_DATA	=	16'h5c67;
    	SET_OV7670 + 94  :	LUT_DATA	=	16'h5d49;
    	SET_OV7670 + 95  :	LUT_DATA	=	16'h5e0e;
    	SET_OV7670 + 96  :	LUT_DATA	=	16'h6404;
    	SET_OV7670 + 97  :	LUT_DATA	=	16'h6520;
    	SET_OV7670 + 98  :	LUT_DATA	=	16'h6605;
    	SET_OV7670 + 99  :	LUT_DATA	=	16'h9404;
    	SET_OV7670 + 100 :	LUT_DATA	=	16'h9508;
    	SET_OV7670 + 101 :	LUT_DATA	=	16'h6c0a;
    	SET_OV7670 + 102 :	LUT_DATA	=	16'h6d55;
    	SET_OV7670 + 103 :	LUT_DATA	=	16'h6e11;
    	SET_OV7670 + 104 :	LUT_DATA	=	16'h6f9f;
    	SET_OV7670 + 105 :	LUT_DATA	=	16'h6a40;
    	SET_OV7670 + 106 :	LUT_DATA	=	16'h0140;
    	SET_OV7670 + 107 :	LUT_DATA	=	16'h0240;
    	SET_OV7670 + 108 :	LUT_DATA	=	16'h13e7;
    	SET_OV7670 + 109 :	LUT_DATA	=	16'h1500;
    	
    	SET_OV7670 + 110 :	LUT_DATA	= 	16'h4f80;
    	SET_OV7670 + 111 :	LUT_DATA	= 	16'h5080;
    	SET_OV7670 + 112 :	LUT_DATA	= 	16'h5100;
    	SET_OV7670 + 113 :	LUT_DATA	= 	16'h5222;
    	SET_OV7670 + 114 :	LUT_DATA	= 	16'h535e;
    	SET_OV7670 + 115 :	LUT_DATA	= 	16'h5480;
    	SET_OV7670 + 116 :	LUT_DATA	= 	16'h589e;
    	
    	SET_OV7670 + 117 : 	LUT_DATA	=	16'h4108;
    	SET_OV7670 + 118 : 	LUT_DATA	=	16'h3f00;
    	SET_OV7670 + 119 : 	LUT_DATA	=	16'h7505;
    	SET_OV7670 + 120 : 	LUT_DATA	=	16'h76e1;
    	SET_OV7670 + 121 : 	LUT_DATA	=	16'h4c00;
    	SET_OV7670 + 122 : 	LUT_DATA	=	16'h7701;
    	
    	SET_OV7670 + 123 : 	LUT_DATA	=	16'h4b09;
    	SET_OV7670 + 124 : 	LUT_DATA	=	16'hc9F0;
    	SET_OV7670 + 125 : 	LUT_DATA	=	16'h4138;
    	SET_OV7670 + 126 : 	LUT_DATA	=	16'h5640;
    	
    	
    	SET_OV7670 + 127 : 	LUT_DATA	=	16'h3411;
    	SET_OV7670 + 128 : 	LUT_DATA	=	16'h3b02;
    	SET_OV7670 + 129 : 	LUT_DATA	=	16'ha489;
    	SET_OV7670 + 130 : 	LUT_DATA	=	16'h9600;
    	SET_OV7670 + 131 : 	LUT_DATA	=	16'h9730;
    	SET_OV7670 + 132 : 	LUT_DATA	=	16'h9820;
    	SET_OV7670 + 133 : 	LUT_DATA	=	16'h9930;
    	SET_OV7670 + 134 : 	LUT_DATA	=	16'h9a84;
    	SET_OV7670 + 135 : 	LUT_DATA	=	16'h9b29;
    	SET_OV7670 + 136 : 	LUT_DATA	=	16'h9c03;
    	SET_OV7670 + 137 : 	LUT_DATA	=	16'h9d4c;
    	SET_OV7670 + 138 : 	LUT_DATA	=	16'h9e3f;
    	SET_OV7670 + 139 : 	LUT_DATA	=	16'h7804;
    	
    	
    	SET_OV7670 + 140 :	LUT_DATA	=	16'h7901;
    	SET_OV7670 + 141 :	LUT_DATA	= 	16'hc8f0;
    	SET_OV7670 + 142 :	LUT_DATA	= 	16'h790f;
    	SET_OV7670 + 143 :	LUT_DATA	= 	16'hc800;
    	SET_OV7670 + 144 :	LUT_DATA	= 	16'h7910;
    	SET_OV7670 + 145 :	LUT_DATA	= 	16'hc87e;
    	SET_OV7670 + 146 :	LUT_DATA	= 	16'h790a;
    	SET_OV7670 + 147 :	LUT_DATA	= 	16'hc880;
    	SET_OV7670 + 148 :	LUT_DATA	= 	16'h790b;
    	SET_OV7670 + 149 :	LUT_DATA	= 	16'hc801;
    	SET_OV7670 + 150 :	LUT_DATA	= 	16'h790c;
    	SET_OV7670 + 151 :	LUT_DATA	= 	16'hc80f;
    	SET_OV7670 + 152 :	LUT_DATA	= 	16'h790d;
    	SET_OV7670 + 153 :	LUT_DATA	= 	16'hc820;
    	SET_OV7670 + 154 :	LUT_DATA	= 	16'h7909;
    	SET_OV7670 + 155 :	LUT_DATA	= 	16'hc880;
    	SET_OV7670 + 156 :	LUT_DATA	= 	16'h7902;
    	SET_OV7670 + 157 :	LUT_DATA	= 	16'hc8c0;
    	SET_OV7670 + 158 :	LUT_DATA	= 	16'h7903;
    	SET_OV7670 + 159 :	LUT_DATA	= 	16'hc840;
    	SET_OV7670 + 160 :	LUT_DATA	= 	16'h7905;
    	SET_OV7670 + 161 :	LUT_DATA	= 	16'hc830; 
    	SET_OV7670 + 162 :	LUT_DATA	= 	16'h7926;
    	
    	SET_OV7670 + 163 :	LUT_DATA	= 	16'h0903;
    	SET_OV7670 + 164 :	LUT_DATA	= 	16'h3b42;
        

	default		 :	LUT_DATA	=	0;
	endcase
end

endmodule

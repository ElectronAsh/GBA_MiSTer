//
// S-3511A RTC chip logic.
//
// ElectronAsh, 17-1-20.
//
//
//
module s3511_rtc (
	input clock,
	input reset_n,
	
	input cs,
	input sck,
	
	input din,
	output reg dout,
	
	input [7:0] year,
	input [4:0] month,
	input [5:0] day,
	input [2:0] dow,	// (day of week).
	
	input pm,
	input [5:0] hour,
	
	input [6:0] minute,
	
	input test,
	input [6:0] second,
	
	output reg int_n
);

reg cs_old;
reg sck_old;

reg [7:0] status_reg;

// cmd_reg bits.
//
// Note: The command byte is input MSB-first, but the "real-time" regs are input LSB-first! ElectronAsh.
//
// Bits [7:4] are a fixed pattern, then the 3-bit cmd, then the RnW flag.
//
// 7  6  5  4  3  2  1  0
// ------------------------
// 0  1  1  0  C2 C2 C0 RnW
//
// C2:C1:C0
//
//  0: 0: 0 = Reset (00 year, 01 month, 01 day, 0 day-of-week, 00 minute, 00 second.)
//  0: 0: 1 = Status reg access.
//  0: 1: 0 = Real-time data access 1 (year data to)
//  0: 1: 1 = Real-time data access 2 (hour data to) 
//  1: 0: 0 = Alarm time / frequency duty setting 1
//  1: 0: 1 = Alarm time / frequency duty setting 2
//  1: 1: 0 = Test mode start.
//  1: 1: 1 = Test mode end.
//

reg [7:0] input_reg;
reg [7:0] cmd_reg;

reg [2:0] bit_cnt;
reg [2:0] reg_addr;


reg [7:0] year_reg;
reg [4:0] month_reg;
reg [5:0] day_reg;
reg [2:0] dow_reg;
reg pm_reg;
reg [6:0] hour_reg;
reg [6:0] minute_reg;
reg [6:0] second_reg;
reg test_reg;


reg [7:0] int_reg;	// (Alarm reg.)
							// Gets compared to the Hours (with PM flag), and Minutes regs to trigger the alarm.

always @(posedge clock or negedge reset_n)
if (!reset_n) begin

end
else begin
	cs_old <= cs;
	sck_old <= sck;

	if (!cs_old & cs) begin	// Rising edge of cs resets the bit count and reg address.
		bit_cnt  <= 3'd0;
		reg_addr <= 3'd0;
	end
	else begin
		if (cs & (!sck_old & sck) ) begin	// cs==HIGH, and the rising edge of sck clocks a bit in.
			
			if (reg_addr==0) input_reg <= {input_reg[6:0], din};	// Commands are MSB-first.
			else input_reg <= {din, input_reg[7:1]};					// Data is LSB-first.
			
			bit_cnt <= bit_cnt + 3'd1;

			if (bit_cnt==3'd7) begin							
				case (reg_addr)
					0: cmd_reg						<= input_reg;
					1: year_reg						<= input_reg;
					2: month_reg					<= input_reg[4:0];
					3: day_reg						<= input_reg[5:0];
					4: dow_reg						<= input_reg[2:0];
					5: {pm_reg, hour_reg}		<= input_reg;
					6: minute_reg					<= input_reg[6:0];
					7: {test_reg, second_reg}	<= input_reg;
					default;
				endcase
				
				if (reg_addr==0 && input_reg[3:1]==3'b011) reg_addr <= 3'd5;	// Command is "Real-time data access 2 (hour data to)", Skip to the hour register.
				else reg_addr <= reg_addr + 1;
			end
		end
	end
end



endmodule

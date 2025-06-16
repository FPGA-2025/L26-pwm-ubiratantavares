module PWM (
    input wire clk,
    input wire rst_n,
    input wire [15:0] duty_cycle, // duty_cycle = period * duty_porcent, 0 <= duty_porcent <= 1
    input wire [15:0] period, // clk_freq / pwm_freq = period
    output reg pwm_out
);

	reg [15:0] pwm_counter;

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin // reset assíncrono, ativo em nível baixo
			pwm_counter <= 16'h0;
			pwm_out <= 1'b0;			
		end else begin
			// lógica de contagem
			pwm_counter <= (pwm_counter >= (period - 1)) ? 16'h0 : pwm_counter + 1; 
			// gera sinal PWM
			pwm_out <= (pwm_counter < duty_cycle) ? 1'b1 : 1'b0; 
		end
	end
endmodule

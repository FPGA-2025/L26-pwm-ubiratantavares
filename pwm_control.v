module PWM_Control #(
    parameter CLK_FREQ = 25_000_000,
    parameter PWM_FREQ = 1_250
) (
    input  wire clk,
    input  wire rst_n,
    output wire [7:0] leds
);
    localparam integer PWM_CLK_PERIOD = CLK_FREQ / PWM_FREQ; // número de ciclos de clock por período PWM: 25_000_000 Hz/1_250 Hz = 20_000 ciclos
    localparam integer PWM_DUTY_CYCLE = 50; // 0.0025% duty cycle

    localparam SECOND         = CLK_FREQ;
    localparam HALF_SECOND    = SECOND / 2;
    localparam QUARTER_SECOND = SECOND / 4;
    localparam EIGHTH_SECOND  = SECOND / 8;

	// limites de contagem para o ciclo de trabalho PWM, baseados nas porcentagens especificadas
	// 0.0025% de 20_000 ciclos = 0.5, arredondado para 1 para valor inteiro mínimo
	localparam integer MIN_PWM_DUTY_COUNT = 1;

	// 70% DE 20_000 ciclos = 14_000
	localparam integer MAX_PWM_DUTY_COUNT = PWM_CLK_PERIOD * 70 / 100;

	// define o passo de incremento/decremento para o ciclo de trabalho durante o fade
	// o valor (MAX - MIN) dividido por 200 passos proporciona uma transição suave
	localparam integer FADE_STEP = (MAX_PWM_DUTY_COUNT - MIN_PWM_DUTY_COUNT) / 200;

	// contador para o período PWM: 0 até PWM_CLK_PERIOD - 1
	reg [14:0] pwm_period_counter;

	// registrador para armazenar o valor atual do ciclo de trabalho
	reg [14:0] pwm_duty_reg;

	// sinal de saída do PWM antes de ser atribuído aos LEDs
	wire pwm_out;

	// contador para controlar a frequência de atualização do ciclo de trabalho do fade: conta até EIGHTH_SECOND - 1
	reg [21:0] fade_timer_counter;

	// flag para indicar a direção do efeito de fade (aumentando ou diminuindo o brilho)
	// 0: aumentando (fade-in)
	// 1: diminuindo (fade-out
	reg fade_direction;

	// bloco que controla o contador principal do período PWM
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) // reset assíncrono, ativo em nível baixo
			pwm_period_counter <= 0; // reinicia o contador do PWM
		else
			// incrementa o contador de ciclos do PWM
			pwm_period_counter <= (pwm_period_counter == (PWM_CLK_PERIOD - 1)) ? 0 : pwm_period_counter + 1;
	end

	// gera sinal PWM
	assign pwm_out = (pwm_period_counter < pwm_duty_reg);

	// atribui o sinal PWM a todos os 8 LEDs de saída
	assign leds = {8{pwm_out}};

    // gerencia o 'pwm_duty_reg' ao longo do tempo para criar o efeito de fade
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin // Reset assíncrono 
            fade_timer_counter <= 0;           // Reinicia o contador de tempo do fade
            fade_direction <= 0;               // Começa no modo fade-in (aumentando o brilho)
            pwm_duty_reg <= MIN_PWM_DUTY_COUNT; // Inicializa o brilho dos LEDs no mínimo [2]
        end else begin
            // Incrementa o contador de tempo para o fade. Quando atinge o limite do EIGHTH_SECOND, atualiza o ciclo de trabalho.
            if (fade_timer_counter == EIGHTH_SECOND - 1) begin
                fade_timer_counter <= 0; // Reinicia o contador de tempo do fade

                // Verifica a direção do fade e ajusta 'pwm_duty_reg'
                if (fade_direction == 0) begin // Modo fade-in (aumentando o brilho)
                    // Se a próxima etapa exceder o máximo, define para o máximo e inverte a direção
                    if (pwm_duty_reg + FADE_STEP >= MAX_PWM_DUTY_COUNT) begin
                        pwm_duty_reg <= MAX_PWM_DUTY_COUNT;
                        fade_direction <= 1; // Muda para fade-out
                    end else begin
                        pwm_duty_reg <= pwm_duty_reg + FADE_STEP; // Aumenta o brilho
                    end
                end else begin // Modo fade-out (diminuindo o brilho)
                    // Se a próxima etapa ficar abaixo do mínimo, define para o mínimo e inverte a direção
                    if (pwm_duty_reg - FADE_STEP <= MIN_PWM_DUTY_COUNT) begin
                        pwm_duty_reg <= MIN_PWM_DUTY_COUNT;
                        fade_direction <= 0; // Muda para fade-in
                    end else begin
                        pwm_duty_reg <= pwm_duty_reg - FADE_STEP; // Diminui o brilho
                    end
                end
            end else begin
                fade_timer_counter <= fade_timer_counter + 1; // Continua contando para a próxima atualização do fade
            end
        end
    end
endmodule

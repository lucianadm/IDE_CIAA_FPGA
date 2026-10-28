module secuencia_leds #(
    parameter integer CICLOS_POR_PASO = 3_000_000
) (
    input  wire clk12,
    output wire LED0,
    output wire LED1,
    output wire LED2,
    output wire LED3
);
    reg [21:0] contador = 0;
    reg [2:0] paso = 0;
    reg [3:0] patron = 4'b0001;

    always @(posedge clk12) begin
        if (contador == CICLOS_POR_PASO - 1) begin
            contador <= 0;
            paso <= (paso == 5) ? 0 : paso + 1'b1;
        end else contador <= contador + 1'b1;
    end

    always @(*) begin
        case (paso)
            0: patron = 4'b0001;
            1: patron = 4'b0010;
            2: patron = 4'b0100;
            3: patron = 4'b1000;
            4: patron = 4'b0100;
            default: patron = 4'b0010;
        endcase
    end
    assign {LED3, LED2, LED1, LED0} = patron;
endmodule

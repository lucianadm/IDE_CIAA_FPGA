module botones_leds_verilog #(
    parameter integer CICLOS_POR_PASO = 3_000_000
) (
    input  wire clk12,
    input  wire BTN1,
    input  wire BTN2,
    input  wire BTN3,
    input  wire BTN4,
    output wire LED0,
    output wire LED1,
    output wire LED2,
    output wire LED3
);
    reg [3:0] botones_meta = 4'b1111;
    reg [3:0] botones_sync = 4'b1111;
    reg [2:0] modo_anterior = 0;
    reg [21:0] contador = 0;
    reg [3:0] paso = 0;
    reg [3:0] patron;
    wire [2:0] modo = !botones_sync[3] ? 4 :
                           !botones_sync[2] ? 3 :
                           !botones_sync[1] ? 2 :
                           !botones_sync[0] ? 1 : 0;

    always @(posedge clk12) begin
        botones_meta <= {BTN4, BTN3, BTN2, BTN1};
        botones_sync <= botones_meta;

        if (modo != modo_anterior) begin
            modo_anterior <= modo;
            contador <= 0;
            paso <= 0;
        end else if (contador == CICLOS_POR_PASO - 1) begin
            contador <= 0;
            paso <= paso + 1'b1;
        end else begin
            contador <= contador + 1'b1;
        end
    end

    always @(*) begin
        case (modo)
            1: begin
                case (paso[1:0])
                    0: patron = 4'b0001; 1: patron = 4'b0010;
                    2: patron = 4'b0100; default: patron = 4'b1000;
                endcase
            end
            2: begin
                case (paso[1:0])
                    0: patron = 4'b1000; 1: patron = 4'b0100;
                    2: patron = 4'b0010; default: patron = 4'b0001;
                endcase
            end
            3: patron = paso;
            4: patron = paso[0] ? 4'b1010 : 4'b0101;
            default: begin
                case (paso % 6)
                    0: patron = 4'b0001; 1: patron = 4'b0010; 2: patron = 4'b0100;
                    3: patron = 4'b1000; 4: patron = 4'b0100; default: patron = 4'b0010;
                endcase
            end
        endcase
    end

    assign {LED3, LED2, LED1, LED0} = patron;
endmodule

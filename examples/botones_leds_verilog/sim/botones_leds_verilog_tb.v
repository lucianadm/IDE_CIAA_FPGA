`timescale 1ns/1ps
module botones_leds_verilog_tb;
    localparam integer CICLOS = 8;
    reg clk12 = 0;
    reg [3:0] btn = 4'b1111;
    wire LED0, LED1, LED2, LED3;
    wire [3:0] leds = {LED3, LED2, LED1, LED0};

    botones_leds_verilog #(.CICLOS_POR_PASO(CICLOS)) dut (
        .clk12(clk12),
        .BTN1(btn[0]), .BTN2(btn[1]), .BTN3(btn[2]), .BTN4(btn[3]),
        .LED0(LED0), .LED1(LED1), .LED2(LED2), .LED3(LED3)
    );
    always #10 clk12 = ~clk12;

    task esperar_relojes;
        input integer cantidad;
        integer i;
        begin
            for (i = 0; i < cantidad; i = i + 1) @(posedge clk12);
            #1;
        end
    endtask

    task seleccionar;
        input [3:0] botones;
        begin
            @(negedge clk12);
            btn = botones;
            esperar_relojes(4);
        end
    endtask

    task comprobar;
        input [3:0] esperado;
        begin
            if (leds !== esperado) begin
                $display("ERROR: esperado %b, recibido %b", esperado, leds);
                $fatal(1);
            end
            esperar_relojes(CICLOS);
        end
    endtask

    initial begin
        $dumpfile("botones_leds_verilog.vcd");
        $dumpvars(0, botones_leds_verilog_tb);
        esperar_relojes(2);

        seleccionar(4'b1110);
        comprobar(4'b0001); comprobar(4'b0010); comprobar(4'b0100); comprobar(4'b1000);

        seleccionar(4'b1101);
        comprobar(4'b1000); comprobar(4'b0100); comprobar(4'b0010); comprobar(4'b0001);

        seleccionar(4'b1011);
        comprobar(4'b0000); comprobar(4'b0001); comprobar(4'b0010); comprobar(4'b0011);

        seleccionar(4'b0111);
        comprobar(4'b0101); comprobar(4'b1010); comprobar(4'b0101); comprobar(4'b1010);

        seleccionar(4'b1111);
        comprobar(4'b0001); comprobar(4'b0010); comprobar(4'b0100); comprobar(4'b1000);

        $display("Todos los modos Verilog fueron comprobados");
        $finish;
    end
endmodule

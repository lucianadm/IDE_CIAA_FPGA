`timescale 1ns/1ps
module secuencia_leds_tb;
    reg clk12 = 0;
    wire LED0, LED1, LED2, LED3;
    wire [3:0] leds = {LED3, LED2, LED1, LED0};

    secuencia_leds #(.CICLOS_POR_PASO(3)) dut (
        .clk12(clk12), .LED0(LED0), .LED1(LED1), .LED2(LED2), .LED3(LED3)
    );
    always #10 clk12 = ~clk12;

    task comprobar;
        input [3:0] esperado;
        begin
            if (leds !== esperado) begin
                $display("ERROR: esperado %b, recibido %b", esperado, leds);
                $fatal(1);
            end
            #60;
        end
    endtask

    initial begin
        $dumpfile("secuencia_leds.vcd");
        $dumpvars(0, secuencia_leds_tb);
        #11;
        comprobar(4'b0001); comprobar(4'b0010); comprobar(4'b0100);
        comprobar(4'b1000); comprobar(4'b0100); comprobar(4'b0010); comprobar(4'b0001);
        $display("Secuencia Verilog comprobada");
        $finish;
    end
endmodule

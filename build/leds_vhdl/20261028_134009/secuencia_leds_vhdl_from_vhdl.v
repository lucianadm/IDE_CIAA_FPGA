module secuencia_leds_vhdl
  (input  clk12,
   output LED0,
   output LED1,
   output LED2,
   output LED3);
  reg [21:0] contador;
  reg [2:0] paso;
  wire [3:0] patron;
  wire [31:0] n9;
  wire n11;
  wire [31:0] n12;
  wire n14;
  wire [31:0] n15;
  wire [31:0] n17;
  wire [2:0] n18;
  wire [2:0] n20;
  wire [31:0] n21;
  wire [31:0] n23;
  wire [21:0] n24;
  wire [21:0] n26;
  wire n33;
  wire n36;
  wire n39;
  wire n42;
  wire n45;
  wire [4:0] n47;
  reg [3:0] n48;
  wire n49;
  wire n50;
  wire n51;
  wire n52;
  reg [21:0] n53;
  wire [2:0] n54;
  reg [2:0] n55;
  assign LED0 = n49; //(module output)
  assign LED1 = n50; //(module output)
  assign LED2 = n51; //(module output)
  assign LED3 = n52; //(module output)
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:16:12 */
  always @*
    contador = n53; // (isignal)
  initial
    contador = 22'b0000000000000000000000;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:17:12 */
  always @*
    paso = n55; // (isignal)
  initial
    paso = 3'b000;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:18:12 */
  assign patron = n48; // (signal)
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:23:25 */
  assign n9 = {10'b0, contador};  // uext
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:23:25 */
  assign n11 = n9 == 32'b00000000001011011100011010111111;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:25:25 */
  assign n12 = {29'b0, paso};  // uext
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:25:25 */
  assign n14 = n12 == 32'b00000000000000000000000000000101;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:25:63 */
  assign n15 = {29'b0, paso};  // uext
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:25:63 */
  assign n17 = n15 + 32'b00000000000000000000000000000001;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:25:58 */
  assign n18 = n17[2:0];  // trunc
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:25:17 */
  assign n20 = n14 ? 3'b000 : n18;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:27:38 */
  assign n21 = {10'b0, contador};  // uext
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:27:38 */
  assign n23 = n21 + 32'b00000000000000000000000000000001;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:27:29 */
  assign n24 = n23[21:0];  // trunc
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:23:13 */
  assign n26 = n11 ? 22'b0000000000000000000000 : n24;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:33:16 */
  assign n33 = paso == 3'b000;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:33:31 */
  assign n36 = paso == 3'b001;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:33:46 */
  assign n39 = paso == 3'b010;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:34:16 */
  assign n42 = paso == 3'b011;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:34:31 */
  assign n45 = paso == 3'b100;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:32:5 */
  assign n47 = {n45, n42, n39, n36, n33};
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:32:5 */
  always @*
    case (n47)
      5'b10000: n48 = 4'b0100;
      5'b01000: n48 = 4'b1000;
      5'b00100: n48 = 4'b0100;
      5'b00010: n48 = 4'b0010;
      5'b00001: n48 = 4'b0001;
      default: n48 = 4'b0010;
    endcase
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:35:19 */
  assign n49 = patron[0]; // extract
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:35:38 */
  assign n50 = patron[1]; // extract
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:35:57 */
  assign n51 = patron[2]; // extract
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:35:76 */
  assign n52 = patron[3]; // extract
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:22:9 */
  always @(posedge clk12)
    n53 <= n26;
  initial
    n53 = 22'b0000000000000000000000;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:22:9 */
  assign n54 = n11 ? n20 : paso;
  /*# F:\jose\IDE_CIAA_FPGA\examples\leds_vhdl\src\secuencia_leds_vhdl.vhd:22:9 */
  always @(posedge clk12)
    n55 <= n54;
  initial
    n55 = 3'b000;
endmodule


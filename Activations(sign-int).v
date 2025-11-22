//--------leaky relu modules--------
//--------Arguments: x = input, a = slope parameter, y = output--------

module LRELU_8(
    input  wire signed [7:0] x, a,
    output wire signed [7:0] y 
);
    assign y = (x > 0) ? x : (a * x);
endmodule

module LRELU_16(
    input  wire signed [15:0] x, a,
    output wire signed [15:0] y 
);
    assign y = (x > 0) ? x : (a * x);
endmodule

module LRELU_32(
    input  wire signed [31:0] x, a,
    output wire signed [31:0] y 
);
    assign y = (x > 0) ? x : (a * x);
endmodule

//--------sigmoid linear piecewise modules 3 --------
module sigmoid_8_3(
    input  wire signed [7:0] x,
    output reg  signed [7:0] y
);

always @(*) begin
    if (x > 8'sd2)
        y = 8'sd1;
    else if (x < -8'sd2)
        y = 8'sd0;
    else
        y = ((x >>> 1) + 8'sd1) >>> 1;  // 0.5(0.5 x + 1)
end
endmodule

module sigmoid_16_3(
    input  wire signed [15:0] x,
    output reg  signed [15:0] y
);

always @(*) begin
    if (x > 16'sd2)
        y = 16'sd1;
    else if (x < -16'sd2)
        y = 16'sd0;
    else
        y = ((x >>> 1) + 16'sd1) >>> 1;   // 0.5(0.5 x + 1)
end
endmodule

module sigmoid_32_3(
    input  wire signed [31:0] x,
    output reg  signed [31:0] y
);

always @(*) begin
    if (x > 32'sd2)
        y = 32'sd1;
    else if (x < -32'sd2)
        y = 32'sd0;
    else
        y = ((x >>> 1) + 32'sd1) >>> 1;   // 0.5(0.5 x + 1)
end
endmodule

//--------sigmoid linear piecewise modules 5 segment --------
//--------Arguments: x = input, y = output--------
//--------Ubah integer sesuai format fixed point yang diinginkan--------
module sigmoid_8_5(
    input  wire signed [7:0] x,
    output reg  signed [7:0] y
);

always @(*) begin
    if (x >= (8'sd7 >>> 2))
        y = 8'sd1;
    else if (x <= -(8'sd7 >>> 2))
        y = 8'sd0;
    else if(x > -(8'sd7 >>> 2) && x < -(8'sd3 >>> 2))
        y = ( ((x <<< 1) + 8'sd3) >>> 2 + 8'sd1) >>> 3;  // 0.0625(x + 1.5) + 0.125
    else if(x < (8'sd7 >>> 2) && x > (8'sd3 >>> 2))
        y = ( ((x <<< 1) - 8'sd3) >>> 2 + 8'sd7) >>> 3;  // 0.0625(x - 1.5) + 0.875
    else
        y = ( (x >>> 1) + 8'sd1 ) >>> 1;  // 0.5(0.5 x + 1)
end
endmodule

module sigmoid_16_5(
    input  wire signed [15:0] x,
    output reg  signed [15:0] y
);

always @(*) begin
    if (x >= (16'sd7 >>> 2))
        y = 16'sd1;
    else if (x <= -(16'sd7 >>> 2))
        y = 16'sd0;
    else if(x > -(16'sd7 >>> 2) && x < -(16'sd3 >>> 2))
        y = ( ((x <<< 1) + 16'sd3) >>> 2 + 16'sd1) >>> 3;  // 0.0625(x + 1.5) + 0.125
    else if(x < (16'sd7 >>> 2) && x > (16'sd3 >>> 2))
        y = ( ((x <<< 1) - 16'sd3) >>> 2 + 16'sd7) >>> 3;  // 0.0625(x - 1.5) + 0.875
    else
        y = ( (x >>> 1) + 16'sd1 ) >>> 1;  // 0.5(0.5 x + 1)
end
endmodule

module sigmoid_32_5(
    input  wire signed [31:0] x,
    output reg  signed [31:0] y
);

always @(*) begin
    if (x >= (32'sd7 >>> 2))
        y = 32'sd1;
    else if (x <= -(32'sd7 >>> 2))
        y = 32'sd0;
    else if(x > -(32'sd7 >>> 2) && x < -(32'sd3 >>> 2))
        y = ( ((x <<< 1) + 32'sd3) >>> 2 + 32'sd1) >>> 3;  // 0.0625(x + 1.5) + 0.125 = 1/8*(1/4*(2x+3)+1)
    else if(x < (32'sd7 >>> 2) && x > (32'sd3 >>> 2))
        y = ( ((x <<< 1) - 32'sd3) >>> 2 + 32'sd7) >>> 3;  // 0.0625(x - 1.5) + 0.875
    else
        y = ( (x >>> 1) + 32'sd1 ) >>> 1;  // 0.5(0.5 x + 1)
end
endmodule

//--------tanh linear piecewise modules 5 segment --------
//--------Arguments: x = input, y = output--------
//--------Ubah integer sesuai format fixed point yang diinginkan--------
module tanh_8_5(
    input  wire signed [7:0] x,
    output reg  signed [7:0] y
);

always @(*) begin
    if (x >= (8'sd3 >>> 2))
        y = 8'sd1;
    else if (x <= -(8'sd3 >>> 2))
        y = -8'sd1;
    else if(x > -(8'sd3 >>> 2) && x < -(8'sd1 >>> 2))
        y = ((x <<< 1) + 8'sd1) >>> 2;  // 0.25(2x + 1)
    else if(x < (8'sd3 >>> 2) && x > (8'sd1 >>> 2))
        y = ((x <<< 1) - 8'sd1) >>> 2;  // 0.25(2x - 1)
    else
        y = x;
end
endmodule

module tanh_16_5(
    input  wire signed [15:0] x,
    output reg  signed [15:0] y
);

always @(*) begin
    if (x >= (16'sd3 >>> 2))
        y = 16'sd1;
    else if (x <= -(16'sd3 >>> 2))
        y = -16'sd1;
    else if(x > -(16'sd3 >>> 2) && x < -(16'sd1 >>> 2))
        y = ((x <<< 1) + 16'sd1) >>> 2;  // 0.25(2x + 1)
    else if(x < (16'sd3 >>> 2) && x > (16'sd1 >>> 2))
        y = ((x <<< 1) - 16'sd1) >>> 2;  // 0.25(2x - 1)
    else
        y = x;
end
endmodule

module tanh_32_5(
    input  wire signed [31:0] x,
    output reg  signed [31:0] y
);

always @(*) begin
    if (x >= (32'sd3 >>> 2))
        y = 32'sd1;
    else if (x <= -(32'sd3 >>> 2))
        y = -32'sd1;
    else if(x > -(32'sd3 >>> 2) && x < -(32'sd1 >>> 2))
        y = ((x <<< 1) + 32'sd1) >>> 2;  // 0.25(2x + 1)
    else if(x < (32'sd3 >>> 2) && x > (32'sd1 >>> 2))
        y = ((x <<< 1) - 32'sd1) >>> 2;  // 0.25(2x - 1)
    else
        y = x;
end
endmodule
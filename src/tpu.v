`include "define.v"

module tpu(clk, rst, start, m, k, n, done, wr_en_out, index_a, index_b, index_out, dataout_a, dataout_b, dataout_o);

input clk, rst, start;
input [3:0] m, k, n;
input       [`WORD_SIZE - 1 : 0] dataout_a, dataout_b;
output reg  [`DATA_SIZE - 1 : 0] index_a, index_b;
output reg  [`WORD_SIZE - 1 : 0] dataout_o;
output      [`DATA_SIZE - 1 : 0] index_out;
output reg done;
output reg wr_en_out;

parameter [2:0] ST_INIT     = 3'b000,
                ST_READ     = 3'b001,
                ST_MULADD   = 3'b010,
                ST_OUTPUT   = 3'b011,
                ST_SET     = 3'b100,
                ST_DONE     = 3'b101;

reg [2:0] curr_state, next_state;
reg [`WORD_SIZE - 1 : 0] a [0:11];
reg [`WORD_SIZE - 1 : 0] b [0:11];
reg [4:0] cnt_m;        // output index, add 1 after one output, at most 26
reg [2:0] cnt_4;
reg [4:0] cnt_k;
wire[4:0] cal_round;
reg read, cal, out;
reg [3:0] remain_m;
reg [3:0] remain_n;
integer i;

wire [7:0] h11, h12, h13, h21, h22, h23, h31, h32, h33, h41, h42, h43,
           v11, v12, v13, v14, v21, v22, v23, v24, v31, v32, v33, v34,
           o11, o12, o13, o14, o21, o22, o23, o24,
           o31, o32, o33, o34, o41, o42, o43, o44;
reg [7:0] a1, a2, a3, a4, b1, b2, b3, b4;
reg [7:0]  res11, res12, res13, res14, res21, res22, res23, res24,
           res31, res32, res33, res34, res41, res42, res43, res44;

assign index_out = (cnt_m - 5'h1);
assign cal_round = k + 4'h8;

PE pe11(.clk(clk), .rst(rst), .top_in(b1),  .bot_out(v11), .left_in(a1),  .right_out(h11), .mult(o11));
PE pe12(.clk(clk), .rst(rst), .top_in(b2),  .bot_out(v12), .left_in(h11), .right_out(h12), .mult(o12));
PE pe13(.clk(clk), .rst(rst), .top_in(b3),  .bot_out(v13), .left_in(h12), .right_out(h13), .mult(o13));
PE pe14(.clk(clk), .rst(rst), .top_in(b4),  .bot_out(v14), .left_in(h13), .right_out(),    .mult(o14));
PE pe21(.clk(clk), .rst(rst), .top_in(v11), .bot_out(v21), .left_in(a2),  .right_out(h21), .mult(o21));
PE pe22(.clk(clk), .rst(rst), .top_in(v12), .bot_out(v22), .left_in(h21), .right_out(h22), .mult(o22));
PE pe23(.clk(clk), .rst(rst), .top_in(v13), .bot_out(v23), .left_in(h22), .right_out(h23), .mult(o23));
PE pe24(.clk(clk), .rst(rst), .top_in(v14), .bot_out(v24), .left_in(h23), .right_out(),    .mult(o24));
PE pe31(.clk(clk), .rst(rst), .top_in(v21), .bot_out(v31), .left_in(a3),  .right_out(h31), .mult(o31));
PE pe32(.clk(clk), .rst(rst), .top_in(v22), .bot_out(v32), .left_in(h31), .right_out(h32), .mult(o32));
PE pe33(.clk(clk), .rst(rst), .top_in(v23), .bot_out(v33), .left_in(h32), .right_out(h33), .mult(o33));
PE pe34(.clk(clk), .rst(rst), .top_in(v24), .bot_out(v34), .left_in(h33), .right_out(),    .mult(o34));
PE pe41(.clk(clk), .rst(rst), .top_in(v31), .bot_out(),    .left_in(a4),  .right_out(h41), .mult(o41));
PE pe42(.clk(clk), .rst(rst), .top_in(v32), .bot_out(),    .left_in(h41), .right_out(h42), .mult(o42));
PE pe43(.clk(clk), .rst(rst), .top_in(v33), .bot_out(),    .left_in(h42), .right_out(h43), .mult(o43));
PE pe44(.clk(clk), .rst(rst), .top_in(v34), .bot_out(),    .left_in(h43), .right_out(),    .mult(o44));

always @(*) begin
    case (curr_state)
        ST_INIT : begin
            read = 1'b0; cal = 1'b0; done = 1'b0; out = 1'b0; wr_en_out = 1'b0; 
        end
        ST_READ : begin
            read = 1'b1; cal = 1'b0; done = 1'b0; out = 1'b0; wr_en_out = 1'b0;
        end
        ST_MULADD : begin
            read = 1'b0; cal = 1'b1; done = 1'b0; out = 1'b0; wr_en_out = 1'b0;
        end
        ST_OUTPUT : begin
            read = 1'b0; cal = 1'b0; done = 1'b0; out = 1'b1;
            wr_en_out = (cnt_4 > 3'h0 && cnt_4 <= 3'h4) ? 1'b1 : 1'b0;
        end
        ST_SET : begin
            read = 1'b0; cal = 1'b0; done = 1'b0; out = 1'b0; wr_en_out = 1'b0;
        end
        ST_DONE : begin
            read = 1'b0; cal = 1'b0; done = 1'b1; out = 1'b0; wr_en_out = 1'b0;
        end
        default : begin
            read = 1'b0; cal = 1'b0; done = 1'b0; out = 1'b0; wr_en_out = 1'b0;
        end
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst)
        curr_state <= ST_INIT;
    else
        curr_state <= next_state;
end

always @(*) begin
    case (curr_state)
        ST_INIT : begin
            next_state = (start) ? ST_READ : ST_INIT;
        end
        ST_READ : begin
            next_state = (cnt_k == k) ? ST_MULADD : ST_READ;
        end
        ST_MULADD : begin
            next_state = (cnt_k < cal_round) ? ST_MULADD : ST_OUTPUT;
        end
        ST_OUTPUT : begin
            if (remain_m < 4'h4) begin
                next_state = (cnt_4 == remain_m) ? ST_SET : ST_OUTPUT;
            end
            else begin
                next_state = (cnt_4 == 3'h4) ? ST_SET : ST_OUTPUT;
            end
        end
        ST_SET : begin
            next_state = (remain_m < 4'h4 && remain_n < 4'h4) ? ST_DONE : ST_READ;
        end
        ST_DONE : begin
            next_state = ST_DONE;
        end
        default : begin
            next_state = ST_INIT;
        end
    endcase
end

// OUTPUT
always @(posedge clk or posedge rst) begin
    if (rst) begin
        res11 <= 8'h0; res12 <= 8'h0; res13 <= 8'h0; res14 <= 8'h0;
        res21 <= 8'h0; res22 <= 8'h0; res23 <= 8'h0; res24 <= 8'h0;
        res31 <= 8'h0; res32 <= 8'h0; res33 <= 8'h0; res34 <= 8'h0;
        res41 <= 8'h0; res42 <= 8'h0; res43 <= 8'h0; res44 <= 8'h0;
    end
    else if (read) begin
        res11 <= 8'h0; res12 <= 8'h0; res13 <= 8'h0; res14 <= 8'h0;
        res21 <= 8'h0; res22 <= 8'h0; res23 <= 8'h0; res24 <= 8'h0;
        res31 <= 8'h0; res32 <= 8'h0; res33 <= 8'h0; res34 <= 8'h0;
        res41 <= 8'h0; res42 <= 8'h0; res43 <= 8'h0; res44 <= 8'h0;
    end
    else if (out) begin
        case (cnt_4)
            2'h0 : dataout_o <= {res14, res13, res12, res11}; 
            2'h1 : dataout_o <= {res24, res23, res22, res21}; 
            2'h2 : dataout_o <= {res34, res33, res32, res31}; 
            2'h3 : dataout_o <= {res44, res43, res42, res41}; 
            default: dataout_o  <= 32'h0;
        endcase
    end
    else if (cal) begin
         res11 <= res11 + o11; res12 <= res12 + o12; res13 <= res13 + o13; res14 <= res14 + o14;
         res21 <= res21 + o21; res22 <= res22 + o22; res23 <= res23 + o23; res24 <= res24 + o24;
         res31 <= res31 + o31; res32 <= res32 + o32; res33 <= res33 + o33; res34 <= res34 + o34;
         res41 <= res41 + o41; res42 <= res42 + o42; res43 <= res43 + o43; res44 <= res44 + o44;
    end
    else begin
        dataout_o       <= 32'h0;
        res11 <= res11 + 8'h0; res12 <= res12 + 8'h0; res13 <= res13 + 8'h0; res14 <= res14 + 8'h0;
        res21 <= res21 + 8'h0; res22 <= res22 + 8'h0; res23 <= res23 + 8'h0; res24 <= res24 + 8'h0;
        res31 <= res31 + 8'h0; res32 <= res32 + 8'h0; res33 <= res33 + 8'h0; res34 <= res34 + 8'h0;
        res41 <= res41 + 8'h0; res42 <= res42 + 8'h0; res43 <= res43 + 8'h0; res44 <= res44 + 8'h0;
    end
end

// feed to PE
always @(posedge clk) begin
    if (cal && (cnt_k < k + 3)) begin
        a1  <= a[cnt_k][31:24];
        a2  <= a[cnt_k][23:16];
        a3  <= a[cnt_k][15: 8];
        a4  <= a[cnt_k][ 7: 0];
        b1  <= b[cnt_k][31:24];
        b2  <= b[cnt_k][23:16];
        b3  <= b[cnt_k][15: 8];
        b4  <= b[cnt_k][ 7: 0];
    end
    else if (cal) begin
        a1  <= 8'b0; a2 <= 8'b0; a3 <= 8'b0; a4 <= 8'b0;
        b1  <= 8'b0; b2 <= 8'b0; b3 <= 8'b0; b4 <= 8'b0;
    end
    else begin
        a1  <= 8'b0; a2 <= 8'b0; a3 <= 8'b0; a4 <= 8'b0;
        b1  <= 8'b0; b2 <= 8'b0; b3 <= 8'b0; b4 <= 8'b0;
    end
end

// COUNTER, INDEX
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt_k   <= 5'h0;
        cnt_m   <= 5'h0;
        index_a <= `DATA_SIZE'h0;
        index_b <= `DATA_SIZE'h0;
        cnt_4   <= 3'h0;
    end
    else begin
        case (curr_state)
            ST_INIT: begin
                remain_m    <= m;
                remain_n    <= n;
            end
            ST_READ: begin
                cnt_k   <= (cnt_k == k ) ? 4'h0 : (cnt_k + 1);
                index_a <= (cnt_k < k) ? (index_a + `DATA_SIZE'h1) : index_a;
                index_b <= (index_b + `DATA_SIZE'h1);

                cnt_4   <= 3'h0;
            end
            ST_MULADD: begin
                cnt_k       <= cnt_k + 5'h1;
            end
            ST_OUTPUT: begin
                cnt_m       <= cnt_m + 5'h1;
                cnt_4       <= cnt_4 + 3'h1;
            end
            ST_SET : begin
                cnt_m       <= cnt_m - 1;
                cnt_k       <= 5'h0;
                remain_m    <= (remain_m > 4'h3) ? (remain_m - 4'h4) : m;
                remain_n    <= (remain_m < 4'h4) ? (remain_n - 4'h4) : remain_n;
                index_a     <= (remain_m < 4'h4) ? `DATA_SIZE'h0 : (index_a);
                index_b     <= (remain_m > 4'h3) ? (index_b - (k+1)) : (index_b - 1);
            end
        endcase
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < 12; i = i + 1) begin
            a[i]    <= 32'h0;
            b[i]    <= 32'h0;
        end
    end
    else if (read && cnt_k > 0) begin
        a[cnt_k - 4'h1][31:24]  <= dataout_a[31:24];
        a[cnt_k       ][23:16]  <= dataout_a[23:16];
        a[cnt_k + 4'h1][15: 8]  <= dataout_a[15: 8];
        a[cnt_k + 4'h2][ 7: 0]  <= dataout_a[ 7: 0];
        b[cnt_k - 4'h1][31:24]  <= dataout_b[31:24];
        b[cnt_k       ][23:16]  <= dataout_b[23:16];
        b[cnt_k + 4'h1][15: 8]  <= dataout_b[15: 8];
        b[cnt_k + 4'd2][ 7: 0]  <= dataout_b[ 7: 0];
    end
end
endmodule

// ********************************************
// **************PE MODULE*********************
// ********************************************
module PE(clk, rst, top_in, left_in, bot_out, right_out, mult);
input clk, rst;
input [7:0] top_in, left_in;
output reg [7:0] bot_out, right_out, mult;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        bot_out     <= 8'h0; 
        right_out   <= 8'h0; 
        mult        <= 8'h0; 
    end
    else begin
        bot_out     <= top_in;
        right_out   <= left_in;
        mult        <= top_in * left_in;
    end
end

endmodule


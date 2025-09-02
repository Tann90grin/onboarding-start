module spi_peripheral (
    input  wire       clk,      // clock
    input  wire       rst_n,     // reset_n - low to reset
    input  wire [2:0] ui_in,
    
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

parameter   MAX_VALID_ADDR = 7'd4;

reg         trans_comp;
reg [1:0]   copi_sync, ncs_sync;
reg [2:0]   sclk_sync;
reg [4:0]   bit_cnt;
reg [15:0]  spi_buf;

wire        sclk_posedge, ncs_negedge, ncs_posedge;

assign sclk_posedge = sclk_sync[2] == 1'b0 && sclk_sync[1] == 1'b1;
assign ncs_negedge = ncs_sync[1] == 1'b1 && ncs_sync[0] == 1'b0;
assign ncs_posedge = ncs_sync[1] == 1'b0 && ncs_sync[0] == 1'b1;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        sclk_sync <= 3'b0;
        copi_sync <= 2'b0;
        ncs_sync <= 2'b0;
    end else begin
        sclk_sync <= {sclk_sync[1:0], ui_in[0]};
        copi_sync <= {copi_sync[0], ui_in[1]};
        ncs_sync <= {ncs_sync[0], ui_in[2]};
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        spi_buf <= 16'b0;
        bit_cnt <= 5'b0;
        trans_comp <= 1'b0;
    end else begin
        if(ncs_negedge) begin
            spi_buf <= 16'b0;
            bit_cnt <= 5'b0;
            trans_comp <= 1'b0;
        end else begin
            if(ncs_sync[0] == 1'b0 && bit_cnt < 5'd16) begin
                if(sclk_posedge) begin
                    spi_buf <= {spi_buf[14:0], copi_sync[1]};
                    bit_cnt <= bit_cnt + 1;
                end
            end
            if(ncs_posedge && bit_cnt == 5'd16) begin
                trans_comp <= 1'b1;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        en_reg_out_7_0 <= 8'b0;
        en_reg_out_15_8 <= 8'b0;
        en_reg_pwm_7_0 <= 8'b0;
        en_reg_pwm_15_8 <= 8'b0;
        pwm_duty_cycle <= 8'b0;
    end else begin
        if (spi_buf[15] == 1'b1 && trans_comp) begin
            if (spi_buf[14:8] <= MAX_VALID_ADDR)begin
                case(spi_buf[14:8])
                7'h00: en_reg_out_7_0 <= spi_buf[7:0];
                7'h01: en_reg_out_15_8 <= spi_buf[7:0];
                7'h02: en_reg_pwm_7_0 <= spi_buf[7:0];
                7'h03: en_reg_pwm_15_8 <= spi_buf[7:0];
                7'h04: pwm_duty_cycle <= spi_buf[7:0];
                default:;
                endcase
            end
            trans_comp <= 1'b0;
        end
    end
end

endmodule
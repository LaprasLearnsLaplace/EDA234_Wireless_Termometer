module OLED12864
  (
    input                clk,        // 12MHz system clock
    input                rst_n,      // System reset, active low
    input    [15:0] temp_in,         // Temperature sensor data

    input       [3:0]   sw,

    output  reg         oled_csn,    // OLED enable
    output  reg         oled_rst,    // OLED reset
    output  reg         oled_dcn,    // OLED data/command control
    output  reg         oled_clk,    // OLED clock signal
    output  reg         oled_dat     // OLED data signal
  )

  localparam INIT_DEPTH = 16'd23; //Number of initialization commands for the LCD
  localparam IDLE = 7'h1, MAIN = 7'h2, INIT = 7'h4, SCAN = 7'h8, WRITE = 7'h10, DELAY = 7'h20,IMAGE=7'h40;
  localparam HIGH	= 1'b1, LOW = 1'b0;
  localparam DATA	= 1'b1, CMD = 1'b0;

  reg  [7:0]    cmd [22:0];
  reg  [39:0]   mem [122:0];
  reg  [127:0]  mem_image[31:0];
  reg  [7:0]    mem_image_num;
  reg  [7:0]    y_p, x_ph, x_pl;
  reg  [(8*21-1):0]   char;
  reg  [7:0]    num, char_reg;
  reg  [4:0]    cnt_main, cnt_init, cnt_scan, cnt_write;
  reg  [5:0]   cnt_Image;
  reg  [15:0]   num_delay, cnt_delay, cnt;
  reg  [6:0]    state, state_back;

  reg  [15:0] temp;
  reg  temp_sign;
  reg  [7:0] temp_int;
  reg  [3:0] temp_dec;
  reg  [7:0] display_temp[4:0];
  reg  clk_12M;
  reg  [2:0] cnt_clk;

  reg  [1:0] temp_flag;

  always @(*)
  begin
    temp = temp_in;
    if (temp[15])
    begin
      temp_sign = 1'b1;
      temp_int = ~temp[11:5] + 1; // Two's complement for integer part
      temp_dec = ((~temp[3:0] + 1) * 10) >> 4; // Two's complement for decimal part
    end
    else
    begin
      temp_sign = 1'b0;
      temp_int = temp[11:5];
      temp_dec = (temp[3:0] * 10) >> 4;
    end

    display_temp[0] = temp_sign ? "-" : " "; // - or space
    display_temp[1] = temp_int / 10;
    display_temp[2] = temp_int % 10;
    display_temp[3] = ".";
    display_temp[4] = temp_dec;
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      temp <= 32'h00000000;
      temp_flag <= 2'b00;
    end
    else
      if (temp_int > 25)
        temp_flag <= 2'b10;
      else if (temp_int < 20)
        temp_flag <= 2'b01;
      else
        temp_flag <= 2'b00;
  end

  always @ (posedge clk or negedge rst_n)
  begin
    if(!rst_n)
    begin
      cnt_main <= 1'b0;
      cnt_init <= 1'b0;
      cnt_scan <= 1'b0;
      cnt_write <= 1'b0;
      cnt_Image <= 1'b0;
      y_p <= 1'b0;
      x_ph <= 1'b0;
      x_pl <= 1'b0;
      num <= 1'b0;
      char <= 1'b0;
      char_reg <= 1'b0;
      num_delay <= 16'd5;
      cnt_delay <= 1'b0;
      cnt <= 1'b0;
      oled_csn <= HIGH;
      oled_rst <= HIGH;
      oled_dcn <= CMD;
      oled_clk <= HIGH;
      oled_dat <= LOW;
      state <= IDLE;
      state_back <= IDLE;
    end
    else
    begin
      case(state)
        IDLE:
        begin
          cnt_main <= 1'b0;
          cnt_init <= 1'b0;
          cnt_scan <= 1'b0;
          cnt_write <= 1'b0;
          y_p <= 1'b0;
          x_ph <= 1'b0;
          x_pl <= 1'b0;
          num <= 1'b0;
          char <= 1'b0;
          char_reg <= 1'b0;
          num_delay <= 16'd5;
          cnt_delay <= 1'b0;
          cnt <= 1'b0;
          mem_image_num<=8'd0;
          oled_csn <= HIGH;
          oled_rst <= HIGH;
          oled_dcn <= CMD;
          oled_clk <= HIGH;
          oled_dat <= LOW;
          state <= MAIN;
          state_back <= MAIN;
        end
        MAIN:
        begin
          if(cnt_main >= 5'd26)
            cnt_main <= 5'd9;
          else
            cnt_main <= cnt_main + 1'b1;
          case(cnt_main)
            5'd0 :
            begin
              state <= INIT;
            end
            //清屏操作
            5'd1 :
            begin
              y_p <= 8'hb0;
              x_ph <= 8'h10;
              x_pl <= 8'h00;
              num <= 5'd16;
              char <= "                ";
              state <= SCAN;
            end
            5'd2 :
            begin
              y_p <= 8'hb1;
              x_ph <= 8'h10;
              x_pl <= 8'h00;
              num <= 5'd16;
              char <= "                ";
              state <= SCAN;
            end
            5'd3 :
            begin
              y_p <= 8'hb2;
              x_ph <= 8'h10;
              x_pl <= 8'h00;
              num <= 5'd16;
              char <= "                ";
              state <= SCAN;
            end
            5'd4 :
            begin
              y_p <= 8'hb3;
              x_ph <= 8'h10;
              x_pl <= 8'h00;
              num <= 5'd16;
              char <= "                ";
              state <= SCAN;
            end
            5'd5 :
            begin
              y_p <= 8'hb4;
              x_ph <= 8'h10;
              x_pl <= 8'h00;
              num <= 5'd16;
              char <= "                ";
              state <= SCAN;
            end
            5'd6 :
            begin
              y_p <= 8'hb5;
              x_ph <= 8'h10;
              x_pl <= 8'h00;
              num <= 5'd16;
              char <= "                ";
              state <= SCAN;
            end
            5'd7 :
            begin
              y_p <= 8'hb6;
              x_ph <= 8'h10;
              x_pl <= 8'h00;
              num <= 5'd16;
              char <= "                ";
              state <= SCAN;
            end
            5'd8 :
            begin
              y_p <= 8'hb7;
              x_ph <= 8'h10;
              x_pl <= 8'h00;
              num <= 5'd16;
              char <= "                ";
              state <= SCAN;
            end
            //显示
            //y_p(b0-b7): 选择8个页中的哪一页，每页8行像素
            //x_ph和x_pl: 组合确定显示的列地址(0-127)
            //OLED屏幕分辨率为128×64，即128列×8页(每页8行)
            // Display
            // y_p(b0-b7): Select which of the 8 pages, each page has 8 rows of pixels
            // x_ph and x_pl: Combined to determine the column address to display (0-127)
            // OLED screen resolution is 128×64, i.e., 128 columns × 8 pages (8 rows per page)
            5'd9 :
            begin
              y_p <= 8'hb0;
              x_ph <= 8'h10;
              x_pl <= 8'h00;
              mem_image_num <= 8'd0;
              state <= IMAGE;
            end
            5'd10:
            begin
              y_p <= 8'hb0;
              x_ph <= 8'h11;
              x_pl <= 8'h00;
              mem_image_num <= 8'd2;
              state <= IMAGE;
            end
            5'd11 :
            begin
              y_p <= 8'hb0;
              x_ph <= 8'h12;
              x_pl <= 8'h00;
              mem_image_num <= 8'd4;
              state <= IMAGE;
            end
            5'd12:
            begin
              y_p <= 8'hb0;
              x_ph <= 8'h13;
              x_pl <= 8'h00;
              mem_image_num <= 8'd6;
              state <= IMAGE;
            end

            // 2nd row image
            5'd13:
            begin
              y_p <= 8'hb2;
              x_ph <= 8'h10;
              x_pl <= 8'h00;
              mem_image_num <= 8'd8;
              state <= IMAGE;
            end
            5'd14:
            begin
              y_p <= 8'hb2;
              x_ph <= 8'h11;
              x_pl <= 8'h00;
              mem_image_num <= 8'd10;
              state <= IMAGE;
            end
            5'd15:
            begin
              y_p <= 8'hb2;
              x_ph <= 8'h12;
              x_pl <= 8'h00;
              mem_image_num <= 8'd12;
              state <= IMAGE;
            end
            5'd16:
            begin
              y_p <= 8'hb2;
              x_ph <= 8'h13;
              x_pl <= 8'h00;
              mem_image_num <= 8'd14;
              state <= IMAGE;
            end

            // 3rd row image
            5'd17:
            begin
              y_p <= 8'hb4;
              x_ph <= 8'h10;
              x_pl <= 8'h00;
              mem_image_num <= 8'd16;
              state <= IMAGE;
            end
            5'd18:
            begin
              y_p <= 8'hb4;
              x_ph <= 8'h11;
              x_pl <= 8'h00;
              mem_image_num <= 8'd18;
              state <= IMAGE;
            end
            5'd19:
            begin
              y_p <= 8'hb4;
              x_ph <= 8'h12;
              x_pl <= 8'h00;
              mem_image_num <= 8'd20;
              state <= IMAGE;
            end
            5'd20:
            begin
              y_p <= 8'hb4;
              x_ph <= 8'h13;
              x_pl <= 8'h00;
              mem_image_num <= 8'd22;
              state <= IMAGE;
            end

            // 4th row image
            5'd21:
            begin
              y_p <= 8'hb6;
              x_ph <= 8'h10;
              x_pl <= 8'h00;
              mem_image_num <= 8'd24;
              state <= IMAGE;
            end
            5'd22:
            begin
              y_p <= 8'hb6;
              x_ph <= 8'h11;
              x_pl <= 8'h00;
              mem_image_num <= 8'd26;
              state <= IMAGE;
            end
            5'd23:
            begin
              y_p <= 8'hb6;
              x_ph <= 8'h12;
              x_pl <= 8'h00;
              mem_image_num <= 8'd28;
              state <= IMAGE;
            end
            5'd24:
            begin
              y_p <= 8'hb6;
              x_ph <= 8'h13;
              x_pl <= 8'h00;
              mem_image_num <= 8'd30;
              state <= IMAGE;
            end

            5'd25 :
            begin
              y_p <= 8'hb2;
              x_ph <= 8'h14;
              x_pl <= 8'h00;
              num <= 5'd5;
              char <= "temp:";
              state <= SCAN;
            end
            5'd26 :
            begin
              y_p <= 8'hb3;
              x_ph <= 8'h14;
              x_pl <= 8'h00;
              num <= 5'd4;
              char <= num <= 5'd5;
              char <= {display_temp[0], display_temp[1], display_temp[2], display_temp[3], display_temp[4]};
              state <= SCAN;
            end
            default:
              state <= IDLE;
          endcase
        end
        INIT:
        begin	//Initialization state
          case(cnt_init)
            5'd0:
            begin
              oled_rst <= LOW;
              cnt_init <= cnt_init + 1'b1;
            end	//Reset
            5'd1:
            begin
              num_delay <= 16'd25000;
              state <= DELAY;
              state_back <= INIT;
              cnt_init <= cnt_init + 1'b1;
            end //dealy
            5'd2:
            begin
              oled_rst <= HIGH;
              cnt_init <= cnt_init + 1'b1;
            end	//reset
            5'd3:
            begin
              num_delay <= 16'd25000;
              state <= DELAY;
              state_back <= INIT;
              cnt_init <= cnt_init + 1'b1;
            end	//dealy
            5'd4:
            begin
              if(cnt>=INIT_DEPTH)
              begin	//当25条指令及数据发出后，配置完成
                cnt <= 1'b0;
                cnt_init <= cnt_init + 1'b1;
              end
              else
              begin
                cnt <= cnt + 1'b1;
                num_delay <= 16'd5;
                oled_dcn <= CMD;
                char_reg <= cmd[cnt];
                state <= WRITE;
                state_back <= INIT;
              end
            end
            5'd5:
            begin
              cnt_init <= 1'b0;
              state <= MAIN;
            end	//Initialization complete and enter the main state
            default:
              state <= IDLE;
          endcase
        end
        SCAN:
        begin	//Ram scan state
          if(cnt_scan == 5'd11)
          begin
            if(num)
              cnt_scan <= 5'd3;
            else
              cnt_scan <= cnt_scan + 1'b1;
          end
          else if(cnt_scan == 5'd12)
            cnt_scan <= 1'b0;
          else
            cnt_scan <= cnt_scan + 1'b1;
          case(cnt_scan)
            5'd 0:
            begin
              oled_dcn <= CMD;
              char_reg <= y_p;
              state <= WRITE;
              state_back <= SCAN;
            end		 // Set page address
            5'd 1:
            begin
              oled_dcn <= CMD;
              char_reg <= x_pl;
              state <= WRITE;
              state_back <= SCAN;
            end	 // Set lower column address
            5'd 2:
            begin
              oled_dcn <= CMD;
              char_reg <= x_ph;
              state <= WRITE;
              state_back <= SCAN;
            end	// Set higher column address

            5'd 3:
            begin
              num <= num - 1'b1;
            end
            5'd 4:
            begin
              oled_dcn <= DATA;
              char_reg <= 8'h00;
              state <= WRITE;
              state_back <= SCAN;
            end // Convert 5*8 dot matrix to 8*8
            5'd 5:
            begin
              oled_dcn <= DATA;
              char_reg <= 8'h00;
              state <= WRITE;
              state_back <= SCAN;
            end	// Convert 5*8 dot matrix to 8*8
            5'd 6:
            begin
              oled_dcn <= DATA;
              char_reg <= 8'h00;
              state <= WRITE;
              state_back <= SCAN;
            end	// Convert 5*8 dot matrix to 8*8
            5'd 7:
            begin
              oled_dcn <= DATA;
              char_reg <= mem[char[(num*8)+:8]][39:32];
              state <= WRITE;
              state_back <= SCAN;
            end
            5'd 8:
            begin
              oled_dcn <= DATA;
              char_reg <= mem[char[(num*8)+:8]][31:24];
              state <= WRITE;
              state_back <= SCAN;
            end
            5'd 9:
            begin
              oled_dcn <= DATA;
              char_reg <= mem[char[(num*8)+:8]][23:16];
              state <= WRITE;
              state_back <= SCAN;
            end
            5'd10:
            begin
              oled_dcn <= DATA;
              char_reg <= mem[char[(num*8)+:8]][15: 8];
              state <= WRITE;
              state_back <= SCAN;
            end
            5'd11:
            begin
              oled_dcn <= DATA;
              char_reg <= mem[char[(num*8)+:8]][ 7: 0];
              state <= WRITE;
              state_back <= SCAN;
            end
            5'd12:
            begin
              state <= MAIN;
            end
            default:
              state <= IDLE;
          endcase
        end




        IMAGE:
        begin	//Image state

          if(cnt_Image == 6'd38)
            cnt_Image <= 1'b0;
          else
            cnt_Image <= cnt_Image+1'b1;
          case(cnt_Image)
            6'd 0:
            begin
              oled_dcn <= CMD;
              char_reg <= y_p;
              state <= WRITE;
              state_back <= IMAGE;
            end		 // Set page address
            6'd 1:
            begin
              oled_dcn <= CMD;
              char_reg <= x_pl;
              state <= WRITE;
              state_back <= IMAGE;
            end	// Set lower column address
            6'd 2:
            begin
              oled_dcn <= CMD;
              char_reg <= x_ph;
              state <= WRITE;
              state_back <= IMAGE;
            end	// Set higher column address

            6'd3 :
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][127:120];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd4 :
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][119:112];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd5 :
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][111:104];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd6 :
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][103:96] ;
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd7 :
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][95:88]  ;
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd8 :
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][87:80]  ;
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd9 :
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][79:72]  ;
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd10:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][71:64]  ;
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd11:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][63:56];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd12:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][55:48];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd13:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][47:40];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd14:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][39:32];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd15:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][31:24];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd16:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][23:16];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd17:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][15: 8];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd18:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num][ 7: 0];
              state <= WRITE;
              state_back <= IMAGE;
            end

            6'd19:
            begin
              oled_dcn <= CMD;
              char_reg <= y_p+1;
              state <= WRITE;
              state_back <= IMAGE;
            end		 // Set page address
            6'd20:
            begin
              oled_dcn <= CMD;
              char_reg <= x_pl;
              state <= WRITE;
              state_back <= IMAGE;
            end	// Set lower column address
            6'd21:
            begin
              oled_dcn <= CMD;
              char_reg <= x_ph;
              state <= WRITE;
              state_back <= IMAGE;
            end	// Set higher column address
            6'd22:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][127:120];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd23:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][119:112];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd24:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][111:104];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd25:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][103:96] ;
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd26:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][95:88]  ;
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd27:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][87:80]  ;
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd28:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][79:72]  ;
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd29:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][71:64]  ;
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd30:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][63:56];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd31:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][55:48];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd32:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][47:40];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd33:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][39:32];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd34:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][31:24];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd35:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][23:16];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd36:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][15: 8];
              state <= WRITE;
              state_back <= IMAGE;
            end
            6'd37:
            begin
              oled_dcn <= DATA;
              char_reg <= mem_image[mem_image_num+1][ 7: 0];
              state <= WRITE;
              state_back <= IMAGE;
            end

            6'd38:
            begin
              state <= MAIN;
            end
            default:
              state <= IDLE;
          endcase
        end



        WRITE:
        begin	// In WRITE state, send data to the screen according to SPI timing
          if(cnt_write >= 5'd17)
            cnt_write <= 1'b0;
          else
            cnt_write <= cnt_write + 1'b1;
          case(cnt_write)
            5'd 0:
            begin
              oled_csn <= LOW;
            end	// The highest bit of the 9-bit data is the data control bit
            5'd 1:
            begin
              oled_clk <= LOW;
              oled_dat <= char_reg[7];
            end	//high bit data first
            5'd 2:
            begin
              oled_clk <= HIGH;
            end
            5'd 3:
            begin
              oled_clk <= LOW;
              oled_dat <= char_reg[6];
            end
            5'd 4:
            begin
              oled_clk <= HIGH;
            end
            5'd 5:
            begin
              oled_clk <= LOW;
              oled_dat <= char_reg[5];
            end
            5'd 6:
            begin
              oled_clk <= HIGH;
            end
            5'd 7:
            begin
              oled_clk <= LOW;
              oled_dat <= char_reg[4];
            end
            5'd 8:
            begin
              oled_clk <= HIGH;
            end
            5'd 9:
            begin
              oled_clk <= LOW;
              oled_dat <= char_reg[3];
            end
            5'd10:
            begin
              oled_clk <= HIGH;
            end
            5'd11:
            begin
              oled_clk <= LOW;
              oled_dat <= char_reg[2];
            end
            5'd12:
            begin
              oled_clk <= HIGH;
            end
            5'd13:
            begin
              oled_clk <= LOW;
              oled_dat <= char_reg[1];
            end
            5'd14:
            begin
              oled_clk <= HIGH;
            end
            5'd15:
            begin
              oled_clk <= LOW;
              oled_dat <= char_reg[0];
            end	//Low bit data last
            5'd16:
            begin
              oled_clk <= HIGH;
            end
            5'd17:
            begin
              oled_csn <= HIGH;
              state <= DELAY;
            end	//
            default:
              state <= IDLE;
          endcase
        end
        DELAY:
        begin	//delay state
          if(cnt_delay >= num_delay)
          begin
            cnt_delay <= 16'd0;
            state <= state_back;
          end
          else
            cnt_delay <= cnt_delay + 1'b1;
        end
        default:
          state <= IDLE;
      endcase
    end
  end

  //OLED Initialization command
  always@(posedge rst_n)
  begin
    cmd[0 ] = {8'hae};
    cmd[1 ] = {8'hd5};
    cmd[2 ] = {8'h80};
    cmd[3 ] = {8'ha8};
    cmd[4 ] = {8'h3f};
    cmd[5 ] = {8'hd3};
    cmd[6 ] = {8'h00};
    cmd[7 ] = {8'h40};
    cmd[8 ] = {8'h8d};
    cmd[9 ] = {8'h14};
    cmd[10] = {8'h20};
    cmd[11] = {8'h02};
    cmd[12] = {8'hc8};
    cmd[13] = {8'ha1};
    cmd[14] = {8'hda};
    cmd[15] = {8'h12};
    cmd[16] = {8'h81};
    cmd[17] = {8'hcf};
    cmd[18] = {8'hd9};
    cmd[19] = {8'hf1};
    cmd[20] = {8'hdb};
    cmd[21] = {8'h40};
    cmd[22] = {8'haf};

  end

  //5*8 dot matrix
  always@(posedge rst_n)
  begin
    mem[  0] = {8'h3E, 8'h51, 8'h49, 8'h45, 8'h3E};   // 48  0
    mem[  1] = {8'h00, 8'h42, 8'h7F, 8'h40, 8'h00};   // 49  1
    mem[  2] = {8'h42, 8'h61, 8'h51, 8'h49, 8'h46};   // 50  2
    mem[  3] = {8'h21, 8'h41, 8'h45, 8'h4B, 8'h31};   // 51  3
    mem[  4] = {8'h18, 8'h14, 8'h12, 8'h7F, 8'h10};   // 52  4
    mem[  5] = {8'h27, 8'h45, 8'h45, 8'h45, 8'h39};   // 53  5
    mem[  6] = {8'h3C, 8'h4A, 8'h49, 8'h49, 8'h30};   // 54  6
    mem[  7] = {8'h01, 8'h71, 8'h09, 8'h05, 8'h03};   // 55  7
    mem[  8] = {8'h36, 8'h49, 8'h49, 8'h49, 8'h36};   // 56  8
    mem[  9] = {8'h06, 8'h49, 8'h49, 8'h29, 8'h1E};   // 57  9
    mem[ 10] = {8'h7C, 8'h12, 8'h11, 8'h12, 8'h7C};   // 65  A
    mem[ 11] = {8'h7F, 8'h49, 8'h49, 8'h49, 8'h36};   // 66  B
    mem[ 12] = {8'h3E, 8'h41, 8'h41, 8'h41, 8'h22};   // 67  C
    mem[ 13] = {8'h7F, 8'h41, 8'h41, 8'h22, 8'h1C};   // 68  D
    mem[ 14] = {8'h7F, 8'h49, 8'h49, 8'h49, 8'h41};   // 69  E
    mem[ 15] = {8'h7F, 8'h09, 8'h09, 8'h09, 8'h01};   // 70  F

    mem[ 32] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00};   // 32  sp
    mem[ 33] = {8'h00, 8'h00, 8'h2f, 8'h00, 8'h00};   // 33  !
    mem[ 34] = {8'h00, 8'h07, 8'h00, 8'h07, 8'h00};   // 34
    mem[ 35] = {8'h14, 8'h7f, 8'h14, 8'h7f, 8'h14};   // 35  #
    mem[ 36] = {8'h24, 8'h2a, 8'h7f, 8'h2a, 8'h12};   // 36  $
    mem[ 37] = {8'h62, 8'h64, 8'h08, 8'h13, 8'h23};   // 37  %
    mem[ 38] = {8'h36, 8'h49, 8'h55, 8'h22, 8'h50};   // 38  &
    mem[ 39] = {8'h00, 8'h05, 8'h03, 8'h00, 8'h00};   // 39  '
    mem[ 40] = {8'h00, 8'h1c, 8'h22, 8'h41, 8'h00};   // 40  (
    mem[ 41] = {8'h00, 8'h41, 8'h22, 8'h1c, 8'h00};   // 41  )
    mem[ 42] = {8'h14, 8'h08, 8'h3E, 8'h08, 8'h14};   // 42  *
    mem[ 43] = {8'h08, 8'h08, 8'h3E, 8'h08, 8'h08};   // 43  +
    mem[ 44] = {8'h00, 8'h00, 8'hA0, 8'h60, 8'h00};   // 44  ,
    mem[ 45] = {8'h08, 8'h08, 8'h08, 8'h08, 8'h08};   // 45  -
    mem[ 46] = {8'h00, 8'h60, 8'h60, 8'h00, 8'h00};   // 46  .
    mem[ 47] = {8'h20, 8'h10, 8'h08, 8'h04, 8'h02};   // 47  /
    mem[ 48] = {8'h3E, 8'h51, 8'h49, 8'h45, 8'h3E};   // 48  0
    mem[ 49] = {8'h00, 8'h42, 8'h7F, 8'h40, 8'h00};   // 49  1
    mem[ 50] = {8'h42, 8'h61, 8'h51, 8'h49, 8'h46};   // 50  2
    mem[ 51] = {8'h21, 8'h41, 8'h45, 8'h4B, 8'h31};   // 51  3
    mem[ 52] = {8'h18, 8'h14, 8'h12, 8'h7F, 8'h10};   // 52  4
    mem[ 53] = {8'h27, 8'h45, 8'h45, 8'h45, 8'h39};   // 53  5
    mem[ 54] = {8'h3C, 8'h4A, 8'h49, 8'h49, 8'h30};   // 54  6
    mem[ 55] = {8'h01, 8'h71, 8'h09, 8'h05, 8'h03};   // 55  7
    mem[ 56] = {8'h36, 8'h49, 8'h49, 8'h49, 8'h36};   // 56  8
    mem[ 57] = {8'h06, 8'h49, 8'h49, 8'h29, 8'h1E};   // 57  9
    mem[ 58] = {8'h00, 8'h36, 8'h36, 8'h00, 8'h00};   // 58  :
    mem[ 59] = {8'h00, 8'h56, 8'h36, 8'h00, 8'h00};   // 59  ;
    mem[ 60] = {8'h08, 8'h14, 8'h22, 8'h41, 8'h00};   // 60  <
    mem[ 61] = {8'h14, 8'h14, 8'h14, 8'h14, 8'h14};   // 61  =
    mem[ 62] = {8'h00, 8'h41, 8'h22, 8'h14, 8'h08};   // 62  >
    mem[ 63] = {8'h02, 8'h01, 8'h51, 8'h09, 8'h06};   // 63  ?
    mem[ 64] = {8'h32, 8'h49, 8'h59, 8'h51, 8'h3E};   // 64  @
    mem[ 65] = {8'h7C, 8'h12, 8'h11, 8'h12, 8'h7C};   // 65  A
    mem[ 66] = {8'h7F, 8'h49, 8'h49, 8'h49, 8'h36};   // 66  B
    mem[ 67] = {8'h3E, 8'h41, 8'h41, 8'h41, 8'h22};   // 67  C
    mem[ 68] = {8'h7F, 8'h41, 8'h41, 8'h22, 8'h1C};   // 68  D
    mem[ 69] = {8'h7F, 8'h49, 8'h49, 8'h49, 8'h41};   // 69  E
    mem[ 70] = {8'h7F, 8'h09, 8'h09, 8'h09, 8'h01};   // 70  F
    mem[ 71] = {8'h3E, 8'h41, 8'h49, 8'h49, 8'h7A};   // 71  G
    mem[ 72] = {8'h7F, 8'h08, 8'h08, 8'h08, 8'h7F};   // 72  H
    mem[ 73] = {8'h00, 8'h41, 8'h7F, 8'h41, 8'h00};   // 73  I
    mem[ 74] = {8'h20, 8'h40, 8'h41, 8'h3F, 8'h01};   // 74  J
    mem[ 75] = {8'h7F, 8'h08, 8'h14, 8'h22, 8'h41};   // 75  K
    mem[ 76] = {8'h7F, 8'h40, 8'h40, 8'h40, 8'h40};   // 76  L
    mem[ 77] = {8'h7F, 8'h02, 8'h0C, 8'h02, 8'h7F};   // 77  M
    mem[ 78] = {8'h7F, 8'h04, 8'h08, 8'h10, 8'h7F};   // 78  N
    mem[ 79] = {8'h3E, 8'h41, 8'h41, 8'h41, 8'h3E};   // 79  O
    mem[ 80] = {8'h7F, 8'h09, 8'h09, 8'h09, 8'h06};   // 80  P
    mem[ 81] = {8'h3E, 8'h41, 8'h51, 8'h21, 8'h5E};   // 81  Q
    mem[ 82] = {8'h7F, 8'h09, 8'h19, 8'h29, 8'h46};   // 82  R
    mem[ 83] = {8'h46, 8'h49, 8'h49, 8'h49, 8'h31};   // 83  S
    mem[ 84] = {8'h01, 8'h01, 8'h7F, 8'h01, 8'h01};   // 84  T
    mem[ 85] = {8'h3F, 8'h40, 8'h40, 8'h40, 8'h3F};   // 85  U
    mem[ 86] = {8'h1F, 8'h20, 8'h40, 8'h20, 8'h1F};   // 86  V
    mem[ 87] = {8'h3F, 8'h40, 8'h38, 8'h40, 8'h3F};   // 87  W
    mem[ 88] = {8'h63, 8'h14, 8'h08, 8'h14, 8'h63};   // 88  X
    mem[ 89] = {8'h07, 8'h08, 8'h70, 8'h08, 8'h07};   // 89  Y
    mem[ 90] = {8'h61, 8'h51, 8'h49, 8'h45, 8'h43};   // 90  Z
    mem[ 91] = {8'h00, 8'h7F, 8'h41, 8'h41, 8'h00};   // 91  [
    mem[ 92] = {8'h55, 8'h2A, 8'h55, 8'h2A, 8'h55};   // 92  .
    mem[ 93] = {8'h00, 8'h41, 8'h41, 8'h7F, 8'h00};   // 93  ]
    mem[ 94] = {8'h04, 8'h02, 8'h01, 8'h02, 8'h04};   // 94  ^
    mem[ 95] = {8'h40, 8'h40, 8'h40, 8'h40, 8'h40};   // 95  _
    mem[ 96] = {8'h00, 8'h01, 8'h02, 8'h04, 8'h00};   // 96  '
    mem[ 97] = {8'h20, 8'h54, 8'h54, 8'h54, 8'h78};   // 97  a
    mem[ 98] = {8'h7F, 8'h48, 8'h44, 8'h44, 8'h38};   // 98  b
    mem[ 99] = {8'h38, 8'h44, 8'h44, 8'h44, 8'h20};   // 99  c
    mem[100] = {8'h38, 8'h44, 8'h44, 8'h48, 8'h7F};   // 100 d
    mem[101] = {8'h38, 8'h54, 8'h54, 8'h54, 8'h18};   // 101 e
    mem[102] = {8'h08, 8'h7E, 8'h09, 8'h01, 8'h02};   // 102 f
    mem[103] = {8'h18, 8'hA4, 8'hA4, 8'hA4, 8'h7C};   // 103 g
    mem[104] = {8'h7F, 8'h08, 8'h04, 8'h04, 8'h78};   // 104 h
    mem[105] = {8'h00, 8'h44, 8'h7D, 8'h40, 8'h00};   // 105 i
    mem[106] = {8'h40, 8'h80, 8'h84, 8'h7D, 8'h00};   // 106 j
    mem[107] = {8'h7F, 8'h10, 8'h28, 8'h44, 8'h00};   // 107 k
    mem[108] = {8'h00, 8'h41, 8'h7F, 8'h40, 8'h00};   // 108 l
    mem[109] = {8'h7C, 8'h04, 8'h18, 8'h04, 8'h78};   // 109 m
    mem[110] = {8'h7C, 8'h08, 8'h04, 8'h04, 8'h78};   // 110 n
    mem[111] = {8'h38, 8'h44, 8'h44, 8'h44, 8'h38};   // 111 o
    mem[112] = {8'hFC, 8'h24, 8'h24, 8'h24, 8'h18};   // 112 p
    mem[113] = {8'h18, 8'h24, 8'h24, 8'h18, 8'hFC};   // 113 q
    mem[114] = {8'h7C, 8'h08, 8'h04, 8'h04, 8'h08};   // 114 r
    mem[115] = {8'h48, 8'h54, 8'h54, 8'h54, 8'h20};   // 115 s
    mem[116] = {8'h04, 8'h3F, 8'h44, 8'h40, 8'h20};   // 116 t
    mem[117] = {8'h3C, 8'h40, 8'h40, 8'h20, 8'h7C};   // 117 u
    mem[118] = {8'h1C, 8'h20, 8'h40, 8'h20, 8'h1C};   // 118 v
    mem[119] = {8'h3C, 8'h40, 8'h30, 8'h40, 8'h3C};   // 119 w
    mem[120] = {8'h44, 8'h28, 8'h10, 8'h28, 8'h44};   // 120 x
    mem[121] = {8'h1C, 8'hA0, 8'hA0, 8'hA0, 8'h7C};   // 121 y
    mem[122] = {8'h44, 8'h64, 8'h54, 8'h4C, 8'h44};   // 122 z
  end

  //OLED display image
  // Using proper clock instead of rst_n
  always@(posedge clk)
  begin
    case (temp_flag)
      2'b00:
      begin
        mem_image[ 0]= {8'h1F,8'h1F,8'h67,8'hE7,8'hC3,8'h83,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h01,8'h03,8'h0F,8'h3E};
        mem_image[ 1]= {8'h00,8'h00,8'h00,8'h00,8'h01,8'h07,8'h0E,8'h1C,8'h38,8'h70,8'hE0,8'hC0,8'h00,8'h00,8'h00,8'h00};
        mem_image[ 2]= {8'hF8,8'hE0,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[ 3]= {8'h00,8'h01,8'h03,8'h1E,8'h0E,8'h06,8'h06,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03};
        mem_image[ 4]= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[ 5]= {8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h07,8'h0E,8'h0C,8'h0C,8'h1C,8'h18,8'h18,8'h1C,8'h0C};
        mem_image[ 6]= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h80,8'h80,8'h80,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0};
        mem_image[ 7]= {8'h06,8'h06,8'h07,8'h07,8'h03,8'h03,8'h03,8'h03,8'h03,8'h81,8'h81,8'h80,8'h80,8'hC0,8'hC0,8'hC0};
        mem_image[ 8]= {8'h03,8'h07,8'h0E,8'h1C,8'h38,8'h60,8'hC0,8'hC0,8'h80,8'hC0,8'hF8,8'h7F,8'h1F,8'h0E,8'h00,8'h00};
        mem_image[ 9]= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h03,8'hFF,8'hFF,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[10]= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[11]= {8'h00,8'h80,8'hC0,8'hE0,8'hE0,8'hC0,8'h80,8'h00,8'h1C,8'h0E,8'h07,8'h07,8'h07,8'h07,8'h07,8'h0E};
        mem_image[12]= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[13]= {8'h1C,8'h08,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h80,8'hC0,8'hC0,8'h00,8'h00,8'h1C,8'h0E,8'h07};
        mem_image[14]= {8'h00,8'h00,8'h0F,8'h3F,8'hFF,8'hE3,8'h83,8'h03,8'h03,8'h03,8'h03,8'h03,8'h03,8'h01,8'h01,8'h01};
        mem_image[15]= {8'h07,8'h0E,8'h0C,8'h00,8'h00,8'h9F,8'hFF,8'hF0,8'hC0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[16]= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hFF,8'hFF,8'hC0,8'h00,8'h00,8'h00,8'h00,8'h0E};
        mem_image[17]= {8'h60,8'h30,8'h30,8'h38,8'h18,8'h18,8'h18,8'h1C,8'h8F,8'hFF,8'hFF,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[18]= {8'h1F,8'h3F,8'h7F,8'h7F,8'h7F,8'h7F,8'h3F,8'h1F,8'h0E,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[19]= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[20]= {8'h0C,8'h3C,8'hF8,8'hF8,8'hF8,8'hF8,8'hF8,8'hF9,8'hF9,8'hF9,8'hF9,8'h38,8'h18,8'h0C,8'h00,8'h00};
        mem_image[21]= {8'h00,8'h00,8'h00,8'h03,8'h03,8'h07,8'h07,8'h07,8'h03,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h80};
        mem_image[22]= {8'h00,8'h00,8'h00,8'h00,8'h1F,8'h3F,8'hFF,8'hFF,8'hFF,8'h3F,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[23]= {8'hC0,8'hE0,8'h70,8'h38,8'h1C,8'h0E,8'h07,8'h03,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[24]= {8'h0E,8'h1C,8'hF8,8'hF0,8'hE0,8'hC0,8'hE0,8'hFC,8'hFF,8'h8F,8'h81,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[25]= {8'h06,8'h06,8'h07,8'hFF,8'hFF,8'h1F,8'h07,8'h03,8'h03,8'h01,8'h01,8'h00,8'h00,8'h00,8'h78,8'hF8};
        mem_image[26]= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[27]= {8'hF0,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h06,8'hFE,8'hFE,8'hF0,8'h00,8'h00};
        mem_image[28]= {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h03,8'h07};
        mem_image[29]= {8'h00,8'h00,8'h00,8'h00,8'h00,8'hC0,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[30]= {8'hFF,8'hFC,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[31]= {8'h00,8'hFF,8'hFF,8'hE0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
      end
      2'b01:
      begin
        mem_image[ 0] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[ 1] = {8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hE0,8'h70,8'h38,8'h1C,8'h0C,8'h0E,8'h06,8'h07,8'h03,8'h03};
        mem_image[ 2] = {8'h80,8'h80,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hE0,8'h70};
        mem_image[ 3] = {8'h03,8'h01,8'h01,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[ 4] = {8'h38,8'h38,8'h1C,8'h0E,8'h07,8'h03,8'h03,8'h01,8'h00,8'h00,8'h00,8'h80,8'h80,8'hC0,8'hC0,8'hC0};
        mem_image[ 5] = {8'h00,8'h80,8'hC3,8'h63,8'h23,8'h26,8'h26,8'h7E,8'hDF,8'hF3,8'h23,8'h83,8'h81,8'h01,8'h00,8'h00};
        mem_image[ 6] = {8'hC0,8'h60,8'h70,8'h70,8'h30,8'h18,8'h18,8'h1C,8'h0E,8'h0E,8'h07,8'h03,8'h01,8'h00,8'h00,8'h00};
        mem_image[ 7] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[ 8] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hC0,8'hE0,8'h30};
        mem_image[ 9] = {8'h03,8'hEF,8'hFF,8'hFF,8'h03,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1F,8'h38,8'h20};
        mem_image[10] = {8'h18,8'h18,8'hD8,8'hD8,8'h98,8'h60,8'hE0,8'hC0,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[11] = {8'h07,8'h0F,8'h18,8'h19,8'h19,8'h1C,8'h0F,8'h07,8'h01,8'h00,8'h00,8'h80,8'hC0,8'hC0,8'hC0,8'hC0};
        mem_image[12] = {8'h07,8'h1F,8'h18,8'h74,8'h67,8'h73,8'h1E,8'h1C,8'h00,8'h00,8'h0F,8'h07,8'h03,8'h0C,8'h9C,8'hF8};
        mem_image[13] = {8'hC0,8'hE4,8'hE4,8'hE0,8'hF0,8'hF8,8'hFC,8'hFC,8'h7C,8'h38,8'h00,8'h00,8'h00,8'h00,8'h07,8'h0F};
        mem_image[14] = {8'hE0,8'hC0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[15] = {8'h1F,8'hFF,8'hFF,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[16] = {8'h00,8'h01,8'h03,8'h3F,8'hFC,8'hE0,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h70,8'hF8,8'hFC,8'hFE};
        mem_image[17] = {8'h18,8'h0C,8'h0E,8'h06,8'h07,8'h07,8'h87,8'hC6,8'hF8,8'h38,8'h00,8'h00,8'h00,8'h00,8'h01,8'h03};
        mem_image[18] = {8'hFE,8'hFE,8'hFE,8'hFE,8'hFC,8'hF8,8'h00,8'h00,8'h00,8'h00,8'h00,8'h07,8'h07,8'h07,8'h0F,8'h0F};
        mem_image[19] = {8'h03,8'h03,8'h03,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[20] = {8'h0F,8'h07,8'h07,8'h03,8'h03,8'h03,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hC0,8'hF0,8'hFC};
        mem_image[21] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h03,8'h03,8'hC3,8'h81,8'h03};
        mem_image[22] = {8'h0F,8'h03,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[23] = {8'h03,8'h07,8'h06,8'h0E,8'h0C,8'h18,8'h18,8'h18,8'h18,8'h30,8'h70,8'h60,8'h60,8'hC0,8'hC0,8'hC0};
        mem_image[24] = {8'h03,8'h06,8'hFC,8'hF8,8'hF8,8'hF8,8'hFF,8'h87,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[25] = {8'h0E,8'h0E,8'h1F,8'hFF,8'hFF,8'h8F,8'h0D,8'h0F,8'h0F,8'h0E,8'h0C,8'h00,8'h00,8'h00,8'h01,8'h03};
        mem_image[26] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h06,8'h0C,8'h18,8'h38,8'h60,8'hC0,8'h80};
        mem_image[27] = {8'h06,8'h0C,8'h18,8'h30,8'h60,8'hE0,8'hC0,8'hC0,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h03};
        mem_image[28] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h03,8'h3F,8'hFE};
        mem_image[29] = {8'h07,8'h3E,8'h78,8'hE0,8'hC0,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[30] = {8'hFC,8'hF0,8'h70,8'h70,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h20,8'h30,8'h38,8'h3C};
        mem_image[31] = {8'h0F,8'h3F,8'hF8,8'hC0,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
      end
      2'b10:
      begin
        mem_image[ 0] = {8'h1F,8'h3F,8'h7F,8'hE7,8'hC3,8'h83,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h01,8'h03,8'h1F,8'h3E};
        mem_image[ 1] = {8'h80,8'h00,8'h00,8'h00,8'h03,8'h03,8'h0E,8'h1C,8'h78,8'hF0,8'hC0,8'hC0,8'h80,8'h00,8'h00,8'h00};
        mem_image[ 2] = {8'h70,8'hE0,8'hC0,8'h80,8'h00,8'h00,8'h00,8'h80,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0};
        mem_image[ 3] = {8'h00,8'h01,8'h07,8'h0F,8'h07,8'h07,8'h03,8'h03,8'h01,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[ 4] = {8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[ 5] = {8'h00,8'h00,8'h00,8'h00,8'h01,8'h01,8'h03,8'h03,8'h03,8'h03,8'h03,8'h06,8'h0E,8'h0E,8'h07,8'h03};
        mem_image[ 6] = {8'h00,8'h00,8'h80,8'h80,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hE0,8'h60,8'h60,8'h60,8'h20,8'h20,8'h20};
        mem_image[ 7] = {8'h03,8'h83,8'h83,8'h81,8'h81,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'hC0,8'hC0,8'hC0,8'hC0};
        mem_image[ 8] = {8'h01,8'h03,8'h06,8'h0C,8'h18,8'h70,8'hE0,8'hC0,8'hC0,8'hFC,8'hFF,8'h1F,8'h07,8'h03,8'h00,8'h00};
        mem_image[ 9] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h03,8'hFF,8'hFF,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[10] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hC0,8'hE0,8'hE0,8'hF0,8'h30,8'h30,8'h60,8'hC0,8'h80,8'h00};
        mem_image[11] = {8'h00,8'h80,8'hC0,8'hE0,8'hE0,8'hC0,8'h87,8'h0F,8'h1F,8'h1F,8'h1E,8'h1E,8'h1E,8'h0F,8'h07,8'h00};
        mem_image[12] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h80,8'hC0,8'h60,8'h60};
        mem_image[13] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h60,8'h60,8'h60,8'h00,8'h03,8'h0F,8'h1F,8'h1E};
        mem_image[14] = {8'hE0,8'hE3,8'hC7,8'h9F,8'hFF,8'hF3,8'h03,8'h03,8'h03,8'h03,8'h03,8'h01,8'h01,8'h01,8'h01,8'h01};
        mem_image[15] = {8'h1F,8'h1F,8'h0F,8'h00,8'h00,8'h8F,8'hFF,8'hF8,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[16] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1F,8'hFF,8'hF0,8'h00,8'h00,8'h00,8'h00,8'h0E};
        mem_image[17] = {8'h30,8'h30,8'h38,8'h18,8'h1C,8'h1C,8'h0C,8'h0E,8'hCE,8'hFF,8'h7F,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[18] = {8'h1F,8'h3F,8'h7F,8'h7F,8'h7F,8'h7F,8'h3F,8'h1F,8'h0E,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[19] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[20] = {8'h00,8'h00,8'h00,8'h0E,8'h0E,8'h0C,8'h0C,8'h0C,8'h0C,8'h0C,8'h0C,8'h0E,8'h0C,8'h00,8'h00,8'h00};
        mem_image[21] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hC0,8'hC0};
        mem_image[22] = {8'h00,8'h00,8'h00,8'h00,8'h1F,8'hBF,8'hFF,8'hFF,8'h7F,8'h12,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[23] = {8'hE0,8'h30,8'h38,8'h1C,8'h0E,8'h07,8'h03,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[24] = {8'h0E,8'h1C,8'hF8,8'hF0,8'hE0,8'hF0,8'hF8,8'hFE,8'hFF,8'hC3,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[25] = {8'h06,8'h07,8'h1F,8'hFD,8'hFF,8'h0F,8'h03,8'h01,8'h01,8'h07,8'h03,8'h01,8'h00,8'h00,8'h7C,8'hFE};
        mem_image[26] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[27] = {8'hE0,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h02,8'h0F,8'hFF,8'hFC,8'h80,8'h00,8'h00};
        mem_image[28] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h03,8'h0F};
        mem_image[29] = {8'h00,8'h00,8'h00,8'h00,8'hFC,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[30] = {8'hFF,8'hF8,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[31] = {8'h00,8'hFF,8'hFF,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
      end
      default:
      begin
        mem_image[ 0] = {8'h1F,8'h3F,8'h7F,8'hE7,8'hC3,8'h83,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h01,8'h03,8'h1F,8'h3E};
        mem_image[ 1] = {8'h80,8'h00,8'h00,8'h00,8'h03,8'h03,8'h0E,8'h1C,8'h78,8'hF0,8'hC0,8'hC0,8'h80,8'h00,8'h00,8'h00};
        mem_image[ 2] = {8'h70,8'hE0,8'hC0,8'h80,8'h00,8'h00,8'h00,8'h80,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0};
        mem_image[ 3] = {8'h00,8'h01,8'h07,8'h0F,8'h07,8'h07,8'h03,8'h03,8'h01,8'h01,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[ 4] = {8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[ 5] = {8'h00,8'h00,8'h00,8'h00,8'h01,8'h01,8'h03,8'h03,8'h03,8'h03,8'h03,8'h06,8'h0E,8'h0E,8'h07,8'h03};
        mem_image[ 6] = {8'h00,8'h00,8'h80,8'h80,8'hC0,8'hC0,8'hC0,8'hC0,8'hC0,8'hE0,8'h60,8'h60,8'h60,8'h20,8'h20,8'h20};
        mem_image[ 7] = {8'h03,8'h83,8'h83,8'h81,8'h81,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'h80,8'hC0,8'hC0,8'hC0,8'hC0};
        mem_image[ 8] = {8'h01,8'h03,8'h06,8'h0C,8'h18,8'h70,8'hE0,8'hC0,8'hC0,8'hFC,8'hFF,8'h1F,8'h07,8'h03,8'h00,8'h00};
        mem_image[ 9] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h03,8'hFF,8'hFF,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[10] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hC0,8'hE0,8'hE0,8'hF0,8'h30,8'h30,8'h60,8'hC0,8'h80,8'h00};
        mem_image[11] = {8'h00,8'h80,8'hC0,8'hE0,8'hE0,8'hC0,8'h87,8'h0F,8'h1F,8'h1F,8'h1E,8'h1E,8'h1E,8'h0F,8'h07,8'h00};
        mem_image[12] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h80,8'hC0,8'h60,8'h60};
        mem_image[13] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h60,8'h60,8'h60,8'h00,8'h03,8'h0F,8'h1F,8'h1E};
        mem_image[14] = {8'hE0,8'hE3,8'hC7,8'h9F,8'hFF,8'hF3,8'h03,8'h03,8'h03,8'h03,8'h03,8'h01,8'h01,8'h01,8'h01,8'h01};
        mem_image[15] = {8'h1F,8'h1F,8'h0F,8'h00,8'h00,8'h8F,8'hFF,8'hF8,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[16] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h1F,8'hFF,8'hF0,8'h00,8'h00,8'h00,8'h00,8'h0E};
        mem_image[17] = {8'h30,8'h30,8'h38,8'h18,8'h1C,8'h1C,8'h0C,8'h0E,8'hCE,8'hFF,8'h7F,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[18] = {8'h1F,8'h3F,8'h7F,8'h7F,8'h7F,8'h7F,8'h3F,8'h1F,8'h0E,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[19] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[20] = {8'h00,8'h00,8'h00,8'h0E,8'h0E,8'h0C,8'h0C,8'h0C,8'h0C,8'h0C,8'h0C,8'h0E,8'h0C,8'h00,8'h00,8'h00};
        mem_image[21] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'hC0,8'hC0};
        mem_image[22] = {8'h00,8'h00,8'h00,8'h00,8'h1F,8'hBF,8'hFF,8'hFF,8'h7F,8'h12,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[23] = {8'hE0,8'h30,8'h38,8'h1C,8'h0E,8'h07,8'h03,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[24] = {8'h0E,8'h1C,8'hF8,8'hF0,8'hE0,8'hF0,8'hF8,8'hFE,8'hFF,8'hC3,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[25] = {8'h06,8'h07,8'h1F,8'hFD,8'hFF,8'h0F,8'h03,8'h01,8'h01,8'h07,8'h03,8'h01,8'h00,8'h00,8'h7C,8'hFE};
        mem_image[26] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[27] = {8'hE0,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h02,8'h0F,8'hFF,8'hFC,8'h80,8'h00,8'h00};
        mem_image[28] = {8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h03,8'h0F};
        mem_image[29] = {8'h00,8'h00,8'h00,8'h00,8'hFC,8'hFE,8'hFE,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[30] = {8'hFF,8'hF8,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        mem_image[31] = {8'h00,8'hFF,8'hFF,8'h80,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
      end
    endcase
  end

endmodule

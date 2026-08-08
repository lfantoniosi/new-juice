module top
#(
    parameter SMS_DEBUGGER_ENABLED = 1'b1
)
(
    input   clkin,
    input   s1,
    input   s2,

    output tmds_clk_p,
    output tmds_clk_n,
    output [2:0] tmds_data_p,
    output [2:0] tmds_data_n,

    input cpu_clkin,
    input rd_n_in,
    input wr_n_in,
    input sltsl_n_in,

    inout int_out,
    output busdir_n,
    output wait_out,
    output datadir,

    inout [7:0] cd,

    input [7:0] mp,

    output [2:0] msel_n,

    // flash
    output mspi_cs,
    output mspi_sclk,
    inout mspi_miso,
    inout mspi_mosi,
 
    // MicroSD
    output sd_sclk,
    inout sd_cmd,
    inout sd_dat0,
    output sd_dat1,
    output sd_dat2,
    output sd_dat3,
   
    // SDRAM
    output O_sdram_clk,
    output O_sdram_cke,
    output O_sdram_cs_n,            // chip select
    output O_sdram_cas_n,           // columns address select
    output O_sdram_ras_n,           // row address select
    output O_sdram_wen_n,           // write enable
    inout [31:0] IO_sdram_dq,       // 32 bit bidirectional data bus
    output [10:0] O_sdram_addr,     // 11 bit multiplexed address bus
    output [1:0] O_sdram_ba,        // two banks
    output [3:0] O_sdram_dqm,      // 32/4

    output audio,
    output sound,

    output led

);
    wire clk;
    BUFG clk_buf(
    .O(clk),    // 27Mhz buffered output clock
    .I(clkin)   // 27Mhz input clock
    );

    // The external MSX CPU clock is sampled in the 108 MHz domain. It is not
    // used directly as an FPGA clock, avoiding a large asynchronous global
    // clock tree and its associated skew.
    wire cpu_clk = cpu_clkin;

    // Do not rely on an HDL declaration initializer to start the PLL reset
    // counter.  The explicit Gowin FF is held at INIT=0 by configuration GSR,
    // then becomes one on the first live 27 MHz edge.  That first edge also
    // asynchronously puts the counter and reset output into a known state.
    wire cold_start_seen;
    wire startup_test_passed;
    DFF #(
        .INIT(1'b0)
    ) cold_start_ff (
        .Q(cold_start_seen),
        .D(1'b1),
        .CLK(clk)
    );

    wire rpll_main_lock;
    (* syn_preserve = 1, ASYNC_REG = "TRUE" *)
    reg [1:0] main_lock_27_sync = 2'b00;
    reg [3:0] main_lock_stable_count = 4'd0;
    localparam [1:0] PLL_START_RESET = 2'b00;
    localparam [1:0] PLL_START_WAIT  = 2'b01;
    localparam [1:0] PLL_START_RUN   = 2'b11;
    reg [1:0] pll_start_state = PLL_START_RESET;
    reg [15:0] pll_start_count = 16'd0;

    // Generate one unconditional S1-equivalent pulse 250 ms after
    // configuration. The pulse generator is reset only by configuration GSR,
    // not by the reset pulse it creates, so it can run exactly once.
    localparam [22:0] AUTO_S1_DELAY_CYCLES = 23'd6_749_999;
    reg [22:0] auto_s1_delay_count = 23'd0;
    reg [4:0] auto_s1_pulse_count = 5'd0;
    reg auto_s1_done = 1'b0;
    reg auto_s1_active = 1'b0;

    always_ff @(posedge clk or negedge cold_start_seen)
    begin
        if (!cold_start_seen) begin
            auto_s1_delay_count <= 23'd0;
            auto_s1_pulse_count <= 5'd0;
            auto_s1_done <= 1'b0;
            auto_s1_active <= 1'b0;
        end else if (auto_s1_active) begin
            if (&auto_s1_pulse_count) begin
                auto_s1_pulse_count <= 5'd0;
                auto_s1_active <= 1'b0;
            end else begin
                auto_s1_pulse_count <= auto_s1_pulse_count + 1'b1;
            end
        end else if (!auto_s1_done) begin
            if (auto_s1_delay_count == AUTO_S1_DELAY_CYCLES) begin
                auto_s1_delay_count <= 23'd0;
                auto_s1_pulse_count <= 5'd0;
                auto_s1_done <= 1'b1;
                auto_s1_active <= 1'b1;
            end else begin
                auto_s1_delay_count <= auto_s1_delay_count + 1'b1;
            end
        end
    end

    wire pll_start_control_n =
        cold_start_seen && !s1 && !auto_s1_active;
    wire reset_n =
        pll_start_control_n && (pll_start_state != PLL_START_RESET);

    // Hold reset for 2.4 ms, then allow 2.4 ms for a qualified lock. If lock
    // is absent, repeat. Gray-adjacent state encodings prevent a reset glitch
    // when moving from the wait state to the permanent running state.
    always_ff @(posedge clk or negedge pll_start_control_n)
    begin
        if (!pll_start_control_n) begin
            main_lock_27_sync <= 2'b00;
            main_lock_stable_count <= 4'd0;
            pll_start_state <= PLL_START_RESET;
            pll_start_count <= 16'd0;
        end else begin
            main_lock_27_sync <=
                {main_lock_27_sync[0], rpll_main_lock};

            case (pll_start_state)
                PLL_START_RESET: begin
                    main_lock_stable_count <= 4'd0;
                    if (&pll_start_count) begin
                        pll_start_state <= PLL_START_WAIT;
                        pll_start_count <= 16'd0;
                    end else begin
                        pll_start_count <= pll_start_count + 1'b1;
                    end
                end

                PLL_START_WAIT: begin
                    if (main_lock_27_sync[1]) begin
                        if (&main_lock_stable_count) begin
                            pll_start_state <= PLL_START_RUN;
                            pll_start_count <= 16'd0;
                        end else begin
                            main_lock_stable_count <=
                                main_lock_stable_count + 1'b1;
                        end
                    end else begin
                        main_lock_stable_count <= 4'd0;
                        if (&pll_start_count) begin
                            pll_start_state <= PLL_START_RESET;
                            pll_start_count <= 16'd0;
                        end else begin
                            pll_start_count <= pll_start_count + 1'b1;
                        end
                    end
                end

                PLL_START_RUN: begin
                    pll_start_count <= 16'd0;
                    main_lock_stable_count <= 4'd0;
                end

                default: begin
                    pll_start_state <= PLL_START_RESET;
                    pll_start_count <= 16'd0;
                    main_lock_stable_count <= 4'd0;
                end
            endcase
        end
    end

    // WonderTANG performs one more short main-PLL reset after SDRAM has
    // completed its first successful startup. Keep this one-shot in the raw
    // 27 MHz domain so its state survives while main_clk is stopped.
    (* syn_preserve = 1, ASYNC_REG = "TRUE" *)
    reg [1:0] startup_passed_pll_sync = 2'b00;
    reg second_pll_reset_done = 1'b0;
    reg second_pll_reset_active = 1'b0;
    reg [4:0] second_pll_reset_count = 5'd0;

    always_ff @(posedge clk or negedge cold_start_seen)
    begin
        if (!cold_start_seen) begin
            startup_passed_pll_sync <= 2'b00;
            second_pll_reset_done <= 1'b0;
            second_pll_reset_active <= 1'b0;
            second_pll_reset_count <= 5'd0;
        end else begin
            startup_passed_pll_sync <=
                {startup_passed_pll_sync[0], startup_test_passed};

            if (!second_pll_reset_done &&
                startup_passed_pll_sync[1]) begin
                second_pll_reset_done <= 1'b1;
                second_pll_reset_active <= 1'b1;
                second_pll_reset_count <= 5'd0;
            end else if (second_pll_reset_active) begin
                if (&second_pll_reset_count) begin
                    second_pll_reset_active <= 1'b0;
                    second_pll_reset_count <= 5'd0;
                end else begin
                    second_pll_reset_count <=
                        second_pll_reset_count + 1'b1;
                end
            end
        end
    end

    wire module_sequence_done;
    wire pll_run_reset_n = reset_n && !second_pll_reset_active;
    wire board_reset_n;
    wire active_module_reset_n;
    wire sd_module_reset_n;
    wire slot_expander_reset_n;
    wire memory_mapper_reset_n;
    wire bios_module_enabled;
    wire psg_module_reset_n;
    wire opll_module_reset_n;
    wire megaram_module_reset_n;
    (* syn_preserve = 1, ASYNC_REG = "TRUE" *)
    reg [1:0] module_sequence_video_sync = 2'b00;

    // Start the video PLL only after every CPU-visible module has completed
    // its startup sequence. This automatically starts SMS and HDMI without
    // requiring an initial access to an SMS I/O port.
    always_ff @(posedge clk or negedge pll_run_reset_n)
    begin
        if (!pll_run_reset_n)
            module_sequence_video_sync <= 2'b00;
        else
            module_sequence_video_sync <=
                {module_sequence_video_sync[0], module_sequence_done};
    end

    wire video_pll_reset_n =
        pll_run_reset_n && second_pll_reset_done &&
        startup_passed_pll_sync[1] &&
        module_sequence_video_sync[1];
    (* syn_preserve = 1, ASYNC_REG = "TRUE" *)
    reg [1:0] startup_passed_sd_sync = 2'b00;
    reg [3:0] sd_stage_count = 4'd0;
    reg sd_stage_enabled = 1'b0;
    reg board_enabled = 1'b0;
    reg [9:0] main_lock_count = 10'd0;
    reg board_reset_release = 1'b0;
    (* syn_preserve = 1, ASYNC_REG = "TRUE" *)
    reg [1:0] sd_ready_main_sync = 2'b00;
    reg sd_ready_fall = 1'b0;
    reg flash_rom_loaded_fall = 1'b0;
    reg reset_in_n_fall = 1'b0;
    reg [3:0] cpu_modules_ready_count = 4'd0;
    reg cpu_modules_ready_reg = 1'b0;

    wire audio_sample_clock;
    wire signed [15:0] psg_audio_sample;
    wire signed [15:0] opll_audio_sample;
    wire signed [15:0] jt51_audio_sample;
    wire signed [15:0] keyclick_audio_sample;
    wire signed [10:0] scc_sound;
    wire signed [15:0] scc_audio_sample;
    wire signed [10:0] jt89_sound;
    wire signed [15:0] jt89_audio_sample;
    wire signed [17:0] audio_mix_wide;
    wire signed [17:0] sound_mix_wide;
    wire [15:0] mixed_audio_sample;
    wire [15:0] mixed_sound_sample;
    reg [15:0] audio_sample_hold = 16'd0;
    reg [15:0] sound_sample_hold = 16'd0;
    (* syn_preserve = 1, ASYNC_REG = "TRUE" *)
    reg [2:0] audio_sample_clock_sync = 3'b000;

    localparam INCLUDE_OPLL = 1'b1;

    // The older board has two independent one-bit analogue audio paths rather
    // than the serial headphone DAC. This clock controls when a coherent
    // sample is captured; each PWM accumulator itself runs at 108 MHz.
    clockdiv #(
        .CLK_HZ(27_000_000),
        .OUT_HZ(44_100)
    ) audio_sample_clock_divider (
        .clk_src(clk),
        .reset_n(board_reset_n),
        .clk_div(audio_sample_clock),
        .clk_rise()
    );
    
    // main pll
    wire main_clk;
    wire sdram_clk;
    rpll_main rpll_main(
        .clkout(main_clk), // 108 MHz main clock
        .lock(rpll_main_lock), 
        .clkoutp(sdram_clk), // 108 MHz rotated SDRAM clock
        .reset(~pll_run_reset_n),
        .clkin(clkin) //input clkin (27Mhz)
    );

    // The PLL lock output may transition during cold configuration. Keep all
    // board logic in reset until it has remained asserted for 1024 main-clock
    // cycles. S1 immediately resets both the PLL and this qualification delay.
    always_ff @(posedge main_clk or negedge pll_run_reset_n)
    begin
        if (!pll_run_reset_n) begin
            main_lock_count <= 10'd0;
            board_reset_release <= 1'b0;
        end else if (!board_reset_release) begin
            if (!rpll_main_lock)
                main_lock_count <= 10'd0;
            else if (&main_lock_count)
                board_reset_release <= 1'b1;
            else
                main_lock_count <= main_lock_count + 1'b1;
        end
    end

    // Franky/SMS video uses a 27 MHz pixel clock and a phase-related 135 MHz
    // serialization clock.  The SMS core itself follows WonderTANG's 54 MHz
    // master domain, with clock enables for each emulated subsystem.
    wire video_clk_135_raw;
    wire video_clk_135;
    wire rpll_video_lock;
    wire sms_clk_54_raw;
    wire sms_clk_54;

    rpll_video rpll_video_inst (
        .clkout(video_clk_135_raw),
        .lock(rpll_video_lock),
        .clkoutd(),
        .reset(~video_pll_reset_n),
        .clkin(clkin)
    );

    BUFG video_clk_135_buf (
        .O(video_clk_135),
        .I(video_clk_135_raw)
    );

    clockdiv2 sms_clock_divider (
        .clk_src(main_clk),
        .reset_n(board_reset_n),
        .clk_div(sms_clk_54_raw),
        .clk_rise()
    );

    BUFG sms_clk_54_buf (
        .O(sms_clk_54),
        .I(sms_clk_54_raw)
    );

    // Synchronize the 44.1 kHz sample clock into the mixer/PWM domain and
    // capture both mixes on the same edge. The separate holding registers let
    // the two physical outputs use different chip mixes later.
    always_ff @(posedge main_clk or negedge board_reset_n)
    begin
        if (!board_reset_n) begin
            audio_sample_clock_sync <= 3'b000;
            audio_sample_hold <= 16'd0;
            sound_sample_hold <= 16'd0;
        end else begin
            audio_sample_clock_sync <=
                {audio_sample_clock_sync[1:0], audio_sample_clock};

            if (audio_sample_clock_sync[1] &&
                !audio_sample_clock_sync[2]) begin
                audio_sample_hold <= mixed_audio_sample;
                sound_sample_hold <= mixed_sound_sample;
            end
        end
    end

    pwm_audio audio_pwm_inst (
        .clk(main_clk),
        .reset_n(board_reset_n),
        .sample(audio_sample_hold),
        .pwm(audio)
    );

    pwm_audio sound_pwm_inst (
        .clk(main_clk),
        .reset_n(board_reset_n),
        .sample(sound_sample_hold),
        .pwm(sound)
    );

    wire [7:0] a_lo;
    wire [7:0] a_hi;
    wire [15:0] addr;
    wire merq_n;
    wire iorq_n;
    wire cs1_n;
    wire cs2_n;
    wire reset_in_n;
    wire rfsh_n;
    wire cs12_n;
    wire m1_n;
    wire inputs_latched;
    wire rd_n;
    wire wr_n;
    wire sltsl_n;
    (* ASYNC_REG = "TRUE" *) reg [1:0] smr_rd_n_sync = 2'b11;
    (* ASYNC_REG = "TRUE" *) reg [1:0] smr_wr_n_sync = 2'b11;
    wire smr_rd_n_fast = smr_rd_n_sync[1];
    wire smr_wr_n_fast = smr_wr_n_sync[1];
    wire [7:0] slot_expander_data_out;
    wire slot_expander_data_out_en;
    wire [7:0] data_out;
    wire data_out_en;
    wire [7:0] sdram_mapper_data_out;
    wire sdram_mapper_data_out_en;
    wire [7:0] mapper_debug_page0;
    wire [7:0] mapper_debug_page1;
    wire [7:0] mapper_debug_page2;
    wire [7:0] mapper_debug_page3;
    wire [7:0] megaram_debug_bank0;
    wire [7:0] megaram_debug_bank1;
    wire [7:0] megaram_debug_bank2;
    wire [7:0] megaram_debug_bank3;
    wire [7:0] megaram_debug_mode;
    wire linear_mode_enabled;
    wire [7:0] debug_expanded_slot;
    wire [7:0] flash_rom_data_out;
    wire flash_rom_data_out_en;
    wire flash_rom_wait_n;
    wire flash_rom_loaded;
    wire mapper_wait_n;
    wire [7:0] smr_data_out;
    wire smr_data_out_en;
    wire smr_wait_n;
    wire [7:0] linear_data_out;
    wire linear_data_out_en;
    wire linear_wait_n;
    wire step_debug_toggle;
    wire [15:0] step_debug_breakpoint_address;
    wire step_debug_breakpoint_arm;
    wire step_debug_wait_n;
    wire step_debug_enabled;
    wire step_debug_instruction_color_alt;
    wire [7:0] sd_data_out;
    wire sd_data_out_en;
    wire sd_overlay_enabled;
    wire sd_busy;
    wire [3:0] page0_subslot_en;
    wire [3:0] page1_subslot_en;
    wire [3:0] page2_subslot_en;
    wire [3:0] page3_subslot_en;
    wire int_n;
    wire wait_n;
    wire mapper_port_read;
    wire [7:0] cd_in;
    wire memory_wait_n = module_sequence_done &&
                         startup_test_wait_n && flash_rom_wait_n;
    //wire memory_wait_n = module_sequence_done &&
    //                     startup_test_wait_n && flash_rom_wait_n &&
    //                     smr_wait_n && linear_wait_n && mapper_wait_n;

    wire sdrc_cmd_en;
    wire [2:0] sdrc_cmd;
    wire sdrc_precharge_ctrl;
    wire sdram_power_down;
    wire sdram_selfrefresh;
    wire [20:0] sdrc_addr;
    wire [3:0] sdrc_dqm;
    wire [31:0] sdrc_data;
    wire [7:0] sdrc_data_len;
    wire [31:0] sdrc_data_in;
    wire sdrc_init_done;

    // Super-MegaRAM and the expanded-slot register must distinguish a memory
    // access from the refresh phase immediately following M1. The general bus
    // debouncer intentionally changes slowly and can retain RD low after the
    // multiplexed address has already become I:R, so use dedicated two-flop
    // strobe synchronizers for these paths.
    always_ff @(posedge main_clk or negedge board_reset_n)
    begin
        if (!board_reset_n) begin
            smr_rd_n_sync <= 2'b11;
            smr_wr_n_sync <= 2'b11;
        end else begin
            smr_rd_n_sync <= {smr_rd_n_sync[0], rd_n_in};
            smr_wr_n_sync <= {smr_wr_n_sync[0], wr_n_in};
        end
    end
    wire sdrc_cmd_ack;
    wire mapper_sdrc_cmd_en;
    wire [2:0] mapper_sdrc_cmd;
    wire mapper_sdrc_precharge_ctrl;
    wire mapper_sdram_power_down;
    wire mapper_sdram_selfrefresh;
    wire [20:0] mapper_sdrc_addr;
    wire [3:0] mapper_sdrc_dqm;
    wire [31:0] mapper_sdrc_data;
    wire [7:0] mapper_sdrc_data_len;
    wire smr_sdrc_cmd_en;
    wire [2:0] smr_sdrc_cmd;
    wire [20:0] smr_sdrc_addr;
    wire [3:0] smr_sdrc_dqm;
    wire [31:0] smr_sdrc_data;
    wire linear_sdrc_cmd_en;
    wire [2:0] linear_sdrc_cmd;
    wire [20:0] linear_sdrc_addr;
    wire [3:0] linear_sdrc_dqm;
    wire [31:0] linear_sdrc_data;
    wire rom_sdrc_cmd_en;
    wire [2:0] rom_sdrc_cmd;
    wire [20:0] rom_sdrc_addr;
    wire [3:0] rom_sdrc_dqm;
    wire [31:0] rom_sdrc_data;
    wire test_sdrc_cmd_en;
    wire [2:0] test_sdrc_cmd;
    wire test_sdrc_precharge_ctrl;
    wire test_sdram_power_down;
    wire test_sdram_selfrefresh;
    wire [20:0] test_sdrc_addr;
    wire [3:0] test_sdrc_dqm;
    wire [31:0] test_sdrc_data;
    wire [7:0] test_sdrc_data_len;
    wire startup_test_failed;
    wire startup_test_wait_n;
    wire startup_test_led;
    wire native_sdram_rd;
    wire native_sdram_wr;
    wire native_sdram_refresh;
    wire [22:0] native_sdram_addr;
    wire [15:0] native_sdram_din;
    wire [1:0] native_sdram_wdm;
    wire [15:0] native_sdram_dout;
    wire [31:0] native_sdram_dout32;
    wire native_sdram_data_ready;
    wire native_sdram_busy;
    wire native_sdram_enabled;
    reg [2:0] psg_cpu_clk_sync = 3'b000;
    (* syn_preserve = 1, ASYNC_REG = "TRUE" *)
    reg [2:0] psg_synth_enable_sync = 3'b000;
    (* syn_preserve = 1, ASYNC_REG = "TRUE" *)
    reg [1:0] psg_reset_sync = 2'b00;
    reg psg_divide_phase = 1'b0;
    reg psg_clock_enable = 1'b0;
    wire psg_address_write;
    wire psg_data_write;
    wire psg_bdir;
    wire psg_bc;
    reg psg_bdir_latched = 1'b0;
    reg psg_bc_latched = 1'b0;
    reg [7:0] psg_data_latched = 8'h00;
    wire [9:0] jt49_sound;
    reg [9:0] psg_filter_history [0:15];
    reg [3:0] psg_filter_index = 4'd0;
    reg [13:0] psg_filter_sum = 14'd0;
    wire [14:0] psg_filter_next =
        {1'b0, psg_filter_sum} + {5'd0, jt49_sound} -
        {5'd0, psg_filter_history[psg_filter_index]};
    wire [9:0] psg_sound = psg_filter_sum[13:4];
    wire ppi_port_c_write;
    wire ppi_control_write;
    reg keyclick_level = 1'b0;
    wire opll_write_selected;
    wire jt51_chip_selected;
    wire jt51_status_read;
    wire [7:0] jt51_data_out;
    wire jt51_irq_n;
    wire signed [15:0] jt51_left;
    wire signed [15:0] jt51_right;
    wire signed [16:0] jt51_stereo_sum;
    reg jt51_clock_phase = 1'b0;
    // 27 MHz * 569408471 / 2^32 = 3,579,545.0017 Hz.
    localparam [31:0] OPLL_PHASE_INCREMENT = 32'd569408471;
    reg [31:0] opll_phase_accumulator = 32'd0;
    reg opll_clock_enable = 1'b0;

    always_ff @(posedge main_clk or negedge board_reset_n)
    begin
        if (!board_reset_n) begin
            board_enabled <= 1'b0;
        end else begin
            board_enabled <= 1'b1;
        end
    end

    assign board_reset_n = board_reset_release;

    // Assert the PSG reset immediately with the module sequence, but release
    // it synchronously in the 108 MHz JT49 domain. This prevents the staged
    // module-ready net from entering every PSG state path as a reset-release
    // timing source.
    always_ff @(posedge main_clk or negedge psg_module_reset_n)
    begin
        if (!psg_module_reset_n)
            psg_reset_sync <= 2'b00;
        else
            psg_reset_sync <= {psg_reset_sync[0], 1'b1};
    end

    // Keep a synchronized copy of the external CPU clock for bus interfaces
    // that need its level. For the PSG, synchronize the existing synthesized
    // 3.579545 MHz YM2413 enable from the 27 MHz domain. Every second rising
    // edge advances JT49 at its required 1.7897725 MHz rate.
    always_ff @(posedge main_clk or negedge board_reset_n)
    begin
        if (!board_reset_n) begin
            psg_cpu_clk_sync <= 3'b000;
            psg_synth_enable_sync <= 3'b000;
            psg_divide_phase <= 1'b0;
            psg_clock_enable <= 1'b0;
        end else begin
            psg_cpu_clk_sync <= {psg_cpu_clk_sync[1:0], cpu_clk};
            psg_synth_enable_sync <=
                {psg_synth_enable_sync[1:0], opll_clock_enable};
            psg_clock_enable <= 1'b0;

            if (psg_synth_enable_sync[1] &&
                !psg_synth_enable_sync[2]) begin
                psg_divide_phase <= ~psg_divide_phase;
                if (psg_divide_phase)
                    psg_clock_enable <= 1'b1;
            end
        end
    end

    // MSX PSG I/O ports. This is deliberately a write-only slave: port A2
    // reads are not decoded and the PSG output data is never put on cd.
    // The PSG's synchronized reset already suppresses all activity until the
    // module sequence is ready, so its bus decode does not need the startup
    // flag on this timing-sensitive combinational path.
    assign psg_address_write = !iorq_n && m1_n && !wr_n &&
                               addr[7:0] == 8'hA0;
    assign psg_data_write = !iorq_n && m1_n && !wr_n &&
                            addr[7:0] == 8'hA1;
    assign psg_bdir = psg_address_write || psg_data_write;
    assign psg_bc = psg_address_write;

    // Register the slow external I/O decode before JT49's bus wrapper. A PSG
    // I/O cycle spans many 108 MHz clocks, so this one-clock pipeline retains
    // bus behavior while removing the multiplexed address path from JT49's
    // internal write-control timing cone.
    always_ff @(posedge main_clk or negedge psg_module_reset_n)
    begin
        if (!psg_module_reset_n) begin
            psg_bdir_latched <= 1'b0;
            psg_bc_latched <= 1'b0;
            psg_data_latched <= 8'h00;
        end else begin
            psg_bdir_latched <= psg_bdir;
            psg_bc_latched <= psg_bc;
            psg_data_latched <= cd_in;
        end
    end

    // The MSX key click is not a fixed-frequency oscillator. PPI port C bit 7
    // is a one-bit audio level; software makes tones and digitized speech by
    // toggling it. Observe both ways software can change that output: a full
    // port-C write at AAh and the 8255 bit-set/reset command at ABh. A mode-set
    // command clears the 8255 output latches, including the key-click output.
    assign ppi_port_c_write = !iorq_n && m1_n && !wr_n &&
                              addr[7:0] == 8'hAA;
    assign ppi_control_write = !iorq_n && m1_n && !wr_n &&
                               addr[7:0] == 8'hAB;

    always_ff @(posedge main_clk or negedge board_reset_n)
    begin
        if (!board_reset_n)
            keyclick_level <= 1'b0;
        else if (ppi_port_c_write)
            keyclick_level <= cd_in[7];
        else if (ppi_control_write && cd_in[7])
            keyclick_level <= 1'b0;
        else if (ppi_control_write && cd_in[3:1] == 3'd7)
            keyclick_level <= cd_in[0];
    end

    jt49_bus #(
        // AY/YM tone period zero behaves as period one. This is required by
        // PSG-DAC software such as Aleste 2's synthesized speech.
        .MUTE_NULL_PERIOD(1'b0)
    ) psg_inst (
        .rst_n(psg_reset_sync[1]),
        .clk(main_clk),
        .clk_en(psg_clock_enable),
        .bdir(psg_bdir_latched),
        .bc1(psg_bc_latched),
        .din(psg_data_latched),
        .sel(1'b1),
        .dout(),
        .sound(jt49_sound),
        .A(),
        .B(),
        .C(),
        .sample(),
        .IOA_in(8'hff),
        .IOA_out(),
        .IOA_oe(),
        .IOB_in(8'hff),
        .IOB_out(),
        .IOB_oe()
    );

    // JT49 produces the period-one carrier digitally at 111.86 kHz. A real
    // MSX attenuates that ultrasonic carrier in the analogue output stage but
    // preserves rapid amplitude-register changes. Average exactly one carrier
    // period (16 JT49 input enables) before the shared 44.1 kHz audio sampler.
    // The resulting boxcar filter also prevents the carrier alias that led
    // upstream JT49 to force period zero silent.
    integer psg_filter_i;
    always_ff @(posedge main_clk or negedge psg_reset_sync[1])
    begin
        if (!psg_reset_sync[1]) begin
            psg_filter_index <= 4'd0;
            psg_filter_sum <= 14'd0;
            for (psg_filter_i = 0; psg_filter_i < 16;
                 psg_filter_i = psg_filter_i + 1)
                psg_filter_history[psg_filter_i] <= 10'd0;
        end else if (psg_clock_enable) begin
            psg_filter_history[psg_filter_index] <= jt49_sound;
            psg_filter_sum <= psg_filter_next[13:0];
            psg_filter_index <= psg_filter_index + 1'b1;
        end
    end

    // MSX-Music/YM2413 ports 7C (address) and 7D (data). Both are write-only.
    // The OPLL is held in its own module reset until startup completes.
    // Keeping that same startup flag out of the write decode avoids a long
    // combinational path into the sound core.
    assign opll_write_selected = !iorq_n && m1_n && !wr_n &&
                                 addr[7:1] == 7'h3E;

    // Advance JT2413 at the native MSX-Music rate while keeping the whole
    // core on the clean 27 MHz clock tree. The carry is a one-cycle enable.
    always_ff @(posedge clk or negedge opll_module_reset_n)
    begin
        if (!opll_module_reset_n) begin
            opll_phase_accumulator <= 32'd0;
            opll_clock_enable <= 1'b0;
            jt51_clock_phase <= 1'b0;
        end else begin
            {opll_clock_enable, opll_phase_accumulator} <=
                {1'b0, opll_phase_accumulator} +
                {1'b0, OPLL_PHASE_INCREMENT};
            if (opll_clock_enable)
                jt51_clock_phase <= ~jt51_clock_phase;
        end
    end

    generate
        if (INCLUDE_OPLL) begin : opll_enabled_impl
            wire signed [15:0] jt2413_sound;

            jt2413 jt2413_inst (
                .rst(~opll_module_reset_n),
                .clk(clk),
                .cen(opll_clock_enable),
                .din(cd_in),
                .addr(addr[0]),
                .cs_n(~opll_write_selected),
                .wr_n(wr_n),
                .snd(jt2413_sound),
                .sample()
            );

            assign opll_audio_sample = jt2413_sound;
        end else begin : opll_disabled_impl
            assign opll_audio_sample = 16'sd0;
        end
    endgenerate

    // SFG-01/YM2151 memory-mapped interface in expanded subslot 1.
    // 3FF0 selects a register and returns status; 3FF1 writes register data.
    assign jt51_chip_selected =
        active_module_reset_n && !sltsl_n && page0_subslot_en[1] &&
        !merq_n && iorq_n && rfsh_n && addr[15:1] == 15'h1ff8;
    assign jt51_status_read =
        jt51_chip_selected && !rd_n && addr[0] == 1'b0;

    // JT51 runs at the same precise 3.579545 MHz enable as JT2413. Its P1
    // enable is asserted on every second chip enable, matching the core API.
    jt51 jt51_inst (
        .rst(~opll_module_reset_n),
        .clk(clk),
        .cen(opll_clock_enable),
        .cen_p1(opll_clock_enable && jt51_clock_phase),
        .cs_n(~jt51_chip_selected),
        .wr_n(wr_n),
        .a0(addr[0]),
        .din(cd_in),
        .dout(jt51_data_out),
        .ct1(),
        .ct2(),
        .irq_n(jt51_irq_n),
        .sample(),
        .left(jt51_left),
        .right(jt51_right),
        .xleft(),
        .xright()
    );

    // Average the stereo outputs to mono, retaining the full signed range.
    assign jt51_stereo_sum =
        {jt51_left[15], jt51_left} + {jt51_right[15], jt51_right};
    assign jt51_audio_sample = jt51_stereo_sum[16:1];

    // JT49's unsigned 10-bit mix has true zero at silence. Scale it into the
    // same approximate 14-bit range used by the previous PSG implementation.
    assign psg_audio_sample = {2'b00, psg_sound, 4'b0000};
    // The original signal is attenuated before being mixed with the PSG.
    // Feed its one-bit level directly into the existing wide mixer; software
    // controls every transition and therefore the resulting frequency.
    assign keyclick_audio_sample =
        keyclick_level ? 16'sh1000 : 16'sd0;
    // Scale the 11-bit SCC and JT89 outputs into the same useful range.
    // This exact sample feeds both the physical audio DAC and HDMI.
    assign scc_audio_sample = {{2{scc_sound[10]}}, scc_sound, 3'b000};
    // JT89 is intentionally attenuated by one bit relative to the other
    // sources before entering the shared mix.
    assign jt89_audio_sample = {{2{jt89_sound[10]}}, jt89_sound, 3'b00};
    // Keep the two board outputs as independent mixes. They intentionally
    // start with identical source lists; remove or rescale terms in only one
    // expression when a chip should be excluded from that physical path.
    assign audio_mix_wide =
        {{2{psg_audio_sample[15]}}, psg_audio_sample} +
        {{2{opll_audio_sample[15]}}, opll_audio_sample} +
        {{3{jt51_audio_sample[15]}}, jt51_audio_sample[15:1]} +
        {{2{scc_audio_sample[15]}}, scc_audio_sample} +
        {{2{jt89_audio_sample[15]}}, jt89_audio_sample} +
        {{2{keyclick_audio_sample[15]}}, keyclick_audio_sample};
    assign sound_mix_wide =
        {{2{psg_audio_sample[15]}}, psg_audio_sample} +
        {{2{opll_audio_sample[15]}}, opll_audio_sample} +
        {{3{jt51_audio_sample[15]}}, jt51_audio_sample[15:1]} +
        {{2{scc_audio_sample[15]}}, scc_audio_sample} +
        {{2{jt89_audio_sample[15]}}, jt89_audio_sample} +
        {{2{keyclick_audio_sample[15]}}, keyclick_audio_sample};
    // JT51 is attenuated by 6 dB above after its stereo-to-mono average.
    // Reducing the complete mix by 6 dB then guarantees 16-bit headroom
    // without changing the established levels of the other sources.
    assign mixed_audio_sample = audio_mix_wide[16:1];
    assign mixed_sound_sample = sound_mix_wide[16:1];

    // ---------------------------------------------------------------------
    // Franky / Sega Master System VDP and PSG
    // ---------------------------------------------------------------------
    // Start the high-toggle SMS/HDMI logic after SDRAM and SD have left reset,
    // so it is already stable before the mapper and the MSX bus are released.
    // Its CPU port decode remains disabled until the full sequence completes.
    wire sms_reset_request_n =
        active_module_reset_n && rpll_video_lock;
    (* syn_preserve = 1, ASYNC_REG = "TRUE" *)
    reg [1:0] sms_reset_sync = 2'b00;
    wire sms_reset_n = sms_reset_sync[1];

    // Assert immediately if either board clock is unavailable, but release
    // reset only after two clean edges in the SMS domain.
    always_ff @(posedge sms_clk_54 or negedge sms_reset_request_n)
    begin
        if (!sms_reset_request_n)
            sms_reset_sync <= 2'b00;
        else
            sms_reset_sync <= {sms_reset_sync[0], 1'b1};
    end

    reg [4:0] sms_divider = 5'd0;
    reg sms_ce_sp = 1'b0;
    reg sms_ce_vdp = 1'b0;
    reg sms_ce_pix = 1'b0;
    reg sms_ce_cpu = 1'b0;
    wire sms_ce_sp_buf;
    wire sms_ce_vdp_buf;
    wire sms_ce_pix_buf;
    wire sms_ce_cpu_buf;

    // 54 MHz / 30 timing wheel:
    //   ce_sp  = 27.0 MHz, ce_vdp = 10.8 MHz,
    //   ce_pix = 5.4 MHz, ce_cpu = 3.6 MHz.
    always_ff @(negedge sms_clk_54 or negedge sms_reset_n)
    begin
        if (!sms_reset_n) begin
            sms_divider <= 5'd0;
            sms_ce_sp <= 1'b0;
            sms_ce_vdp <= 1'b0;
            sms_ce_pix <= 1'b0;
            sms_ce_cpu <= 1'b0;
        end else begin
            sms_ce_sp <= sms_divider[0];
            sms_ce_vdp <= 1'b0;
            sms_ce_pix <= 1'b0;
            sms_ce_cpu <= 1'b0;
            sms_divider <= sms_divider + 1'b1;

            case (sms_divider)
                5'd4, 5'd14:
                    sms_ce_vdp <= 1'b1;
                5'd9: begin
                    sms_ce_vdp <= 1'b1;
                    sms_ce_pix <= 1'b1;
                    sms_ce_cpu <= 1'b1;
                end
                5'd19: begin
                    sms_ce_vdp <= 1'b1;
                    sms_ce_pix <= 1'b1;
                end
                5'd24: begin
                    sms_ce_vdp <= 1'b1;
                    sms_ce_cpu <= 1'b1;
                end
                5'd29: begin
                    sms_divider <= 5'd0;
                    sms_ce_vdp <= 1'b1;
                    sms_ce_pix <= 1'b1;
                end
                default: begin
                end
            endcase
        end
    end

    // Match WonderTANG's Franky clocking: the four periodic clock-enable
    // signals use dedicated global buffers before reaching the SMS cores.
    // Keeping every consumer on the buffered copies also preserves their
    // relative phase across the VDP, video timing, JT89 and bus bridge.
    BUFG sms_ce_sp_bufg (
        .O(sms_ce_sp_buf),
        .I(sms_ce_sp)
    );

    BUFG sms_ce_vdp_bufg (
        .O(sms_ce_vdp_buf),
        .I(sms_ce_vdp)
    );

    BUFG sms_ce_pix_bufg (
        .O(sms_ce_pix_buf),
        .I(sms_ce_pix)
    );

    BUFG sms_ce_cpu_bufg (
        .O(sms_ce_cpu_buf),
        .I(sms_ce_cpu)
    );

    wire sms_vdp_selected =
        sms_reset_n && !iorq_n && m1_n &&
        addr[7:1] == 7'b1000100;
    wire sms_psg_selected =
        sms_reset_n && !iorq_n && m1_n &&
        addr[7:1] == 7'b0100100;
    // WonderTANG mirrors VDP reads through the nominal PSG ports 48h/49h.
    // Writes to those ports still go only to the PSG.
    wire sms_vdp_read_selected =
        (sms_vdp_selected || sms_psg_selected) && !rd_n;
    wire sms_vdp_access =
        (sms_vdp_selected && (!rd_n || !wr_n)) ||
        (sms_psg_selected && !rd_n);
    reg sms_vdp_activated = 1'b0;

    // The sound display owns the framebuffer until software first touches
    // either SMS VDP port, including mirrored reads at 48h/49h. Once
    // activated, SMS video owns it until the next board or external MSX reset.
    // PSG writes do not switch it.
    always_ff @(posedge main_clk or negedge board_reset_n)
    begin
        if (!board_reset_n || !reset_in_n)
            sms_vdp_activated <= 1'b0;
        else if (sms_vdp_access)
            sms_vdp_activated <= 1'b1;
    end

    wire sms_vdp_rd_n;
    wire sms_vdp_wr_n;
    wire sms_psg_wr_n;
    wire [7:0] sms_vdp_data_out;
    wire [7:0] sms_bridge_read_data;
    wire sms_bridge_read_data_en;
    wire sms_vdp_rd_request_n =
        sms_vdp_read_selected ? 1'b0 : 1'b1;
    wire sms_vdp_wr_request_n =
        (!wr_n && sms_vdp_selected) ? 1'b0 : 1'b1;
    reg sms_vdp_rd_strobe_n = 1'b1;
    reg sms_vdp_wr_strobe_n = 1'b1;
    reg sms_prev_vdp_rd_n = 1'b1;
    reg sms_prev_vdp_wr_n = 1'b1;

    // WonderTANG's Franky bus interface holds each VDP request until the
    // 54 MHz domain observes its edge, then releases it on a VDP enable.
    always_ff @(posedge sms_clk_54 or negedge sms_reset_n)
    begin
        if (!sms_reset_n) begin
            sms_vdp_rd_strobe_n <= 1'b1;
            sms_vdp_wr_strobe_n <= 1'b1;
            sms_prev_vdp_rd_n <= 1'b1;
            sms_prev_vdp_wr_n <= 1'b1;
        end else begin
            if (sms_ce_vdp_buf) begin
                sms_vdp_rd_strobe_n <= 1'b1;
                sms_vdp_wr_strobe_n <= 1'b1;
            end

            if (sms_prev_vdp_rd_n != sms_vdp_rd_request_n) begin
                sms_vdp_rd_strobe_n <= sms_vdp_rd_request_n;
                sms_prev_vdp_rd_n <= sms_vdp_rd_request_n;
            end

            if (sms_prev_vdp_wr_n != sms_vdp_wr_request_n) begin
                sms_vdp_wr_strobe_n <= sms_vdp_wr_request_n;
                sms_prev_vdp_wr_n <= sms_vdp_wr_request_n;
            end
        end
    end

    assign sms_vdp_rd_n = sms_vdp_rd_strobe_n;
    assign sms_vdp_wr_n = sms_vdp_wr_strobe_n;
    assign sms_psg_wr_n =
        (!wr_n && sms_psg_selected) ? 1'b0 : 1'b1;
    assign sms_bridge_read_data = sms_vdp_data_out;
    assign sms_bridge_read_data_en = sms_vdp_read_selected;

    jt89 sms_psg_inst (
        .rst(~sms_reset_n),
        .clk(sms_clk_54),
        .clk_en(sms_ce_cpu_buf),
        .wr_n(sms_psg_wr_n),
        .din(cd_in),
        .mux(8'hFF),
        .soundL(jt89_sound),
        .soundR(),
        .ready()
    );

    wire [8:0] sms_vdp_x;
    wire [8:0] sms_vdp_y;
    wire [11:0] sms_vdp_color;
    wire sms_vdp_irq_n;
    wire sms_vdp_mask_column;
    wire sms_vdp_mode_m1;
    wire sms_vdp_mode_m2;
    wire sms_vdp_mode_m3;
    wire sms_vdp_mode_m4;

    vdp #(
        .MAX_SPPL(7)
    ) sms_vdp_inst (
        .clk_sys(sms_clk_54),
        .ce_vdp(sms_ce_vdp_buf),
        .ce_pix(sms_ce_pix_buf),
        .ce_sp(sms_ce_sp_buf),
        .gg(1'b0),
        .sp64(1'b0),
        .HL(1'b0),
        .RD_n(sms_vdp_rd_n),
        .WR_n(sms_vdp_wr_n),
        .IRQ_n(sms_vdp_irq_n),
        .A(addr[7:0]),
        .D_in(cd_in),
        .D_out(sms_vdp_data_out),
        .x(sms_vdp_x),
        .y(sms_vdp_y),
        .color(sms_vdp_color),
        .mask_column(sms_vdp_mask_column),
        .smode_M1(sms_vdp_mode_m1),
        .smode_M2(sms_vdp_mode_m2),
        .smode_M3(sms_vdp_mode_m3),
        .smode_M4(sms_vdp_mode_m4),
        .reset_n(sms_reset_n)
    );

    wire sms_vdp_hsync;
    wire sms_vdp_vsync;
    wire sms_vdp_hblank;
    wire sms_vdp_vblank;

    video sms_video_timing_inst (
        .clk(sms_clk_54),
        .ce_pix(sms_ce_pix_buf),
        .pal(1'b0),
        .gg(1'b0),
        .border(1'b0),
        .mask_column(sms_vdp_mask_column),
        .smode_M1(sms_vdp_mode_m1),
        .smode_M3(sms_vdp_mode_m3),
        .x(sms_vdp_x),
        .y(sms_vdp_y),
        .hsync(sms_vdp_hsync),
        .vsync(sms_vdp_vsync),
        .hblank(sms_vdp_hblank),
        .vblank(sms_vdp_vblank)
    );

    // Capture the SMS raster into a true dual-port framebuffer.  The write
    // side remains wholly in the 54 MHz SMS domain; HDMI reads at 27 MHz.
    reg [8:0] sms_fb_x = 9'h1FE;
    reg [8:0] sms_fb_y = 9'd0;
    wire [15:0] sms_fb_write_addr = {sms_fb_y[7:0], sms_fb_x[7:0]};
    wire [5:0] sms_fb_read_data;
    wire [5:0] sound_scope_pixel;
    wire [5:0] sms_vdp_framebuffer_pixel =
        {sms_vdp_color[11:10], sms_vdp_color[7:6], sms_vdp_color[3:2]};
    reg [1:0] sms_vdp_activated_fb_sync = 2'b00;

    always_ff @(posedge clk or negedge sms_reset_n)
    begin
        if (!sms_reset_n)
            sms_vdp_activated_fb_sync <= 2'b00;
        else
            sms_vdp_activated_fb_sync <=
                {sms_vdp_activated_fb_sync[0], sms_vdp_activated};
    end

    sound_scope sound_scope_inst (
        .clk(clk),
        .reset_n(sms_reset_n),
        .x(sms_fb_x[7:0]),
        .y(sms_fb_y[7:0]),
        .psg_sample(psg_sound),
        .scc_sample(scc_sound),
        .opll_sample(opll_audio_sample),
        .opm_sample(jt51_audio_sample),
        .pixel(sound_scope_pixel)
    );

    always_ff @(posedge sms_clk_54 or negedge sms_reset_n)
    begin
        if (!sms_reset_n) begin
            sms_fb_x <= 9'h1FE;
            sms_fb_y <= 9'd0;
        end else if (sms_ce_pix_buf) begin
            sms_fb_x <= sms_fb_x + 1'b1;
            if (sms_vdp_x == 9'd0) begin
                sms_fb_x <= 9'h1FE;
                sms_fb_y <= sms_fb_y + 1'b1;
            end
            if (sms_vdp_y == 9'd0)
                sms_fb_y <= 9'd0;
        end
    end

    wire [9:0] hdmi_x;
    wire [9:0] hdmi_y;
    reg [9:0] hdmi_x_offset = 10'd0;
    reg [9:0] hdmi_y_offset = 10'd0;
    wire [15:0] sms_fb_read_addr =
        {hdmi_y_offset[8:1], hdmi_x_offset[8:1]};
    wire hdmi_fb_window_active =
        !hdmi_x_offset[9] &&
        !hdmi_y_offset[9] &&
        (hdmi_y_offset < 10'd384);

    always_ff @(posedge clk or negedge sms_reset_n)
    begin
        if (!sms_reset_n) begin
            hdmi_x_offset <= 10'd0;
            hdmi_y_offset <= 10'd0;
        end else begin
            hdmi_x_offset <= hdmi_x - 10'd112;
            hdmi_y_offset <= hdmi_y - 10'd44;
        end
    end

    dpram #(
        .widthad_a(16),
        .width_a(6)
    ) sms_framebuffer_inst (
        .clock_a(clk),
        .address_a(sms_fb_write_addr),
        .wren_a(!sms_fb_x[8] && !sms_fb_y[8]),
        .rden_a(1'b0),
        .data_a(sms_vdp_activated_fb_sync[1] ?
                sms_vdp_framebuffer_pixel : sound_scope_pixel),
        .q_a(),
        .clock_b(clk),
        .address_b(sms_fb_read_addr),
        .wren_b(1'b0),
        .rden_b(1'b1),
        .data_b(6'd0),
        .q_b(sms_fb_read_data)
    );

    wire sms_debug_terminal_pixel;
    generate
        if (SMS_DEBUGGER_ENABLED) begin : sms_debugger_enabled_impl
            debug_trace_terminal debug_trace_terminal_inst (
                .cpu_clk(main_clk),
                .pixel_clk(clk),
                .reset_n(board_reset_n),
                .display_enabled(step_debug_enabled),
                .debug_wait_n(step_debug_wait_n),
                .bus_address(addr),
                .bus_data(cd_in),
                .m1_n(m1_n),
                .merq_n(merq_n),
                .rd_n(rd_n),
                .wr_n(wr_n),
                .rfsh_n(rfsh_n),
                .x(hdmi_x),
                .y(hdmi_y),
                .subslot(debug_expanded_slot),
                .mapper_page0(mapper_debug_page0),
                .mapper_page1(mapper_debug_page1),
                .mapper_page2(mapper_debug_page2),
                .mapper_page3(mapper_debug_page3),
                .megaram_bank0(megaram_debug_bank0),
                .megaram_bank1(megaram_debug_bank1),
                .megaram_bank2(megaram_debug_bank2),
                .megaram_bank3(megaram_debug_bank3),
                .megaram_type(megaram_debug_mode),
                .pixel(sms_debug_terminal_pixel)
            );
        end else begin : sms_debugger_disabled_impl
            assign sms_debug_terminal_pixel = 1'b0;
        end
    endgenerate

    wire [7:0] hdmi_base_red =
        hdmi_fb_window_active ? {sms_fb_read_data[1:0], 6'd0} : 8'd0;
    wire [7:0] hdmi_base_green =
        hdmi_fb_window_active ? {sms_fb_read_data[3:2], 6'd0} : 8'd0;
    wire [7:0] hdmi_base_blue =
        hdmi_fb_window_active ? {sms_fb_read_data[5:4], 6'd0} : 8'd0;
    // Debug mode owns the complete HDMI picture: white trace text on black.
    // As soon as it is disabled the normal SMS VDP/sound-scope image resumes.
    wire [7:0] hdmi_red = step_debug_enabled ?
                          {8{sms_debug_terminal_pixel}} : hdmi_base_red;
    wire [7:0] hdmi_green = step_debug_enabled ?
                            {8{sms_debug_terminal_pixel}} : hdmi_base_green;
    wire [7:0] hdmi_blue = step_debug_enabled ?
                           {8{sms_debug_terminal_pixel}} : hdmi_base_blue;

    wire hdmi_audio_clk_raw;
    wire hdmi_audio_clk;
    clockdiv #(
        .CLK_HZ(27_000_000),
        .OUT_HZ(44_100)
    ) hdmi_audio_clock_divider (
        .clk_src(clk),
        .reset_n(sms_reset_n),
        .clk_div(hdmi_audio_clk_raw),
        .clk_rise()
    );

    BUFG hdmi_audio_clk_buf (
        .O(hdmi_audio_clk),
        .I(hdmi_audio_clk_raw)
    );

    reg [15:0] hdmi_mix_meta = 16'd0;
    reg [15:0] hdmi_mix_sample = 16'd0;
    // Apply one bit of gain only to HDMI, with saturation rather than wrap.
    wire signed [16:0] hdmi_mix_louder_wide =
        $signed({audio_sample_hold[15], audio_sample_hold}) <<< 1;
    wire [15:0] hdmi_mix_louder_sample =
        hdmi_mix_louder_wide[16:15] == 2'b00 ||
        hdmi_mix_louder_wide[16:15] == 2'b11 ? hdmi_mix_louder_wide[15:0] :
        hdmi_mix_louder_wide[16] ? 16'h8000 : 16'h7FFF;
    always_ff @(posedge clk or negedge sms_reset_n)
    begin
        if (!sms_reset_n) begin
            hdmi_mix_meta <= 16'd0;
            hdmi_mix_sample <= 16'd0;
        end else begin
            // audio_sample_hold is a coherent, slowly changing snapshot of
            // the same complete mix sent to audio_drive.
            hdmi_mix_meta <= hdmi_mix_louder_sample;
            hdmi_mix_sample <= hdmi_mix_meta;
        end
    end

    wire [15:0] hdmi_audio_samples [1:0];
    assign hdmi_audio_samples[0] = hdmi_mix_sample;
    assign hdmi_audio_samples[1] = hdmi_mix_sample;

    wire [9:0] hdmi_tmds_internal [2:0];
    hdmi #(
        .VIDEO_ID_CODE(2),
        .DVI_OUTPUT(1'b0),
        .VIDEO_REFRESH_RATE(60.0),
        .IT_CONTENT(1'b1),
        .AUDIO_RATE(44_100),
        .AUDIO_BIT_WIDTH(16),
        .VENDOR_NAME({"Unknown", 8'd0}),
        .PRODUCT_DESCRIPTION({"Franky SMS", 48'd0}),
        .SOURCE_DEVICE_INFORMATION(8'h00),
        .START_X(0),
        .START_Y(0),
        .NUM_CHANNELS(3)
    ) hdmi_inst (
        .clk_pixel_x5(video_clk_135),
        .clk_pixel(clk),
        .clk_audio(hdmi_audio_clk),
        .reset(~sms_reset_n),
        .rgb({hdmi_red, hdmi_green, hdmi_blue}),
        .audio_sample_word(hdmi_audio_samples),
        .cx(hdmi_x),
        .cy(hdmi_y),
        .frame_width(),
        .frame_height(),
        .screen_width(),
        .screen_height(),
        .tmds_internal(hdmi_tmds_internal)
    );

    wire [2:0] hdmi_tmds;
    wire hdmi_tmds_clock_unused;
    serializer #(
        .NUM_CHANNELS(3),
        .VIDEO_RATE(0)
    ) hdmi_serializer_inst (
        .clk_pixel(clk),
        .clk_pixel_x5(video_clk_135),
        .reset(~sms_reset_n),
        .tmds_internal(hdmi_tmds_internal),
        .tmds(hdmi_tmds),
        .tmds_clock(hdmi_tmds_clock_unused)
    );

    ELVDS_OBUF hdmi_output_buffers [3:0] (
        .I({clk, hdmi_tmds}),
        .O({tmds_clk_p, tmds_data_p}),
        .OB({tmds_clk_n, tmds_data_n})
    );
    
    input_debouncer
    #(
        .WIDTH(3)
    )
    bus_data_debouncer(
        .clk(main_clk),
        .reset_n(board_reset_n),
        .in({rd_n_in, wr_n_in, sltsl_n_in}),
        .out({rd_n, wr_n, sltsl_n})
    );

    input_debouncer
    #(
        .WIDTH(8)
    )
    bus_control_debouncer(
        .clk(main_clk),
        .reset_n(board_reset_n),
        .in(cd),
        .out(cd_in)
    );

    mp_debouncer mp_debouncer_inst(
        .clk(main_clk),
        .reset_n(board_reset_n),
        .mp(mp),
        .msel_n(msel_n),
        .a_lo(a_lo),
        .a_hi(a_hi),
        .addr(addr),
        .merq_n(merq_n),
        .iorq_n(iorq_n),
        .cs1_n(cs1_n),
        .cs2_n(cs2_n),
        .reset_in_n(reset_in_n),
        .rfsh_n(rfsh_n),
        .cs12_n(cs12_n),
        .m1_n(m1_n),
        .inputs_latched(inputs_latched)
    );

    generate
        if (SMS_DEBUGGER_ENABLED) begin : cpu_step_debugger_enabled_impl
            cpu_step_debugger cpu_step_debugger_inst (
                .clk(main_clk),
                .reset_n(board_reset_n),
                .s2(s2),
                .m1_n(m1_n),
                .merq_n(merq_n),
                .iorq_n(iorq_n),
                .rd_n(rd_n),
                .rfsh_n(rfsh_n),
                .fetch_address(addr),
                .fetch_data(cd_in),
                .software_toggle(step_debug_toggle),
                .breakpoint_address(step_debug_breakpoint_address),
                .breakpoint_arm(step_debug_breakpoint_arm),
                .wait_n(step_debug_wait_n),
                .enabled(step_debug_enabled),
                .instruction_color_alt(step_debug_instruction_color_alt)
            );
        end else begin : cpu_step_debugger_disabled_impl
            assign step_debug_wait_n = 1'b1;
            assign step_debug_enabled = 1'b0;
            assign step_debug_instruction_color_alt = 1'b0;
        end
    endgenerate

    // SDRAM owns the external memory bus until its startup test has passed.
    // Synchronize that result into the SD controller's 27 MHz domain and
    // leave a full 16 SD clocks between the SDRAM and SD reset releases.
    // This reset also feeds SD's 108 MHz register interface, matching the
    // original board-enabled reset's 27 MHz release behavior.
    always_ff @(posedge clk or negedge board_enabled)
    begin
        if (!board_enabled) begin
            startup_passed_sd_sync <= 2'b00;
            sd_stage_count <= 4'd0;
            sd_stage_enabled <= 1'b0;
        end else begin
            startup_passed_sd_sync <=
                {startup_passed_sd_sync[0], startup_test_passed};

            if (!startup_passed_sd_sync[1]) begin
                sd_stage_count <= 4'd0;
                sd_stage_enabled <= 1'b0;
            end else if (!sd_stage_enabled) begin
                if (sd_stage_count == 4'd15)
                    sd_stage_enabled <= 1'b1;
                else
                    sd_stage_count <= sd_stage_count + 1'b1;
            end
        end
    end

    assign sd_module_reset_n = board_enabled && sd_stage_enabled;

    // Synchronize the 27 MHz SD-stage release into the 108 MHz bus domain.
    // Release every CPU-visible module together on a falling main-clock edge,
    // leaving half a cycle of reset-recovery margin before their next active
    // edge. This avoids partial mapper reset release after cold configuration.
    always_ff @(posedge main_clk or negedge board_reset_n)
    begin
        if (!board_reset_n)
            sd_ready_main_sync <= 2'b00;
        else
            sd_ready_main_sync <=
                {sd_ready_main_sync[0], sd_module_reset_n};
    end

    always_ff @(negedge main_clk or negedge board_reset_n)
    begin
        if (!board_reset_n) begin
            sd_ready_fall <= 1'b0;
            flash_rom_loaded_fall <= 1'b0;
            reset_in_n_fall <= 1'b0;
            cpu_modules_ready_count <= 4'd0;
            cpu_modules_ready_reg <= 1'b0;
        end else begin
            // Capture rising-edge-domain readiness signals before using them
            // in the falling-edge release counter. This keeps the half-cycle
            // crossings direct and gives the decision logic a full cycle.
            sd_ready_fall <= sd_ready_main_sync[1];
            flash_rom_loaded_fall <= flash_rom_loaded;
            reset_in_n_fall <= reset_in_n;

            if (!sd_ready_fall ||
                !flash_rom_loaded_fall || !reset_in_n_fall) begin
                cpu_modules_ready_count <= 4'd0;
                cpu_modules_ready_reg <= 1'b0;
            end else if (!cpu_modules_ready_reg) begin
                if (&cpu_modules_ready_count)
                    cpu_modules_ready_reg <= 1'b1;
                else
                    cpu_modules_ready_count <=
                        cpu_modules_ready_count + 1'b1;
            end
        end
    end

    wire cpu_modules_ready_n = cpu_modules_ready_reg;

    assign slot_expander_reset_n = cpu_modules_ready_n;
    assign memory_mapper_reset_n = cpu_modules_ready_n;
    assign bios_module_enabled = cpu_modules_ready_n;
    assign psg_module_reset_n = cpu_modules_ready_n;
    assign opll_module_reset_n = cpu_modules_ready_n;
    // Reset MegaRAM immediately from the MSX /RESET input. Its release remains
    // gated by the startup sequence so SDRAM and the sampled bus are ready.
    assign megaram_module_reset_n = cpu_modules_ready_n && reset_in_n;
    assign module_sequence_done = cpu_modules_ready_n;
    assign active_module_reset_n = cpu_modules_ready_n;

    slot_expander slot_expander_inst(
        .clk(main_clk),
        .reset_n(slot_expander_reset_n),
        .addr(addr),
        .data_in(cd_in),
        .merq_n(merq_n),
        .iorq_n(iorq_n),
        .rd_n(smr_rd_n_fast),
        .wr_n(smr_wr_n_fast),
        .sltsl_n(sltsl_n),
        .data_out(slot_expander_data_out),
        .data_out_en(slot_expander_data_out_en),
        .page0_subslot_en(page0_subslot_en),
        .page1_subslot_en(page1_subslot_en),
        .page2_subslot_en(page2_subslot_en),
        .page3_subslot_en(page3_subslot_en),
        .debug_expanded_slot(debug_expanded_slot)
    );

    sdram_startup_test
    #(
        .CLK_FREQ_HZ(108_000_000),
        .USE_ADDRESS_PATTERN(1'b1)
    )
    sdram_startup_test_inst(
        .clk(main_clk),
        .reset_n(board_enabled),
        .sdrc_init_done(sdrc_init_done),
        .sdrc_cmd_ack(sdrc_cmd_ack),
        .sdrc_data_in(sdrc_data_in),
        .sdrc_cmd_en(test_sdrc_cmd_en),
        .sdrc_cmd(test_sdrc_cmd),
        .sdrc_precharge_ctrl(test_sdrc_precharge_ctrl),
        .sdram_power_down(test_sdram_power_down),
        .sdram_selfrefresh(test_sdram_selfrefresh),
        .sdrc_addr(test_sdrc_addr),
        .sdrc_dqm(test_sdrc_dqm),
        .sdrc_data(test_sdrc_data),
        .sdrc_data_len(test_sdrc_data_len),
        .test_passed(startup_test_passed),
        .test_failed(startup_test_failed),
        .wait_n(startup_test_wait_n),
        .led(startup_test_led)
    );

    sdram_mapper sdram_mapper_inst(
        .clk(main_clk),
        .cpu_clk_high(psg_cpu_clk_sync[1]),
        .reset_n(memory_mapper_reset_n),
        .addr(addr),
        .data_in(cd_in),
        .merq_n(merq_n),
        .iorq_n(iorq_n),
        .rd_n(rd_n),
        .wr_n(wr_n),
        .rfsh_n(rfsh_n),
        .m1_n(m1_n),
        .sltsl_n(sltsl_n),
        .page0_subslot_en(page0_subslot_en),
        .page1_subslot_en(page1_subslot_en),
        .page2_subslot_en(page2_subslot_en),
        .page3_subslot_en(page3_subslot_en),
        .data_out(sdram_mapper_data_out),
        .data_out_en(sdram_mapper_data_out_en),
        .wait_n(mapper_wait_n),
        .debug_page0(mapper_debug_page0),
        .debug_page1(mapper_debug_page1),
        .debug_page2(mapper_debug_page2),
        .debug_page3(mapper_debug_page3),
        .sdrc_cmd_en(mapper_sdrc_cmd_en),
        .sdrc_cmd(mapper_sdrc_cmd),
        .sdrc_precharge_ctrl(mapper_sdrc_precharge_ctrl),
        .sdram_power_down(mapper_sdram_power_down),
        .sdram_selfrefresh(mapper_sdram_selfrefresh),
        .sdrc_addr(mapper_sdrc_addr),
        .sdrc_dqm(mapper_sdrc_dqm),
        .sdrc_data(mapper_sdrc_data),
        .sdrc_data_len(mapper_sdrc_data_len),
        .sdrc_data_in(sdrc_data_in),
        .sdrc_init_done(sdrc_init_done),
        .sdrc_cmd_ack(sdrc_cmd_ack)
    );

    super_megaram #(
        .INCLUDE_SCC(1'b1),
        .DEBUGGER_ENABLED(SMS_DEBUGGER_ENABLED)
    ) super_megaram_inst(
        .clk(main_clk),
        .cpu_clk(cpu_clk),
        .reset_n(megaram_module_reset_n),
        .addr(addr),
        .data_in(cd_in),
        .merq_n(merq_n),
        .iorq_n(iorq_n),
        .rd_n(smr_rd_n_fast),
        .wr_n(smr_wr_n_fast),
        .rfsh_n(rfsh_n),
        .m1_n(m1_n),
        .bus_snapshot_valid(inputs_latched),
        .sltsl_n(sltsl_n),
        .page0_subslot_en(page0_subslot_en),
        .page1_subslot_en(page1_subslot_en),
        .page2_subslot_en(page2_subslot_en),
        .page3_subslot_en(page3_subslot_en),
        .data_out(smr_data_out),
        .data_out_en(smr_data_out_en),
        .wait_n(smr_wait_n),
        .step_debug_toggle(step_debug_toggle),
        .breakpoint_address(step_debug_breakpoint_address),
        .breakpoint_arm(step_debug_breakpoint_arm),
        .debug_bank0(megaram_debug_bank0),
        .debug_bank1(megaram_debug_bank1),
        .debug_bank2(megaram_debug_bank2),
        .debug_bank3(megaram_debug_bank3),
        .debug_mode(megaram_debug_mode),
        .linear_mode_enabled(linear_mode_enabled),
        .scc_sound(scc_sound),
        .sdrc_cmd_en(smr_sdrc_cmd_en),
        .sdrc_cmd(smr_sdrc_cmd),
        .sdrc_addr(smr_sdrc_addr),
        .sdrc_dqm(smr_sdrc_dqm),
        .sdrc_data(smr_sdrc_data),
        .sdrc_data_in(sdrc_data_in),
        .sdrc_init_done(sdrc_init_done),
        .sdrc_cmd_ack(sdrc_cmd_ack)
    );

    linear_rom linear_rom_inst(
        .clk(main_clk),
        .reset_n(megaram_module_reset_n),
        .enabled(linear_mode_enabled),
        .addr(addr),
        .merq_n(merq_n),
        .iorq_n(iorq_n),
        .rd_n(smr_rd_n_fast),
        .wr_n(smr_wr_n_fast),
        .rfsh_n(rfsh_n),
        .bus_snapshot_valid(inputs_latched),
        .sltsl_n(sltsl_n),
        .page0_subslot_en(page0_subslot_en),
        .page1_subslot_en(page1_subslot_en),
        .page2_subslot_en(page2_subslot_en),
        .page3_subslot_en(page3_subslot_en),
        .data_out(linear_data_out),
        .data_out_en(linear_data_out_en),
        .wait_n(linear_wait_n),
        .sdrc_cmd_en(linear_sdrc_cmd_en),
        .sdrc_cmd(linear_sdrc_cmd),
        .sdrc_addr(linear_sdrc_addr),
        .sdrc_dqm(linear_sdrc_dqm),
        .sdrc_data(linear_sdrc_data),
        .sdrc_data_in(sdrc_data_in),
        .sdrc_init_done(sdrc_init_done),
        .sdrc_cmd_ack(sdrc_cmd_ack)
    );

    sd_registers sd_registers_inst(
        .clk(main_clk),
        .sd_clk(clk),
        // Startup order: SDRAM test, SD controller, then the staged
        // CPU-visible modules beginning with the slot expander.
        .reset_n(sd_module_reset_n),
        .cpu_clk(cpu_clk),
        .addr(addr),
        .data_in(cd_in),
        .merq_n(merq_n),
        .iorq_n(iorq_n),
        .m1_n(m1_n),
        .rd_n(rd_n),
        .wr_n(wr_n),
        .sltsl_n(sltsl_n),
        .subslot0_selected(page1_subslot_en[0]),
        .data_out(sd_data_out),
        .data_out_en(sd_data_out_en),
        .overlay_enabled(sd_overlay_enabled),
        .busy(sd_busy),
        .sd_sclk(sd_sclk),
        .sd_cmd(sd_cmd),
        .sd_dat0(sd_dat0),
        .sd_dat1(sd_dat1),
        .sd_dat2(sd_dat2),
        .sd_dat3(sd_dat3)
    );

    flash_roms flash_roms_inst(
        .clk(main_clk),
        .reset_n(board_enabled),
        .load_enable(startup_test_passed),
        .addr(addr),
        .data_in(cd_in),
        .merq_n(merq_n),
        .iorq_n(iorq_n),
        .rd_n(rd_n),
        .wr_n(wr_n),
        .rfsh_n(rfsh_n),
        .sltsl_n(sltsl_n),
        .page0_subslot_en(page0_subslot_en),
        .page1_subslot_en(page1_subslot_en),
        .dos2_overlay_enabled(sd_overlay_enabled),
        .data_out(flash_rom_data_out),
        .data_out_en(flash_rom_data_out_en),
        .wait_n(flash_rom_wait_n),
        .loaded(flash_rom_loaded),
        .mspi_cs(mspi_cs),
        .mspi_sclk(mspi_sclk),
        .mspi_miso(mspi_miso),
        .mspi_mosi(mspi_mosi),
        .sdrc_cmd_en(rom_sdrc_cmd_en),
        .sdrc_cmd(rom_sdrc_cmd),
        .sdrc_addr(rom_sdrc_addr),
        .sdrc_dqm(rom_sdrc_dqm),
        .sdrc_data(rom_sdrc_data),
        .sdrc_data_in(sdrc_data_in),
        .sdrc_cmd_ack(sdrc_cmd_ack)
    );

    assign sdrc_cmd_en = board_enabled ?
        (startup_test_passed ?
            (rom_sdrc_cmd_en || linear_sdrc_cmd_en ||
             smr_sdrc_cmd_en || mapper_sdrc_cmd_en) :
            test_sdrc_cmd_en) : 1'b0;
    assign sdrc_cmd = startup_test_passed ?
        (rom_sdrc_cmd_en ? rom_sdrc_cmd :
         linear_sdrc_cmd_en ? linear_sdrc_cmd :
         smr_sdrc_cmd_en ? smr_sdrc_cmd : mapper_sdrc_cmd) :
        test_sdrc_cmd;
    assign sdrc_precharge_ctrl = startup_test_passed ? mapper_sdrc_precharge_ctrl : test_sdrc_precharge_ctrl;
    assign sdram_power_down = startup_test_passed ? mapper_sdram_power_down : test_sdram_power_down;
    assign sdram_selfrefresh = startup_test_passed ? mapper_sdram_selfrefresh : test_sdram_selfrefresh;
    assign sdrc_addr = startup_test_passed ?
        (rom_sdrc_cmd_en ? rom_sdrc_addr :
         linear_sdrc_cmd_en ? linear_sdrc_addr :
         smr_sdrc_cmd_en ? smr_sdrc_addr : mapper_sdrc_addr) :
        test_sdrc_addr;
    assign sdrc_dqm = startup_test_passed ?
        (rom_sdrc_cmd_en ? rom_sdrc_dqm :
         linear_sdrc_cmd_en ? linear_sdrc_dqm :
         smr_sdrc_cmd_en ? smr_sdrc_dqm : mapper_sdrc_dqm) :
        test_sdrc_dqm;
    assign sdrc_data = startup_test_passed ?
        (rom_sdrc_cmd_en ? rom_sdrc_data :
         linear_sdrc_cmd_en ? linear_sdrc_data :
         smr_sdrc_cmd_en ? smr_sdrc_data : mapper_sdrc_data) :
        test_sdrc_data;
    assign sdrc_data_len = startup_test_passed ? mapper_sdrc_data_len : test_sdrc_data_len;

    // All source selects are mutually exclusive. A parallel masked OR avoids
    // the serial priority chain while preserving each device's own registered
    // read data and WAIT handshake.
    wire slot_drive_en =
        active_module_reset_n && slot_expander_data_out_en;
    wire mapper_drive_en =
        active_module_reset_n && sdram_mapper_data_out_en;
    wire smr_drive_en =
        active_module_reset_n && smr_data_out_en;
    wire linear_drive_en =
        active_module_reset_n && linear_data_out_en;
    wire bios_drive_en =
        active_module_reset_n && bios_module_enabled &&
        flash_rom_data_out_en;
    wire sd_drive_en =
        active_module_reset_n && sd_data_out_en;
    wire sms_drive_en = sms_bridge_read_data_en;
    wire jt51_drive_en = active_module_reset_n && jt51_status_read;

    assign data_out =
        ({8{slot_drive_en}} & slot_expander_data_out) |
        ({8{mapper_drive_en}} & sdram_mapper_data_out) |
        ({8{smr_drive_en}} & smr_data_out) |
        ({8{linear_drive_en}} & linear_data_out) |
        ({8{bios_drive_en}} & flash_rom_data_out) |
        ({8{sd_drive_en}} & sd_data_out) |
        ({8{sms_drive_en}} & sms_bridge_read_data) |
        ({8{jt51_drive_en}} & jt51_data_out);

    assign data_out_en =
        slot_drive_en || mapper_drive_en || smr_drive_en ||
        linear_drive_en ||
        bios_drive_en || sd_drive_en || sms_drive_en || jt51_drive_en;

    assign mapper_port_read =
        (active_module_reset_n && !iorq_n && m1_n && !rd_n &&
         addr[7:2] == 6'b111111) ||
        sms_vdp_read_selected;
    
    cd_demux cd_demux_inst(
        .data_out(data_out),
        .data_out_en(data_out_en),
        .wait_in_n(memory_wait_n && step_debug_wait_n),
        .rd_n(rd_n),
        .sltsl_n(sltsl_n),
        .mapper_port_read(mapper_port_read),
        .cd(cd),
        .busdir_n(busdir_n),
        .datadir(datadir),
        .wait_n(wait_n)
    );

    sdram_command_adapter sdram_command_adapter_inst(
        .clk(main_clk),
        .reset_n(board_enabled),
        .rfsh_n(rfsh_n),
        .m1_n(m1_n),
        .merq_n(merq_n),
        .iorq_n(iorq_n),
        .rd_n(smr_rd_n_fast),
        .wr_n(smr_wr_n_fast),
        .cmd_en(sdrc_cmd_en),
        .cmd(sdrc_cmd),
        .cmd_addr(sdrc_addr),
        .cmd_dqm(sdrc_dqm),
        .cmd_data(sdrc_data),
        .read_data(sdrc_data_in),
        .init_done(sdrc_init_done),
        .cmd_ack(sdrc_cmd_ack),
        .rd(native_sdram_rd),
        .wr(native_sdram_wr),
        .refresh(native_sdram_refresh),
        .addr(native_sdram_addr),
        .din(native_sdram_din),
        .wdm(native_sdram_wdm),
        .dout32(native_sdram_dout32),
        .data_ready(native_sdram_data_ready),
        .busy(native_sdram_busy),
        .enabled(native_sdram_enabled)
    );

    sdram
    #(
        .FREQ(108_000_000),
        .CAS(5'd3),
        .T_WR(5'd3),
        .T_MRD(5'd2),
        .T_RP(5'd2),
        .T_RCD(5'd2),
        .T_RC(5'd7)
    )
    sdram_inst(
        .SDRAM_DQ(IO_sdram_dq),
        .SDRAM_A(O_sdram_addr),
        .SDRAM_BA(O_sdram_ba),
        .SDRAM_nCS(O_sdram_cs_n),
        .SDRAM_nWE(O_sdram_wen_n),
        .SDRAM_nRAS(O_sdram_ras_n),
        .SDRAM_nCAS(O_sdram_cas_n),
        .SDRAM_CLK(O_sdram_clk),
        .SDRAM_CKE(O_sdram_cke),
        .SDRAM_DQM(O_sdram_dqm),
        .clk(main_clk),
        .clk_sdram(sdram_clk),
        .resetn(board_enabled),
        .rd(native_sdram_rd),
        .wr(native_sdram_wr),
        .refresh(native_sdram_refresh),
        .addr(native_sdram_addr),
        .din(native_sdram_din),
        .wdm(native_sdram_wdm),
        .dout(native_sdram_dout),
        .dout32(native_sdram_dout32),
        .data_ready(native_sdram_data_ready),
        .busy(native_sdram_busy),
        .enabled(native_sdram_enabled)
    );

    // This older board has no interrupt inverter transistor, so drive the
    // active-low cartridge /INT signal directly from the active-low sources.
    assign int_n =
        (sms_reset_n ? sms_vdp_irq_n : 1'b1) &&
        (opll_module_reset_n ? jt51_irq_n : 1'b1);

    assign int_out = int_n ? 1'bz : 1'b0;
    assign wait_out = ~wait_n;

    // Before the SDRAM test passes, preserve its failure-code blinker.
    // Afterwards the LED indicates an active SD-card command.
    assign led = startup_test_passed ? sd_busy : startup_test_led;

endmodule

// -*- SystemC -*-
// DESCRIPTION: Verilator Example: Top level main for invoking SystemC model
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2017 by Wilson Snyder.
// SPDX-License-Identifier: CC0-1.0
//======================================================================

// SystemC global header
#include <systemc.h>

// Include common routines
#include <verilated.h>
#if VM_TRACE
#include <verilated_vcd_sc.h>
#endif

#include <sys/stat.h>  // mkdir

// Include model header, generated from Verilating "top.v"
#include "Vtop.h"

int sc_main(int argc, char* argv[]) {
    // This is a more complicated example, please also see the simpler
    // examples/make_hello_c.

    // Prevent unused variable warnings
    if (0 && argc && argv) {}

    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs
    Verilated::debug(0);

    // Randomization reset policy
    // May be overridden by commandArgs
    Verilated::randReset(2);

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    Verilated::commandArgs(argc, argv);

    // Create logs/ directory in case we have traces to put under it
    Verilated::mkdir("logs");

    // General logfile
    ios::sync_with_stdio();

    // Defaults time
#if (SYSTEMC_VERSION>20011000)
#else
    sc_time dut(1.0, sc_ns);
    sc_set_default_time_unit(dut);
#endif

    // Define clocks
#if (SYSTEMC_VERSION>=20070314)
    sc_clock clk     ("clk",    10,SC_NS, 0.5, 3,SC_NS, true);
    sc_clock fastclk ("fastclk", 2,SC_NS, 0.5, 2,SC_NS, true);
#else
    sc_clock clk     ("clk",    10, 0.5, 3, true);
    sc_clock fastclk ("fastclk", 2, 0.5, 2, true);
#endif

    // Define interconnect
    sc_signal<bool> reset_l;
    // sc_signal<bool> ip2bus_mstrd_req;
    // sc_signal<bool> ip2bus_mstwr_req;
    // sc_signal<uint32_t> ip2bus_mst_addr;
    // sc_signal<uint32_t> ip2bus_mst_length;
    // sc_signal<uint32_t> ip2bus_mst_be;
    // sc_signal<bool> ip2bus_mst_type;
    // sc_signal<bool> ip2bus_mst_lock;
    // sc_signal<bool> ip2bus_mst_reset;
    //
    // sc_signal<bool> bus2ip_mst_cmdack;
    // sc_signal<bool> bus2ip_mst_cmplt;
    //
    sc_signal<uint32_t> InputImageAddress;
    sc_signal<uint32_t> OutputImageAddress;
    sc_signal<bool>  BeginRotation;
    // sc_signal<bool>  RotationDone;
    // // sc_signal<uint32_t>  RotationType;
    // // sc_signal<uint32_t>  NumberOf120PixelsBlocks_X;
    // // sc_signal<uint32_t>  NumberOf120PixelsBlocks_Y;
    // // sc_signal<uint32_t> bus2ip_mstrd_rem;
    //
    //
    // sc_signal<bool> bus2ip_mstrd_src_rdy_n;
    // sc_signal<bool> bus2ip_mstrd_src_dsc_n;
    // sc_signal<uint32_t>ip2bus_mstwr_rem;
    // sc_signal<bool>ip2bus_mstwr_src_dsc_n;
    // sc_signal<bool>bus2ip_mstwr_dst_rdy_n;
    // sc_signal<bool>bus2ip_mstwr_dst_dsc_n;



    // Construct the Verilated model, from inside Vtop.h
    Vtop* top = new Vtop("top");
    // Attach signals to the model
    top->Clk       (clk);
    top->ResetL   (reset_l);

    // top->PIXEL_WIDTH(PIXEL_WIDTH),
    //
    // top->	ip2bus_mstrd_req(ip2bus_mstrd_req);
    // top-> ip2bus_mstwr_req(ip2bus_mstwr_req);
    // top-> ip2bus_mst_addr(ip2bus_mst_addr);
    // top-> ip2bus_mst_length(ip2bus_mst_length);
    // top-> ip2bus_mst_be(ip2bus_mst_be);
    // top-> ip2bus_mst_type(ip2bus_mst_type);
    // top-> ip2bus_mst_lock(ip2bus_mst_lock);
    // top->ip2bus_mst_reset(ip2bus_mst_reset);
    // // top-> ip2bus_mst_length(ip2bus_mst_length),
    // // top-> ip2bus_mst_be(ip2bus_mst_be),
    // // top-> ip2bus_mst_type(ip2bus_mst_type),
    //
    // // top->	ip2bus_mst_lock(ip2bus_mst_lock),
    // // top->	ip2bus_mst_reset(ip2bus_mst_reset),
    // top->	bus2ip_mst_cmdack(bus2ip_mst_cmdack);
    // top->	bus2ip_mst_cmplt(bus2ip_mst_cmplt);
    // // top->	bus2ip_mst_error(bus2ip_mst_error),
    // // top->	bus2ip_mst_rearbitrate(bus2ip_mst_rearbitrate),
    // // top->	bus2ip_mst_cmd_timeout(bus2ip_mst_cmd_timeout),
    //
    // // top->	bus2ip_mstrd_d(bus2ip_mstrd_d),
    // top->	bus2ip_mstrd_rem(bus2ip_mstrd_rem);
    // // top->	bus2ip_mstrd_sof_n(bus2ip_mstrd_sof_n),
    // // top->	bus2ip_mstrd_eof_n(bus2ip_mstrd_eof_n),
    // top->	bus2ip_mstrd_src_rdy_n(bus2ip_mstrd_src_rdy_n);
    // top->	bus2ip_mstrd_src_dsc_n(bus2ip_mstrd_src_dsc_n);
    // // top->	ip2bus_mstrd_dst_rdy_n(ip2bus_mstrd_dst_rdy_n),
    // // top->	ip2bus_mstrd_dst_dsc_n(ip2bus_mstrd_dst_dsc_n),
    // // top->	ip2bus_mstwr_d(ip2bus_mstwr_d),
    // top->	ip2bus_mstwr_rem(ip2bus_mstwr_rem);
    // // top->	ip2bus_mstwr_sof_n(ip2bus_mstwr_sof_n),
    // // top->	ip2bus_mstwr_eof_n(ip2bus_mstwr_eof_n),
    // // top->	ip2bus_mstwr_src_rdy_n(ip2bus_mstwr_src_rdy_n),
    // top->	ip2bus_mstwr_src_dsc_n(ip2bus_mstwr_src_dsc_n);
    // top->	bus2ip_mstwr_dst_rdy_n(bus2ip_mstwr_dst_rdy_n);
    // top->	bus2ip_mstwr_dst_dsc_n(bus2ip_mstwr_dst_dsc_n);
    //
    top->	InputImageAddress(InputImageAddress);
    top->	OutputImageAddress(OutputImageAddress);
    top->	BeginRotation(BeginRotation);
    // top->	RotationDone(RotationDone);
    // // top->	RotationType(RotationType);
    // // top->	NumberOf120PixelsBlocks_X(NumberOf120PixelsBlocks_X);
    // // top->	NumberOf120PixelsBlocks_Y(NumberOf120PixelsBlocks_Y);
    //
    // // top->	StartPixel_X(StartPixel_X);
    // // top->	StartPixel_Y(StartPixel_Y);
    // // top->	NumberOfPixelsPerLine(NumberOfPixelsPerLine);


#if VM_TRACE
    // Before any evaluation, need to know to calculate those signals only used
    //for tracing
    Verilated::traceEverOn(true);
#endif

    // You must do one evaluation before enabling waves, in order to allow
    // SystemC to interconnect everything for testing.
#if (SYSTEMC_VERSION>=20070314)
    sc_start(1,SC_NS);
#else
    sc_start(1);
#endif

#if VM_TRACE
    // If verilator was invoked with --trace argument,
    // and if at run time passed the +trace argument, turn on tracing
    VerilatedVcdSc* tfp = NULL;
    const char* flag = Verilated::commandArgsPlusMatch("trace");
    if (flag && 0==strcmp(flag, "+trace")) {
        cout << "Enabling waves into logs/vlt_dump.vcd...\n";
        tfp = new VerilatedVcdSc;
        top->trace(tfp, 99);  // Trace 99 levels of hierarchy
        Verilated::mkdir("logs");
        tfp->open("logs/vlt_dump.vcd");
    }
#endif

    // Simulate until $finish
    while (!Verilated::gotFinish()) {
#if VM_TRACE
        // Flush the wave files each cycle so we can immediately see the output
        // Don't do this in "real" programs, do it in an abort() handler instead
        if (tfp) tfp->flush();
#endif

        // Apply inputs
        if (VL_TIME_Q() > 1 && VL_TIME_Q() < 10) {
            reset_l = !1;  // Assert reset
        } else if (VL_TIME_Q() > 1) {
            reset_l = !0;  // Deassert reset
        }

        // Simulate 1ns
#if (SYSTEMC_VERSION>=20070314)
        sc_start(1,SC_NS);
#else
        sc_start(1);
#endif
    }

    // Final model cleanup
    top->final();

    // Close trace if opened
#if VM_TRACE
    if (tfp) { tfp->close(); tfp = NULL; }
#endif

    //  Coverage analysis (since test passed)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
#endif

    // Destroy model
    delete top; top = NULL;

    // Fin
    return 0;
}

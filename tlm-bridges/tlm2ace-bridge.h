/*
 * TLM-2.0 to ACE bridge.
 *
 * Copyright (c) 2019 Xilinx Inc.
 * Written by Francisco Iglesias.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef TLM2ACE_BRIDGE_H__
#define TLM2ACE_BRIDGE_H__

#include "tlm-bridges/tlm2axi-bridge.h"

template
<int ADDR_WIDTH,
	int DATA_WIDTH,
	int ID_WIDTH = 8,
	int AxLEN_WIDTH = 8,
	int AxLOCK_WIDTH = 1,
	int AWUSER_WIDTH = 2,
	int ARUSER_WIDTH = 2,
	int WUSER_WIDTH = 2,
	int RUSER_WIDTH = 2,
	int BUSER_WIDTH = 2,
	int CACHELINE_SZ = 64,
	int CD_DATA_WIDTH = DATA_WIDTH>
class tlm2ace_bridge
: public sc_core::sc_module
{
private:
	typedef ACESnoopChannels_M<
				ADDR_WIDTH,
				CD_DATA_WIDTH,
				CACHELINE_SZ> ACESnoopChannels_M__;
	tlm2axi_bridge<
		ADDR_WIDTH,
		DATA_WIDTH,
		ID_WIDTH,
		AxLEN_WIDTH,
		AxLOCK_WIDTH,
		AWUSER_WIDTH,
		ARUSER_WIDTH,
		WUSER_WIDTH,
		RUSER_WIDTH,
		BUSER_WIDTH,
		ACE_MODE_ACE,
		CACHELINE_SZ,
		CD_DATA_WIDTH> m_bridge;

	// Against the bridge
	tlm_utils::simple_initiator_socket<tlm2ace_bridge> m_init_socket;
	tlm_utils::simple_target_socket<tlm2ace_bridge> m_snoop_tgt_socket;

	virtual void b_transport(tlm::tlm_generic_payload& trans,
				sc_time& delay)
	{
		m_init_socket->b_transport(trans, delay);
	}

	virtual void b_transport_snoop(tlm::tlm_generic_payload& trans,
				sc_time& delay)
	{
		snoop_init_socket->b_transport(trans, delay);
	}

	ACESnoopChannels_M__& m_snp_chnls;
public:
	tlm_utils::simple_target_socket<tlm2ace_bridge> tgt_socket;
	tlm_utils::simple_initiator_socket<tlm2ace_bridge> snoop_init_socket;

	sc_in<bool>& clk;
	sc_in<bool>& resetn;

	/* Write address channel.  */
	sc_out<bool >& awvalid;
	sc_in<bool >& awready;
	sc_out<sc_bv<ADDR_WIDTH> >& awaddr;
	sc_out<sc_bv<3> >& awprot;
	sc_out<AXISignal(AWUSER_WIDTH) >& awuser;// AXI4 only
	sc_out<sc_bv<4> >& awregion;		// AXI4 only
	sc_out<sc_bv<4> >& awqos;		// AXI4 only
	sc_out<sc_bv<4> >& awcache;
	sc_out<sc_bv<2> >& awburst;
	sc_out<sc_bv<3> >& awsize;
	sc_out<AXISignal(AxLEN_WIDTH) >& awlen;
	sc_out<AXISignal(ID_WIDTH) >& awid;
	sc_out<AXISignal(AxLOCK_WIDTH) >& awlock;

	/* Write data channel.  */
	sc_out<bool >& wvalid;
	sc_in<bool >& wready;
	sc_out<sc_bv<DATA_WIDTH> >& wdata;
	sc_out<sc_bv<DATA_WIDTH/8> >& wstrb;
	sc_out<AXISignal(WUSER_WIDTH) >& wuser;	// AXI4 only
	sc_out<bool >& wlast;

	/* Write response channel.  */
	sc_in<bool >& bvalid;
	sc_out<bool >& bready;
	sc_in<sc_bv<2> >& bresp;
	sc_in<AXISignal(BUSER_WIDTH) >& buser;
	sc_in<AXISignal(ID_WIDTH) >& bid;

	/* Read address channel.  */
	sc_out<bool >& arvalid;
	sc_in<bool >& arready;
	sc_out<sc_bv<ADDR_WIDTH> >& araddr;
	sc_out<sc_bv<3> >& arprot;
	sc_out<AXISignal(ARUSER_WIDTH) >& aruser;	// AXI4 only
	sc_out<sc_bv<4> >& arregion;			// AXI4 only
	sc_out<sc_bv<4> >& arqos;			// AXI4 only
	sc_out<sc_bv<4> >& arcache;
	sc_out<sc_bv<2> >& arburst;
	sc_out<sc_bv<3> >& arsize;
	sc_out<AXISignal(AxLEN_WIDTH) >& arlen;
	sc_out<AXISignal(ID_WIDTH) >& arid;
	sc_out<AXISignal(AxLOCK_WIDTH) >& arlock;

	/* Read data channel.  */
	sc_in<bool >& rvalid;
	sc_out<bool >& rready;
	sc_in<sc_bv<DATA_WIDTH> >& rdata;
	sc_in<sc_bv<4> >& rresp;
	sc_in<AXISignal(RUSER_WIDTH) >& ruser;		// AXI4 only
	sc_in<AXISignal(ID_WIDTH) >& rid;
	sc_in<bool >& rlast;

	// AXI4 ACE signals
	sc_out<sc_bv<3> >& awsnoop;
	sc_out<sc_bv<2> >& awdomain;
	sc_out<sc_bv<2> >& awbar;

	sc_out<bool >& wack;

	sc_out<sc_bv<4> >& arsnoop;
	sc_out<sc_bv<2> >& ardomain;
	sc_out<sc_bv<2> >& arbar;

	sc_out<bool >& rack;

	// Snoop address channel
	sc_in<bool >&  acvalid;
	sc_out<bool >& acready;
	sc_in<sc_bv<ADDR_WIDTH> >& acaddr;
	sc_in<sc_bv<4> >& acsnoop;
	sc_in<sc_bv<3> >& acprot;

	// Snoop response channel
	sc_out<bool >& crvalid;
	sc_in<bool >& crready;
	sc_out<sc_bv<5> >& crresp;

	// Snoop data channel
	sc_out<bool >& cdvalid;
	sc_in<bool >& cdready;
	sc_out<sc_bv<CD_DATA_WIDTH> >& cddata;
	sc_out<bool >& cdlast;

	SC_HAS_PROCESS(tlm2ace_bridge);

	tlm2ace_bridge(sc_core::sc_module_name name, bool aligner_enable=true) :
		sc_module(name),

		m_bridge("tlm2axi_bridge", V_AXI4, aligner_enable),
		m_init_socket("init_socket"),
		m_snoop_tgt_socket("snoop_tgt_socket"),

		m_snp_chnls(m_bridge.GetACESnoopChannels()),

		tgt_socket("target_socket"),
		snoop_init_socket("snoop_init_socket"),

		clk(m_bridge.clk),
		resetn(m_bridge.resetn),
		awvalid(m_bridge.awvalid),
		awready(m_bridge.awready),
		awaddr(m_bridge.awaddr),
		awprot(m_bridge.awprot),
		awuser(m_bridge.awuser),
		awregion(m_bridge.awregion),
		awqos(m_bridge.awqos),
		awcache(m_bridge.awcache),
		awburst(m_bridge.awburst),
		awsize(m_bridge.awsize),
		awlen(m_bridge.awlen),
		awid(m_bridge.awid),
		awlock(m_bridge.awlock),
		wvalid(m_bridge.wvalid),
		wready(m_bridge.wready),
		wdata(m_bridge.wdata),
		wstrb(m_bridge.wstrb),
		wuser(m_bridge.wuser),
		wlast(m_bridge.wlast),
		bvalid(m_bridge.bvalid),
		bready(m_bridge.bready),
		bresp(m_bridge.bresp),
		buser(m_bridge.buser),
		bid(m_bridge.bid),
		arvalid(m_bridge.arvalid),
		arready(m_bridge.arready),
		araddr(m_bridge.araddr),
		arprot(m_bridge.arprot),
		aruser(m_bridge.aruser),
		arregion(m_bridge.arregion),
		arqos(m_bridge.arqos),
		arcache(m_bridge.arcache),
		arburst(m_bridge.arburst),
		arsize(m_bridge.arsize),
		arlen(m_bridge.arlen),
		arid(m_bridge.arid),
		arlock(m_bridge.arlock),
		rvalid(m_bridge.rvalid),
		rready(m_bridge.rready),
		rdata(m_bridge.rdata),
		rresp(m_bridge.rresp),
		ruser(m_bridge.ruser),
		rid(m_bridge.rid),
		rlast(m_bridge.rlast),

		awsnoop(m_bridge.awsnoop),
		awdomain(m_bridge.awdomain),
		awbar(m_bridge.awbar),
		wack(m_bridge.wack),

		arsnoop(m_bridge.arsnoop),
		ardomain(m_bridge.ardomain),
		arbar(m_bridge.arbar),
		rack(m_bridge.rack),

		acvalid(m_snp_chnls.acvalid),
		acready(m_snp_chnls.acready),
		acaddr(m_snp_chnls.acaddr),
		acsnoop(m_snp_chnls.acsnoop),
		acprot(m_snp_chnls.acprot),

		crvalid(m_snp_chnls.crvalid),
		crready(m_snp_chnls.crready),
		crresp(m_snp_chnls.crresp),

		cdvalid(m_snp_chnls.cdvalid),
		cdready(m_snp_chnls.cdready),
		cddata(m_snp_chnls.cddata),
		cdlast(m_snp_chnls.cdlast)
	{
		tgt_socket.register_b_transport(
				this, &tlm2ace_bridge::b_transport);
		m_snoop_tgt_socket.register_b_transport(
				this, &tlm2ace_bridge::b_transport_snoop);

		m_init_socket(m_bridge.tgt_socket);
		m_snp_chnls.snoop_init_socket(m_snoop_tgt_socket);
	}
};
#endif

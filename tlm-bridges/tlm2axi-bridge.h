/*
 * TLM-2.0 to AXI bridge.
 *
 * Copyright (c) 2017-2018 Xilinx Inc.
 * Written by Edgar E. Iglesias,
 *            Francisco Iglesias.
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

#ifndef TLM2AXI_BRIDGE_H__
#define TLM2AXI_BRIDGE_H__
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <vector>
#include <list>
#include <sstream>

#include "tlm-bridges/amba.h"
#include "tlm-bridges/amba-ace.h"
#include "tlm-modules/tlm-aligner.h"
#include "tlm-extensions/genattr.h"
#include "tlm-bridges/private/ace/snoop-channels.h"

#define TLM2AXI_BRIDGE_MSG "tlm2axi-bridge"

#define D(x)

using namespace AMBA::ACE;

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
	int ACE_MODE = ACE_MODE_OFF,
	int CACHELINE_SZ = 64,
	int CD_DATA_WIDTH = DATA_WIDTH>
class tlm2axi_bridge
: public sc_core::sc_module,
	public tlm_aligner::IValidator,
	public axi_common
{
public:
	typedef ACESnoopChannels_M<
				ADDR_WIDTH,
				CD_DATA_WIDTH,
				CACHELINE_SZ> ACESnoopChannels_M__;

	tlm_utils::simple_target_socket<tlm2axi_bridge> tgt_socket;

	tlm2axi_bridge(sc_core::sc_module_name name,
			AXIVersion version = V_AXI4, bool aligner_enable=true) :
		sc_module(name),
		axi_common(this),
		tgt_socket("target_socket"),

		clk("clk"),
		resetn("resetn"),

		awvalid("awvalid"),
		awready("awready"),
		awaddr("awaddr"),
		awprot("awprot"),
		awuser("awuser"),
		awregion("awregion"),
		awqos("awqos"),
		awcache("awcache"),
		awburst("awburst"),
		awsize("awsize"),
		awlen("awlen"),
		awid("awid"),
		awlock("awlock"),

		wid("wid"),
		wvalid("wvalid"),
		wready("wready"),
		wdata("wdata"),
		wstrb("wstrb"),
		wuser("wuser"),
		wlast("wlast"),

		bvalid("bvalid"),
		bready("bready"),
		bresp("bresp"),
		buser("buser"),
		bid("bid"),

		arvalid("arvalid"),
		arready("arready"),
		araddr("araddr"),
		arprot("arprot"),
		aruser("aruser"),
		arregion("arregion"),
		arqos("arqos"),
		arcache("arcache"),
		arburst("arburst"),
		arsize("arsize"),
		arlen("arlen"),
		arid("arid"),
		arlock("arlock"),

		rvalid("rvalid"),
		rready("rready"),
		rdata("rdata"),
		rresp("rresp"),
		ruser("ruser"),
		rid("rid"),
		rlast("rlast"),

		// AXI4 ACE signals
		awsnoop("awsnoop"),
		awdomain("awdomain"),
		awbar("awbar"),
		wack("wack"),

		arsnoop("arsnoop"),
		ardomain("ardomain"),
		arbar("arbar"),

		rack("rack"),

		m_snp_chnls(NULL),

		m_version(version),
		m_maxBurstLength(AXI4_MAX_BURSTLENGTH),
		aligner(NULL),
		proxy_init_socket(NULL),
		proxy_target_socket(NULL),
		dummy("axi_dummy")
	{
		if (ACE_MODE == ACE_MODE_ACE) {
			m_snp_chnls = new ACESnoopChannels_M__(
						"ace_snp_chnls", clk, resetn);
		}

		if (m_version == V_AXI3) {
			m_maxBurstLength = AXI3_MAX_BURSTLENGTH;
		}

		if (aligner_enable) {
			aligner = new tlm_aligner("aligner",
						  DATA_WIDTH,
						  m_maxBurstLength * DATA_WIDTH / 8, /* MAX AXI length.  */
						  4 * 1024, /* AXI never allows crossing of 4K boundary.  */
						  true); /* WRAP burst-types require natural alignment.  */

			proxy_init_socket = new tlm_utils::simple_initiator_socket<tlm2axi_bridge>("proxy_init_socket");
			proxy_target_socket = new tlm_utils::simple_target_socket<tlm2axi_bridge>("proxy_target_socket");

			(*proxy_init_socket)(aligner->target_socket);
			aligner->init_socket(*proxy_target_socket);

			tgt_socket.register_b_transport(this, &tlm2axi_bridge::b_transport_proxy);
			proxy_target_socket->register_b_transport(this, &tlm2axi_bridge::b_transport);
		} else {
			tgt_socket.register_b_transport(this, &tlm2axi_bridge::b_transport);
		}

		SC_THREAD(read_address_phase);
		SC_THREAD(write_address_phase);
		SC_THREAD(read_resp_phase);
		SC_THREAD(write_data_phase);
		SC_THREAD(write_resp_phase);

		SC_THREAD(reset);
	}

	~tlm2axi_bridge() {
		delete proxy_init_socket;
		delete proxy_target_socket;
		delete aligner;
		delete m_snp_chnls;
	}

	SC_HAS_PROCESS(tlm2axi_bridge);

	sc_in<bool> clk;
	sc_in<bool> resetn;

	/* Write address channel.  */
	sc_out<bool > awvalid;
	sc_in<bool > awready;
	sc_out<sc_bv<ADDR_WIDTH> > awaddr;
	sc_out<sc_bv<3> > awprot;
	sc_out<AXISignal(AWUSER_WIDTH) > awuser;// AXI4 only
	sc_out<sc_bv<4> > awregion;		// AXI4 only
	sc_out<sc_bv<4> > awqos;		// AXI4 only
	sc_out<sc_bv<4> > awcache;
	sc_out<sc_bv<2> > awburst;
	sc_out<sc_bv<3> > awsize;
	sc_out<AXISignal(AxLEN_WIDTH) > awlen;
	sc_out<AXISignal(ID_WIDTH) > awid;
	sc_out<AXISignal(AxLOCK_WIDTH) > awlock;

	/* Write data channel.  */
	sc_out<AXISignal(ID_WIDTH) > wid;	// AXI3 only
	sc_out<bool > wvalid;
	sc_in<bool > wready;
	sc_out<sc_bv<DATA_WIDTH> > wdata;
	sc_out<sc_bv<DATA_WIDTH/8> > wstrb;
	sc_out<AXISignal(WUSER_WIDTH) > wuser;	// AXI4 only
	sc_out<bool > wlast;

	/* Write response channel.  */
	sc_in<bool > bvalid;
	sc_out<bool > bready;
	sc_in<sc_bv<2> > bresp;
	sc_in<AXISignal(BUSER_WIDTH) > buser;
	sc_in<AXISignal(ID_WIDTH) > bid;

	/* Read address channel.  */
	sc_out<bool > arvalid;
	sc_in<bool > arready;
	sc_out<sc_bv<ADDR_WIDTH> > araddr;
	sc_out<sc_bv<3> > arprot;
	sc_out<AXISignal(ARUSER_WIDTH) > aruser;	// AXI4 only
	sc_out<sc_bv<4> > arregion;			// AXI4 only
	sc_out<sc_bv<4> > arqos;			// AXI4 only
	sc_out<sc_bv<4> > arcache;
	sc_out<sc_bv<2> > arburst;
	sc_out<sc_bv<3> > arsize;
	sc_out<AXISignal(AxLEN_WIDTH) > arlen;
	sc_out<AXISignal(ID_WIDTH) > arid;
	sc_out<AXISignal(AxLOCK_WIDTH) > arlock;

	/* Read data channel.  */
	sc_in<bool > rvalid;
	sc_out<bool > rready;
	sc_in<sc_bv<DATA_WIDTH> > rdata;
	sc_in<sc_bv<(ACE_MODE == ACE_MODE_ACE) ? 4 : 2> > rresp;
	sc_in<AXISignal(RUSER_WIDTH) > ruser;		// AXI4 only
	sc_in<AXISignal(ID_WIDTH) > rid;
	sc_in<bool > rlast;

	// AXI4 ACE signals
	sc_out<sc_bv<3> > awsnoop;
	sc_out<sc_bv<2> > awdomain;
	sc_out<sc_bv<2> > awbar;

	sc_out<bool > wack;

	sc_out<sc_bv<4> > arsnoop;
	sc_out<sc_bv<2> > ardomain;
	sc_out<sc_bv<2> > arbar;

	sc_out<bool > rack;

	ACESnoopChannels_M__& GetACESnoopChannels() { return *m_snp_chnls; };

private:
	class Transaction :
		public ace_tx_helpers
	{
	public:
		Transaction(tlm::tlm_generic_payload& gp) :
			m_gp(gp),
			m_burstType(AXI_BURST_INCR),
			m_beat(1),
			m_numBeats(0)
		{
			genattr_extension *genattr;

			m_gp.get_extension(genattr);
			if (genattr) {
				m_genattr.copy_from(*genattr);
			}

			SetupBurstType();
			SetupNumBeats();

			if (ACE_MODE) {
				setup_ace_helpers(&m_gp);
			}
		}

		void SetupBurstType()
		{
			unsigned int streaming_width = m_gp.get_streaming_width();
			unsigned int datalen = m_gp.get_data_length();

			if (streaming_width == datalen &&
				m_genattr.get_wrap()) {
				m_burstType = AXI_BURST_WRAP;
			} else if (streaming_width >= datalen) {
				m_burstType = AXI_BURST_INCR;
			} else if (streaming_width == DATA_BUS_BYTES) {
				m_burstType = AXI_BURST_FIXED;
			} else if (streaming_width < DATA_BUS_BYTES &&
				   m_genattr.get_burst_width() >= streaming_width) {
				m_burstType = AXI_BURST_FIXED;
			} else if (streaming_width < DATA_BUS_BYTES &&
				   m_genattr.get_burst_width() == 0) {
				//
				// Specify this with burst_width if streaming
				// width is less than the data bus width
				//
				m_burstType = AXI_BURST_FIXED;
				if (streaming_width > 1) {
					streaming_width &= (~0x1);
				}

				m_genattr.set_burst_width(streaming_width);
			} else {
				SC_REPORT_ERROR(TLM2AXI_BRIDGE_MSG,
						"Unsupported burst type");
			}
		}

		void SetupNumBeats()
		{
			uint64_t address = m_gp.get_address();
			unsigned int dataLen = m_gp.get_data_length();
			uint32_t burst_width = GetBurstWidth();
			uint64_t alignedAddress;
			unsigned int alignment;

			alignedAddress = (address / burst_width) * burst_width;
			alignment = address - alignedAddress;

			if (m_burstType == AXI_BURST_FIXED) {
				burst_width -= alignment;
			} else {
				dataLen += alignment;
			}

			m_numBeats = (dataLen + burst_width - 1) / burst_width;
		}

		uint32_t GetNumBeats() { return m_numBeats; }

		uint32_t GetBurstWidth()
		{
			uint32_t burst_width = m_genattr.get_burst_width();

			if (burst_width == 0) {
				// Default to databus width
				burst_width = DATA_BUS_BYTES;
			}
			return burst_width;
		}

		uint8_t GetBurstType() { return m_burstType; }

		tlm::tlm_generic_payload& GetGP() { return m_gp; }

		uint32_t GetAxID() { return m_genattr.get_transaction_id(); }

		uint64_t GetAddress() { return m_gp.get_address(); }

		uint8_t GetAxProt()
		{
			uint8_t AxProt = 0;

			if (m_genattr.get_non_secure()) {
				AxProt |= AXI_PROT_NS;
			}
			return AxProt;
		}

		uint8_t GetAxLock()
		{
			uint8_t AxLock = AXI_LOCK_NORMAL;

			if (m_genattr.get_exclusive()) {
				AxLock = AXI_LOCK_EXCLUSIVE;
			} else if (AxLOCK_WIDTH > AXI4_AxLOCK_WIDTH &&
					m_genattr.get_locked()) {
				AxLock = AXI_LOCK_LOCKED;
			}
			return AxLock;
		}

		uint8_t GetAxCache()
		{
			uint8_t AxCache = 0;

			 AxCache = m_genattr.get_bufferable() |
					(m_genattr.get_modifiable() << 1) |
					(m_genattr.get_read_allocate() << 2) |
					(m_genattr.get_write_allocate() << 3);
			return AxCache;
		}

		uint8_t GetAxQoS()
		{
			uint8_t AxQoS = 0;

			AxQoS = m_genattr.get_qos();
			return AxQoS;
		}

		uint8_t GetAxRegion()
		{
			uint8_t AxRegion = 0;

			AxRegion = m_genattr.get_region();
			return AxRegion;
		}

		void IncBeat() { m_beat++; }

		bool IsFirstBeat() { return m_beat == 1; }

		bool IsLastBeat() { return m_beat == m_numBeats; }

		bool IsExclusive() { return m_genattr.get_exclusive(); }

		sc_event& DoneEvent() { return m_done; }

		bool hasData()
		{
			if (ACE_MODE) {
				if (IsBarrier() || IsEvict()) {
					return false;
				}
			}
			return true;
		}

		bool IsRead()
		{
			if (ACE_MODE) {
				//
				// Transactions with no data transfer but that
				// are sent out on the rd channels.
				//
				if (HasSingleRdDataTransfer()) {
					return true;
				}
			}
			return m_gp.is_read();
		}

		bool IsWrite()
		{
			if (ACE_MODE) {
				if (IsEvict() || IsWriteBarrier()) {
					return true;
				}
			}
			return m_gp.is_write();
		}

	private:
		tlm::tlm_generic_payload& m_gp;
		genattr_extension m_genattr;
		sc_event m_done;
		uint8_t m_burstType;
		uint32_t m_beat;
		uint32_t m_numBeats;
	};

	int prepare_wbeat(Transaction *tr, unsigned int offset, unsigned int data_offset);

	bool validate(uint64_t t_addr,
			unsigned int t_len,
			unsigned int streaming_width)
	{
		bool valid_for_axi = true;
		unsigned int bus_width_bytes = MIN(DATA_WIDTH / 8, streaming_width);
		unsigned int num_beats;

		num_beats = (t_len + bus_width_bytes - 1) / bus_width_bytes;

		switch (num_beats) {
		case 1: /* Not a burst.  */
		case 2:
		case 4:
		case 8:
		case 16:
			break;
		default:
			valid_for_axi = false;
		}
		switch (bus_width_bytes) {
		case 1:
		case 2:
		case 4:
		case 8:
		case 16:
		case 32:
		case 64:
		case 128:
			break;
		default:
			valid_for_axi = false;
		}

		if (streaming_width > bus_width_bytes) {
			uint64_t wrapping_addr;

			switch (streaming_width) {
			case 2:
			case 4:
			case 8:
			case 16:
			case 32:
			case 64:
			case 128:
				break;
			default:
				valid_for_axi = false;
			}

			/* Compute wrapping address.  Next pos aligned to t_len.*/
			wrapping_addr = t_addr + t_len / t_len;
			if (wrapping_addr - t_addr != streaming_width) {
				valid_for_axi = false;
			}
		}

		return valid_for_axi;
	}

	// Lookup a transaction in a vector. If found, return
	// the pointer and remove it.
	Transaction *LookupAxID(std::vector<Transaction*> &vec,
					      uint32_t id)
	{
		Transaction *tr = NULL;
		unsigned int i;

		// Find _FIRST_ bid in vector
		for (i = 0; i < vec.size(); i++) {
			if (vec[i]->GetAxID() == id) {
				break;
			}
		}

		// If found, remove and return it.
		if (i < vec.size()) {
			tr = vec[i];
			vec.erase(vec.begin() + i);
		}
		return tr;
	}

	// Useful for debugging the response handling.
	void print_vec(std::vector<Transaction*> &vec, const char *name) {
		int i;

		printf("name=%s size=%d\n", name, (int)vec.size());
		for (i = 0; i < vec.size(); i++) {
			printf("vec[%d].AxID = %d\n", i, vec[i]->GetAxID());
		}
		printf("\n");
	}

	bool Validate(Transaction& tr)
	{
		tlm::tlm_generic_payload& trans = tr.GetGP();

		if (trans.get_data_length() == 0) {
			SC_REPORT_INFO(TLM2AXI_BRIDGE_MSG,
					"Zero-length transaction");
			return false;
		}

		if (trans.get_streaming_width() == 0) {
			SC_REPORT_INFO(TLM2AXI_BRIDGE_MSG,
					"Zero-length streaming-width");
			return false;
		}

		if (!ValidateBurstWidth(tr.GetBurstWidth())) {
			return false;
		}

		if (tr.GetNumBeats() > m_maxBurstLength) {
			return false;
		}

		if (!tr.IsRead() && !tr.IsWrite()) {
			return false;
		}

		return true;
	}

	virtual void b_transport_proxy(tlm::tlm_generic_payload& trans,
					sc_time& delay) {
		return proxy_init_socket[0]->b_transport(trans, delay);
	}

	virtual void b_transport(tlm::tlm_generic_payload& trans,
					sc_time& delay)
	{
		Transaction tr(trans);

		// Since we're going todo waits in order to wiggle the
		// AXI signals, we need to eliminate the accumulated
		// TLM delay.
		wait(delay, resetn.negedge_event());
		delay = SC_ZERO_TIME;

		// Abort if reset got asserted.
		if (resetn.read() && Validate(tr)) {
			// Hand it over to the signal wiggling machinery.
			if (tr.IsRead()) {
				rdTransFifo.write(&tr);
			} else {
				wrTransFifo.write(&tr);
			}
			// Wait until the transaction is done.
			wait(tr.DoneEvent());
		} else {
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		}
	}

	bool read_address_phase(Transaction *rt)
	{
		int axsize = map_size_to_axsize_assert(rt->GetBurstWidth());

		if (reset_asserted()) {
			arvalid.write(false);
			return false;
		}

		araddr.write(rt->GetAddress());
		arprot.write(rt->GetAxProt());
		arsize.write(axsize);
		arlen.write(rt->GetNumBeats() - 1);
		arburst.write(rt->GetBurstType());
		arid.write(rt->GetAxID());
		arlock.write(rt->GetAxLock());
		arcache.write(rt->GetAxCache());
		arqos.write(rt->GetAxQoS());
		arregion.write(rt->GetAxRegion());

		if (ACE_MODE) {
			arsnoop.write(rt->GetAxSnoop());
			ardomain.write(rt->GetAxDomain());
			arbar.write(rt->GetAxBar());

			//
			// Barrier transactions must have axlen == 0
			// (Section 3.1.5 [1]). Also DVM transactions (Section
			// C12.6 [1]).
			//
			if (rt->GetAxBar() || rt->IsDVM()) {
				arlen.write(0);
			}

			if (ACE_MODE == ACE_MODE_ACE) {
				//
				// Wait until the DVM Sync response has been
				// sent before transmitting DVMComplete
				//
				if (rt->IsDVMComplete() &&
					m_snp_chnls->GetNumDVMSyncResp() == 0) {

					wait(m_snp_chnls->DVMSyncRespEvent() |
						resetn.negedge_event());
				}
				m_snp_chnls->DecNumDVMSyncResp();
			}
		}

		arvalid.write(true);

		// Wait for arready but exit if reset is asserted
		wait_abort_on_reset(arready);

		arvalid.write(false);

		// Return false if reset was asserted while waiting for arready
		return resetn.read();
	}

	bool write_address_phase(Transaction *wt)
	{
		int axsize = map_size_to_axsize_assert(wt->GetBurstWidth());

		if (reset_asserted()) {
			awvalid.write(false);
			return false;
		}

		awaddr.write(wt->GetAddress());
		awprot.write(wt->GetAxProt());
		awsize.write(axsize);
		awlen.write(wt->GetNumBeats() - 1);
		awburst.write(wt->GetBurstType());
		awid.write(wt->GetAxID());
		awlock.write(wt->GetAxLock());
		awcache.write(wt->GetAxCache());
		awqos.write(wt->GetAxQoS());
		awregion.write(wt->GetAxRegion());

		if (ACE_MODE) {
			awsnoop.write(wt->GetAxSnoop());
			awdomain.write(wt->GetAxDomain());
			awbar.write(wt->GetAxBar());

			// Barrier transactions must have axlen == 0
			// (Section 3.1.5 [1])
			if (wt->GetAxBar()) {
				awlen.write(0);
			}
		}

		awvalid.write(true);

		return true;
	}

	bool ValidateBurstWidth(uint32_t burst_width)
	{
		static const unsigned int widths[] = {
			1, 2, 4, 8, 16, 32, 64, 128
		};
		unsigned int i;

		for (i = 0; i < sizeof widths / sizeof widths[0]; i++) {
			if (widths[i] == burst_width) {
				return true;
			}
		}
		return false;
	}

	void address_phase(sc_fifo<Transaction*> &transFifo)
	{
		while (true) {
			Transaction *tr = transFifo.read();

			/* Send the address and pass on the transaction to the
			 * next pipeline step if reset was not asserted.
			 */
			if (tr->IsRead()) {
				if (read_address_phase(tr)) {
					rdResponses.push_back(tr);
				}

			} else {
				if (write_address_phase(tr)) {
					wrDataFifo.write(tr);
					tr = NULL;
					wait_abort_on_reset(awready);
				}
				awvalid.write(false);
			}

			/* Abort transaction if reset is asserted. */
			if (reset_asserted()) {
				if (tr) {
					abort(tr);
				}
				wait_for_reset_release();
			}
		}
	}

	void read_address_phase() {
		address_phase(rdTransFifo);
	}

	void write_address_phase() {
		address_phase(wrTransFifo);
	}

	void read_resp_phase()
	{
		rready.write(false);

		while (true) {
			Transaction *tr = NULL;
			tlm::tlm_generic_payload *trans = NULL;
			unsigned char *data = NULL;
			unsigned char *be = NULL;
			unsigned int len = 0;
			unsigned int be_len = 0;
			uint64_t data64 = 0;
			unsigned int bitoffset = 0;
			unsigned int pos = 0;
			unsigned int addr_pos = 0;
			unsigned int streaming_width = 0;

			while (len || tr == NULL) {
				rready.write(true);

				wait(clk.posedge_event() | resetn.negedge_event());

				if (reset_asserted()) {
					break;
				}

				if (rvalid.read()) {
					sc_bv<128> data128 = 0;
					unsigned int readlen;
					unsigned int w;
					uint64_t addr;

					if (tr == NULL) {
						uint32_t rid_u32 = to_uint(rid);

						tr = LookupAxID(rdResponses, rid_u32);

						if (!tr) {
							SC_REPORT_ERROR(TLM2AXI_BRIDGE_MSG,
								"Received a read response "
								"with an unexpected "
								"transaction ID");
						}

						trans = &tr->GetGP();
						addr = trans->get_address();
						data = trans->get_data_ptr();
						len = trans->get_data_length();
						be = trans->get_byte_enable_ptr();
						be_len = trans->get_byte_enable_length();
						streaming_width = trans->get_streaming_width();

					}

					//
					// ACE Clean and Make transactions have
					// a single data transfer and data must
					// be ignored.
					//
					// Section C3.2.1 [1]
					//
					if (ACE_MODE && tr->HasSingleRdDataTransfer()) {
						break;
					}

					addr = trans->get_address() + (addr_pos % streaming_width);
					bitoffset = (addr * 8) % DATA_WIDTH;
					readlen = (DATA_WIDTH - bitoffset) / 8;
					readlen = readlen <= len ? readlen : len;
					// Respect the genattr burstwidh attribute
					readlen = readlen <= tr->GetBurstWidth() ? readlen : tr->GetBurstWidth();
					if (tr->GetBurstType() == AXI_BURST_FIXED ||
					    tr->IsFirstBeat()) {
						unsigned int t;

						// For narrow bursts, the lanes need to be aligned.
						t = addr & (tr->GetBurstWidth() - 1);
						t = tr->GetBurstWidth() - t;
						readlen = readlen > t ? t : readlen;
					}

					for (w = 0; w < readlen; w += sizeof data64) {
						unsigned int copylen = readlen - w;

						copylen = copylen <= sizeof data64 ? copylen : sizeof data64;
						data128 = rdata.read() >> (w * 8 + bitoffset);
						data64 = data128.to_uint64();

						assert(copylen <= len);
						if (be && be_len) {
							uint64_t val = data64;
							unsigned int i;

							for (i = 0; i < copylen; i++) {
								if (be[(pos + i)% be_len] == TLM_BYTE_ENABLED) {
									data[pos + i] = val & 0xff;
								}
								val >>= 8;
							}
						} else {
							memcpy(data + pos, &data64, copylen);
						}

						D(printf("Read addr=%x data64=%lx len=%d readlen=%d pos=%d w=%d sw=%d ofset=%d, copylen=%d\n",
							addr, data64, len, readlen, pos, w, streaming_width,
							(w * 8 + bitoffset), copylen));
						if (tr->GetBurstType() != AXI_BURST_FIXED) {
							addr_pos += copylen;
						}
						pos += copylen;
						len -= copylen;
					}

					if (rlast.read() && len) {
						SC_REPORT_ERROR(TLM2AXI_BRIDGE_MSG,
							"Received a premature rlast");
					}
				}
			}
			rready.write(false);

			//
			// Translate the response and notify if not in reset.
			//
			if (resetn.read() == true) {
				uint64_t resp = rresp.read().to_uint64();

				tlm_gp_set_axi_resp(*trans, resp & 3);

				if (ACE_MODE == ACE_MODE_ACE) {
					if (m_snp_chnls->ExtractIsShared(resp)) {
						tr->SetShared();
					}
					if (m_snp_chnls->ExtractPassDirty(resp)) {
						tr->SetDirty();
					}

					// Signal rack
					rack.write(true);
					wait(clk.posedge_event() | resetn.negedge_event());
					rack.write(false);

					// Reset asserted while rack is being signaled
					if (reset_asserted()) {
						abort(tr);
						wait_for_reset_release();
						continue;
					}
				}

				tr->DoneEvent().notify();
			} else {
				//
				// Reset is asserted, abort the transaction.
				//
				if (tr) {
					abort(tr);
				}
				wait_for_reset_release();
			}
		}
	}

	void write_data_phase()
	{
		wvalid.write(false);

		while (true) {
			Transaction *tr = wrDataFifo.read();
			tlm::tlm_generic_payload& trans = tr->GetGP();
			unsigned int len = trans.get_data_length();
			unsigned int pos = 0, addr_pos = 0;

			//
			// Start the data transfer if not in reset. ACE write
			// barriers and Evict do not have data transfer.
			//
			if (!reset_asserted() && tr->hasData()) {
				while (pos < len) {
					unsigned int d;

					d = prepare_wbeat(tr, addr_pos, pos);
					pos += d;
					if (tr->GetBurstType() != AXI_BURST_FIXED) {
						addr_pos += d;
					}

					wlast.write(tr->IsLastBeat());

					/* Wait for wready but abort if reset is asserted. */
					wait_abort_on_reset(wready);

					if (reset_asserted()) {
						break;
					}

					tr->IncBeat();
				}
			}

			wlast.write(false);
			wvalid.write(false);

			//
			// Pass the transaction to the next pipeline step if
			// not in reset.
			//
			if (resetn.read() == true) {
				wrResponses.push_back(tr);
			} else {
				// In reset
				abort(tr);
				wait_for_reset_release();
			}
		}
	}

	void write_resp_phase()
	{
		bready.write(false);

		while (true) {
			Transaction *tr;
			uint32_t bid_u32;

			bready.write(true);

			/* Wait for bvalid but abort if reset is asserted. */
			wait_abort_on_reset(bvalid);
			bready.write(false);

			/* Reset is asserted. */
			if (reset_asserted()) {
				wait_for_reset_release();

				/* Restart. */
				continue;
			}

			bid_u32 = to_uint(bid);

			tr = LookupAxID(wrResponses, bid_u32);
			if (!tr) {
				SC_REPORT_ERROR("tlm2axi-bridge",
					"Received a write response "
					"with an unexpected transaction ID");
			}

			tlm_gp_set_axi_resp(tr->GetGP(),
					bresp.read().to_uint64());

			if (ACE_MODE == ACE_MODE_ACE) {
				wack.write(true);

				// Wait 1 clk cycle (or for reset)
				wait(clk.posedge_event() | resetn.negedge_event());

				wack.write(false);

				if (reset_asserted()) {
					abort(tr);
					wait_for_reset_release();
					continue;
				}
			}

			tr->DoneEvent().notify();
		}
	}

	void reset()
	{
		while(true) {

			wait(resetn.negedge_event());

			//
			// Reset got asserted, abort all transactions
			//

			tlm2axi_clear_fifo(rdTransFifo);

			for (unsigned int i = 0; i < rdResponses.size(); i++) {
				abort(rdResponses[i]);
			}
			rdResponses.clear();

			tlm2axi_clear_fifo(wrTransFifo);

			tlm2axi_clear_fifo(wrDataFifo);

			for (unsigned int i = 0; i < wrResponses.size(); i++) {
				abort(wrResponses[i]);
			}
			wrResponses.clear();

			if (ACE_MODE == ACE_MODE_ACE) {
				rack.write(false);
				wack.write(false);
			}
		}
	}

	class axi_dummy : public sc_core::sc_module
	{
	public:
		// AXI4
		sc_signal<AXISignal(ID_WIDTH) > wid;

		// AXI3
		sc_signal<sc_bv<4> > awqos;
		sc_signal<sc_bv<4> > awregion;
		sc_signal<AXISignal(AWUSER_WIDTH) > awuser;
		sc_signal<AXISignal(WUSER_WIDTH) > wuser;
		sc_signal<AXISignal(BUSER_WIDTH) > buser;
		sc_signal<sc_bv<4> > arregion;
		sc_signal<sc_bv<4> > arqos;
		sc_signal<AXISignal(ARUSER_WIDTH) > aruser;
		sc_signal<AXISignal(RUSER_WIDTH) > ruser;

		// AXI4 ACE signals
		sc_signal<sc_bv<3> > awsnoop;
		sc_signal<sc_bv<2> > awdomain;
		sc_signal<sc_bv<2> > awbar;
		sc_signal<bool > wack;
		sc_signal<sc_bv<4> > arsnoop;
		sc_signal<sc_bv<2> > ardomain;
		sc_signal<sc_bv<2> > arbar;
		sc_signal<bool > rack;

		axi_dummy(sc_module_name name) :
			wid("wid"),
			awqos("awqos"),
			awregion("awregion"),
			awuser("awuser"),
			wuser("wuser"),
			buser("buser"),
			arregion("arregion"),
			arqos("arqos"),
			aruser("aruser"),
			ruser("ruser"),

			// AXI4 ACE signals
			awsnoop("awsnoop"),
			awdomain("awdomain"),
			awbar("awbar"),
			wack("wack"),
			arsnoop("arsnoop"),
			ardomain("ardomain"),
			arbar("arbar"),
			rack("rack")
		{ }
	};

	void bind_dummy(void)
	{
		if (m_version == V_AXI4) {
			wid(dummy.wid);

			//
			// Optional signals
			//
			if (AWUSER_WIDTH == 0) {
				awuser(dummy.awuser);
			}
			if (WUSER_WIDTH == 0) {
				wuser(dummy.wuser);
			}
			if (BUSER_WIDTH == 0) {
				buser(dummy.buser);
			}
			if (ARUSER_WIDTH == 0) {
				aruser(dummy.aruser);
			}
			if (RUSER_WIDTH == 0) {
				ruser(dummy.ruser);
			}

			if (ACE_MODE == ACE_MODE_OFF) {
				awsnoop(dummy.awsnoop);
				awdomain(dummy.awdomain);
				awbar(dummy.awbar);
				wack(dummy.wack);
				arsnoop(dummy.arsnoop);
				ardomain(dummy.ardomain);
				arbar(dummy.arbar);
				rack(dummy.rack);
			} else if (ACE_MODE == ACE_MODE_ACELITE) {
				rack(dummy.rack);
				wack(dummy.wack);
			}
		} else if (m_version == V_AXI3) {
			awqos(dummy.awqos);
			awregion(dummy.awregion);
			awuser(dummy.awuser);
			wuser(dummy.wuser);
			buser(dummy.buser);
			arregion(dummy.arregion);
			arqos(dummy.arqos);
			aruser(dummy.aruser);
			ruser(dummy.ruser);

			// AXI4 ACE signals
			awsnoop(dummy.awsnoop);
			awdomain(dummy.awdomain);
			awbar(dummy.awbar);
			wack(dummy.wack);
			arsnoop(dummy.arsnoop);
			ardomain(dummy.ardomain);
			arbar(dummy.arbar);
			rack(dummy.rack);
		}
	}

	void before_end_of_elaboration()
	{
		bind_dummy();
	}

	ACESnoopChannels_M__ *m_snp_chnls;

	static const uint32_t DATA_BUS_BYTES = DATA_WIDTH/8;

	sc_fifo<Transaction*> rdTransFifo;
	sc_fifo<Transaction*> wrTransFifo;

	std::vector<Transaction*> rdResponses;

	sc_fifo<Transaction*> wrDataFifo;
	std::vector<Transaction*> wrResponses;

	AXIVersion m_version;
	unsigned int m_maxBurstLength;
	tlm_aligner *aligner;
	tlm_utils::simple_initiator_socket<tlm2axi_bridge> *proxy_init_socket;
	tlm_utils::simple_target_socket<tlm2axi_bridge> *proxy_target_socket;
	axi_dummy dummy;
};

template
<int ADDR_WIDTH, int DATA_WIDTH, int ID_WIDTH, int AxLEN_WIDTH,
	int AxLOCK_WIDTH, int AWUSER_WIDTH, int ARUSER_WIDTH, int WUSER_WIDTH,
	int RUSER_WIDTH, int BUSER_WIDTH, int ACE_MODE, int CD_DATA_WIDTH,
	int CACHELINE_SZ>
int tlm2axi_bridge<ADDR_WIDTH,
		DATA_WIDTH,
		ID_WIDTH,
		AxLEN_WIDTH,
		AxLOCK_WIDTH,
		AWUSER_WIDTH,
		ARUSER_WIDTH,
		WUSER_WIDTH,
		RUSER_WIDTH,
		BUSER_WIDTH,
		ACE_MODE,
		CD_DATA_WIDTH,
		CACHELINE_SZ>
::prepare_wbeat(Transaction *tr, unsigned int offset, unsigned int data_offset)
{
	tlm::tlm_generic_payload& trans = tr->GetGP();
	unsigned int streaming_width = trans.get_streaming_width();
	sc_dt::uint64 addr = trans.get_address();
	unsigned char *data = trans.get_data_ptr();
	unsigned int len = trans.get_data_length();
	unsigned char *be = trans.get_byte_enable_ptr();
	int be_len = trans.get_byte_enable_length();
	unsigned int bitoffset;
	sc_bv<DATA_WIDTH/8> strb = 0;
	sc_bv<DATA_WIDTH> data128 = 0;
	uint64_t t64;
	unsigned int i;
	unsigned int maxlen, wlen;

	assert(streaming_width);
	addr += (offset % streaming_width);
	data += data_offset;
	len -= data_offset;

	bitoffset = (addr * 8) % DATA_WIDTH;
	maxlen = (DATA_WIDTH - bitoffset) / 8;
	if (maxlen > (streaming_width - (offset % streaming_width))) {
		maxlen = (streaming_width - (offset % streaming_width));
	}
	wlen = len <= maxlen ? len : maxlen;
	// Respect the genattr burstwidh attribute
	wlen = wlen <= tr->GetBurstWidth() ? wlen : tr->GetBurstWidth();

	if (tr->GetBurstType() == AXI_BURST_FIXED || tr->IsFirstBeat()) {
		unsigned int t;

		// For narrow bursts, the lanes need to be aligned.
		t = addr & (tr->GetBurstWidth() - 1);
		t = tr->GetBurstWidth() - t;
		D(printf("realign wlen=%d t=%d bw=%d offset=%d\n",
			wlen, t, tr->GetBurstWidth(), offset));
		wlen = wlen > t ? t : wlen;
	}

	D(printf("WBEAT: pos=%d wlen=%d bitoffset=%d\n", offset, wlen, bitoffset));

	if (be && be_len) {
		strb = 0;
		for (i = 0; i < wlen; i++) {
			uint8_t b = be[(i + offset) % be_len];
			if (b == TLM_BYTE_ENABLED) {
				strb[i] = true;
			}
		}
	} else {
		/* All lanes active.  */
		for (i = 0; i < wlen; i++) {
			strb[i] = true;
		}
	}
	strb.lrotate(bitoffset / 8);

	for (i = 0; i < wlen; i += sizeof(t64)) {
		unsigned int copylen = wlen - i;

		t64 = 0;
		copylen = copylen < sizeof(t64) ? copylen : sizeof(t64);
		memcpy(&t64, data + i, copylen);
		data128.range(copylen * 8 - 1 + i * 8 + bitoffset,
			i * 8 + bitoffset) = t64;
	}

	if (m_version == V_AXI3) {
		wid.write(tr->GetAxID());
	}

	wdata.write(data128);
	D(std::cout << "strb " << strb << std::endl);
	D(std::cout << "data128 " << data128 << std::endl);

	wstrb.write(strb);
	wvalid.write(true);
	return wlen;
}
#undef D
#endif

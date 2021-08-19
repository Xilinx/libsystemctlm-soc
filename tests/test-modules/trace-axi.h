/*
 * Copyright (c) 2018 Xilinx Inc.
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

#ifndef TRACE_AXI_H__
#define TRACE_AXI_H__

#define TX_TRACE_INFO "trace"

template<int ADDR_WIDTH,
	 int DATA_WIDTH,
	 int ID_WIDTH = 8,
	 int AxLEN_WIDTH = 8,
	 int AxLOCK_WIDTH = 1,
	 int AWUSER_WIDTH = 2,
	 int ARUSER_WIDTH = 2,
	 int WUSER_WIDTH = 2,
	 int RUSER_WIDTH = 2,
	 int BUSER_WIDTH = 2>
class trace_axi : public sc_core::sc_module
{
public:
	sc_in<bool > clk;
	sc_in<bool > resetn;

	/* Write address channel.  */
	sc_in<bool > awvalid;
	sc_in<bool > awready;
	sc_in<sc_bv<ADDR_WIDTH> > awaddr;
	sc_in<sc_bv<3> > awprot;
	sc_in<AXISignal(AWUSER_WIDTH) > awuser;	// AXI4 only
	sc_in<sc_bv<4> > awregion;		// AXI4 only
	sc_in<sc_bv<4> > awqos;			// AXI4 only
	sc_in<sc_bv<4> > awcache;
	sc_in<sc_bv<2> > awburst;
	sc_in<sc_bv<3> > awsize;
	sc_in<AXISignal(AxLEN_WIDTH) > awlen;
	sc_in<AXISignal(ID_WIDTH) > awid;
	sc_in<AXISignal(AxLOCK_WIDTH) > awlock;

	/* Write data channel.  */
	sc_in<AXISignal(ID_WIDTH) > wid;		// AXI3 only
	sc_in<bool > wvalid;
	sc_in<bool > wready;
	sc_in<sc_bv<DATA_WIDTH> > wdata;
	sc_in<sc_bv<DATA_WIDTH/8> > wstrb;
	sc_in<AXISignal(WUSER_WIDTH) > wuser;	// AXI4 only
	sc_in<bool > wlast;

	/* Write response channel.  */
	sc_in<bool > bvalid;
	sc_in<bool > bready;
	sc_in<sc_bv<2> > bresp;
	sc_in<AXISignal(BUSER_WIDTH) > buser;	// AXI4 only
	sc_in<AXISignal(ID_WIDTH) > bid;

	/* Read address channel.  */
	sc_in<bool > arvalid;
	sc_in<bool > arready;
	sc_in<sc_bv<ADDR_WIDTH> > araddr;
	sc_in<sc_bv<3> > arprot;
	sc_in<AXISignal(ARUSER_WIDTH) > aruser;	// AXI4 only
	sc_in<sc_bv<4> > arregion;		// AXI4 only
	sc_in<sc_bv<4> > arqos;			// AXI4 only
	sc_in<sc_bv<4> > arcache;
	sc_in<sc_bv<2> > arburst;
	sc_in<sc_bv<3> > arsize;
	sc_in<AXISignal(AxLEN_WIDTH) > arlen;
	sc_in<AXISignal(ID_WIDTH) > arid;
	sc_in<AXISignal(AxLOCK_WIDTH) > arlock;

	/* Read data channel.  */
	sc_in<bool > rvalid;
	sc_in<bool > rready;
	sc_in<sc_bv<DATA_WIDTH> > rdata;
	sc_in<sc_bv<2> > rresp;
	sc_in<AXISignal(RUSER_WIDTH) > ruser;	// AXI4 only
	sc_in<AXISignal(ID_WIDTH) > rid;
	sc_in<bool > rlast;

	SC_HAS_PROCESS(trace_axi);
	trace_axi(sc_core::sc_module_name name,
			AXIVersion version = V_AXI4) :
		sc_module(name),

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

		dummy("axi_dummy"),
		m_print_all(false),
		m_print_addr(false),
		m_print_min_max_addr(false),
		m_print_ar(false),
		m_print_rr(false),
		m_print_aw(false),
		m_print_w(false),
		m_print_b(false),
		m_version(version)
	{
		SC_THREAD(trace);
	}

	// Print all detected transactions
	//
	void print_all(bool en = true) { m_print_all = en; }

	//
	// Print axsignals of transactions targeting the given address
	//
	void print_tx_with_address(uint64_t addr, bool en = true)
	{
		m_print_addr = en;
		m_addr.push_back(addr);
	}
	//
	// Print axsignals of transactions targeting the given address range
	//
	void print_tx_with_address(uint64_t min_addr, uint64_t max_addr, bool en = true)
	{
		m_print_min_max_addr = en;
		m_min_addr = min_addr;
		m_max_addr = max_addr;
	}

	void print_ar() { m_print_ar = true; }
	void print_rr() { m_print_rr = true; }
	void print_aw() { m_print_aw = true; }
	void print_w() { m_print_w = true; }
	void print_b() { m_print_b = true; }
	//
	// Display all read transactions
	//
	void print_rd()
	{
		m_print_ar = true;
		m_print_rr = true;
	}

	//
	// Display all write transactions
	//
	void print_wr()
	{
		m_print_aw = true;
		m_print_w = true;
		m_print_b = true;
	}

private:
	class axi_dummy : public sc_core::sc_module {
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
			ruser("ruser")
		{}
	};

	void bind_dummy(void) {
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
		}
	}

	void before_end_of_elaboration()
	{
		bind_dummy();
	}

	class Transaction
	{
	public:
		Transaction(uint64_t AxAddr,
				uint32_t AxLen,
				uint8_t AxSize,
				uint8_t AxBurst,
				uint8_t AxID,
				uint8_t AxCache,
				uint8_t AxLock,
				uint8_t AxQoS,
				uint8_t AxRegion,
				uint32_t AxUser,
				bool is_write,
				AXIVersion version) :
			m_AxAddr(AxAddr),
			m_AxLen(AxLen),
			m_AxSize(AxSize),
			m_AxBurst(AxBurst),
			m_AxID(AxID),
			m_AxCache(AxCache),
			m_AxLock(AxLock),
			m_AxQoS(AxQoS),
			m_AxRegion(AxRegion),
			m_AxUser(AxUser),
			m_is_write(is_write),
			m_version(version)
		{}

		uint64_t GetAxAddr() { return m_AxAddr; }
		inline bool GetB() { return m_AxCache & 0x1; }
		inline bool GetC() { return (m_AxCache >> 1) & 0x1; }
		inline bool GetE() { return m_AxLock == AXI_LOCK_EXCLUSIVE; }
		inline bool GetL() { return m_AxLock == AXI_LOCK_LOCKED; }
		inline uint8_t GetQoS() { return m_AxQoS; }
		inline uint8_t GetRegion() { return m_AxRegion; }
		inline uint32_t GetUser() { return m_AxUser; }
		inline bool isWrite() { return m_is_write; }

		void print()
		{
			std::ostringstream msg;
			std::string ax;

			msg << "[" << sc_time_stamp() << "]: ";

			ax = (m_is_write ? "aw" : "ar");

			msg << (m_is_write ? "write addr ch: { " : "read addr ch: { ");
			msg << ax << "id: 0x" << std::hex << m_AxID << ", ";
			msg << ax << "addr: 0x" << std::hex << m_AxAddr << ", ";
			msg << ax << "len: 0x" << std::hex << m_AxLen << ", ";
			msg << ax << "size: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxSize) << ", ";
			msg << ax << "burst: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxBurst) << ", ";
			msg << ax << "cache: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxCache) << ", ";
			msg << ax << "lock: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxLock) << ", ";

			if (m_version == V_AXI4) {
				msg << ax << "qos: 0x" << std::hex
					<< static_cast<uint32_t>(m_AxQoS) << ", ";
				msg << ax << "region: 0x" << std::hex
					<< static_cast<uint32_t>(m_AxRegion) << ", ";
				msg << ax << "user: 0x" << std::hex << m_AxUser;
			}
			msg << " }";

			SC_REPORT_INFO(TX_TRACE_INFO, msg.str().c_str());
		}

	private:
		uint64_t m_AxAddr;
		uint32_t m_AxLen;
		uint8_t  m_AxSize;
		uint8_t  m_AxBurst;
		uint32_t m_AxID;
		uint8_t  m_AxCache;
		uint8_t  m_AxLock;
		uint8_t  m_AxQoS;
		uint8_t  m_AxRegion;
		uint32_t m_AxUser;

		bool m_is_write;
		AXIVersion m_version;
	};

	Transaction SampleAR()
	{
		return Transaction(araddr.read().to_uint64(),
					to_uint(arlen),
					to_uint(arsize),
					to_uint(arburst),
					to_uint(arid),
					to_uint(arcache),
					to_uint(arlock),
					to_uint(arqos),
					to_uint(arregion),
					to_uint(aruser),
					false,
					m_version);
	}

	Transaction SampleAW()
	{
		return Transaction(awaddr.read().to_uint64(),
					to_uint(awlen),
					to_uint(awsize),
					to_uint(awburst),
					to_uint(awid),
					to_uint(awcache),
					to_uint(awlock),
					to_uint(awqos),
					to_uint(awregion),
					to_uint(awuser),
					true,
					m_version);
	}

	inline bool check_addresses(Transaction& tr)
	{
		if (m_print_addr) {
			std::vector<uint64_t>::iterator it = m_addr.begin();

			// Check if addr
			for (;it != m_addr.end(); it++) {
				if (tr.GetAxAddr() == (*it)) {
					return true;
				}
			}
		}
		return false;
	}

	inline bool check_min_max_addr(Transaction& tr)
	{
		if (m_print_min_max_addr) {
			return tr.GetAxAddr() >= m_min_addr &&
				tr.GetAxAddr() <= m_max_addr;
		}
		return false;
	}

	void print_ax_ch(Transaction& tr)
	{
		bool print_ax = tr.isWrite() ? m_print_aw : m_print_ar;

		if (m_print_all || print_ax || check_addresses(tr) ||
			check_min_max_addr(tr)) {
			tr.print();
		}
	}

	void print_rr_ch()
	{
		std::ostringstream msg;

		msg << "[" << sc_time_stamp() << "]: ";

		msg << "read resp ch: { ";

		msg << "rid: 0x" << std::hex << to_uint(rid) << ", ";
		msg << "rvalid: 0x" << std::hex << to_uint(rvalid) << ", ";
		msg << "rready: 0x" << std::hex << to_uint(rready) << ", ";
		msg << "rresp: 0x" << std::hex << to_uint(rresp) << ", ";
		msg << "rlast: 0x" << std::hex << to_uint(rlast) << ", ";

		if (m_version == V_AXI4) {
			msg << "ruser: 0x" << std::hex << to_uint(ruser) << ", ";
		}

		msg << "rdata: { ";
		for (int i = 0; i < DATA_WIDTH; i+=8) {
			unsigned firstbit = i;
			unsigned lastbit = firstbit + (8 - 1);
			uint8_t d;

			d = rdata.read().range(lastbit, firstbit).to_uint();

			if (i) {
				msg << ", ";
			}
			msg << "0x" << std::hex << static_cast<uint32_t>(d);
		}
		msg << " } }";

		SC_REPORT_INFO(TX_TRACE_INFO, msg.str().c_str());
	}

	void print_w_ch()
	{
		std::ostringstream msg;

		msg << "[" << sc_time_stamp() << "]: ";

		msg << "write data ch: { ";

		if (m_version == V_AXI3) {
			msg << "wid: 0x" << std::hex << to_uint(wid) << ", ";
		}
		msg << "wvalid: 0x" << std::hex << to_uint(wvalid) << ", ";
		msg << "wready: 0x" << std::hex << to_uint(wready) << ", ";
		msg << "wlast: 0x" << std::hex << to_uint(wlast) << ", ";

		if (m_version == V_AXI4) {
			msg << "wuser: 0x" << std::hex << to_uint(wuser) << ", ";
		}

		msg << "wdata: { ";
		for (int i = 0; i < DATA_WIDTH; i+=8) {
			unsigned firstbit = i;
			unsigned lastbit = firstbit + (8 - 1);
			uint8_t d;

			d = wdata.read().range(lastbit, firstbit).to_uint();

			if (i) {
				msg << ", ";
			}
			msg << "0x" << std::hex << static_cast<uint32_t>(d);
		}
		msg << " }, wstrb: " << std::dec << wstrb << " }";

		SC_REPORT_INFO(TX_TRACE_INFO, msg.str().c_str());
	}

	void print_b_ch()
	{
		std::ostringstream msg;

		msg << "[" << sc_time_stamp() << "]: ";

		msg << "write resp ch: { ";

		msg << "bid: 0x" << std::hex << to_uint(bid) << ", ";
		msg << "bvalid: 0x" << std::hex << to_uint(bvalid) << ", ";
		msg << "bready: 0x" << std::hex << to_uint(bready) << ", ";
		msg << "bresp: 0x" << std::hex << to_uint(bresp);

		if (m_version == V_AXI4) {
			msg << ", buser: 0x" << std::hex << to_uint(buser);
		}
		msg << " }";

		SC_REPORT_INFO(TX_TRACE_INFO, msg.str().c_str());
	}

	void trace()
	{
		while (true) {
			wait(clk.posedge_event());

			if (arvalid.read() && arready.read()) {
				Transaction tr = SampleAR();

				print_ax_ch(tr);
			}

			if (rvalid.read() && rready.read()) {
				if (m_print_all || m_print_rr) {
					print_rr_ch();
				}
			}

			if (awvalid.read() && awready.read()) {
				Transaction tr = SampleAW();

				print_ax_ch(tr);
			}

			if (wvalid.read() && wready.read()) {
				if (m_print_all || m_print_w) {
					print_w_ch();
				}
			}

			if (bvalid.read() && bready.read()) {
				if (m_print_all || m_print_b) {
					print_b_ch();
				}
			}
		}
	}

	axi_dummy dummy;

	bool m_print_all;
	bool m_print_addr;
	bool m_print_min_max_addr;
	bool m_print_ar;
	bool m_print_rr;
	bool m_print_aw;
	bool m_print_w;
	bool m_print_b;

	std::vector<uint64_t> m_addr;
	uint64_t m_min_addr;
	uint64_t m_max_addr;

	AXIVersion m_version;
};

#endif /* TRACE_AXI_H__ */

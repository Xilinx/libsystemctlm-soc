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

#ifndef TRACE_AXILITE_H__
#define TRACE_AXILITE_H__

#define TX_TRACE_INFO "trace"

template
<int ADDR_WIDTH, int DATA_WIDTH>
class trace_axilite : public sc_core::sc_module
{
public:
	sc_in<bool > clk;
	sc_in<bool > resetn;

	/* Write address channel.  */
	sc_in<bool > awvalid;
	sc_in<bool > awready;
	sc_in<sc_bv<ADDR_WIDTH> > awaddr;
	sc_in<sc_bv<3> > awprot;

	/* Write data channel.  */
	sc_in<bool > wvalid;
	sc_in<bool > wready;
	sc_in<sc_bv<DATA_WIDTH> > wdata;
	sc_in<sc_bv<DATA_WIDTH/8> > wstrb;

	/* Write response channel.  */
	sc_in<bool > bvalid;
	sc_in<bool > bready;
	sc_in<sc_bv<2> > bresp;

	/* Read address channel.  */
	sc_in<bool > arvalid;
	sc_in<bool > arready;
	sc_in<sc_bv<ADDR_WIDTH> > araddr;
	sc_in<sc_bv<3> > arprot;

	/* Read data channel.  */
	sc_in<bool > rvalid;
	sc_in<bool > rready;
	sc_in<sc_bv<DATA_WIDTH> > rdata;
	sc_in<sc_bv<2> > rresp;

	SC_HAS_PROCESS(trace_axilite);
	trace_axilite(sc_core::sc_module_name name) :
		sc_module(name),

		clk("clk"),
		resetn("resetn"),

		awvalid("awvalid"),
		awready("awready"),
		awaddr("awaddr"),
		awprot("awprot"),

		wvalid("wvalid"),
		wready("wready"),
		wdata("wdata"),
		wstrb("wstrb"),

		bvalid("bvalid"),
		bready("bready"),
		bresp("bresp"),

		arvalid("arvalid"),
		arready("arready"),
		araddr("araddr"),
		arprot("arprot"),

		rvalid("rvalid"),
		rready("rready"),
		rdata("rdata"),
		rresp("rresp"),

		m_print_all(false),
		m_print_addr(false),
		m_print_min_max_addr(false),
		m_print_ar(false),
		m_print_rr(false),
		m_print_aw(false),
		m_print_w(false),
		m_print_b(false)
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
	class Transaction
	{
	public:
		Transaction(uint64_t AxAddr, uint8_t  AxProt, bool is_write) :
			m_AxAddr(AxAddr),
			m_AxProt(AxProt),
			m_is_write(is_write)
		{}

		uint64_t GetAxAddr() { return m_AxAddr; }
		inline bool isWrite() { return m_is_write; }

		void print()
		{
			std::ostringstream msg;
			std::string ax;

			msg << "[" << sc_time_stamp() << "]: ";

			ax = (m_is_write ? "aw" : "ar");

			msg << (m_is_write ? "write addr ch: { " : "read addr ch: { ");
			msg << ax << "addr: 0x" << std::hex << m_AxAddr << ", ";
			msg << ax << "prot: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxProt) << ", ";
			msg << " }";

			SC_REPORT_INFO(TX_TRACE_INFO, msg.str().c_str());
		}

	private:
		uint64_t m_AxAddr;
		uint8_t m_AxProt;

		bool m_is_write;
	};

	Transaction SampleAR()
	{
		return Transaction(araddr.read().to_uint64(),
					to_uint(arprot),
					false);
	}

	Transaction SampleAW()
	{
		return Transaction(awaddr.read().to_uint64(),
					to_uint(awprot),
					true);
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

		msg << "rvalid: 0x" << std::hex << to_uint(rvalid) << ", ";
		msg << "rready: 0x" << std::hex << to_uint(rready) << ", ";
		msg << "rresp: 0x" << std::hex << to_uint(rresp) << ", ";

		msg << "rdata: { ";
		for (int i = (DATA_WIDTH-8); i >= 0; i-=8) {
			unsigned firstbit = i;
			unsigned lastbit = firstbit + (8 - 1);
			uint8_t d;

			d = rdata.read().range(lastbit, firstbit).to_uint();

			if (i <(DATA_WIDTH-8)) {
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

		msg << "wvalid: 0x" << std::hex << to_uint(wvalid) << ", ";
		msg << "wready: 0x" << std::hex << to_uint(wready) << ", ";

		msg << "wdata: { ";
		for (int i = (DATA_WIDTH-8); i >= 0; i-=8) {
			unsigned firstbit = i;
			unsigned lastbit = firstbit + (8 - 1);
			uint8_t d;

			d = wdata.read().range(lastbit, firstbit).to_uint();

			if (i <(DATA_WIDTH-8)) {
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

		msg << "bvalid: 0x" << std::hex << to_uint(bvalid) << ", ";
		msg << "bready: 0x" << std::hex << to_uint(bready) << ", ";
		msg << "bresp: 0x" << std::hex << to_uint(bresp);

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
};

#endif /* TRACE_AXILITE_H__ */

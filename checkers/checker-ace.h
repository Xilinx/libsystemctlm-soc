/*
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
 *
 *
 * References:
 *
 * [1] AMBA AXI and ACE Protocol Specification, ARM IHI 0022D, ID102711
 *
 */

#ifndef CHECKER_ACE_H__
#define CHECKER_ACE_H__

#include "checker-utils.h"
#include <list>
#include <sstream>
#include <vector>
#include "tlm-bridges/amba.h"

#define RD_TX_ERROR "rd_tx"
#define WR_TX_ERROR "wr_tx"
#define ACE_HANDSHAKE_ERROR "ace_handshakes"
#define AC_CH_ERROR "ac_channel"
#define CR_CH_ERROR "cr_channel"
#define CD_CH_ERROR "cd_channel"
#define BARRIER_ERROR "ace_barrier"
#define CD_DATA_ERROR "cd_data"

using namespace AMBA::ACE;

ACE_CHECKER(checker_ace_stable)
{
public:
	ACE_CHECKER_CTOR(checker_ace_stable)
	{
		SC_THREAD(monitor_archannel_stable);
		SC_THREAD(monitor_awchannel_stable);

		if (m_pc.GetACEMode() == ACE_MODE_ACE) {
			SC_THREAD(monitor_acchannel_stable);
			SC_THREAD(monitor_crchannel_stable);
			SC_THREAD(monitor_cdchannel_stable);
		}
	}

private:
#define SAMPLE_SIGNAL(d, s) s = d.s
#define SAMPLE_ACE_SIGNAL(d, s) s = d.s

	class sample_awchannel {
	public:
		sc_bv<3> awsnoop;
		sc_bv<2> awdomain;
		sc_bv<2> awbar;

		bool cmp_eq_stable_valid_cycle_signals(const sample_awchannel& rhs) {
			bool eq = true;

			eq &= awsnoop == rhs.awsnoop;
			eq &= awdomain == rhs.awdomain;
			eq &= awbar == rhs.awbar;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_SIGNAL(dev, awsnoop);
			SAMPLE_SIGNAL(dev, awdomain);
			SAMPLE_SIGNAL(dev, awbar);
		}

		const char *get_name(void) { return "awchannel"; }
	};

	class sample_archannel {
	public:
		sc_bv<4> arsnoop;
		sc_bv<2> ardomain;
		sc_bv<2> arbar;

		bool cmp_eq_stable_valid_cycle_signals(const sample_archannel& rhs) {
			bool eq = true;

			eq &= arsnoop == rhs.arsnoop;
			eq &= ardomain == rhs.ardomain;
			eq &= arbar == rhs.arbar;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_SIGNAL(dev, arsnoop);
			SAMPLE_SIGNAL(dev, ardomain);
			SAMPLE_SIGNAL(dev, arbar);
		}

		const char *get_name(void) { return "archannel"; }
	};

	class sample_acchannel {
	public:
		bool acvalid;
		sc_bv<T::ADDR_W> acaddr;
		sc_bv<4> acsnoop;
		sc_bv<3> acprot;

		bool cmp_eq_stable_valid_cycle_signals(const sample_acchannel& rhs) {
			bool eq = true;

			eq &= acvalid == rhs.acvalid;
			eq &= acaddr == rhs.acaddr;
			eq &= acsnoop == rhs.acsnoop;
			eq &= acprot == rhs.acprot;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_ACE_SIGNAL(dev, acvalid);
			SAMPLE_ACE_SIGNAL(dev, acaddr);
			SAMPLE_ACE_SIGNAL(dev, acsnoop);
			SAMPLE_ACE_SIGNAL(dev, acprot);
		}

		const char *get_name(void) { return "acchannel"; }
	};

	class sample_crchannel {
	public:
		bool crvalid;
		sc_bv<5> crresp;

		bool cmp_eq_stable_valid_cycle_signals(const sample_crchannel& rhs) {
			bool eq = true;

			eq &= crvalid == rhs.crvalid;
			eq &= crresp == rhs.crresp;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_ACE_SIGNAL(dev, crvalid);
			SAMPLE_ACE_SIGNAL(dev, crresp);
		}

		const char *get_name(void) { return "crchannel"; }
	};

	class sample_cdchannel {
	public:
		bool cdvalid;
		sc_bv<T::CD_DATA_W> cddata;
		bool cdlast;

		bool cmp_eq_stable_valid_cycle_signals(const sample_cdchannel& rhs) {
			bool eq = true;

			eq &= cdvalid == rhs.cdvalid;
			eq &= cddata == rhs.cddata;
			eq &= cdlast == rhs.cdlast;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_ACE_SIGNAL(dev, cdvalid);
			SAMPLE_ACE_SIGNAL(dev, cddata);
			SAMPLE_ACE_SIGNAL(dev, cdlast);
		}

		const char *get_name(void) { return "cdchannel"; }
	};

	GEN_STABLE_MON(aw)
	GEN_STABLE_MON(ar)

#define GEN_STABLE_MON_ACE(ch)							\
	void monitor_ ## ch ## channel_stable(void) {				\
		monitor_xchannel_stable<sample_ ## ch ##channel> mon(this);	\
		mon.run(m_pc, m_pc.ch ## valid, m_pc.ch ## ready);	\
	}

	GEN_STABLE_MON_ACE(ac)
	GEN_STABLE_MON_ACE(cr)
	GEN_STABLE_MON_ACE(cd)
};

ACE_CHECKER(checker_ace_reset)
{
public:
	ACE_CHECKER_CTOR(checker_ace_reset)
	{
		if (m_cfg.en_reset_check() &&
			m_pc.GetACEMode() == ACE_MODE_ACE) {
			SC_THREAD(ace_reset_check);
		}
	}

private:
	void check_signal(sc_in<bool>& sig)
	{
		if (sig.read() != false) {
			std::ostringstream msg;

			msg << sig.name() <<
				" asserted after at reset release!";

			SC_REPORT_ERROR(AXI_RESET_ERROR, msg.str().c_str());
		}
	}

	void ace_reset_check()
	{
		while (true) {

			sc_core::wait(resetn.negedge_event());

			wait_for_reset_release();

			check_signal(rack);
			check_signal(wack);

			check_signal(acvalid);
			check_signal(crvalid);
			check_signal(cdvalid);
		}
	}
};


ACE_CHECKER(checker_ace_handshakes)
{
public:
	ACE_CHECKER_CTOR(checker_ace_handshakes)
	{
		if (m_cfg.en_handshakes_check()) {
			SC_THREAD(axi_handshakes_check);

			if (m_pc.GetACEMode() == ACE_MODE_ACE) {
				SC_THREAD(ace_handshakes_check);
				SC_THREAD(rack_wack_check);
			}
		}
	}

private:
	typedef axi_handshakes_checker::HandshakeMonitor HandshakeMonitor;

	template<typename PC>
	class IAxLen :
		public ace_helpers
	{
	public:
		IAxLen(PC& pc) :
			m_pc(pc)
		{}

		bool hasData()
		{
			bool is_evict = IsEvict(to_uint(m_pc.awdomain),
						to_uint(m_pc.awsnoop));
			bool is_barrier = to_uint(m_pc.awbar) > 0;

			if (is_barrier || is_evict) {
				return false;
			}

			return true;
		}

		uint32_t get_arlen()
		{
			if (HasSingleRdDataTransfer(to_uint(m_pc.ardomain),
						to_uint(m_pc.arsnoop),
						to_uint(m_pc.arbar))) {
				return 0;
			}
			return to_uint(m_pc.arlen);
		}
		uint32_t get_awlen() { return to_uint(m_pc.awlen); }
		bool get_wlast() { return m_pc.wlast.read(); }

		uint32_t get_awid() { return to_uint(m_pc.awid); }
		uint32_t get_wid() { return to_uint(m_pc.wid); }
		uint32_t get_bid() { return to_uint(m_pc.bid); }

		bool is_axi3() { return false; }
		bool is_axi4lite() { return false; }
	private:
		PC& m_pc;
	};

	void axi_handshakes_check()
	{
		axi_handshakes_checker checker(this);
		IAxLen<typename T::PCType> axlen(m_pc);

		checker.run(m_pc, m_cfg, axlen);
	}

	enum { DataTransfer = 0x1 };

	//
	// Returns the number of handshakes required for transmitting a
	// cacheline on the cd channel.
	//
	uint32_t get_cd_handshakes_per_line()
	{
		uint32_t line_sz = m_cfg.get_cacheline_sz();
		uint32_t cd_data_bus_width_bytes = T::CD_DATA_W / 8;

		return line_sz / cd_data_bus_width_bytes;
	}

	template<typename T_SIG>
	bool has_datatransfer(T_SIG& crresp)
	{
		return (to_uint(crresp) & DataTransfer) == DataTransfer;
	}

	void ace_handshakes_check()
	{
		uint64_t max_clks = m_cfg.get_max_clks();

		HandshakeMonitor ac_channel("ac", acvalid,
						acready, max_clks);

		HandshakeMonitor cr_channel("cr", crvalid,
						crready, max_clks);

		HandshakeMonitor cd_channel("cd", cdvalid,
						cdready, max_clks);

		uint32_t cd_handshakes_per_line = get_cd_handshakes_per_line();
		uint32_t m_cr = 0;
		uint32_t m_cd = 0;

		while (true) {
			bool inc_crvalid = m_cr > 0;
			bool inc_cdvalid = m_cd > 0;

			sc_core::wait(clk.posedge_event() | resetn.negedge_event());
			if (reset_asserted()) {
				ac_channel.restart();
				cr_channel.restart();
				cd_channel.restart();
				m_cr = 0;
				m_cd = 0;

				wait_for_reset_release();
				continue;
			}

			if (ac_channel.run()) {
				//
				// Got ac handshake expect a cr now.
				//
				m_cr++;
			}
			if (cr_channel.run(inc_crvalid)) {
				//
				// Got cr expect the cd handshakes if
				// transfering data.
				//
				m_cr--;

				if (has_datatransfer(crresp)) {
					//
					// Add the number of handeshakes
					// required for a cacheline
					//
					m_cd += cd_handshakes_per_line;
				}
			}
			if (cd_channel.run(inc_cdvalid)) {
				m_cd--;
			}
		}
	}

	class AckCheck
	{
	public:
		AckCheck(sc_in<bool >& valid,
				sc_in<bool >& ready,
				sc_in<bool >& last,
				sc_in<bool >& ack,
				uint64_t max_clks) :
			m_valid(valid),
			m_ready(ready),
			m_last(last),
			m_ack(ack),
			m_expect_ack(0),
			m_ack_wait(0),
			m_max_clks(max_clks)
		{}

		AckCheck(sc_in<bool >& valid,
				sc_in<bool >& ready,
				sc_in<bool >& ack,
				uint64_t max_clks) :
			m_valid(valid),
			m_ready(ready),
			m_last(valid), // For wack double 'valid' role
			m_ack(ack),
			m_expect_ack(0),
			m_ack_wait(0),
			m_max_clks(max_clks)
		{}

		void restart()
		{
			m_expect_ack = 0;
			m_ack_wait = 0;
		}

		void run()
		{
			// Store if ack can be set this clock cycle
			bool expecting_ack = m_expect_ack > 0;

			if (expect_new_ack()) {
				m_expect_ack++;
			}

			if (m_ack.read() && !expecting_ack) {
				//
				// Got one ack when not waiting for one
				//
				std::ostringstream msg;

				msg << m_ack.name() <<
					" asserted but not expected!";

				SC_REPORT_ERROR(ACE_HANDSHAKE_ERROR,
						msg.str().c_str());

			} else if (m_ack.read()) {
				//
				// Got one ack, restart the wait
				//
				m_expect_ack--;
				m_ack_wait = 0;
			} else if (expecting_ack) {
				//
				// Expecting ack, inc ack wait
				//
				inc_ack_w();
			}
		}

		void inc_ack_w()
		{
			m_ack_wait++;
			if (m_ack_wait == m_max_clks) {
				std::ostringstream msg;

				msg << m_ack.name() << " not asserted after"
					<< m_last.name() << "!";

				SC_REPORT_ERROR(ACE_HANDSHAKE_ERROR,
						msg.str().c_str());
			}
		}

	private:
		bool expect_new_ack()
		{
			return m_valid.read() &&
				m_ready.read() &&
				m_last.read();
		}

		sc_in<bool >& m_valid;
		sc_in<bool >& m_ready;
		sc_in<bool >& m_last;
		sc_in<bool >& m_ack;

		uint32_t m_expect_ack;
		uint32_t m_ack_wait;

		uint64_t m_max_clks;
	};

	void rack_wack_check()
	{
		uint64_t max_clks = m_cfg.get_max_clks();

		AckCheck check_rack(rvalid, rready,
					rlast, rack, max_clks);

		AckCheck check_wack(bvalid, bready, wack, max_clks);

		while (true) {
			sc_core::wait(clk.posedge_event() | resetn.negedge_event());
			if (reset_asserted()) {
				check_rack.restart();
				check_wack.restart();
				wait_for_reset_release();
				continue;
			}

			check_rack.run();
			check_wack.run();
		}
	}
};

ACE_CHECKER(checker_ace_rd_tx)
{
public:
	ACE_CHECKER_CTOR(checker_ace_rd_tx)
	{
		if(enabled()) {
			SC_THREAD(rd_check);
		}
	}

	~checker_ace_rd_tx()
	{
		ClearList(m_rtList);
	}

private:
	bool enabled()
	{
		return m_cfg.en_rd_tx_check() || m_cfg.en_resp_check();
	}

	class Transaction :
		public ace_helpers
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
				uint8_t AxSnoop,
				uint8_t AxDomain,
				uint8_t AxBar) :
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

			m_AxSnoop(AxSnoop),
			m_AxDomain(AxDomain),
			m_AxBar(AxBar),

			m_rresp(0),

			m_numBeats(AxLen + 1)
		{}

		uint32_t GetID() { return m_AxID; }
		inline bool GetExclusive()
		{
			return m_AxLock == AXI_LOCK_EXCLUSIVE;
		}

		void DecNumBeats() { m_numBeats--; }
		bool Done()
		{
			if (HasSingleRdDataTransfer()) {
				assert((unsigned int) m_numBeats ==
					(m_AxLen + 1));
				return true;
			}

			return m_numBeats == 0;
		}

		void ReportError(std::ostringstream& msg)
		{
			msg << " on tx: { ";

			msg << "arid: 0x" << std::hex << m_AxID << ", ";
			msg << "araddr: 0x" << std::hex << m_AxAddr << ", ";
			msg << "arlen: 0x" << std::hex << m_AxLen << ", ";
			msg << "arsize: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxSize) << ", ";
			msg << "arburst: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxBurst) << ", ";
			msg << "arcache: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxCache) << ", ";
			msg << "arlock: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxLock);
			msg << ", arqos: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxQoS) << ", ";
			msg << "arregion: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxRegion) << ", ";
			msg << "aruser: 0x" << std::hex << m_AxUser;

			msg << ", arsnoop: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxSnoop);
			msg << ", ardomain: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxDomain);
			msg << ", arbar: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxBar);

			msg << " }";

			SC_REPORT_ERROR(RD_TX_ERROR, msg.str().c_str());
		}

		bool IsBarrier() { return m_AxBar > 0; }

		bool CheckARSnoop(unsigned int ace_mode)
		{
			//
			// Validate according table C3-7 [1]
			//

			// Barrier tx
			if (m_AxBar) {
				// Only allowed snoop on barrier
				return m_AxSnoop == 0;
			}

			if (m_AxSnoop == AR::ReadNoSnoop &&
				(m_AxDomain == Domain::NonSharable ||
				m_AxDomain == Domain::System)) {
				return true;
			}

			switch(m_AxSnoop) {
			case AR::DVMComplete:
			case AR::DVMMessage:
			case AR::ReadShared:
			case AR::ReadClean:
			case AR::ReadNotSharedDirty:
			case AR::ReadUnique:
			case AR::CleanUnique:
			case AR::MakeUnique:
				//
				// Not allowed on ACELite (section C11.2 1])
				//
				if (ace_mode != ACE_MODE_ACE) {
					return false;
				}
			case AR::ReadOnce:
				if (m_AxDomain == Domain::Inner ||
					m_AxDomain == Domain::Outer) {
					return true;
				}
				// Return false
				break;
			case AR::CleanShared:
			case AR::CleanInvalid:
			case AR::MakeInvalid:
				if (m_AxDomain == Domain::NonSharable ||
					m_AxDomain == Domain::Inner ||
					m_AxDomain == Domain::Outer) {
					return true;
				}
				// Return false
				break;
			default:
				break;
			};

			return false;
		}

		bool CheckARCache()
		{
			// C3-3 [1]
			if (!is_modifiable() &&
				m_AxDomain != Domain::System) {
				return false;
			}

			if (m_AxDomain == Domain::System &&
				is_cacheable()) {
				return false;
			}
			return true;
		}

		bool CheckBurstAddr(std::ostringstream& msg,
					uint64_t line_sz)
		{
			//
			// C3.1.5 [1]
			//
			if (is_cacheline_sized_tx()) {
				uint32_t bus_width = T::DATA_W / 8;
				uint32_t numberBytes = 1 << m_AxSize;

				if (numberBytes != bus_width) {
					msg << "arsize does not "
						<< "match data bus width";
					return false;
				}

				if (line_sz != (numberBytes * m_numBeats)) {
					msg << "arsize, arlen does not "
						<< "match the cacheline size";
					return false;
				}

				// Must be normal
				if (m_AxBar) {
					msg << "arbar is not 'normal'";
					return false;
				}

				// Must be normal
				if (!is_modifiable()) {
					msg << "arcache is not 'modifiable'";
					return false;
				}

				if (m_AxBurst == AXI_BURST_INCR) {
					if (m_AxAddr != align(m_AxAddr, line_sz)) {
						msg << "arburst INCR but " <<
							"address is not " <<
							"cacheline size aligned'";
						return false;
					}
				} else if (m_AxBurst == AXI_BURST_WRAP) {
					if (m_AxAddr != align(m_AxAddr, bus_width)) {
						msg << "arburst WRAP but " <<
							"address is not " <<
							"data bus width aligned'";
						return false;
					}
				} else if (m_AxBurst == AXI_BURST_FIXED) {
					msg << "arburst FIXED error";
					return false;
				}
			}

			return true;
		}

		bool AllowsExclusive()
		{
			// C3.2.1
			switch(m_AxSnoop) {
			case AR::ReadNoSnoop:
			case AR::ReadClean:
			case AR::ReadShared:
			case AR::CleanUnique:
				return true;
			default:
				break;
			};
			return false;
		}

		bool AllowsIsShared()
		{
			// C3.2.1
			switch(m_AxSnoop) {
			case AR::ReadNoSnoop:
			case AR::ReadUnique:
			case AR::CleanUnique:
			case AR::CleanInvalid:
			case AR::MakeUnique:
			case AR::MakeInvalid:
				return false;
			default:
				break;
			};
			return true;
		}

		bool AllowsPassDirty()
		{
			//
			// C3.2.1
			//
			// If m_AxSnoop is 0 it is either ReadNoSnoop or
			// ReadOnce (domain is checked in check_arsignals).
			//
			return ace_helpers::AllowPassDirty(m_AxDomain,
								m_AxSnoop);
		}

		bool IsReadNotSharedDirty()
		{
			// C3.2.1
			if (m_AxDomain == Domain::Inner ||
				m_AxDomain == Domain::Outer) {
				return m_AxSnoop == AR::ReadNotSharedDirty;
			}
			return false;
		}

		bool IsDVM()
		{
			return ace_helpers::IsDVM(m_AxDomain, m_AxSnoop);
		}

		void SetRresp(uint8_t rresp) { m_rresp = rresp; }
		uint8_t GetRresp() { return m_rresp; }

		bool CheckRresp(uint8_t rresp)
		{
			uint8_t passdirty_isshared_old = m_rresp & 0xc;
			uint8_t passdirty_isshared = rresp & 0xc;

			//
			// C3.2.1, pass dirty and is shared must be constant on
			// all data transactions
			//
			return passdirty_isshared == passdirty_isshared_old;
		}

		bool IsFirstBeat()
		{
			return (unsigned int)m_numBeats == (m_AxLen + 1);
		}

		bool HasSingleRdDataTransfer()
		{
			// C3.2.1
			//
			// Transactions with a single data transfer
			//
			return ace_helpers::HasSingleRdDataTransfer(m_AxDomain,
								m_AxSnoop,
								m_AxBar);
		}

		bool CheckBarrierSignals(std::ostringstream& msg)
		{
			if (m_AxAddr != 0) {
				msg << "Read barrier error: araddr != 0x0";
				return false;
			}
			if (m_AxLen != 0) {
				msg << "Read barrier error: arlen != 0x0";
				return false;
			}
			if (m_AxBurst != AXI_BURST_INCR) {
				msg << "Read barrier error: arburst != INCR";
				return false;
			}
			if (m_AxSnoop != 0) {
				msg << "Read barrier error: arsnoop != 0x0";
				return false;
			}
			if (m_AxCache != 2) {
				msg << "Read barrier error: arcache != 0x2";
				return false;
			}
			if (m_AxLock != 0) {
				msg << "Read barrier error: arlock != 0x0";
				return false;
			}
			return true;
		}

		//
		// From section C12.6 [1]
		//
		bool CheckDVMSignals(std::ostringstream& msg)
		{
			uint32_t bus_width = T::DATA_W / 8;
			uint32_t numberBytes = 1 << m_AxSize;

			if (m_AxSnoop == AR::DVMComplete && m_AxAddr != 0) {
				msg << "DVM error: araddr != 0x0";
				return false;
			}
			if (m_AxLen != 0) {
				msg << "DVM error: arlen != 0x0";
				return false;
			}
			if (numberBytes != bus_width) {
				msg << "DVM error: arsize does not "
					<< "match data bus width";
				return false;
			}
			if (m_AxBurst != AXI_BURST_INCR) {
				msg << "DVM error: arburst != INCR";
				return false;
			}
			if (m_AxCache != 2) {
				msg << "DVM error: arcache != 0x2";
				return false;
			}
			if (m_AxLock != 0) {
				msg << "DVM error: arlock != 0x0";
				return false;
			}
			return true;
		}

		bool IsDVMSync()
		{
			if (m_AxSnoop == AR::DVMMessage) {
				return IsDVMSyncCmd(m_AxAddr);
			}
			return false;
		}

		bool IsDVMHint()
		{
			if (m_AxSnoop == AR::DVMMessage) {
				return IsDVMHintCmd(m_AxAddr);
			}
			return false;
		}

		bool IsDVMComplete()
		{
			return m_AxSnoop == AR::DVMComplete;
		}

	private:
		bool is_cacheline_sized_tx()
		{
			if (m_AxBar) {
				return false;
			}

			switch(m_AxSnoop) {
			case AR::ReadClean:
			case AR::ReadShared:
			case AR::ReadNotSharedDirty:
			case AR::ReadUnique:
			case AR::CleanUnique:
			case AR::MakeUnique:
				if (m_AxDomain == Domain::Inner ||
					m_AxDomain == Domain::Outer) {
					return true;
				}
				// Return false
				break;
			case AR::CleanShared:
			case AR::CleanInvalid:
			case AR::MakeInvalid:
				if (m_AxDomain == Domain::NonSharable ||
					m_AxDomain == Domain::Inner ||
					m_AxDomain == Domain::Outer) {
					return true;
				}
				// Return false
				break;
			default:
				break;
			};

			return false;
		}

		bool is_modifiable() { return IsModifiable(m_AxCache); }

		bool is_cacheable() { return IsCacheable(m_AxCache); }

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

		uint8_t m_AxSnoop;
		uint8_t m_AxDomain;
		uint8_t m_AxBar;

		uint8_t m_rresp;

		int m_numBeats;
	};

	Transaction *GetFirst(uint32_t id)
	{
		for (typename std::list<Transaction*>::iterator it = m_rtList.begin();
			it != m_rtList.end(); it++) {
			Transaction *t = (*it);

			if (t && t->GetID() == id) {
				return t;
			}
		}
		return NULL;
	}

	void ClearList(std::list<Transaction*>& l)
	{
		for (typename std::list<Transaction*>::iterator it = l.begin();
			it != l.end(); it++) {
			Transaction *t = (*it);
			delete t;
		}
		l.clear();
	}

	Transaction *SampleARSignals()
	{
		return new Transaction(araddr.read().to_uint64(),
					to_uint(arlen),
					to_uint(arsize),
					to_uint(arburst),
					to_uint(arid),
					to_uint(arcache),
					to_uint(arlock),
					to_uint(arqos),
					to_uint(arregion),
					to_uint(aruser),
					to_uint(arsnoop),
					to_uint(ardomain),
					to_uint(arbar));
	}

	bool check_rresp(Transaction *tr)
	{
		uint8_t resp = to_uint(rresp) & 0x3;

		if (tr->GetExclusive() && !tr->AllowsExclusive()) {
			return false;
		} else if (tr->GetExclusive()) {
			// Accept AXI_OKAY as non error
			return resp == AXI_EXOKAY || resp == AXI_OKAY;
		}

		return resp == AXI_OKAY;
	}

	void check_ace_resp(Transaction *tr)
	{
		uint8_t resp = to_uint(rresp);
		std::ostringstream msg;

		if (!check_rresp(tr)) {
			msg << "rresp error: rresp is not AXI_OKAY | AXI_EXOKAY"
				<< ", resp: 0x" << hex
				<< static_cast<uint32_t>(resp);
			tr->ReportError(msg);
		}

		if (tr->IsBarrier() && resp)
		{
			msg << "rresp error: read barrier with resp: 0x"
				<< hex << static_cast<uint32_t>(resp);
			tr->ReportError(msg);
		}

		if (tr->IsFirstBeat() && tr->HasSingleRdDataTransfer()
			&& rlast.read() == false) {
			msg << "rresp error: rlast not asserted on single data "
				"transfer transaction, resp: 0x" << hex
				<< static_cast<uint32_t>(resp);

			tr->ReportError(msg);
		}

		if (m_pc.GetACEMode() == ACE_MODE_ACE) {
			bool pass_dirty = tr->ExtractPassDirty(resp);
			bool is_shared = tr->ExtractIsShared(resp);

			if (is_shared && !tr->AllowsIsShared()) {
				msg << "rresp error: IsShared not allowed, resp: 0x"
					<< hex << static_cast<uint32_t>(resp);
				tr->ReportError(msg);
			}

			if (pass_dirty && !tr->AllowsPassDirty()) {
				msg << "rresp error: PassDirty not allowed, resp: 0x"
					<< hex << static_cast<uint32_t>(resp);
				tr->ReportError(msg);
			}

			if (pass_dirty && is_shared && tr->IsReadNotSharedDirty()) {
				msg << "rresp error: IsShared and "
					<< "PassDirty not allowed, resp: 0x"
					<< hex << static_cast<uint32_t>(resp);
				tr->ReportError(msg);
			}

			if (tr->IsDVM())
			{
				if (is_shared || pass_dirty) {
					msg << "rresp error: DVM with IsShared or "
						<< "PassDirty, resp: 0x"
						<< hex << static_cast<uint32_t>(resp);
					tr->ReportError(msg);
				}

				// EXOKAY answer is checked above

				if (resp && tr->IsDVMComplete()) {
					msg << "rresp error: DVM Complete with resp "
						<< "!= 0 resp: 0x"
						<< hex << static_cast<uint32_t>(resp);
					tr->ReportError(msg);
				}
				if (resp && tr->IsDVMSync()) {
					msg << "rresp error: DVM Sync with resp "
						<< "!= 0 resp: 0x"
						<< hex << static_cast<uint32_t>(resp);
					tr->ReportError(msg);
				}
				if (resp && tr->IsDVMHint()) {
					msg << "rresp error: DVM Sync with resp "
						<< "!= 0 resp: 0x"
						<< hex << static_cast<uint32_t>(resp);
					tr->ReportError(msg);
				}
			}

			if (tr->IsFirstBeat()) {
				tr->SetRresp(resp);
			} else if (!tr->CheckRresp(resp)) {
				msg << "rresp error: PassDirty and IsShared must not "
					"change between read data transfers, "
					<< "prev transfer resp: 0x" << hex
					<< static_cast<uint32_t>(tr->GetRresp())
					<< ", resp: 0x" << hex
					<< static_cast<uint32_t>(resp);

				tr->ReportError(msg);
			}
		}
	}

	bool id_in_list(std::list<Transaction*>& l, uint32_t id)
	{
		typename std::list<Transaction*>::iterator it = l.begin();

		for (; it != l.end(); it++) {
			Transaction *t = (*it);
			if (!t->IsBarrier() && t->GetID() == id) {
				//
				// Found barrier transaction
				//
				return true;
			}
		}
		return false;
	}

	bool normal_tx_id_in_list(std::list<Transaction*>& l, uint32_t id)
	{
		typename std::list<Transaction*>::iterator it = l.begin();

		for (; it != l.end(); it++) {
			Transaction *t = (*it);
			if (!t->IsBarrier() && !t->IsDVM()
				&& t->GetID() == id) {
				//
				// Found non barrier non dvm transaction
				//
				return true;
			}
		}
		return false;
	}

	bool barrier_id_in_list(std::list<Transaction*>& l, uint32_t id)
	{
		typename std::list<Transaction*>::iterator it = l.begin();

		for (; it != l.end(); it++) {
			Transaction *t = (*it);
			if (t->IsBarrier() && t->GetID() == id) {
				//
				// Found barrier transaction
				//
				return true;
			}
		}
		return false;
	}

	bool dvm_id_in_list(std::list<Transaction*>& l, uint32_t id)
	{
		typename std::list<Transaction*>::iterator it = l.begin();

		for (; it != l.end(); it++) {
			Transaction *t = (*it);
			if (t->IsDVM() && t->GetID() == id) {
				//
				// Found barrier transaction
				//
				return true;
			}
		}
		return false;
	}

	bool check_ongoing_barrier_ids(Transaction *tr, std::ostringstream& msg)
	{
		if (barrier_id_in_list(m_rtList, tr->GetID())) {

			msg << "arsnoop error: ongoing barrier with the same id"
				" as a ";
			if (tr->IsDVM()) {
				msg << "DVM";
			} else {
				msg << "normal transaction";
			}

			return false;
		}

		return true;
	}

	bool check_ongoing_dvm_ids(Transaction *tr, std::ostringstream& msg)
	{
		if (dvm_id_in_list(m_rtList, tr->GetID())) {

			msg << "arsnoop error: ongoing dvm with the same id"
				" as a ";
			if (tr->IsBarrier()) {
				msg << "barrier";
			} else {
				msg << "normal transaction";
			}

			return false;
		}

		return true;
	}

	bool check_ongoing_normal_tx_ids(Transaction *tr, std::ostringstream& msg)
	{
		if (normal_tx_id_in_list(m_rtList, tr->GetID())) {

			msg << "arsnoop error: normal transaction with the same"
				" id as a ";
			if (tr->IsBarrier()) {
				msg << "barrier";
			} else if (tr->IsDVM()) {
				msg << "DVM";
			}

			return false;
		}

		return true;
	}

	uint32_t get_barrier_count(std::list<Transaction*>& l)
	{
		typename std::list<Transaction*>::iterator it = l.begin();
		uint32_t num_barrier = 0;

		for (; it != l.end(); it++) {
			Transaction *t = (*it);

			if (t->IsBarrier()) {
				num_barrier++;
			}
		}
		return num_barrier;
	}

	bool check_barrier_num_outstanding(std::ostringstream& msg)
	{
		uint32_t num_barrier = get_barrier_count(m_rtList);
		uint32_t max_outstanding = 256;

		if (num_barrier >= max_outstanding) {
			msg << "Read barrier: number of outstanding is > 256";
			return false;
		}
		return true;
	}

	void check_arsignals(Transaction *tr)
	{
		uint64_t line_sz = m_cfg.get_cacheline_sz();
		unsigned int ace_mode = m_pc.GetACEMode();
		std::ostringstream msg;

		if (!tr->CheckARSnoop(ace_mode)) {
			msg << "arsnoop error";
			tr->ReportError(msg);
		}

		if (!tr->CheckARCache()) {
			msg << "arcache <-> ardomain error";
			tr->ReportError(msg);
		}

		if (!tr->CheckBurstAddr(msg, line_sz)) {
			tr->ReportError(msg);
		}

		//
		// C8.4.1 Barrier transaction are required to use different ids
		// than non barrier transactions. Also check barrier arsignals
		// and outstanding count.
		//
		// C12.3.5 DVM transaction are required to use different ids
		// than non dvm transactions.
		//
		if (tr->IsBarrier()) {
			if (!tr->CheckBarrierSignals(msg)) {
				tr->ReportError(msg);
			}

			//
			// ACELite does not have a limit on outstandig barriers
			//
			if (m_pc.GetACEMode() == ACE_MODE_ACE) {
				if (!check_barrier_num_outstanding(msg)) {
					tr->ReportError(msg);
				}
			}

			if (!check_ongoing_normal_tx_ids(tr, msg)) {
				tr->ReportError(msg);
			}

			if (!check_ongoing_dvm_ids(tr, msg)) {
				tr->ReportError(msg);
			}
		} else if (tr->IsDVM()) {
			if (!tr->CheckDVMSignals(msg)) {
				tr->ReportError(msg);
			}

			if (!check_ongoing_normal_tx_ids(tr, msg)) {
				tr->ReportError(msg);
			}

			if (!check_ongoing_barrier_ids(tr, msg)) {
				tr->ReportError(msg);
			}
		} else {
			if (!check_ongoing_barrier_ids(tr, msg)) {
				tr->ReportError(msg);
			}

			if (!check_ongoing_dvm_ids(tr, msg)) {
				tr->ReportError(msg);
			}
		}
	}

	void rd_check(void)
	{
		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());

			if (reset_asserted()) {
				ClearList(m_rtList);
				wait_for_reset_release();
				continue;
			}

			if (arvalid.read() && arready.read()) {
				if (m_rtList.size() < m_cfg.max_depth()) {
					Transaction *tr = SampleARSignals();

					if (m_cfg.en_rd_tx_check()) {
						check_arsignals(tr);
					}

					m_rtList.push_back(tr);
				} else {
					SC_REPORT_ERROR(RD_TX_ERROR,
							"Maximum outstanding "
							"transactions reached");
				}
			}

			if (rvalid.read() && rready.read()) {
				Transaction *rt = GetFirst(to_uint(rid));

				if (rt) {
					if (m_cfg.en_resp_check()) {
						check_ace_resp(rt);
					}

					//
					// Only decrement if it is not an
					// single data transfer transaction
					//
					if (!rt->HasSingleRdDataTransfer()) {
						rt->DecNumBeats();
					}

					//
					// Check rlast
					//
					if (m_cfg.en_rd_tx_check() &&
						rlast.read() != rt->Done()) {

						std::ostringstream msg;

						msg << "Wrongly ordered transaction"
							<< " identified or "
							<< "unexpected burst length";

						rt->ReportError(msg);
					}

					//
					// Transaction done (RACK is checked by
					// the handshake checker)
					//
					if (rlast.read()) {
						m_rtList.remove(rt);
						delete rt;
					}

				} else {
					std::ostringstream msg;

					msg << "Unexpected transaction id "
						<< "on read response channel"
						<< " (id: "
						<< to_uint(rid) << ")";

					SC_REPORT_ERROR(RD_TX_ERROR,
							msg.str().c_str());
				}
			}
		}
	}

	std::list<Transaction*> m_rtList;
};

ACE_CHECKER(checker_ace_wr_tx)
{
public:
	ACE_CHECKER_CTOR(checker_ace_wr_tx)
	{
		if (enabled()) {
			SC_THREAD(wr_check);
		}
	}

	~checker_ace_wr_tx()
	{
		ClearList(m_wtList);
		ClearList(m_respList);
	}
private:
	bool enabled()
	{
		return m_cfg.en_wr_tx_check() ||
			m_cfg.en_wstrb_check() ||
			m_cfg.en_resp_check();
	}

	class Transaction :
		public ace_helpers
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
				uint8_t AxSnoop,
				uint8_t AxDomain,
				uint8_t AxBar) :
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

			m_AxSnoop(AxSnoop),
			m_AxDomain(AxDomain),
			m_AxBar(AxBar),

			m_numberBytes(1 << AxSize),
			m_beat(1),
			m_numBeats(AxLen + 1)
		{}

		uint32_t GetID() { return m_AxID; }

		void IncBeat() { m_beat++; }
		uint32_t GetBeat() { return m_beat; }

		inline bool GetExclusive() { return m_AxLock == AXI_LOCK_EXCLUSIVE; }
		bool Done() { return m_beat > m_numBeats; }

		bool CheckWstrb(sc_in<sc_bv<T::DATA_W/8> >& wstrb,
				bool allow_gaps)
		{
			uint64_t alignedAddress = align(m_AxAddr, m_numberBytes);
			uint32_t data_bus_bytes = wstrb.read().length();
			unsigned int lower_byte_lane;
			unsigned int upper_byte_lane;
			unsigned int i;

			//
			// Equations taken from [1]
			//
			if (m_beat == 1) {
				lower_byte_lane = m_AxAddr -
						align(m_AxAddr, data_bus_bytes);
				upper_byte_lane = alignedAddress +
						(m_numberBytes-1) -
						align(m_AxAddr, data_bus_bytes);
			} else {
				uint64_t addr = alignedAddress;
				if (m_AxBurst != AXI_BURST_FIXED) {
					addr += (m_beat-1) * m_numberBytes;
				}

				lower_byte_lane = addr - align(addr, data_bus_bytes);
				upper_byte_lane = lower_byte_lane +
							(m_numberBytes-1);
			}

			// Verify wstrb zeros upp to the first enabled lane
			for (i = 0; i < lower_byte_lane; i++) {
				if (wstrb.read().bit(i)) {
					return false;
				}
			}

			if (!allow_gaps) {
				//
				// Verify wstrb ones until upper_byte_lane
				// (except in last beat).
				//
				if (m_beat == m_numBeats) {
					//
					// Last beat might not have all lanes
					// up to upper_byte_lane enabled (if
					// the transaction is not filling the
					// transfer size on the last beat), but
					// must have lower_byte_lane enabled.

					//
					// lower_byte_lane lane must always be
					// enabled (else a gap is identified).
					//
					if (!wstrb.read().bit(i++)) {
						return false;
					}

					//
					// Expect wstrb zeros after the first
					// zero is found (by breaking here)
					//
					for (; i <= upper_byte_lane; i++) {
						if (!wstrb.read().bit(i)) {
							break;
						}
					}
				} else {
					//
					// Other beats must have
					// lower_byte_lane to upper_byte_lane
					// enabled
					//
					for (; i <= upper_byte_lane; i++) {
						if (!wstrb.read().bit(i)) {
							return false;
						}
					}
				}
			} else {
				//
				// Only verify zeros after upper_byte_lane
				// (since gaps are allowed)
				//
				i = upper_byte_lane + 1;
			}

			// Verify wstrb zeros til the end of the data bus width
			for (; i < data_bus_bytes; i++) {
				if (wstrb.read().bit(i)) {
					return false;
				}
			}

			return true;
		}

		void ReportError(std::ostringstream& msg)
		{
			msg << " on tx: { ";

			msg << "awid: 0x" << std::hex << m_AxID << ", ";
			msg << "awaddr: 0x" << std::hex << m_AxAddr << ", ";
			msg << "awlen: 0x" << std::hex << m_AxLen << ", ";
			msg << "awsize: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxSize) << ", ";
			msg << "awburst: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxBurst) << ", ";
			msg << "awcache: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxCache) << ", ";
			msg << "awlock: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxLock);

			msg << ", awqos: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxQoS) << ", ";
			msg << "awregion: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxRegion) << ", ";
			msg << "awuser: 0x" << std::hex << m_AxUser;

			msg << ", awsnoop: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxSnoop);
			msg << ", awdomain: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxDomain);
			msg << ", awbar: 0x" << std::hex
				<< static_cast<uint32_t>(m_AxBar);

			msg << " }";

			SC_REPORT_ERROR(WR_TX_ERROR, msg.str().c_str());
		}

		bool IsBarrier() { return m_AxBar > 0; }

		bool CheckAWSnoop(unsigned int ace_mode)
		{
			//
			// Validate according table C3-8 [1]
			//

			// Barrier tx
			if (m_AxBar) {
				// Only allowed snoop on barrier
				return m_AxSnoop == 0;
			}

			if (m_AxSnoop == AW::WriteNoSnoop &&
				(m_AxDomain == Domain::NonSharable ||
				m_AxDomain == Domain::System)) {
				return true;
			}

			switch(m_AxSnoop) {
			case AW::Evict:
				//
				// Not allowed on ACELite (section C11.2 1])
				//
				if (ace_mode != ACE_MODE_ACE) {
					return false;
				}
			case AW::WriteUnique:
			case AW::WriteLineUnique:
				if (m_AxDomain == Domain::Inner ||
					m_AxDomain == Domain::Outer) {
					return true;
				}
				// Return false
				break;

			case AW::WriteClean:
			case AW::WriteBack:
				//
				// Not allowed on ACELite (section C11.2 1])
				//
				if (ace_mode != ACE_MODE_ACE) {
					return false;
				}

				if (m_AxDomain == Domain::NonSharable ||
					m_AxDomain == Domain::Inner ||
					m_AxDomain == Domain::Outer) {
					return true;
				}
				// Return false
				break;
			default:
				break;
			};

			return false;
		}

		bool CheckAWCache()
		{
			// C3-3 [1]
			if (!is_modifiable() &&
				m_AxDomain != Domain::System) {
				return false;
			}

			if (m_AxDomain == Domain::System &&
				is_cacheable()) {
				return false;
			}
			return true;
		}

		bool CheckCachelineSzTx(std::ostringstream& msg,
					uint64_t line_sz)
		{
			//
			// C3.1.5 [1]
			//
			if (is_cacheline_sized_tx()) {
				uint32_t bus_width = T::DATA_W / 8;
				uint32_t numberBytes = 1 << m_AxSize;

				if (numberBytes != bus_width) {
					msg << "awsize does not "
						<< "match data bus width";
					return false;
				}

				if (line_sz != (numberBytes * (m_numBeats))) {
					msg << "awsize, awlen does not "
						<< "match the cacheline size";
					return false;
				}

				// Must be normal
				if (!is_modifiable()) {
					msg << "awcache is not 'modifiable'";
					return false;
				}

				// Must be normal
				if (GetExclusive()) {
					msg << "awlock with 'exclusive' set "
						"on a cacheline sized transaction";
					return false;
				}

				if (m_AxBurst == AXI_BURST_INCR) {
					if (m_AxAddr != align(m_AxAddr, line_sz)) {
						msg << "awburst INCR but " <<
							"address is not " <<
							"cacheline size aligned'";
						return false;
					}
				} else if (m_AxBurst == AXI_BURST_WRAP) {
					if (m_AxAddr != align(m_AxAddr, bus_width)) {
						msg << "awburst WRAP but " <<
							"address is not " <<
							"data bus width aligned'";
						return false;
					}
				} else if (m_AxBurst == AXI_BURST_FIXED) {
					msg << "awburst FIXED error";
					return false;
				}
			}

			return true;
		}

		bool CheckWriteUnique(std::ostringstream& msg)
		{
			//
			// C3.1.5 [1]
			//
			if (IsWriteUnique()) {
				bool burst_ok = m_AxBurst == AXI_BURST_INCR ||
						m_AxBurst == AXI_BURST_WRAP;

				if (!burst_ok) {
					msg << "awburst error";
					return false;
				}

				if (!is_modifiable()) {
					msg << "awcache is not 'modifiable'";
					return false;
				}

				// Must be normal
				if (GetExclusive()) {
					msg << "awlock with 'exclusive' set "
						"on a cacheline sized transaction";
					return false;
				}
			}

			return true;
		}

		bool CheckWriteBackWriteClean(std::ostringstream& msg,
					uint64_t line_sz)
		{
			//
			// C3.1.5 [1]
			//
			if (IsWriteBack() || IsWriteClean()) {
				uint32_t bus_width = T::DATA_W / 8;
				uint32_t numberBytes = 1 << m_AxSize;
				uint32_t tx_len = numberBytes * m_numBeats;

				if (numberBytes != bus_width) {
					msg << "awsize does not "
						<< "match data bus width";
					return false;
				}

				if (tx_len > line_sz) {
					msg << "numberBytes: " << dec << numberBytes
						<< ", m_numBeats: " << m_numBeats
						<< ", line_sz: " << line_sz << " ";
					msg << "awsize, awlen generates a "
						"transaction size > cacheline "
						"size";
					return false;
				}

				if (!is_modifiable()) {
					msg << "awcache is not 'modifiable'";
					return false;
				}

				// Must be normal
				if (GetExclusive()) {
					msg << "awlock with 'exclusive' set "
						"on a cacheline sized transaction";
					return false;
				}

				//
				// Both INC and WRAP below requires axsize
				// aligned address
				//
				if (m_AxBurst &&
					m_AxAddr != align(m_AxAddr, bus_width)) {
					msg << "awburst INC/WRAP but " <<
						"address is not " <<
						"data bus width aligned'";
					return false;
				}

				if (m_AxBurst == AXI_BURST_INCR) {
					uint64_t aligned_start = align(m_AxAddr, line_sz);
					uint64_t aligned_end;

					if (m_numBeats > 16) {
						msg << "awlen in INC is > 16 ";
					}

					// Address of last byte in the transfer
					aligned_end = m_AxAddr + tx_len - 1;

					//
					// Get address of the cacheline
					// containing the last byte
					//
					aligned_end = align(aligned_end, line_sz);

					//
					// return if it is the same address
					// (the same cacheline)
					//
					if ((aligned_end - aligned_start) != 0) {
						msg << "length error: transaction"
							" must be kept inside "
							"one cache line,";
						return false;
					}

				} else if (m_AxBurst == AXI_BURST_WRAP) {
					unsigned int allowed[] = {
						2, 4, 8, 16
					};
					const unsigned int allowed_len =
						sizeof allowed / sizeof allowed[0];
					unsigned int i = 0;

					for (; i < allowed_len; i++) {
						if (allowed[i] == m_AxLen) {
							break;
						}
					}

					if (i == allowed_len) {
						msg << "awlen in WRAP not 2, 4, 8, 16 ";
						return false;
					}

				} else if (m_AxBurst == AXI_BURST_FIXED) {
					msg << "awburst FIXED error";
					return false;
				}
			}

			return true;
		}

		bool IsWriteNoSnoop()
		{
			if (m_AxBar == 0 && m_AxSnoop == AW::WriteNoSnoop &&
				(m_AxDomain == Domain::NonSharable ||
				m_AxDomain == Domain::System)) {
				return true;
			}
			return false;
		}

		bool IsEvict()
		{
			if (m_AxBar == 0 && m_AxSnoop == AW::Evict &&
				(m_AxDomain == Domain::Inner ||
				 m_AxDomain == Domain::Outer)) {
				return true;
			}
			return false;
		}

		bool IsWriteUnique()
		{
			if (m_AxBar == 0) {
				return ace_helpers::IsWriteUnique(m_AxDomain,
								m_AxSnoop);
			}
			return false;
		}

		bool IsWriteBack()
		{
			if (m_AxBar == 0 ) {
				return ace_helpers::IsWriteBack(m_AxDomain,
								m_AxSnoop);
			}
			return false;
		}

		bool IsWriteClean()
		{
			if (m_AxBar == 0) {
				return ace_helpers::IsWriteClean(m_AxDomain,
								m_AxSnoop);
			}
			return false;
		}

		bool IsWriteLineUnique()
		{
			if (m_AxBar == 0) {
				return ace_helpers::IsWriteLineUnique(
								m_AxDomain,
								m_AxSnoop);
			}
			return false;
		}

		bool HasData()
		{
			if (IsBarrier() || IsEvict()) {
				return false;
			}
			return true;
		}

		bool CheckBarrierSignals(std::ostringstream& msg)
		{
			if (m_AxAddr != 0) {
				msg << "Write barrier error: awaddr != 0x0";
				return false;
			}
			if (m_AxLen != 0) {
				msg << "Write barrier error: awlen != 0x0";
				return false;
			}
			if (m_AxBurst != 1) {
				msg << "Write barrier error: awburst != 0x1";
				return false;
			}
			if (m_AxSnoop != 0) {
				msg << "Write barrier error: awsnoop != 0x0";
				return false;
			}
			if (m_AxCache != 2) {
				msg << "Write barrier error: awcache != 0x2";
				return false;
			}
			if (m_AxLock != 0) {
				msg << "Write barrier error: awlock != 0x0";
				return false;
			}
			return true;
		}
	private:
		bool is_modifiable()
		{
			return (m_AxCache >> 1) & 0x1;
		}

		bool is_cacheable()
		{
			return (m_AxCache >> 2) & 0x3;
		}

		bool is_cacheline_sized_tx()
		{
			if (m_AxBar) {
				return false;
			}

			switch(m_AxSnoop) {
			case AW::WriteLineUnique:
			case AW::Evict:
				if (m_AxDomain == Domain::Inner ||
					m_AxDomain == Domain::Outer) {
					return true;
				}
				// Return false
				break;
			default:
				break;
			};

			return false;
		}

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

		uint8_t m_AxSnoop;
		uint8_t m_AxDomain;
		uint8_t m_AxBar;

		uint32_t m_numberBytes;
		uint32_t m_beat;
		uint32_t m_numBeats;
	};

	Transaction* SampleAWSignals()
	{
		return new Transaction(awaddr.read().to_uint64(),
					to_uint(awlen),
					to_uint(awsize),
					to_uint(awburst),
					to_uint(awid),
					to_uint(awcache),
					to_uint(awlock),
					to_uint(awqos),
					to_uint(awregion),
					to_uint(awuser),
					to_uint(awsnoop),
					to_uint(awdomain),
					to_uint(awbar));
	}

	Transaction *GetFirst(std::list<Transaction*>& trList,
				uint32_t id)
	{
		for (typename std::list<Transaction*>::iterator it = trList.begin();
			it != trList.end(); it++) {
			Transaction *t = (*it);

			if (t && t->GetID() == id) {
				return t;
			}
		}
		return NULL;
	}

	bool PreviousHaveData(uint32_t id)
	{
		//
		// For AXI3:
		//
		// For a slave that supports write data interleaving, the order in
		// which it receives the first data item of each transaction must be
		// the same as the order in which it receives the addresses for the
		// transactions.
		//

		for (typename std::list<Transaction*>::iterator it = m_wtList.begin();
			it != m_wtList.end(); it++) {
			Transaction *t = (*it);

			if (t->GetID() == id) {
				break;
			}

			if (t->GetBeat() == 1) {
				//
				// Transaction has no yet received data and was
				// received before than current wid
				//
				return false;
			}
		}

		return true;
	}

	bool check_bresp(Transaction *tr, std::ostringstream& msg)
	{
		uint8_t resp = to_uint(bresp) & 0x3;

		if (tr->GetExclusive()) {
			//
			// Section C3.4
			// Accept EXOKAY only for WriteNoSnoop
			//
			if (!tr->IsWriteNoSnoop()) {
				msg << "bresp error: EXOKAY is allowed only on"
					"WriteNoSnoop transactions, bresp: 0x"
					<< hex << static_cast<uint32_t>(resp);
				return false;
			}

			//
			// Only allow EXOKAY or OKAY
			//
			if (resp != AXI_EXOKAY && resp != AXI_OKAY) {
				msg << "bresp error: Only OKAY and EXOKAY bresp"
					" is allowed, bresp: 0x"
					<< hex << static_cast<uint32_t>(resp);
				return false;
			}
		} else {
			//
			// Only allow OKAY
			//
			if (resp != AXI_OKAY) {
				msg << "bresp error: Only OKAY bresp is allowed"
					", bresp: 0x"
					<< hex << static_cast<uint32_t>(resp);
				return false;
			}
		}

		return true;
	}

	void check_ace_resp(Transaction *tr)
	{
		uint8_t resp = to_uint(bresp);
		std::ostringstream msg;

		if (!check_bresp(tr, msg)) {
			tr->ReportError(msg);
		}

		if (tr->IsBarrier() && resp != 0) {
			msg << "bresp error: barrier bresp != 0, bresp: 0x"
				<< hex << static_cast<uint32_t>(resp);
			tr->ReportError(msg);
		}
	}

	void ClearList(std::list<Transaction*>& l)
	{
		for (typename std::list<Transaction*>::iterator it = l.begin();
			it != l.end(); it++) {
			Transaction *t = (*it);
			delete t;
		}
		l.clear();
	}

	bool in_list(std::list<Transaction*>& l, uint8_t snoop)
	{
		typename std::list<Transaction*>::iterator it = l.begin();

		for (; it != l.end(); it++) {
			Transaction *t = (*it);

			if (snoop == AW::WriteBack) {
				if (t->IsWriteBack()) {
					break;
				}
			} else {
				if (t->IsWriteClean()) {
					break;
				}
			}
		}

		//
		// Check that none found else return true
		//
		if (it != l.end()) {
			return true;
		}

		return false;
	}

	bool check_ongoing_writeclean(Transaction *tr, std::ostringstream& msg)
	{
		// Look for writeclean in lists
		if (in_list(m_wtList, AW::WriteClean) ||
			in_list(m_respList, AW::WriteClean)) {

			msg << "awsnoop error: ongoing WriteClean while issuing"
				" a ";
			if (tr->IsWriteUnique()) {
				msg << "WriteUnique";
			} else  {
				msg << "WriteLineUnique";
			}
			// An ongoing writeclean found
			return false;
		}

		// No ongoing writeclean found
		return true;
	}

	bool check_ongoing_writeback(Transaction *tr, std::ostringstream& msg)
	{
		// Look for writeclean in lists
		if (in_list(m_wtList, AW::WriteBack) ||
			in_list(m_respList, AW::WriteBack)) {

			msg << "awsnoop error: ongoing WriteBack while issuing"
				" a ";
			if (tr->IsWriteUnique()) {
				msg << "WriteUnique";
			} else  {
				msg << "WriteLineUnique";
			}
			// An ongoing writeback found
			return false;
		}

		// No ongoing writeclean found
		return true;
	}

	bool check_ongoing_writeunique(Transaction *tr, std::ostringstream& msg)
	{
		// Look for writeclean in lists
		if (in_list(m_wtList, AW::WriteUnique) ||
			in_list(m_respList, AW::WriteUnique)) {

			msg << "awsnoop error: ongoing WriteUnique while issuing"
				" a ";
			if (tr->IsWriteBack()) {
				msg << "WriteBack";
			} else  {
				msg << "WriteClean";
			}
			// An ongoing writeback found
			return false;
		}

		// No ongoing writeclean found
		return true;
	}

	bool check_ongoing_writelineunique(Transaction *tr,
						std::ostringstream& msg)
	{
		// Look for writeclean in lists
		if (in_list(m_wtList, AW::WriteLineUnique) ||
			in_list(m_respList, AW::WriteLineUnique)) {

			msg << "awsnoop error: ongoing WriteLineUnique while "
				"issuing a ";

			if (tr->IsWriteBack()) {
				msg << "WriteBack";
			} else  {
				msg << "WriteClean";
			}
			// An ongoing writeback found
			return false;
		}

		// No ongoing writeclean found
		return true;
	}

	bool id_in_list(std::list<Transaction*>& l, uint32_t id)
	{
		typename std::list<Transaction*>::iterator it = l.begin();

		for (; it != l.end(); it++) {
			Transaction *t = (*it);
			if (!t->IsBarrier() && t->GetID() == id) {
				//
				// Found barrier transaction
				//
				return true;
			}
		}
		return false;
	}

	bool barrier_id_in_list(std::list<Transaction*>& l, uint32_t id)
	{
		typename std::list<Transaction*>::iterator it = l.begin();

		for (; it != l.end(); it++) {
			Transaction *t = (*it);
			if (t->IsBarrier() && t->GetID() == id) {
				//
				// Found barrier transaction
				//
				return true;
			}
		}
		return false;
	}

	bool check_ongoing_barrier_ids(Transaction *tr, std::ostringstream& msg)
	{
		if (barrier_id_in_list(m_wtList, tr->GetID()) ||
		    barrier_id_in_list(m_respList, tr->GetID())) {

			msg << "awsnoop error: ongoing barrier with the same id"
				" as a normal transaction";

			return false;
		}

		return true;
	}

	bool check_ongoing_normal_tx_ids(Transaction *tr, std::ostringstream& msg)
	{
		if (id_in_list(m_wtList, tr->GetID()) ||
		    id_in_list(m_respList, tr->GetID())) {

			msg << "awsnoop error: normal transaction with the same"
				" id as an barrier";

			return false;
		}

		return true;
	}

	uint32_t get_barrier_count(std::list<Transaction*>& l)
	{
		typename std::list<Transaction*>::iterator it = l.begin();
		uint32_t num_barrier = 0;

		for (; it != l.end(); it++) {
			Transaction *t = (*it);

			if (t->IsBarrier()) {
				num_barrier++;
			}
		}
		return num_barrier;
	}

	bool check_barrier_num_outstanding(std::ostringstream& msg)
	{
		uint32_t max_outstanding = 256;
		uint32_t num_barrier = 0;

		num_barrier += get_barrier_count(m_wtList);
		num_barrier += get_barrier_count(m_respList);

		if (num_barrier >= max_outstanding) {
			msg << "Write barrier: number of outstanding is > 256";
			return false;
		}
		return true;
	}

	void check_awsignals(Transaction *tr)
	{
		uint64_t line_sz = m_cfg.get_cacheline_sz();
		unsigned int ace_mode = m_pc.GetACEMode();
		std::ostringstream msg;

		if (!tr->CheckAWSnoop(ace_mode)) {
			msg << "awsnoop error";
			tr->ReportError(msg);
		}

		if (!tr->CheckAWCache()) {
			msg << "awcache <-> awdomain error";
			tr->ReportError(msg);
		}

		if (!tr->CheckCachelineSzTx(msg, line_sz)) {
			tr->ReportError(msg);
		}

		if (!tr->CheckWriteUnique(msg)) {
			tr->ReportError(msg);
		}

		if (!tr->CheckWriteBackWriteClean(msg, line_sz)) {
			tr->ReportError(msg);
		}


		//
		// C4.8.6, WriteUnique WriteLineUnique must not be issued
		// simultanously as WriteBack and WriteClean
		//
		if (tr->IsWriteUnique() || tr->IsWriteLineUnique()) {

			if (!check_ongoing_writeback(tr, msg)) {
				tr->ReportError(msg);
			}

			if (!check_ongoing_writeclean(tr, msg)) {
				tr->ReportError(msg);
			}
		}

		if (tr->IsWriteBack() || tr->IsWriteClean()) {

			if (!check_ongoing_writeunique(tr, msg)) {
				tr->ReportError(msg);
			}

			if (!check_ongoing_writelineunique(tr, msg)) {
				tr->ReportError(msg);
			}
		}

		//
		// C8.4.1 Barrier transaction are required to use different ids
		// than non barrier transactions. Also check barrier awsignals
		// and outstanding count.
		//
		if (tr->IsBarrier()) {
			if (!tr->CheckBarrierSignals(msg)) {
				tr->ReportError(msg);
			}
			//
			// ACELite does not have a limit on outstandig barriers
			//
			if (m_pc.GetACEMode() == ACE_MODE_ACE) {
				if (!check_barrier_num_outstanding(msg)) {
					tr->ReportError(msg);
				}
			}
			if (!check_ongoing_normal_tx_ids(tr, msg)) {
				tr->ReportError(msg);
			}
		} else {
			if (!check_ongoing_barrier_ids(tr, msg)) {
				tr->ReportError(msg);
			}
		}
	}

	Transaction *next_from(std::list<Transaction*>& l)
	{
		if (l.empty()) {
			return NULL;
		}
		return l.front();
	}

	void wr_check()
	{
		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());

			if (reset_asserted()) {
				ClearList(m_wtList);
				ClearList(m_respList);
				wait_for_reset_release();
				continue;
			}

			if (awvalid.read() && awready.read()) {
				if (m_wtList.size() < m_cfg.max_depth()) {
					Transaction *tr = SampleAWSignals();

					if(m_cfg.en_wr_tx_check()) {
						check_awsignals(tr);
					}

					if (m_wtList.empty() && !tr->HasData()) {
						//
						// Evict & Barriers have no data
						//
						m_respList.push_back(tr);
					} else {
						m_wtList.push_back(tr);
					}
				} else {
					SC_REPORT_ERROR(WR_TX_ERROR,
							"Maximum outstanding "
							"transactions reached");
				}
			}

			if (wvalid.read() && wready.read()) {
				if (!m_wtList.empty()) {
					Transaction *wt = m_wtList.front();

					if (m_cfg.en_wstrb_check()) {
						bool allow_gaps = m_cfg.allow_wstrb_gaps();

						if (wt->IsWriteLineUnique()) {
							// C3.1.5
							allow_gaps = false;
						}

						if(!wt->CheckWstrb(wstrb, allow_gaps)) {
							std::ostringstream msg;

							msg << "wstrb not following "
								<< "expected format";

							wt->ReportError(msg);
						}
					}

					wt->IncBeat();

					//
					// Check wlast
					//
					if (m_cfg.en_wr_tx_check() &&
						wlast.read() != wt->Done()) {
						std::ostringstream msg;

						msg << "Error on data burst length "
							<< "or wlast identified "
							<< "on write data channel";

						wt->ReportError(msg);
					}

					if (wlast.read()) {
						//
						// Wr tx data phase done,
						// move tx to response list
						//
						m_wtList.remove(wt);

						if (m_respList.size() < m_cfg.max_depth()) {
							m_respList.push_back(wt);
						} else {
							SC_REPORT_ERROR(WR_TX_ERROR,
									"Maximum outstanding "
									"transactions reached");
						}

						//
						// Write barriers and Evict
						// don't have a data phase so
						// move them to the response
						// phase
						//
						wt = next_from(m_wtList);
						while (wt && !wt->HasData()) {
							m_wtList.remove(wt);
							m_respList.push_back(wt);
							wt = next_from(m_wtList);
						}
					}
				} else {
					std::ostringstream msg;

					msg << "Unexpected data identified "
						<< "on write data channel";

					SC_REPORT_ERROR(WR_TX_ERROR,
							msg.str().c_str());
				}
			}

			if (bvalid.read() && bready.read()) {
				Transaction *wt = GetFirst(m_respList,
							   to_uint(bid));

				if (wt) {
					if (m_cfg.en_resp_check()) {
						check_ace_resp(wt);
					}

					// Transaction done
					m_respList.remove(wt);
					delete wt;
				} else {
					std::ostringstream msg;

					msg << "Unexpected transaction id "
						<< "on write response channel"
						<< " (id: "
						<< to_uint(rid) << ")";

					SC_REPORT_ERROR(WR_TX_ERROR,
							msg.str().c_str());
				}
			}
		}
	}

	std::list<Transaction*> m_wtList;
	std::list<Transaction*> m_respList;
};

ACE_CHECKER(checker_ace_snoop_channels)
{
public:
	ACE_CHECKER_CTOR(checker_ace_snoop_channels)
	{
		if (m_cfg.en_ace_snoop_ch_check()) {
			SC_THREAD(ace_snoop_ch_check);
		}
	}

	~checker_ace_snoop_channels()
	{
		ClearList(m_crList);
		ClearList(m_cdList);
	}

private:
	class Transaction :
		public ace_helpers
	{
	public:
		Transaction(uint64_t acaddr, uint8_t acsnoop, uint8_t acprot) :
			m_acaddr(acaddr),
			m_acsnoop(acsnoop),
			m_acprot(acprot),
			m_crresp(0),
			m_numBeats(0)
		{}

		void SetNumBeats(uint32_t numBeats) { m_numBeats = numBeats; }
		void DecnumBeats() { m_numBeats--; }
		bool Done() { return m_numBeats == 0; }

		void set_crresp(uint8_t crresp) { m_crresp = crresp; }

		bool has_datatransfer()
		{
			return ExtractDataTransfer(m_crresp);
		}
		bool has_error_bit()
		{
			return ExtractErrorBit(m_crresp);
		}
		bool pass_dirty()
		{
			return ExtractPassDirty(m_crresp);
		}
		bool is_shared()
		{
			return ExtractIsShared(m_crresp);
		}
		bool is_was_unique()
		{
			return ExtractWasUnique(m_crresp);
		}

		void PrintTx(std::ostringstream& msg)
		{
			msg << " { ";
			msg << "acaddr: 0x" << std::hex << m_acaddr;
			msg << ", acsnoop: 0x" << std::hex <<
				static_cast<uint32_t>(m_acsnoop);
			msg << ", acprot: 0x" << std::hex <<
				static_cast<uint32_t>(m_acprot);
			msg << ", crresp: 0x" << std::hex <<
				static_cast<uint32_t>(m_crresp);
			msg << " }";
		}

		void ac_error(std::ostringstream& msg)
		{
			PrintTx(msg);
			SC_REPORT_ERROR(AC_CH_ERROR, msg.str().c_str());
		}

		void cr_error(std::ostringstream& msg)
		{
			PrintTx(msg);
			SC_REPORT_ERROR(CR_CH_ERROR, msg.str().c_str());
		}

		bool check_acsnoop()
		{
			switch (m_acsnoop) {
			case AC::ReadOnce:
			case AC::ReadShared:
			case AC::ReadClean:
			case AC::ReadNotSharedDirty:
			case AC::ReadUnique:
			case AC::CleanShared:
			case AC::CleanInvalid:
			case AC::MakeInvalid:
			case AC::DVMComplete:
			case AC::DVMMessage:
				return true;
			default:
				break;
			};
			return false;
		}

		bool check_acaddr()
		{
			uint64_t snoop_data_bus_width = T::CD_DATA_W / 8;
			uint64_t aligned_addr = align(m_acaddr,
							snoop_data_bus_width);

			return m_acaddr == aligned_addr;
		}

		bool AllowsIsShared()
		{
			switch(m_acsnoop) {
			case AC::ReadUnique:
			case AC::CleanInvalid:
			case AC::MakeInvalid:
				return false;
			default:
				break;
			};
			return true;
		}
	private:
		uint64_t m_acaddr;
		uint8_t m_acsnoop;
		uint8_t m_acprot;

		uint8_t m_crresp;

		uint32_t m_numBeats;
	};

	void check_acsignals(Transaction *tr)
	{
		std::ostringstream msg;

		if (!tr->check_acsnoop()) {
			msg << "acsnoop error:";
			tr->ac_error(msg);
		}

		if (!tr->check_acaddr()) {
			msg << "acaddr error: not aligned to snoop data bus "
				"byte width";
			tr->ac_error(msg);
		}
	}

	void check_crsignals(Transaction *tr)
	{
		std::ostringstream msg;

		if (tr->pass_dirty() && !tr->has_datatransfer()) {
			msg << "crresp error: PassDirty set but not DataTransfer";
			tr->cr_error(msg);
		}

		if (tr->is_shared() && !tr->AllowsIsShared()) {
			msg << "crresp error: IsShared wrongly asserted";
			tr->cr_error(msg);
		}
	}

	void ClearList(std::list<Transaction*>& l)
	{
		for (typename std::list<Transaction*>::iterator it = l.begin();
			it != l.end(); it++) {
			Transaction *t = (*it);
			delete t;
		}
		l.clear();
	}

	Transaction *SampleACChannel()
	{
		return new Transaction(to_uint(acaddr),
					to_uint(acsnoop),
					to_uint(acprot));
	}

	void ace_snoop_ch_check()
	{
		uint32_t snoop_data_bus_width = T::CD_DATA_W / 8;
		uint32_t beats_per_cacheline = m_cfg.get_cacheline_sz() /
						snoop_data_bus_width;

		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());

			if (reset_asserted()) {
				ClearList(m_crList);
				ClearList(m_cdList);
				wait_for_reset_release();
				continue;
			}

			if (acvalid.read() && acready.read()) {
				uint32_t num_outstanding = m_crList.size() +
								m_cdList.size();

				if (num_outstanding < m_cfg.max_depth()) {
					Transaction *tr = SampleACChannel();

					check_acsignals(tr);

					m_crList.push_back(tr);
				} else {
					SC_REPORT_ERROR(AC_CH_ERROR,
							"Maximum outstanding "
							"transactions reached");
				}
			}

			if (crvalid.read() && crready.read()) {
				if (!m_crList.empty()) {
					Transaction *tr = m_crList.front();

					tr->set_crresp(to_uint(crresp));

					check_crsignals(tr);

					m_crList.remove(tr);

					if (tr->has_datatransfer()) {
						tr->SetNumBeats(beats_per_cacheline);
						m_cdList.push_back(tr);
					} else {
						delete tr;
					}
				} else {
					std::ostringstream msg;

					msg << "cr channel error: ";
					msg << "Unexpected cr channel activity";

					SC_REPORT_ERROR(CR_CH_ERROR,
							msg.str().c_str());
				}
			}

			if (cdvalid.read() && cdready.read()) {
				if (!m_cdList.empty()) {
					Transaction *tr = m_cdList.front();

					tr->DecnumBeats();

					if (tr->Done()) {

						if (!cdlast.read()) {
							std::ostringstream msg;

							msg << "cd channel error:"
								" cdlast not set";

							SC_REPORT_ERROR(CD_CH_ERROR,
									msg.str().c_str());
						}

						// Done
						m_cdList.remove(tr);
						delete tr;
					}
				} else {
					std::ostringstream msg;

					msg << "Unexpected cd channel activity";

					SC_REPORT_ERROR(CD_CH_ERROR,
							msg.str().c_str());
				}
			}
		}
	}

	std::list<Transaction*> m_crList;
	std::list<Transaction*> m_cdList;
};

ACE_CHECKER(checker_ace_barrier)
{
public:
	ACE_CHECKER_CTOR(checker_ace_barrier)
	{
		if (m_cfg.en_ace_barrier_check()) {
			SC_THREAD(ace_barrier_check);
		}
	}

	~checker_ace_barrier()
	{
		ClearList(m_rList);
		ClearList(m_wList);
	}

private:
	class Transaction
	{
	public:
		Transaction(bool is_write,
				uint8_t AxID,
				uint8_t AxProt,
				uint8_t AxDomain,
				uint8_t AxBar) :
			m_is_write(is_write),
			m_AxID(AxID),
			m_AxProt(AxProt),
			m_AxDomain(AxDomain),
			m_AxBar(AxBar)
		{}

		bool IsWrite() { return m_is_write; }

		bool IsPair(Transaction *tr)
		{
			if (m_is_write == !tr->m_is_write) {
				return false;
			}
			if (m_AxID != tr->m_AxID) {
				return false;
			}
			if (m_AxProt != tr->m_AxProt) {
				return false;
			}
			if (m_AxDomain != tr->m_AxDomain) {
				return false;
			}
			if (m_AxBar != tr->m_AxBar) {
				return false;
			}
			return true;
		}

	private:
		bool m_is_write;

		uint32_t m_AxID;
		uint8_t m_AxProt;
		uint8_t m_AxDomain;
		uint8_t m_AxBar;
	};

	Transaction *SampleARSignals()
	{
		return new Transaction(false,
					to_uint(arid),
					to_uint(arprot),
					to_uint(ardomain),
					to_uint(arbar));
	}

	Transaction *SampleAWSignals()
	{
		return new Transaction(false,
					to_uint(awid),
					to_uint(awprot),
					to_uint(awdomain),
					to_uint(awbar));
	}

	void ClearList(std::list<Transaction*>& l)
	{
		for (typename std::list<Transaction*>::iterator it = l.begin();
			it != l.end(); it++) {
			Transaction *t = (*it);
			delete t;
		}
		l.clear();
	}

	bool check_pair(Transaction *tr, std::list<Transaction*>& l)
	{
		Transaction *pair;
		std::ostringstream msg;

		if (l.empty()) {
			return false;
		}

		pair = l.front();

		//
		// Section 8.4.1, Barriers pairs must be issued in the same
		// sequence
		//
		if (!pair->IsPair(tr)) {
			msg << "barrier error: unexpected ";

			if (tr->IsWrite()) {
				msg << "write";
			} else {
				msg << "read";
			}

			msg << " barrier detected (pair not found)";

			SC_REPORT_ERROR(BARRIER_ERROR, msg.str().c_str());
		}

		l.remove(pair);
		delete pair;

		return true;
	}

	void ace_barrier_check()
	{
		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());

			if (reset_asserted()) {
				ClearList(m_rList);
				ClearList(m_wList);
				wait_for_reset_release();
				continue;
			}

			if (arvalid.read() && arready.read()) {
				bool is_read_barrier = to_uint(arbar);

				if (is_read_barrier) {
					if (m_rList.size() < m_cfg.max_depth()) {
						Transaction *tr = SampleARSignals();

						if (check_pair(tr, m_wList)) {
							delete tr;
						} else {
							m_rList.push_back(tr);
						}
					} else {
						SC_REPORT_ERROR(BARRIER_ERROR,
								"Maximum outstanding "
								"transactions reached");
					}
				}
			}

			if (awvalid.read() && awready.read()) {
				bool is_write_barrier = to_uint(awbar);

				if (is_write_barrier) {
					if (m_wList.size() < m_cfg.max_depth()) {
						Transaction *tr =
							SampleAWSignals();

						if (check_pair(tr, m_rList)) {
							delete tr;
						} else {
							m_wList.push_back(tr);
						}
					} else {
						SC_REPORT_ERROR(BARRIER_ERROR,
								"Maximum outstanding "
								"transactions reached");
					}
				}
			}
		}
	}

	std::list<Transaction*> m_rList;
	std::list<Transaction*> m_wList;
};

ACE_CHECKER(checker_ace_cd_data)
{
public:
	ACE_CHECKER_CTOR(checker_ace_cd_data)
	{
		if (m_cfg.en_ace_cd_data_check()) {
			SC_THREAD(ace_cd_data_check);
		}
	}

	~checker_ace_cd_data()
	{
		ClearList(m_crList);
		ClearList(m_rtList);
		ClearList(m_wtList);
		m_allocated.clear();
	}

private:
	class Transaction :
		public ace_helpers
	{
	public:
		Transaction(uint64_t addr, uint8_t snoop, uint8_t prot,
				uint32_t id = 0, bool is_read = false) :
			m_AxID(id),
			m_addr(addr),
			m_snoop(snoop),
			m_non_secure(get_non_secure(prot)),
			m_is_read(is_read),
			m_crresp(0)
		{}

		void set_crresp(uint8_t crresp) { m_crresp = crresp; }

		uint32_t GetID() { return m_AxID; }

		uint64_t GetAddress() { return m_addr; }
		uint8_t GetSnoop() { return m_snoop; }

		bool has_datatransfer()
		{
			return ExtractDataTransfer(m_crresp);
		}
		bool is_shared()
		{
			return ExtractIsShared(m_crresp);
		}

		enum { NonSecureShift = 1 };

		bool get_non_secure(uint8_t prot)
		{
			// bit[1]
			return (prot >> NonSecureShift) & 0x1;
		}

		bool IsNonSecure() { return m_non_secure; }

		bool AllocateCacheline()
		{
			switch(m_snoop) {
			case AR::ReadClean:
			case AR::ReadNotSharedDirty:
			case AR::ReadShared:
			case AR::ReadUnique:
			case AR::CleanUnique:
			case AR::MakeUnique:
				return true;
			default:
				break;
			};
			return false;
		}

		bool EvictCacheline()
		{
			if (m_is_read) {
				switch(m_snoop) {
				case AR::CleanInvalid:
				case AR::MakeInvalid:
					return true;
				default:
					break;
				};
			} else {
				switch(m_snoop) {
				case AW::WriteBack:
				case AW::Evict:
					return true;
				default:
					break;
				};
			}
			return false;
		}

		bool MustHaveData()
		{
			switch(m_snoop) {
			case AC::ReadOnce:
			case AC::ReadShared:
			case AC::ReadClean:
			case AC::ReadNotSharedDirty:
			case AC::ReadUnique:
				return true;
			default:
				break;
			};
			return false;
		}

		void dump()
		{
			cout << " { "
				<< " id: 0x" << hex << m_AxID
				<< ", addr: 0x" << hex << m_addr

				<< ", snoop: 0x" << hex
					<< static_cast<uint32_t>(m_snoop)

				<< ", is_read: " << m_is_read
				<< ", ccrresp: " << m_crresp
				<< " } " << endl;
		}

	private:
		uint32_t m_AxID;

		uint64_t m_addr;
		uint8_t m_snoop;
		bool m_non_secure;

		bool m_is_read;

		uint8_t m_crresp;
	};

	class Address
	{
	public:
		Address(Transaction *tr) :
			m_addr(tr->GetAddress()),
			m_non_secure(tr->IsNonSecure())
		{}

		friend bool operator==(const Address& lhs, const Address& rhs)
		{
			return lhs.m_addr == rhs.m_addr &&
				lhs.m_non_secure == rhs.m_non_secure;
		}

	private:
		uint64_t m_addr;
		bool m_non_secure;
	};

	Transaction *SampleARSignals()
	{
		return new Transaction(to_uint(araddr),
					to_uint(arsnoop),
					to_uint(arprot),
					to_uint(arid),
					true);
	}

	Transaction *SampleAWSignals()
	{
		return new Transaction(to_uint(awaddr),
					to_uint(awsnoop),
					to_uint(awprot),
					to_uint(awid),
					false);
	}

	Transaction *SampleACChannel()
	{
		return new Transaction(to_uint(acaddr),
					to_uint(acsnoop),
					to_uint(acprot));
	}

	void ClearList(std::list<Transaction*>& l)
	{
		for (typename std::list<Transaction*>::iterator it = l.begin();
			it != l.end(); it++) {
			Transaction *t = (*it);
			delete t;
		}
		l.clear();
	}

	Transaction *GetFirst(std::list<Transaction*>& l, uint32_t id)
	{
		for (typename std::list<Transaction*>::iterator it = l.begin();
			it != l.end(); it++) {
			Transaction *t = (*it);

			if (t && t->GetID() == id) {
				return t;
			}
		}
		return NULL;
	}

	bool in_list(std::list<Address>& l, Address& addr)
	{
		for (typename std::list<Address>::iterator it = l.begin();
			it != l.end(); it++) {

			if ((*it) == addr) {
				return true;
			}
		}
		return false;
	}

	void process_rchannel(Transaction *tr)
	{
		Address addr(tr);

		if (tr->AllocateCacheline() &&
			!in_list(m_allocated, addr)) {

			//
			// Alloc cache line
			//
			m_allocated.push_back(addr);

		} else if (tr->EvictCacheline() &&
				in_list(m_allocated, addr)) {

			//
			// Evict cache line
			//
			m_allocated.remove(addr);
		}
	}

	void process_bchannel(Transaction *tr)
	{
		if (tr->EvictCacheline()) {
			Address addr(tr);

			if (in_list(m_allocated, addr)) {

				//
				// Evict cache line
				//
				m_allocated.remove(addr);
			}
		}
	}

	void process_crchannel(Transaction *tr)
	{
		//
		// Remove the line for the allocated list if the master does
		// not retain a copy of the cacheline.
		//
		if (!tr->is_shared()) {
			Address addr(tr);

			if (in_list(m_allocated, addr)) {
				m_allocated.remove(addr);
			}
		}
	}

	void check_crresp(Transaction *tr)
	{
		Address addr(tr);
		std::ostringstream msg;

		//
		// Check that the snoop transactions recommended to have data
		// transfer data (Section 5.2.2 [1]).
		//
		if (in_list(m_allocated, addr) && tr->MustHaveData() &&
			!tr->has_datatransfer()) {

			msg << "snoop transaction: 0x" << hex
				<< static_cast<uint32_t>(tr->GetSnoop())
				<< " without data (cache line should have been"
					" cached))";

			SC_REPORT_ERROR(CD_DATA_ERROR, msg.str().c_str());

		} else if (!in_list(m_allocated, addr) &&
				tr->has_datatransfer()) {

			msg << "snoop transaction: unexpected data "
				"(cache line should not have been in cache), "
				"addr 0x" << hex << tr->GetAddress();

			SC_REPORT_ERROR(CD_DATA_ERROR, msg.str().c_str());
		}
	}

	void ace_cd_data_check()
	{
		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());
			if (reset_asserted()) {
				ClearList(m_crList);
				ClearList(m_rtList);
				ClearList(m_wtList);
				m_allocated.clear();
				wait_for_reset_release();
				continue;
			}

			if (arvalid.read() && arready.read()) {
				if (m_rtList.size() < m_cfg.max_depth()) {
					Transaction *tr = SampleARSignals();
					m_rtList.push_back(tr);
				} else {
					SC_REPORT_ERROR(CD_DATA_ERROR,
							"Maximum outstanding "
							"transactions reached");
				}
			}

			if (rvalid.read() && rready.read()) {
				Transaction *rt = GetFirst(m_rtList,
								to_uint(rid));

				if (rt && rlast.read()) {
					//
					// Transaction done, cacheline can now
					// be considered allocated / not
					// allocated.
					//
					process_rchannel(rt);

					m_rtList.remove(rt);
					delete rt;
				}
			}

			if (awvalid.read() && awready.read()) {
				if (m_wtList.size() < m_cfg.max_depth()) {
					Transaction *tr = SampleAWSignals();
					m_wtList.push_back(tr);
				} else {
					SC_REPORT_ERROR(CD_DATA_ERROR,
							"Maximum outstanding "
							"transactions reached");
				}
			}

			if (bvalid.read() && bready.read()) {
				Transaction *wt = GetFirst(m_wtList,
								to_uint(bid));

				if (wt) {
					//
					// Transaction done, cacheline can now
					// be considered evicted / not
					// evicted.
					//
					process_bchannel(wt);

					m_wtList.remove(wt);
					delete wt;
				}
			}

			if (acvalid.read() && acready.read()) {
				if (m_crList.size() < m_cfg.max_depth()) {
					Transaction *tr = SampleACChannel();
					m_crList.push_back(tr);
				} else {
					SC_REPORT_ERROR(CD_DATA_ERROR,
							"Maximum outstanding "
							"transactions reached");
				}
			}

			if (crvalid.read() && crready.read()) {
				if (!m_crList.empty()) {
					Transaction *tr = m_crList.front();

					tr->set_crresp(to_uint(crresp));

					check_crresp(tr);

					process_crchannel(tr);

					m_crList.remove(tr);
					delete tr;
				}
			}
		}
	}

	std::list<Address> m_allocated;

	std::list<Transaction*> m_rtList;
	std::list<Transaction*> m_wtList;
	std::list<Transaction*> m_crList;
};

#endif /* CHECKER_ACE_H__ */

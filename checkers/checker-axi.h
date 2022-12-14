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
 *
 *
 * References:
 *
 * [1] AMBA AXI and ACE Protocol Specification, ARM IHI 0022D, ID102711
 *
 */

#ifndef CHECKER_AXI_H__
#define CHECKER_AXI_H__

#include "checker-utils.h"
#include <list>
#include <sstream>
#include <vector>

#define RD_TX_ERROR "rd_tx"
#define WR_TX_ERROR "wr_tx"
#define ADDR_ALINGMENT_ERROR "addr_alignment"
#define AXI_HANDSHAKE_ERROR "axi_handshakes"

AXI_CHECKER(checker_axi_stable)
{
public:
	AXI_CHECKER_CTOR(checker_axi_stable)
	{
		SC_THREAD(monitor_archannel_stable);
		SC_THREAD(monitor_awchannel_stable);
		SC_THREAD(monitor_wchannel_stable);
		SC_THREAD(monitor_bchannel_stable);
		SC_THREAD(monitor_rchannel_stable);
	}

private:
#define SAMPLE_SIGNAL(d, s) s = d.s
	class sample_awchannel {
	public:
		bool awvalid;
		bool awready;
		sc_bv<T::ADDR_W> awaddr;
		sc_bv<3> awprot;
		AXISignal(T::ARUSER_W) awuser;
		sc_bv<4> awregion;
		sc_bv<4> awqos;
		sc_bv<4> awcache;
		sc_bv<2> awburst;
		sc_bv<3> awsize;
		AXISignal(T::AxLEN_W) awlen;
		AXISignal(T::ID_W) awid;
		AXISignal(T::AxLOCK_W) awlock;

		bool cmp_eq_stable_valid_cycle_signals(const sample_awchannel& rhs) {
			bool eq = true;

			eq &= awaddr == rhs.awaddr;
			eq &= awprot == rhs.awprot;
			eq &= awuser == rhs.awuser;
			eq &= awregion == rhs.awregion;
			eq &= awqos == rhs.awqos;
			eq &= awcache == rhs.awcache;
			eq &= awburst == rhs.awburst;
			eq &= awsize == rhs.awsize;
			eq &= awlen == rhs.awlen;
			eq &= awid == rhs.awid;
			eq &= awlock == rhs.awlock;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_SIGNAL(dev, awvalid);
			SAMPLE_SIGNAL(dev, awready);
			SAMPLE_SIGNAL(dev, awaddr);
			SAMPLE_SIGNAL(dev, awprot);
			SAMPLE_SIGNAL(dev, awuser);
			SAMPLE_SIGNAL(dev, awregion);
			SAMPLE_SIGNAL(dev, awqos);
			SAMPLE_SIGNAL(dev, awcache);
			SAMPLE_SIGNAL(dev, awburst);
			SAMPLE_SIGNAL(dev, awsize);
			SAMPLE_SIGNAL(dev, awlen);
			SAMPLE_SIGNAL(dev, awid);
			SAMPLE_SIGNAL(dev, awlock);
		}

		const char *get_name(void) { return "awchannel"; }
	};

	class sample_archannel {
	public:
		bool arvalid;
		bool arready;
		sc_bv<T::ADDR_W> araddr;
		sc_bv<3> arprot;
		AXISignal(T::ARUSER_W) aruser;
		sc_bv<4> arregion;
		sc_bv<4> arqos;
		sc_bv<4> arcache;
		sc_bv<2> arburst;
		sc_bv<3> arsize;
		AXISignal(T::AxLEN_W) arlen;
		AXISignal(T::ID_W) arid;
		AXISignal(T::AxLOCK_W) arlock;

		bool cmp_eq_stable_valid_cycle_signals(const sample_archannel& rhs) {
			bool eq = true;

			eq &= araddr == rhs.araddr;
			eq &= arprot == rhs.arprot;
			eq &= aruser == rhs.aruser;
			eq &= arregion == rhs.arregion;
			eq &= arqos == rhs.arqos;
			eq &= arcache == rhs.arcache;
			eq &= arburst == rhs.arburst;
			eq &= arsize == rhs.arsize;
			eq &= arlen == rhs.arlen;
			eq &= arid == rhs.arid;
			eq &= arlock == rhs.arlock;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_SIGNAL(dev, arvalid);
			SAMPLE_SIGNAL(dev, arready);
			SAMPLE_SIGNAL(dev, araddr);
			SAMPLE_SIGNAL(dev, arprot);
			SAMPLE_SIGNAL(dev, aruser);
			SAMPLE_SIGNAL(dev, arregion);
			SAMPLE_SIGNAL(dev, arqos);
			SAMPLE_SIGNAL(dev, arcache);
			SAMPLE_SIGNAL(dev, arburst);
			SAMPLE_SIGNAL(dev, arsize);
			SAMPLE_SIGNAL(dev, arlen);
			SAMPLE_SIGNAL(dev, arid);
			SAMPLE_SIGNAL(dev, arlock);
		}

		const char *get_name(void) { return "archannel"; }
	};

	class sample_wchannel {
	public:
		bool wvalid;
		bool wready;
		sc_bv<T::DATA_W> wdata;
		sc_bv<T::DATA_W/8> wstrb;
		AXISignal(T::WUSER_W) wuser;
		AXISignal(T::ID_W) wid;
		bool wlast;

		bool cmp_eq_stable_valid_cycle_signals(const sample_wchannel& rhs) {
			bool eq = true;

			eq &= wdata == rhs.wdata;
			eq &= wstrb == rhs.wstrb;
			eq &= wuser == rhs.wuser;
			eq &= wid == rhs.wid;
			eq &= wlast == rhs.wlast;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_SIGNAL(dev, wvalid);
			SAMPLE_SIGNAL(dev, wready);
			SAMPLE_SIGNAL(dev, wdata);
			SAMPLE_SIGNAL(dev, wstrb);
			SAMPLE_SIGNAL(dev, wuser);
			SAMPLE_SIGNAL(dev, wid);
			SAMPLE_SIGNAL(dev, wlast);
		}

		const char *get_name(void) { return "wchannel"; }
	};

	class sample_bchannel {
	public:
		bool bvalid;
		bool bready;
		sc_bv<2> bresp;
		AXISignal(T::RUSER_W) buser;
		AXISignal(T::ID_W) bid;

		bool cmp_eq_stable_valid_cycle_signals(const sample_bchannel& rhs) {
			bool eq = true;

			eq &= bresp == rhs.bresp;
			eq &= buser == rhs.buser;
			eq &= bid == rhs.bid;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_SIGNAL(dev, bvalid);
			SAMPLE_SIGNAL(dev, bready);
			SAMPLE_SIGNAL(dev, bresp);
			SAMPLE_SIGNAL(dev, buser);
			SAMPLE_SIGNAL(dev, bid);
		}

		const char *get_name(void) { return "bchannel"; }
	};

	class sample_rchannel {
	public:
		bool rvalid;
		bool rready;
		sc_bv<T::DATA_W> rdata;
		sc_bv<T::RRESP_W> rresp;
		AXISignal(T::RUSER_W) ruser;
		AXISignal(T::ID_W) rid;
		bool rlast;

		bool cmp_eq_stable_valid_cycle_signals(const sample_rchannel& rhs) {
			bool eq = true;

			eq &= rdata == rhs.rdata;
			eq &= rresp == rhs.rresp;
			eq &= ruser == rhs.ruser;
			eq &= rid == rhs.rid;
			eq &= rlast == rhs.rlast;
			return eq;
		}

		void sample_from(T& dev) {
			SAMPLE_SIGNAL(dev, rvalid);
			SAMPLE_SIGNAL(dev, rready);
			SAMPLE_SIGNAL(dev, rdata);
			SAMPLE_SIGNAL(dev, rresp);
			SAMPLE_SIGNAL(dev, ruser);
			SAMPLE_SIGNAL(dev, rid);
			SAMPLE_SIGNAL(dev, rlast);
		}

		const char *get_name(void) { return "rchannel"; }
	};

	GEN_STABLE_MON(aw)
	GEN_STABLE_MON(ar)
	GEN_STABLE_MON(w)
	GEN_STABLE_MON(b)
	GEN_STABLE_MON(r)
};

AXI_CHECKER(check_rd_tx)
{
public:
	AXI_CHECKER_CTOR(check_rd_tx)
	{
		if(enabled()) {
			SC_THREAD(rd_check);
		}
	}

private:
	bool enabled()
	{
		if(m_cfg.en_rd_order_check() ||
			m_cfg.en_resp_check()) {
			return true;
		}
		return true;
	}

	class Transaction
	{
	public:
		Transaction(uint64_t AxAddr,
				uint32_t AxLen,
				uint8_t AxSize,
				uint8_t AxBurst,
				uint32_t AxID,
				uint8_t AxCache,
				uint8_t AxLock,
				uint8_t AxQoS,
				uint8_t AxRegion,
				uint32_t AxUser,
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
			m_version(version),
			m_numBeats(AxLen + 1)
		{}

		uint32_t GetID() { return m_AxID; }
		inline bool GetE() { return m_AxLock == AXI_LOCK_EXCLUSIVE; }

		void DecNumBeats() { m_numBeats--; }
		bool Done() { return m_numBeats == 0; }

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

			if (m_version == V_AXI4) {
				msg << ", arqos: 0x" << std::hex
					<< static_cast<uint32_t>(m_AxQoS) << ", ";
				msg << "arregion: 0x" << std::hex
					<< static_cast<uint32_t>(m_AxRegion) << ", ";
				msg << "aruser: 0x" << std::hex << m_AxUser;
			}

			msg << " }";

			SC_REPORT_ERROR(RD_TX_ERROR, msg.str().c_str());
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

		AXIVersion m_version;
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
					m_pc.GetVersion());
	}

	bool check_axi_resp(Transaction *tr)
	{
		uint8_t resp = to_uint(rresp);

		if (tr->GetE()) {
			// Accept AXI_OKAY as non error
			return resp == AXI_EXOKAY || resp == AXI_OKAY;
		}
		return resp == AXI_OKAY;
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
					m_rtList.push_back(SampleARSignals());
				}
			}

			if (rvalid.read() && rready.read()) {
				Transaction *rt = GetFirst(to_uint(rid));

				if (rt) {
					rt->DecNumBeats();

					if (m_cfg.en_resp_check()) {
						if (!check_axi_resp(rt)) {
							std::ostringstream msg;

							msg << "Error response"
							<< " identifed, rresp: "
							<< "0x"<< std::hex
							<< to_uint(rresp);

							rt->ReportError(msg);
						}
					}

					if (m_cfg.en_rd_order_check()) {
						if (rlast.read() != rt->Done()) {
							std::ostringstream msg;

							msg << "Wrongly ordered transaction"
								<< " identified (has an "
								<< "unexpected burst length)";

							rt->ReportError(msg);
						}
					}

					// Transaction done
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

AXI_CHECKER(check_wr_tx)
{
public:
	AXI_CHECKER_CTOR(check_wr_tx)
	{
		if (enabled()) {
			SC_THREAD(wr_check);
		}
	}

private:
	bool enabled()
	{
		return m_cfg.en_wstrb_check() || m_cfg.en_wr_bursts_check();
	}

	class Transaction
	{
	public:
		Transaction(uint64_t AxAddr,
				uint32_t AxLen,
				uint8_t AxSize,
				uint8_t AxBurst,
				uint32_t AxID,
				uint8_t AxCache,
				uint8_t AxLock,
				uint8_t AxQoS,
				uint8_t AxRegion,
				uint32_t AxUser,
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

			m_numberBytes(1 << AxSize),
			m_beat(1),
			m_numBeats(AxLen + 1),
			m_version(version)
		{}

		uint32_t GetID() { return m_AxID; }

		void IncBeat() { m_beat++; }
		uint32_t GetBeat() { return m_beat; }

		inline bool GetE() { return m_AxLock == AXI_LOCK_EXCLUSIVE; }
		bool Done() { return m_beat > m_numBeats; }

		bool CheckWstrb(sc_bv<T::DATA_W/8>& wstrb,
				bool allow_gaps)
		{
			uint64_t alignedAddress = align(m_AxAddr, m_numberBytes);
			uint32_t data_bus_bytes = wstrb.length();
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
				if (wstrb.bit(i)) {
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
					if (!wstrb.bit(i++)) {
						return false;
					}

					//
					// Expect wstrb zeros after the first
					// zero is found (by breaking here)
					//
					for (; i <= upper_byte_lane; i++) {
						if (!wstrb.bit(i)) {
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
						if (!wstrb.bit(i)) {
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
				if (wstrb.bit(i)) {
					return false;
				}
			}

			return true;
		}

		uint64_t align(uint64_t addr, uint64_t alignTo)
		{
			return (addr / alignTo) * alignTo;
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

			if (m_version == V_AXI4) {
				msg << ", awqos: 0x" << std::hex
					<< static_cast<uint32_t>(m_AxQoS) << ", ";
				msg << "awregion: 0x" << std::hex
					<< static_cast<uint32_t>(m_AxRegion) << ", ";
				msg << "awuser: 0x" << std::hex << m_AxUser;
			}

			msg << " }";

			SC_REPORT_ERROR(WR_TX_ERROR, msg.str().c_str());
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

		uint32_t m_numberBytes;
		uint32_t m_beat;
		uint32_t m_numBeats;
		AXIVersion m_version;
	};

	class WData {
	public:
		WData(uint32_t wid,
			sc_in<sc_bv<T::DATA_W/8> >& wstrb,
			bool wlast) :
			m_wid(wid),
			m_wlast(wlast),
			m_wt(NULL)
		{
			m_wstrb = wstrb.read();
		}

		~WData()
		{
			delete m_wt;
			m_wt = NULL;
		}

		bool IsWLast() { return m_wlast; }
		uint32_t GetWID() { return m_wid; }

		sc_bv<T::DATA_W/8> &GetWstrb() { return m_wstrb; }

		void SetTransaction(Transaction *wt) { m_wt = wt; }
		Transaction *GetTransaction() { return m_wt; }

	private:
		uint32_t m_wid;
		sc_bv<T::DATA_W/8> m_wstrb;
		bool m_wlast;

		Transaction *m_wt;
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
					m_pc.GetVersion());
	}

	WData* SampleWDataSignals()
	{
		// AXI4 ignores WID
		return new WData(to_uint(wid), wstrb, wlast.read());
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

	WData *GetFirst(std::list<WData*>& trList,
				uint32_t id)
	{
		for (typename std::list<WData*>::iterator it = trList.begin();
			it != trList.end(); it++) {
			WData *wd = (*it);

			if (wd) {
				if (m_pc.GetVersion() == V_AXI3) {
					if (wd->GetWID() == id) {
						return wd;
					}
				} else {
					Transaction *t = wd->GetTransaction();

					if (t && t->GetID() == id) {
						return wd;
					}
				}
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

	Transaction *GetNext()
	{
		if (m_pc.GetVersion()) {
			bool do_order_check = m_cfg.en_wr_tx_data_order_check();
			Transaction *wt = GetFirst(m_wtList, to_uint(wid));

			if (do_order_check && wt) {
				if (!PreviousHaveData(wt->GetID())) {
					SC_REPORT_ERROR(WR_TX_ERROR,
						"The first data item of each "
						"transaction is not in the same "
						"order as the order of the "
						"addresses");
				}
			}

			return wt;
		} else if (!m_wtList.empty()) {
			return m_wtList.front();
		}
		return NULL;
	}

	bool check_axi_resp(Transaction *tr)
	{
		uint8_t resp = to_uint(bresp);

		if (tr && tr->GetE()) {
			// Accept AXI_OKAY as non error
			return resp == AXI_EXOKAY || resp == AXI_OKAY;
		}
		return resp == AXI_OKAY;
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

	void ClearList(std::list<WData*>& l)
	{
		for (typename std::list<WData*>::iterator it = l.begin();
			it != l.end(); it++) {
			WData *t = (*it);
			delete t;
		}
		l.clear();
	}

	void process_aw_w_axi4()
	{
		while (!m_wtList.empty() && !m_wdataList.empty()) {
			Transaction *wt = GetNext();
			WData *wd =  m_wdataList.front();

			if (m_cfg.en_wstrb_check()) {
				bool allow_gaps = m_cfg.allow_wstrb_gaps();

				if(!wt->CheckWstrb(wd->GetWstrb(),
							allow_gaps)) {
					std::ostringstream msg;

					msg << "wstrb not following "
						<< "expected format";

					wt->ReportError(msg);
				}
			}

			wt->IncBeat();

			if (wd->IsWLast()) {
				//
				// Check that wlast matches Done()
				//
				if (m_cfg.en_wr_bursts_check()) {
					std::ostringstream msg;

					msg << "Error on data burst length "
						<< "or wlast identified "
						<< "on write data channel";

					if (!wt->Done()) {
						wt->ReportError(msg);
					}
				}

				//
				// Transaction done (AW signals) but
				// keep for error output
				//
				m_wtList.remove(wt);
				wd->SetTransaction(wt);

				//
				// aw / w phase done,
				// move WData with wlast to the response list
				//
				m_wdataList.remove(wd);

				if (m_respList.size() < m_cfg.max_depth()) {
					m_respList.push_back(wd);
				} else {
					SC_REPORT_ERROR(WR_TX_ERROR,
							"Maximum outstanding "
							"transactions reached");
				}
			} else {
				//
				// WData (without wlast) done
				//
				m_wdataList.remove(wd);
				delete wd;
			}
		}
	}

	void process_aw_w_axi3()
	{
		for (typename
			std::list<Transaction*>::iterator it = m_wtList.begin();
			it != m_wtList.end();) {
			Transaction *wt = (*it);
			WData *wd = GetFirst(m_wdataList, wt->GetID());
			bool done = false;

			while (wd != NULL) {
				if (m_cfg.en_wstrb_check()) {
					std::ostringstream msg;
					bool allow_gaps =
						m_cfg.allow_wstrb_gaps();

					msg << "wstrb not following expected "
						<< "format";

					if(!wt->CheckWstrb(wd->GetWstrb(),
								allow_gaps)) {

						wt->ReportError(msg);
					}
				}

				wt->IncBeat();

				if (wd->IsWLast()) {
					//
					// Check that wlast matches Done()
					//
					if (m_cfg.en_wr_bursts_check()) {
						std::ostringstream msg;

						msg << "Error on data burst "
							<< "length or wlast "
							<< "identified on "
							<< "write data "
							<< "channel";

						if (!wt->Done()) {
							wt->ReportError(msg);
						}
					}

					//
					// Transaction done (AW signals) but
					// keep for error output
					//
					wd->SetTransaction(wt);
					it = m_wtList.erase(it);

					//
					// aw / w phase done,
					// move WData with wlast to the
					// response list
					//
					m_wdataList.remove(wd);

					if (m_respList.size() <
						m_cfg.max_depth()) {
						m_respList.push_back(wd);
					} else {
						SC_REPORT_ERROR(WR_TX_ERROR,
							"Maximum outstanding "
							"transactions reached");
					}

					done = true;
					break;
				} else {
					//
					// WData (without wlast) done
					//
					m_wdataList.remove(wd);
					delete wd;

					// Get next WData
					wd = GetFirst(m_wdataList,
							wt->GetID());
				}
			}

			if (!done) {
				it++;
			}
		}
	}

	void wr_check()
	{
		uint32_t max_wdata_depth = m_cfg.max_depth();

		if (m_pc.GetVersion()) {
			max_wdata_depth *= AXI3_MAX_BURSTLENGTH;
		} else {
			max_wdata_depth *= AXI4_MAX_BURSTLENGTH;
		}

		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());

			if (reset_asserted()) {
				ClearList(m_wtList);
				ClearList(m_wdataList);
				ClearList(m_respList);
				wait_for_reset_release();
				continue;
			}

			if (awvalid.read() && awready.read()) {
				if (m_wtList.size() < m_cfg.max_depth()) {
					m_wtList.push_back(SampleAWSignals());
				} else {
					SC_REPORT_ERROR(WR_TX_ERROR,
							"Maximum outstanding "
							"transactions reached");
				}
			}

			if (wvalid.read() && wready.read()) {
				if (m_wdataList.size() < max_wdata_depth) {
					m_wdataList.push_back(
						SampleWDataSignals());
				} else {
					std::ostringstream msg;

					msg << "Maximum outstanding (wdata) "
						<< "transactions reached";

					SC_REPORT_ERROR(WR_TX_ERROR,
							msg.str().c_str());
				}
			}

			if (m_pc.GetVersion() == V_AXI4) {
				process_aw_w_axi4();
			} else {
				process_aw_w_axi3();
			}

			if (bvalid.read() && bready.read()) {
				WData *wd = GetFirst(m_respList,
							   to_uint(bid));

				if (wd) {
					Transaction *wt = wd->GetTransaction();

					if (m_cfg.en_resp_check()) {
						if (!check_axi_resp(wt)) {
							std::ostringstream msg;

							msg << "Error response"
							<< " identifed, bresp: "
							<< "0x" << std::hex
							<< to_uint(bresp);

							if (wt) {
								wt->ReportError(
									msg);
							} else {
								SC_REPORT_ERROR(
									WR_TX_ERROR,
									msg.str().c_str());
							}
						}
					}

					// Transaction done
					m_respList.remove(wd);
					delete wd;
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
	std::list<WData*> m_wdataList;
	std::list<WData*> m_respList;
};

AXI_CHECKER(check_addr_alignment)
{
public:
	AXI_CHECKER_CTOR(check_addr_alignment)
	{
		if (enabled()) {
			SC_THREAD(addr_alignment_check);
		}
	}

private:
	bool enabled()
	{
		if (m_cfg.en_addr_align_check() ||
			m_cfg.en_valid_axlen_check()) {
			return true;
		}

		return false;
	}

	bool check_address_alignment(uint64_t addr, uint8_t axburst,
					uint8_t axsize, uint8_t axlen)
	{
		uint32_t numberBytes = (1 << axsize);
		uint32_t burstlen = axlen + 1;
		uint64_t mask_4k = ~(4096 - 1);
		uint64_t aligned_addr;
		uint64_t last_addr;
		uint64_t end_addr;
		bool ret = true;

		aligned_addr = (addr / numberBytes) * numberBytes;

		switch (axburst) {
		case AXI_BURST_WRAP:
			ret = aligned_addr == addr;
			break;
		case AXI_BURST_INCR:
			end_addr = aligned_addr + burstlen * numberBytes;
			// Compute the last address accessed by this transfer.
			last_addr = end_addr - 1;

			// AXI transactions are not allowed to cross 4K regions.
			ret = (aligned_addr & mask_4k) == (last_addr & mask_4k);
			break;
		default:
			break;
		}
		return ret;
	}

	bool check_burst_length(uint8_t axburst, uint32_t axlen)
	{
		if (axburst == AXI_BURST_WRAP) {
			uint32_t burstlen = axlen + 1;

			switch(burstlen) {
			case 2:
			case 4:
			case 8:
			case 16:
				return true;
			default:
				return false;
			}
		}

		return true;
	}

	void check_rd_tx()
	{

		if (m_cfg.en_valid_axlen_check()) {
			if (!check_burst_length(to_uint(arburst),
						to_uint(arlen))) {
				std::ostringstream msg;

				msg << "Read burst length: "
					<< std::dec << (to_uint(arlen) + 1)
					<< " error with AXI burst type: "
					<< std::hex << to_uint(arburst)
					<< endl;

				SC_REPORT_ERROR(ADDR_ALINGMENT_ERROR,
						msg.str().c_str());
			}
		}

		if (m_cfg.en_addr_align_check()) {
			if (!check_address_alignment(
					to_uint(araddr),
					to_uint(arburst),
					to_uint(arsize),
					to_uint(arlen))) {
				std::ostringstream msg;

				msg << "Read address: "
					<< std::hex << to_uint(araddr)
					<< " wrongly aligned/sized with AXI burst type: "
					<< std::hex << to_uint(arburst)
					<< " and transfer size: "
					<< std::dec << to_uint(arsize)
					<< endl;

				SC_REPORT_ERROR(ADDR_ALINGMENT_ERROR,
						msg.str().c_str());
			}
		}
	}

	void check_wr_tx()
	{
		if (m_cfg.en_valid_axlen_check()) {
			if (!check_burst_length(to_uint(awburst),
						to_uint(awlen))) {
				std::ostringstream msg;

				msg << "Write burst length: "
					<< std::dec << (to_uint(awlen) + 1)
					<< " error with AXI burst type: "
					<< std::hex << to_uint(awburst)
					<< endl;

				SC_REPORT_ERROR(ADDR_ALINGMENT_ERROR,
						msg.str().c_str());
			}
		}

		if (m_cfg.en_addr_align_check()) {
			if (!check_address_alignment(
					awaddr.read().to_uint64(),
					to_uint(awburst),
					to_uint(awsize),
					to_uint(awlen))) {
				std::ostringstream msg;

				msg << "Write address: "
					<< std::hex << awaddr.read().to_uint64()
					<< "wrongly aligned/sized with AXI burst type: "
					<< std::hex << to_uint(awburst)
					<< "and transfer size: "
					<< std::dec << to_uint(awsize)
					<< endl;

				SC_REPORT_ERROR(ADDR_ALINGMENT_ERROR,
						msg.str().c_str());
			}
		}
	}

	void addr_alignment_check()
	{
		while (true) {
			wait(clk.posedge_event() | resetn.negedge_event());

			if (reset_asserted()) {
				wait_for_reset_release();
				continue;
			}

			if (arvalid.read() && arready.read()) {
				check_rd_tx();
			}

			if (awvalid.read() && awready.read()) {
				check_wr_tx();
			}
		}
	}

	enum { MAX_AxSIZE = 8 };
};

AXI_CHECKER(check_axi_handshakes)
{
public:
	AXI_CHECKER_CTOR(check_axi_handshakes)
	{
		if (m_cfg.en_handshakes_check()) {
			SC_THREAD(axi_handshakes_check);
		}
	}

private:
	template<typename PC>
	class IAxLen
	{
	public:
		IAxLen(PC& pc) :
			m_pc(pc)
		{}

		bool hasData() { return true; }

		uint32_t get_arlen() { return to_uint(m_pc.arlen); }
		uint32_t get_awlen() { return to_uint(m_pc.awlen); }
		bool get_wlast() { return m_pc.wlast.read(); }

		uint32_t get_awid() { return to_uint(m_pc.awid); }
		uint32_t get_wid() { return to_uint(m_pc.wid); }
		uint32_t get_bid() { return to_uint(m_pc.bid); }

		bool is_axi3() { return m_pc.GetVersion() == V_AXI3; }
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
};

AXI_CHECKER(check_axi_reset)
{
public:
	AXI_CHECKER_CTOR(check_axi_reset)
	{
		if (m_cfg.en_reset_check()) {
			SC_THREAD(axi_reset_check);
		}
	}

private:
	void axi_reset_check()
	{
		axi_reset_checker checker(this);

		checker.run();
	}
};

#endif

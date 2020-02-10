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
 */
#ifndef SIGNALGENERATOR_H
#define SIGNALGENERATOR_H

#include <tlm-bridges/private/chi/pkts.h>

#define SG_CHI_CH(name, flit_width)		\
sc_out<bool > name ## flitpend;			\
sc_out<bool > name ## flitv;			\
sc_out<sc_bv<flit_width> > name ## flit;	\
sc_out<bool > name ## lcrdv

enum { RxDat, TxDat };
enum { RxRsp, TxRsp };

#define TESTCASE(x)			\
{					\
std::cout << " * " << #x << std::endl;	\
x();					\
m_s->verify_error(#x " failed", false);	\
}

#define TESTCASE_NEG(x) 		\
{					\
std::cout << " * " << #x << std::endl;	\
x();					\
m_s->verify_error(#x " failed", true);	\
}

#define SIGGEN_RUN(TS)			\
template<				\
	int DATA_WIDTH,			\
	int ADDR_WIDTH,			\
	int NODEID_WIDTH,		\
	int RSVDC_WIDTH,		\
	int DATACHECK_WIDTH,		\
	int POISON_WIDTH,		\
	int DAT_OPCODE_WIDTH>		\
void SignalGen< 			\
		DATA_WIDTH,		\
		ADDR_WIDTH,		\
		NODEID_WIDTH,		\
		RSVDC_WIDTH,		\
		DATACHECK_WIDTH,	\
		POISON_WIDTH,		\
		DAT_OPCODE_WIDTH>::		\
run()					\
{					\
	TS<SigGenT> suite(this);	\
	suite.run_tests();		\
}

template<
	int DATA_WIDTH = 512,
	int ADDR_WIDTH = 44,
	int NODEID_WIDTH = 7,
	int RSVDC_WIDTH = 32,
	int DATACHECK_WIDTH = 64,
	int POISON_WIDTH = 8,
	int DAT_OPCODE_WIDTH = Dat::Opcode_Width>
class SignalGen : public sc_core::sc_module
{
public:

	typedef SignalGen<
			DATA_WIDTH,
			ADDR_WIDTH,
			NODEID_WIDTH,
			RSVDC_WIDTH,
			DATACHECK_WIDTH,
			POISON_WIDTH,
			DAT_OPCODE_WIDTH> SigGenT;

	enum {
		DATA_W = DATA_WIDTH,
		ADDR_W = ADDR_WIDTH,
		NODEID_W = NODEID_WIDTH,
		RSVDC_W = RSVDC_WIDTH,
		DATACHECK_W = DATACHECK_WIDTH,
		POISON_W = POISON_WIDTH
		};

	typedef BRIDGES::ReqPkt< ADDR_WIDTH,
			NODEID_WIDTH,
			RSVDC_WIDTH> ReqPkt_t;

	typedef BRIDGES::RspPkt<NODEID_WIDTH> RspPkt_t;

	// lsb 3 bits on address not used
	typedef BRIDGES::SnpPkt<ADDR_WIDTH-3, NODEID_WIDTH> SnpPkt_t;

	typedef BRIDGES::DatPkt< DATA_WIDTH,
			NODEID_WIDTH,
			RSVDC_WIDTH,
			DATACHECK_WIDTH,
			POISON_WIDTH,
			DAT_OPCODE_WIDTH> DatPkt_t;

	enum {
		TXREQ_FLIT_W = ReqPkt_t::FLIT_WIDTH,
		TXRSP_FLIT_W = RspPkt_t::FLIT_WIDTH,
		TXDAT_FLIT_W = DatPkt_t::FLIT_WIDTH,

		RXRSP_FLIT_W = RspPkt_t::FLIT_WIDTH,
		RXDAT_FLIT_W = DatPkt_t::FLIT_WIDTH,
		RXSNP_FLIT_W = SnpPkt_t::FLIT_WIDTH,
		};

	sc_in<bool> clk;
	sc_out<bool> resetn;

	sc_out<bool > txsactive;
	sc_out<bool > rxsactive;

	//
	// RN-F TX link
	//
	sc_out<bool > txlinkactivereq;
	sc_out<bool > txlinkactiveack;

	// Generate TX channels
	SG_CHI_CH(txreq, TXREQ_FLIT_W);
	SG_CHI_CH(txrsp, TXRSP_FLIT_W);
	SG_CHI_CH(txdat, TXDAT_FLIT_W);

	//
	// RN-F RX link
	//
	sc_out<bool > rxlinkactivereq;
	sc_out<bool > rxlinkactiveack;

	// Generate RX channels
	SG_CHI_CH(rxrsp, RXRSP_FLIT_W);
	SG_CHI_CH(rxdat, RXDAT_FLIT_W);
	SG_CHI_CH(rxsnp, RXSNP_FLIT_W);

	SC_HAS_PROCESS(SignalGen);
	SignalGen(sc_core::sc_module_name name) :
		sc_module(name),

		clk("clk"),
		resetn("resetn"),

		txsactive("txsactive"),
		rxsactive("rxsactive"),

		txlinkactivereq("txlinkactivereq"),
		txlinkactiveack("txlinkactiveack"),

		// Init TX channels
		CHI_INIT_CH(txreq),
		CHI_INIT_CH(txrsp),
		CHI_INIT_CH(txdat),

		rxlinkactivereq("rxlinkactivereq"),
		rxlinkactiveack("rxlinkactiveack"),

		// Init RX channels
		CHI_INIT_CH(rxrsp),
		CHI_INIT_CH(rxdat),
		CHI_INIT_CH(rxsnp)
	{
		sc_report_handler::set_handler(error_handler);

		SC_THREAD(run);
	}

	static std::vector<std::string>& GetMessageTypes()
	{
		static std::vector<std::string> msg_types;

		return msg_types;
	}

	static void SetMessageType(std::string msg_type)
	{
		GetMessageTypes().push_back(msg_type);
	}

	static bool InMessageTypes(std::string& msg_type)
	{
		std::vector<std::string>::iterator it =
				GetMessageTypes().begin();

		for (; it != GetMessageTypes().end(); it++) {
			if (msg_type == (*it)) {
				return true;
			}
		}
		return false;
	}

	static bool& Error()
	{
		static bool error = false;

		return error;
	}

	static bool& Debug()
	{
		static bool debug = false;

		return debug;
	}

	static void error_handler(const sc_report& rep, const sc_actions& ac)
	{
		std::string msg_type(rep.get_msg_type());

		if (Error() == false && Debug()) {
			cout << endl << rep.get_msg() << endl << endl;
		}

		if (InMessageTypes(msg_type)) {
			Error() = true;
		} else {
			sc_report_handler::default_handler(rep, ac);
		}
	}

	void verify_error(std::string str, bool val)
	{
		if (Error() != val) {
			SC_REPORT_ERROR("chi-pc-test", str.c_str());
		}
		Error() = false;
	}

	void GenerateDatFlit(	int dir,
				uint8_t QoS = 0,
				uint16_t TgtID = 0,
				uint16_t SrcID = 0,
				uint8_t TxnID = 0,
				uint16_t HomeNID = 0,
				uint8_t Opcode = 0,
				uint8_t RespErr = 0,
				uint8_t Resp = 0,
				uint8_t FwdState_DataPull_DataSource = 0,
				uint8_t DBID = 0,
				uint8_t CCID = 0,
				uint8_t DataID = 0,
				bool TraceTag = 0,
				uint32_t RSVDC = 0,
				uint64_t DataCheck = 0,
				uint8_t Poison = 0)
	{
		sc_bv<DatPkt_t::FLIT_WIDTH> tmp;

		m_pos = 0;

		Set(tmp, QoS, DatPkt_t::QoS_Width);
		Set(tmp, TgtID, DatPkt_t::TgtID_Width);
		Set(tmp, SrcID, DatPkt_t::SrcID_Width);
		Set(tmp, TxnID, DatPkt_t::TxnID_Width);
		Set(tmp, HomeNID, DatPkt_t::HomeNID_Width);
		Set(tmp, Opcode, DatPkt_t::Opcode_Width);
		Set(tmp, RespErr, DatPkt_t::RespErr_Width);
		Set(tmp, Resp, DatPkt_t::Resp_Width);

		Set(tmp, FwdState_DataPull_DataSource,
			DatPkt_t::FwdState_DataPull_DataSource_Width);

		Set(tmp, DBID, DatPkt_t::DBID_Width);
		Set(tmp, CCID, DatPkt_t::CCID_Width);
		Set(tmp, DataID, DatPkt_t::DataID_Width);
		Set(tmp, TraceTag, DatPkt_t::TraceTag_Width);

		if (RSVDC_WIDTH) {
			Set(tmp, RSVDC, DatPkt_t::RSVDC_Width);
		}

		if (dir == RxDat) {
			rxdatflit.write(tmp);
		} else {
			txdatflit.write(tmp);
		}
	}

	void GenerateSnpFlit( uint8_t QoS = 0,
		uint16_t SrcID = 0,
		uint8_t TxnID = 0,
		uint16_t FwdNID = 0,
		uint8_t FwdTxnID = 0,
		uint8_t Opcode = 0,
		uint64_t Address = 0,
		bool NonSecure = 0,
		bool DoNotGoToSD = 0,
		bool RetToSrc = 0,
		bool TraceTag = 0)
	{
		sc_bv<SnpPkt_t::FLIT_WIDTH> tmp;

		m_pos = 0;

		Set(tmp, QoS, SnpPkt_t::QoS_Width);
		Set(tmp, SrcID, SnpPkt_t::SrcID_Width);
		Set(tmp, TxnID, SnpPkt_t::TxnID_Width);
		Set(tmp, FwdNID, SnpPkt_t::FwdNID_Width);
		Set(tmp, FwdTxnID, SnpPkt_t::FwdTxnID_Width);
		Set(tmp, Opcode, SnpPkt_t::Opcode_Width);
		Set(tmp, Address >> 3, SnpPkt_t::Addr_Width);
		Set(tmp, NonSecure, SnpPkt_t::NS_Width);
		Set(tmp, DoNotGoToSD, SnpPkt_t::DoNotGoToSD_Width);
		Set(tmp, RetToSrc, SnpPkt_t::RetToSrc_Width);
		Set(tmp, TraceTag, SnpPkt_t::TraceTag_Width);

		rxsnpflit.write(tmp);
	}

	void GenerateRspFlit( int dir,
		uint8_t QoS = 0,
		uint16_t TgtID = 0,
		uint16_t SrcID = 0,
		uint8_t TxnID = 0,
		uint8_t Opcode = 0,
		uint8_t RespErr = 0,
		uint8_t Resp = 0,
		uint8_t FwdState_DataPull = 0,
		uint8_t DBID = 0,
		uint8_t PCrdType = 0,
		bool TraceTag = 0)
	{
		sc_bv<RspPkt_t::FLIT_WIDTH> tmp;

		m_pos = 0;

		Set(tmp, QoS, RspPkt_t::QoS_Width);
		Set(tmp, TgtID, RspPkt_t::TgtID_Width);
		Set(tmp, SrcID, RspPkt_t::SrcID_Width);
		Set(tmp, TxnID, RspPkt_t::TxnID_Width);
		Set(tmp, Opcode, RspPkt_t::Opcode_Width);
		Set(tmp, RespErr, RspPkt_t::RespErr_Width);
		Set(tmp, Resp, RspPkt_t::Resp_Width);

		Set(tmp, FwdState_DataPull,
			RspPkt_t::FwdState_DataPull_Width);

		Set(tmp, DBID, RspPkt_t::DBID_Width);
		Set(tmp, PCrdType, RspPkt_t::PCrdType_Width);
		Set(tmp, TraceTag, RspPkt_t::TraceTag_Width);

		if (dir == RxRsp) {
			rxrspflit.write(tmp);
		} else {
			txrspflit.write(tmp);
		}
	}

	void GenerateReqFlit( uint8_t QoS = 0,
		uint16_t TgtID = 0,
		uint16_t SrcID = 0,
		uint8_t TxnID = 0,
		uint16_t ReturnNID_StashNID = 0,
		bool StashNIDValid_Endian = 0,
		uint8_t ReturnTxnID = 0,
		uint8_t Opcode = 0,
		uint32_t Size = 0,
		uint64_t Address = 0,
		bool NonSecure = 0,
		bool LikelyShared = 0,
		bool AllowRetry = 0,
		uint8_t Order = 0,
		uint8_t PCrdType = 0,
		bool Allocate = 0,
		bool Cacheable = 0,
		bool DeviceMemory = 0,
		bool EarlyWrAck = 0,
		bool SnpAttr = 0,
		uint16_t LPID = 0,
		bool Excl_SnoopMe = 0,
		bool ExpCompAck = 0,
		bool TraceTag = 0,
		uint32_t RSVDC = 0)
	{
		sc_bv<ReqPkt_t::FLIT_WIDTH> tmp;

		m_pos = 0;

		Set(tmp, QoS, ReqPkt_t::QoS_Width);
		Set(tmp, TgtID, ReqPkt_t::TgtID_Width);
		Set(tmp, SrcID, ReqPkt_t::SrcID_Width);
		Set(tmp, TxnID, ReqPkt_t::TxnID_Width);

		Set(tmp, ReturnNID_StashNID,
				ReqPkt_t::ReturnNID_StashNID_Width);

		Set(tmp, StashNIDValid_Endian,
				ReqPkt_t::StashNIDValid_Endian_Width);

		//
		// For stash transactions ReturnTxnID contains
		// { [7:6]: 0b00, StashLPIDValid[5], StashLPID[4:0] }
		//
		Set(tmp, ReturnTxnID,
				ReqPkt_t::ReturnTxnID_Width);

		Set(tmp, Opcode, ReqPkt_t::Opcode_Width);
		Set(tmp, Size, ReqPkt_t::Size_Width);
		Set(tmp, Address, ReqPkt_t::Addr_Width);
		Set(tmp, NonSecure, ReqPkt_t::NS_Width);
		Set(tmp, LikelyShared,
				ReqPkt_t::LikelyShared_Width);
		Set(tmp, AllowRetry, ReqPkt_t::AllowRetry_Width);
		Set(tmp, Order, ReqPkt_t::Order_Width);
		Set(tmp, PCrdType, ReqPkt_t::PCrdType_Width);

		Set(tmp, GetMemAttr(Allocate,
					Cacheable,
					DeviceMemory,
					EarlyWrAck), ReqPkt_t::MemAttr_Width);

		Set(tmp, SnpAttr, ReqPkt_t::SnpAttr_Width);
		Set(tmp, LPID, ReqPkt_t::LPID_Width);

		Set(tmp, Excl_SnoopMe,
				ReqPkt_t::ExclSnoopMe_Width);

		Set(tmp, ExpCompAck, ReqPkt_t::ExpCompAck_Width);
		Set(tmp, TraceTag, ReqPkt_t::TraceTag_Width);

		if (RSVDC_WIDTH) {
			Set(tmp, RSVDC, RSVDC_WIDTH);
		}

		txreqflit.write(tmp);
	}

	enum {
		AllocateShift = 3,
		CacheableShift = 2,
		DeviceMemoryShift = 1,
		EarlyWrAckShift = 0
	};

	uint8_t GetMemAttr(bool Allocate,
				bool Cacheable,
				bool DeviceMemory,
				bool EarlyWrAck)
	{
		uint8_t memattr;

		memattr = (Allocate << AllocateShift) |
			(Cacheable << CacheableShift) |
			(DeviceMemory << DeviceMemoryShift) |
			(EarlyWrAck << EarlyWrAckShift);

		return memattr;
	}

	template<typename T1, typename T2>
	void Set(T1& flit, T2 val, unsigned int width)
	{
		unsigned int firstbit = m_pos;
		unsigned int lastbit = firstbit + width - 1;
		T2 mask = (1 << width) - 1;

		flit.range(lastbit, firstbit) = val & mask;

		m_pos += width;
	}

	template<typename T>
	void Set(T& flit, bool val, unsigned int width)
	{
		flit.bit(m_pos) = val;
		m_pos += width;
	}

	void run();

	unsigned int m_pos;
};

#define SIGGEN_TESTSUITE(name)	\
template<typename T>		\
class name

#define SIGGEN_TESTSUITE_CTOR(name)			\
public:							\
	sc_in<bool>& clk;				\
	sc_out<bool>& resetn;				\
							\
	sc_out<bool >& txsactive;			\
	sc_out<bool >& rxsactive;			\
							\
	sc_out<bool >& txlinkactivereq;			\
	sc_out<bool >& txlinkactiveack;			\
							\
	sc_out<bool >& txreqflitpend;			\
	sc_out<bool >& txreqflitv;			\
	sc_out<sc_bv<T::TXREQ_FLIT_W> >& txreqflit;	\
	sc_out<bool >& txreqlcrdv;			\
							\
	sc_out<bool >& txrspflitpend;			\
	sc_out<bool >& txrspflitv;			\
	sc_out<sc_bv<T::TXRSP_FLIT_W> >& txrspflit;	\
	sc_out<bool >& txrsplcrdv;			\
							\
	sc_out<bool >& txdatflitpend;			\
	sc_out<bool >& txdatflitv;			\
	sc_out<sc_bv<T::TXDAT_FLIT_W> >& txdatflit;	\
	sc_out<bool >& txdatlcrdv;			\
							\
	sc_out<bool >& rxlinkactivereq;			\
	sc_out<bool >& rxlinkactiveack;			\
							\
	sc_out<bool >& rxrspflitpend;			\
	sc_out<bool >& rxrspflitv;			\
	sc_out<sc_bv<T::RXRSP_FLIT_W> >& rxrspflit;	\
	sc_out<bool >& rxrsplcrdv;			\
							\
	sc_out<bool >& rxdatflitpend;			\
	sc_out<bool >& rxdatflitv;			\
	sc_out<sc_bv<T::RXDAT_FLIT_W> >& rxdatflit;	\
	sc_out<bool >& rxdatlcrdv;			\
							\
	sc_out<bool >& rxsnpflitpend;			\
	sc_out<bool >& rxsnpflitv;			\
	sc_out<sc_bv<T::RXSNP_FLIT_W> >& rxsnpflit;	\
	sc_out<bool >& rxsnplcrdv;			\
							\
	T *m_s;						\
							\
	template<typename EVENT>			\
	void wait(EVENT& e) { sc_core::wait(e); }	\
							\
	void SetMessageType(std::string m_type)		\
	{						\
		m_s->SetMessageType(m_type);		\
	}						\
							\
	name(T *s) :					\
		clk(s->clk),				\
		resetn(s->resetn),			\
		txsactive(s->txsactive),		\
		rxsactive(s->rxsactive),		\
		txlinkactivereq(s->txlinkactivereq),	\
		txlinkactiveack(s->txlinkactiveack),	\
		txreqflitpend(s->txreqflitpend),	\
		txreqflitv(s->txreqflitv),		\
		txreqflit(s->txreqflit),		\
		txreqlcrdv(s->txreqlcrdv),		\
		txrspflitpend(s->txrspflitpend),	\
		txrspflitv(s->txrspflitv),		\
		txrspflit(s->txrspflit),		\
		txrsplcrdv(s->txrsplcrdv),		\
		txdatflitpend(s->txdatflitpend),	\
		txdatflitv(s->txdatflitv),		\
		txdatflit(s->txdatflit),		\
		txdatlcrdv(s->txdatlcrdv),		\
		rxlinkactivereq(s->rxlinkactivereq),	\
		rxlinkactiveack(s->rxlinkactiveack),	\
		rxrspflitpend(s->rxrspflitpend),	\
		rxrspflitv(s->rxrspflitv),		\
		rxrspflit(s->rxrspflit),		\
		rxrsplcrdv(s->rxrsplcrdv),		\
		rxdatflitpend(s->rxdatflitpend),	\
		rxdatflitv(s->rxdatflitv),		\
		rxdatflit(s->rxdatflit),		\
		rxdatlcrdv(s->rxdatlcrdv),		\
		rxsnpflitpend(s->rxsnpflitpend),	\
		rxsnpflitv(s->rxsnpflitv),		\
		rxsnpflit(s->rxsnpflit),		\
		rxsnplcrdv(s->rxsnplcrdv),		\
		m_s(s)



#endif /* SIGNALGENERATOR_H */

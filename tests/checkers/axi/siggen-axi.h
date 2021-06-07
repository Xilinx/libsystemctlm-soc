/*
 * Copyright (c) 2018 Xilinx Inc.
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

#define TESTCASE(x)			\
{					\
std::cout << " * " << #x << std::endl;	\
x();					\
}

#define TESTCASE_NEG(x) 		\
{					\
std::cout << " * " << #x << std::endl;	\
x();					\
m_s->verify_error(#x " failed");	\
}

#define SIGGEN_RUN(TS)			\
template				\
<int ADDR_WIDTH,			\
	int DATA_WIDTH,			\
	int ID_WIDTH,			\
	int AxLEN_WIDTH,		\
	int AxLOCK_WIDTH,		\
	int AWUSER_WIDTH,		\
	int ARUSER_WIDTH,		\
	int WUSER_WIDTH,		\
	int RUSER_WIDTH,		\
	int BUSER_WIDTH>		\
void SignalGen< ADDR_WIDTH,		\
		DATA_WIDTH,		\
		ID_WIDTH,		\
		AxLEN_WIDTH,		\
		AxLOCK_WIDTH,		\
		AWUSER_WIDTH,		\
		ARUSER_WIDTH,		\
		WUSER_WIDTH, 		\
		RUSER_WIDTH, 		\
		BUSER_WIDTH>::		\
run()					\
{					\
	TS<SigGenT> suite(this);	\
	suite.run_tests();		\
}

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
	int BUSER_WIDTH = 2>
class SignalGen : public sc_core::sc_module
{
public:
	enum {	ADDR_W = ADDR_WIDTH,
		DATA_W = DATA_WIDTH,
		ID_W = ID_WIDTH,
		AxLEN_W = AxLEN_WIDTH,
		AxLOCK_W = AxLOCK_WIDTH,
		AWUSER_W = AWUSER_WIDTH,
		ARUSER_W = ARUSER_WIDTH,
		WUSER_W = WUSER_WIDTH,
		RUSER_W = RUSER_WIDTH,
		BUSER_W = BUSER_WIDTH };

	typedef SignalGen<
			ADDR_WIDTH,
			DATA_WIDTH,
			ID_WIDTH,
			AxLEN_WIDTH,
			AxLOCK_WIDTH,
			AWUSER_WIDTH,
			ARUSER_WIDTH,
			WUSER_WIDTH,
			RUSER_WIDTH,
			BUSER_WIDTH> SigGenT;

	sc_in<bool> clk;
	sc_out<bool> resetn;

	/* Write address channel.  */
	sc_out<bool> awvalid;
	sc_out<bool> awready;
	sc_out<sc_bv<ADDR_WIDTH> > awaddr;
	sc_out<sc_bv<3> > awprot;
	sc_out<AXISignal(AWUSER_WIDTH) > awuser;	// AXI4 only
	sc_out<sc_bv<4> > awregion; 			// AXI4 only
	sc_out<sc_bv<4> > awqos;			// AXI4 only
	sc_out<sc_bv<4> > awcache;
	sc_out<sc_bv<2> > awburst;
	sc_out<sc_bv<3> > awsize;
	sc_out<AXISignal(AxLEN_WIDTH) > awlen;
	sc_out<AXISignal(ID_WIDTH) > awid;
	sc_out<AXISignal(AxLOCK_WIDTH) > awlock;

	/* Write data channel.  */
	sc_out<AXISignal(ID_WIDTH) > wid;	// AXI3 only
	sc_out<bool> wvalid;
	sc_out<bool> wready;
	sc_out<sc_bv<DATA_WIDTH> > wdata;
	sc_out<sc_bv<DATA_WIDTH/8> > wstrb;
	sc_out<AXISignal(WUSER_WIDTH) > wuser;	// AXI4 only
	sc_out<bool> wlast;

	/* Write response channel.  */
	sc_out<bool> bvalid;
	sc_out<bool> bready;
	sc_out<sc_bv<2> > bresp;
	sc_out<AXISignal(BUSER_WIDTH) > buser;	// AXI4 only
	sc_out<AXISignal(ID_WIDTH) > bid;

	/* Read address channel.  */
	sc_out<bool> arvalid;
	sc_out<bool> arready;
	sc_out<sc_bv<ADDR_WIDTH> > araddr;
	sc_out<sc_bv<3> > arprot;
	sc_out<AXISignal(ARUSER_WIDTH) > aruser;	// AXI4 only
	sc_out<sc_bv<4> > arregion;		// AXI4 only
	sc_out<sc_bv<4> > arqos;			// AXI4 only
	sc_out<sc_bv<4> > arcache;
	sc_out<sc_bv<2> > arburst;
	sc_out<sc_bv<3> > arsize;
	sc_out<AXISignal(AxLEN_WIDTH) > arlen;
	sc_out<AXISignal(ID_WIDTH) > arid;
	sc_out<AXISignal(AxLOCK_WIDTH) > arlock;

	/* Read data channel.  */
	sc_out<bool> rvalid;
	sc_out<bool> rready;
	sc_out<sc_bv<DATA_WIDTH> > rdata;
	sc_out<sc_bv<2> > rresp;
	sc_out<AXISignal(RUSER_WIDTH) > ruser;	// AXI4 only
	sc_out<AXISignal(ID_WIDTH) > rid;
	sc_out<bool> rlast;

	SC_HAS_PROCESS(SignalGen);
	SignalGen(sc_core::sc_module_name name,
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
		dummy("axi_dummy")
	{
		sc_report_handler::set_handler(error_handler);

		SC_THREAD(run);
	}

	static std::string& GetMessageType()
	{
		static std::string msg_type;

		return msg_type;
	}

	static void SetMessageType(std::string msg_type)
	{
		std::string& m_msg_type = GetMessageType();

		m_msg_type = msg_type;
	}

	static bool& Error()
	{
		static bool error = false;

		return error;
	}

	static void error_handler(const sc_report& rep, const sc_actions& ac)
	{
		std::string& m_msg_type = GetMessageType();
		std::string msg_type(rep.get_msg_type());

		if (m_msg_type == msg_type) {
			Error() = true;
		} else {
			sc_report_handler::default_handler(rep, ac);
		}
	}

	void verify_error(std::string str)
	{
		if (Error() != true) {
			SC_REPORT_ERROR("axi-pc-test", str.c_str());
		}
		Error() = false;
	}

	void run();

private:

	class axi_dummy : public sc_core::sc_module {
	public:
		// AXI4
		sc_signal<sc_bv<ID_WIDTH> > wid;

		// AXI3
		sc_signal<sc_bv<4>> awqos;
		sc_signal<sc_bv<4>> awregion;
		sc_signal<sc_bv<AWUSER_WIDTH>> awuser;
		sc_signal<sc_bv<WUSER_WIDTH>> wuser;
		sc_signal<sc_bv<BUSER_WIDTH>> buser;
		sc_signal<sc_bv<4>> arregion;
		sc_signal<sc_bv<4>> arqos;
		sc_signal<sc_bv<ARUSER_WIDTH>> aruser;
		sc_signal<sc_bv<RUSER_WIDTH>> ruser;

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
		{ }
	};

	void bind_dummy(void)
	{
		if (m_version == V_AXI4) {
			wid(dummy.wid);
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

	AXIVersion m_version;
	axi_dummy dummy;
};

#define SIGGEN_TESTSUITE(name)	\
template<typename T>		\
class name

#define SIGGEN_TESTSUITE_CTOR(name)			\
public:							\
	sc_in<bool>& clk;				\
	sc_out<bool>& resetn;				\
	sc_out<bool>& awvalid;				\
	sc_out<bool>& awready;				\
	sc_out<sc_bv<T::ADDR_W> >& awaddr;		\
	sc_out<sc_bv<3> >& awprot;			\
	sc_out<AXISignal(T::AWUSER_W) >& awuser;	\
	sc_out<sc_bv<4> >& awregion;			\
	sc_out<sc_bv<4> >& awqos;			\
	sc_out<sc_bv<4> >& awcache;			\
	sc_out<sc_bv<2> >& awburst;			\
	sc_out<sc_bv<3> >& awsize;			\
	sc_out<AXISignal(T::AxLEN_W) >& awlen;		\
	sc_out<AXISignal(T::ID_W) >& awid;		\
	sc_out<AXISignal(T::AxLOCK_W) >& awlock;	\
	sc_out<AXISignal(T::ID_W) >& wid;		\
	sc_out<bool>& wvalid;				\
	sc_out<bool>& wready;				\
	sc_out<sc_bv<T::DATA_W> >& wdata;		\
	sc_out<sc_bv<T::DATA_W/8> >& wstrb;		\
	sc_out<AXISignal(T::WUSER_W) >& wuser;		\
	sc_out<bool>& wlast;				\
	sc_out<bool>& bvalid;				\
	sc_out<bool>& bready;				\
	sc_out<sc_bv<2> >& bresp;			\
	sc_out<AXISignal(T::BUSER_W) >& buser;		\
	sc_out<AXISignal(T::ID_W) >& bid;		\
	sc_out<bool>& arvalid;				\
	sc_out<bool>& arready;				\
	sc_out<sc_bv<T::ADDR_W> >& araddr;		\
	sc_out<sc_bv<3> >& arprot;			\
	sc_out<AXISignal(T::ARUSER_W) >& aruser;	\
	sc_out<sc_bv<4> >& arregion;			\
	sc_out<sc_bv<4> >& arqos;			\
	sc_out<sc_bv<4> >& arcache;			\
	sc_out<sc_bv<2> >& arburst;			\
	sc_out<sc_bv<3> >& arsize;			\
	sc_out<AXISignal(T::AxLEN_W) >& arlen;		\
	sc_out<AXISignal(T::ID_W) >& arid;		\
	sc_out<AXISignal(T::AxLOCK_W) >& arlock;	\
	sc_out<bool>& rvalid;				\
	sc_out<bool>& rready;				\
	sc_out<sc_bv<T::DATA_W> >& rdata;		\
	sc_out<sc_bv<2> >& rresp;			\
	sc_out<AXISignal(T::RUSER_W) >& ruser;		\
	sc_out<AXISignal(T::ID_W) >& rid;		\
	sc_out<bool>& rlast;				\
	T *m_s;						\
							\
	template<typename EVENT>			\
	void wait(EVENT& e) { sc_core::wait(e); }	\
							\
	name(T *s) :					\
		clk(s->clk),				\
		resetn(s->resetn),			\
		awvalid(s->awvalid),			\
		awready(s->awready),			\
		awaddr(s->awaddr),			\
		awprot(s->awprot),			\
		awuser(s->awuser),			\
		awregion(s->awregion),			\
		awqos(s->awqos),			\
		awcache(s->awcache),			\
		awburst(s->awburst),			\
		awsize(s->awsize),			\
		awlen(s->awlen),			\
		awid(s->awid),				\
		awlock(s->awlock),			\
		wid(s->wid),				\
		wvalid(s->wvalid),			\
		wready(s->wready),			\
		wdata(s->wdata),			\
		wstrb(s->wstrb),			\
		wuser(s->wuser),			\
		wlast(s->wlast),			\
		bvalid(s->bvalid),			\
		bready(s->bready),			\
		bresp(s->bresp),			\
		buser(s->buser),			\
		bid(s->bid),				\
		arvalid(s->arvalid),			\
		arready(s->arready),			\
		araddr(s->araddr),			\
		arprot(s->arprot),			\
		aruser(s->aruser),			\
		arregion(s->arregion),			\
		arqos(s->arqos),			\
		arcache(s->arcache),			\
		arburst(s->arburst),			\
		arsize(s->arsize),			\
		arlen(s->arlen),			\
		arid(s->arid),				\
		arlock(s->arlock),			\
		rvalid(s->rvalid),			\
		rready(s->rready),			\
		rdata(s->rdata),			\
		rresp(s->rresp),			\
		ruser(s->ruser),			\
		rid(s->rid),				\
		rlast(s->rlast),			\
		m_s(s)

#endif /* SIGNALGENERATOR_H */

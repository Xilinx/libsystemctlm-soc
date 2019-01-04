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
<int ADDR_WIDTH, int DATA_WIDTH>	\
void SignalGen< ADDR_WIDTH,		\
		DATA_WIDTH >::		\
run()					\
{					\
	TS<SigGenT> suite(this);	\
	suite.run_tests();		\
}

template
<int ADDR_WIDTH, int DATA_WIDTH >
class SignalGen : public sc_core::sc_module
{
public:
	enum {	ADDR_W = ADDR_WIDTH,
		DATA_W = DATA_WIDTH
		};

	typedef SignalGen< ADDR_WIDTH, DATA_WIDTH > SigGenT;

	sc_in<bool> clk;
	sc_out<bool> resetn;

	/* Write address channel.  */
	sc_out<bool> awvalid;
	sc_out<bool> awready;
	sc_out<sc_bv<ADDR_WIDTH> > awaddr;
	sc_out<sc_bv<3> > awprot;

	/* Write data channel.  */
	sc_out<bool> wvalid;
	sc_out<bool> wready;
	sc_out<sc_bv<DATA_WIDTH> > wdata;
	sc_out<sc_bv<DATA_WIDTH/8> > wstrb;

	/* Write response channel.  */
	sc_out<bool> bvalid;
	sc_out<bool> bready;
	sc_out<sc_bv<2> > bresp;

	/* Read address channel.  */
	sc_out<bool> arvalid;
	sc_out<bool> arready;
	sc_out<sc_bv<ADDR_WIDTH> > araddr;
	sc_out<sc_bv<3> > arprot;

	/* Read data channel.  */
	sc_out<bool> rvalid;
	sc_out<bool> rready;
	sc_out<sc_bv<DATA_WIDTH> > rdata;
	sc_out<sc_bv<2> > rresp;

	SC_HAS_PROCESS(SignalGen);
	SignalGen(sc_core::sc_module_name name) :
		sc_module(name),

		clk("clk"),

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
		rresp("rresp")
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
			SC_REPORT_ERROR("pc-axilite-test", str.c_str());
		}
		Error() = false;
	}

	void run();

private:
	static std::string m_msg_type;
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
	sc_out<bool>& wvalid;				\
	sc_out<bool>& wready;				\
	sc_out<sc_bv<T::DATA_W> >& wdata;		\
	sc_out<sc_bv<T::DATA_W/8> >& wstrb;		\
	sc_out<bool>& bvalid;				\
	sc_out<bool>& bready;				\
	sc_out<sc_bv<2> >& bresp;			\
	sc_out<bool>& arvalid;				\
	sc_out<bool>& arready;				\
	sc_out<sc_bv<T::ADDR_W> >& araddr;		\
	sc_out<sc_bv<3> >& arprot;			\
	sc_out<bool>& rvalid;				\
	sc_out<bool>& rready;				\
	sc_out<sc_bv<T::DATA_W> >& rdata;		\
	sc_out<sc_bv<2> >& rresp;			\
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
		wvalid(s->wvalid),			\
		wready(s->wready),			\
		wdata(s->wdata),			\
		wstrb(s->wstrb),			\
		bvalid(s->bvalid),			\
		bready(s->bready),			\
		bresp(s->bresp),			\
		arvalid(s->arvalid),			\
		arready(s->arready),			\
		araddr(s->araddr),			\
		arprot(s->arprot),			\
		rvalid(s->rvalid),			\
		rready(s->rready),			\
		rdata(s->rdata),			\
		rresp(s->rresp),			\
		m_s(s)

#endif /* SIGNALGENERATOR_H */

/*
 * TLM remoteport glue
 *
 * Copyright (c) 2016 Xilinx Inc
 * Written by Edgar E. Iglesias
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
#ifndef REMOTE_PORT_TLM_WIRES
#define REMOTE_PORT_TLM_WIRES

class remoteport_tlm_wires
	: public sc_module, public remoteport_tlm_dev
{
public:
	SC_HAS_PROCESS(remoteport_tlm_wires);
	remoteport_tlm_wires(sc_module_name name,
			     unsigned int nr_wires_in,
			     unsigned int nr_wires_out,
			     bool posted_updates = true);
	void cmd_interrupt(struct rp_pkt &pkt, bool can_sync);
	void tie_off(void);

	sc_vector<sc_in<bool> > wires_in;
	sc_vector<sc_out<bool> > wires_out;

	static void cmd_interrupt_null(remoteport_tlm *adaptor,
					struct rp_pkt &pkt,
					bool can_sync,
					remoteport_tlm_wires *dev);
private:
	void interrupt_action(struct rp_pkt &pkt);

	struct {
		unsigned int nr_wires_in;
		unsigned int nr_wires_out;
		bool posted_updates;
	} cfg;

	const char *wire_name;
	void wire_update(void);
};

#endif

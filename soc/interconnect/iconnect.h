/*
 * Simple TLM model of an interconnect
 *
 * Copyright (c) 2011 Edgar E. Iglesias.
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
#ifndef INTERCONNECT_ICONNECT_H__
#define INTERCONNECT_ICONNECT_H__

/*
 * To differentiate between targets that want to be passed absolute
 * addresses with every transaction. Most targets or slaves will use
 * the relative mode. But for example, when bridging accesses over to
 * any slave inside a QEMU instance, the addresses need to be absolute.
 */
enum addrmode {
	ADDRMODE_RELATIVE,
	ADDRMODE_ABSOLUTE
};

struct memmap_entry {
	uint64_t addr;
	uint64_t size;
	enum addrmode addrmode;
	int sk_idx;
};

template<unsigned int N_INITIATORS, unsigned int N_TARGETS>
class iconnect
: public sc_core::sc_module
{
public:
	struct memmap_entry map[N_TARGETS * 4];

	tlm_utils::simple_target_socket_tagged<iconnect> *t_sk[N_INITIATORS];
	tlm_utils::simple_initiator_socket_tagged<iconnect> *i_sk[N_TARGETS];

	SC_HAS_PROCESS(iconnect);
	iconnect(sc_core::sc_module_name name);
	virtual void b_transport(int id,
				 tlm::tlm_generic_payload& trans,
				 sc_time& delay);

	virtual bool get_direct_mem_ptr(int id,
                                  tlm::tlm_generic_payload& trans,
                                  tlm::tlm_dmi&  dmi_data);

	virtual unsigned int transport_dbg(int id,
					tlm::tlm_generic_payload& trans);

	virtual void invalidate_direct_mem_ptr(int id,
                                         sc_dt::uint64 start_range,
                                         sc_dt::uint64 end_range);

	/*
	 * set_target_offset()
	 *
	 * Used to allow the users to attach an initiator socket
	 * to our target socket that gets all of it's accesses offset by
	 * a base before entering the interconnect.  */
	void set_target_offset(unsigned int id, sc_dt::uint64 offset);
	int memmap(sc_dt::uint64 addr, sc_dt::uint64 size,
		enum addrmode addrmode, int idx, tlm::tlm_target_socket<> &s);
private:
	sc_dt::int64 target_offset[N_INITIATORS];

	unsigned int map_address(sc_dt::uint64 addr, sc_dt::uint64& offset);
	void unmap_offset(unsigned int target_nr,
				sc_dt::uint64 offset, sc_dt::uint64& addr);

};

template<unsigned int N_INITIATORS, unsigned int N_TARGETS>
iconnect<N_INITIATORS, N_TARGETS>::iconnect (sc_module_name name)
	: sc_module(name)
{
	char txt[32];
	unsigned int i;

	for (i = 0; i < N_INITIATORS; i++) {
		sprintf(txt, "target_socket_%d", i);

		set_target_offset(i, 0);

		t_sk[i] = new tlm_utils::simple_target_socket_tagged<iconnect>(txt);

		t_sk[i]->register_b_transport(this, &iconnect::b_transport, i);
		t_sk[i]->register_transport_dbg(this, &iconnect::transport_dbg, i);
		t_sk[i]->register_get_direct_mem_ptr(this,
				&iconnect::get_direct_mem_ptr, i);
	}

	for (i = 0; i < N_TARGETS; i++) {
		sprintf(txt, "init_socket_%d", i);
		i_sk[i] = new tlm_utils::simple_initiator_socket_tagged<iconnect>(txt);

		i_sk[i]->register_invalidate_direct_mem_ptr(this,
				&iconnect::invalidate_direct_mem_ptr, i);
		map[i].size = 0;
	}
}

template<unsigned int N_INITIATORS, unsigned int N_TARGETS>
void iconnect<N_INITIATORS, N_TARGETS>::set_target_offset(unsigned int id,
		sc_dt::uint64 offset)
{
	assert(id < N_INITIATORS);
	target_offset[id] = offset;
}

template<unsigned int N_INITIATORS, unsigned int N_TARGETS>
int iconnect<N_INITIATORS, N_TARGETS>::memmap(
		sc_dt::uint64 addr, sc_dt::uint64 size,
		enum addrmode addrmode, int idx,
		tlm::tlm_target_socket<> &s)
{
	unsigned int i;

	for (i = 0; i < N_TARGETS * 4; i++) {
		if (map[i].size == 0) {
			/* Found a free entry.  */
			map[i].addr = addr;
			map[i].size = size;
			map[i].addrmode = addrmode;
			map[i].sk_idx = i;
			if (idx == -1)
				i_sk[i]->bind(s);
			else
				map[i].sk_idx = idx;
			return i;
		}
	}
	printf("FATAL! mapping onto full interconnect!\n");
	abort();
	return -1;
}

template<unsigned int N_INITIATORS, unsigned int N_TARGETS>
unsigned int iconnect<N_INITIATORS, N_TARGETS>::map_address(
			sc_dt::uint64 addr,
			sc_dt::uint64& offset)
{
	unsigned int i;

	for (i = 0; i < N_TARGETS * 4; i++) {
		if (map[i].size
		    && addr >= map[i].addr
		    && addr <= (map[i].addr + map[i].size)) {
			if (map[i].addrmode == ADDRMODE_RELATIVE) {
				offset = addr - map[i].addr;
			} else {
				offset = addr;
			}
			return map[i].sk_idx;
		}
	}

	/* Did not find any slave !?!?  */
	printf("DECODE ERROR! %lx\n", (unsigned long) addr);
	return 0;
}

template<unsigned int N_INITIATORS, unsigned int N_TARGETS>
void iconnect<N_INITIATORS, N_TARGETS>::unmap_offset(
			unsigned int target_nr,
			sc_dt::uint64 offset,
			sc_dt::uint64& addr)
{
	if (target_nr >= N_TARGETS) {
		SC_REPORT_FATAL("TLM-2", "Invalid target_nr in iconnect\n");
	}

	if (map[target_nr].addrmode == ADDRMODE_RELATIVE) {
		if (offset >= map[target_nr].size) {
			printf("offset=%lx\n", (unsigned long) offset);
			SC_REPORT_FATAL("TLM-2", "Invalid range in iconnect\n");
		}

		addr = map[target_nr].addr + offset;
	} else {
		addr = offset;
	}
	return;
}

template<unsigned int N_INITIATORS, unsigned int N_TARGETS>
void iconnect<N_INITIATORS, N_TARGETS>::b_transport(int id,
			tlm::tlm_generic_payload& trans, sc_time& delay)
{
	sc_dt::uint64 addr;
	sc_dt::uint64 offset;
	unsigned int target_nr;

	if (id >= (int) N_INITIATORS) {
		SC_REPORT_FATAL("TLM-2", "Invalid socket tag in iconnect\n");
	}

	addr = trans.get_address();
	addr += target_offset[id];
	target_nr = map_address(addr, offset);

	trans.set_address(offset);
	/* Forward the transaction.  */
	(*i_sk[target_nr])->b_transport(trans, delay);
	/* Restore the addresss.  */
	trans.set_address(addr);
}

template<unsigned int N_INITIATORS, unsigned int N_TARGETS>
bool iconnect<N_INITIATORS, N_TARGETS>::get_direct_mem_ptr(int id,
					tlm::tlm_generic_payload& trans,
					tlm::tlm_dmi& dmi_data)
{
	sc_dt::uint64 addr;
	sc_dt::uint64 offset;
	unsigned int target_nr;
	bool r;

	if (id >= (int) N_INITIATORS) {
		SC_REPORT_FATAL("TLM-2", "Invalid socket tag in iconnect\n");
	}

	addr = trans.get_address();
	addr += target_offset[id];
	target_nr = map_address(addr, offset);

	trans.set_address(offset);
	/* Forward the transaction.  */
	r = (*i_sk[target_nr])->get_direct_mem_ptr(trans, dmi_data);

	unmap_offset(target_nr, dmi_data.get_start_address(), addr);
	dmi_data.set_start_address(addr);
	unmap_offset(target_nr, dmi_data.get_end_address(), addr);
	dmi_data.set_end_address(addr);
	return r;
}

template<unsigned int N_INITIATORS, unsigned int N_TARGETS>
unsigned int iconnect<N_INITIATORS, N_TARGETS>::transport_dbg(int id,
				tlm::tlm_generic_payload& trans)
{
	sc_dt::uint64 addr;
	sc_dt::uint64 offset;
	unsigned int target_nr;

	if (id >= (int) N_INITIATORS) {
		SC_REPORT_FATAL("TLM-2", "Invalid socket tag in iconnect\n");
	}

	addr = trans.get_address();
	addr += target_offset[id];
	target_nr = map_address(addr, offset);

	trans.set_address(offset);
	/* Forward the transaction.  */
	(*i_sk[target_nr])->transport_dbg(trans);
	/* Restore the addresss.  */
	trans.set_address(addr);
	return 0;
}

template<unsigned int N_INITIATORS, unsigned int N_TARGETS>
void iconnect<N_INITIATORS, N_TARGETS>::invalidate_direct_mem_ptr(int id,
                                         sc_dt::uint64 start_range,
                                         sc_dt::uint64 end_range)
{
	sc_dt::uint64 start, end;
	unsigned int i;

	unmap_offset(id, start_range, start);
	unmap_offset(id, end_range, end);

	/* Reverse the offsetting.  */
	start -= target_offset[id];
	end -= target_offset[id];

	for (i = 0; i < N_INITIATORS; i++) {
		(*t_sk[i])->invalidate_direct_mem_ptr(start, end);
	}
}
#endif

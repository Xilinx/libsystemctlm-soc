/*
 * TLM remoteport glue
 *
 * Copyright (c) 2013-2018 Xilinx Inc
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
#ifndef REMOTE_PORT_TLM
#define REMOTE_PORT_TLM

#include "utils/async_event.h"

extern "C" {
#include "remote-port-proto.h"
};

class remoteport_packet {
public:
	union {
		struct rp_pkt *pkt;
		uint8_t *u8;
	};
	size_t data_offset;
	size_t size;

	remoteport_packet(void);
	~remoteport_packet(void) {
		free(u8);
	}
	void alloc(size_t size);
	// Copies this packet onto pkt, including allocation of
	// necessary space.
	void copy(class remoteport_packet &pkt);
};

class remoteport_tlm;

#define RP_MAX_OUTSTANDING_TRANSACTIONS 256
class remoteport_tlm_dev
{
public:
	unsigned int dev_id;
	remoteport_tlm *adaptor;

	// Response slots to handling multiple outstanding transactions.
	struct {
		remoteport_packet pkt;
		sc_event ev;
		uint32_t id;
		bool used;
		bool valid;
	} resp[RP_MAX_OUTSTANDING_TRANSACTIONS];

	remoteport_tlm_dev(void) {
		unsigned int i;

		for (i = 0; i < sizeof resp / sizeof resp[0]; i++) {
			resp[i].used = false;
			resp[i].id = 0;
			resp[i].valid = false;
		}
	}

	// Used to lookup a response slot that is currently
	// waiting for a given remote-port packet ID.
	unsigned int response_lookup(uint32_t id);

	// Called by devices that need to wait for a response
	// for a given remote-port packet ID.
	// An index into resp[] will be returned.
	unsigned int response_wait(uint32_t id);

	// Called by devices when they no longer need the
	// response slot returned by response_wait().
	void response_done(unsigned int resp_idx);

	virtual void cmd_write(struct rp_pkt &pkt, bool can_sync,
			       unsigned char *data, size_t len);
	virtual void cmd_read(struct rp_pkt &pkt, bool can_sync);
	virtual void cmd_interrupt(struct rp_pkt &pkt, bool can_sync);
	virtual void cmd_ats_inv(struct rp_pkt &pkt, bool can_sync);
	virtual void tie_off(void) {} ;
};

class Iremoteport_tlm_sync
{
public:
	Iremoteport_tlm_sync() {};

	// Convert an sc_time into int64 nanoseconds trying to avoid rounding errors.
	// This should be good enough as a default implemetation for most synchronizers.
	virtual int64_t map_time(sc_time t) {
		sc_time tr, tmp;
		double dtr;

		tr = sc_get_time_resolution();
		dtr = tr.to_seconds() * 1000 * 1000 * 1000;

		tmp = t * dtr;
		return tmp.value();
	}

	// Limited direct access to quantum keeper.
	virtual sc_core::sc_time get_current_time() = 0;
	virtual sc_core::sc_time get_local_time() = 0;

	virtual void set_local_time(sc_core::sc_time t) = 0;
	virtual void inc_local_time(sc_core::sc_time t) = 0;
	virtual void sync(void) = 0;
	virtual void reset(void) = 0;

	// Account peer time through some implementation specific quantum keeper.
	virtual void account_time(int64_t rclk) = 0;

	// Optional remote-port hooks.
	virtual void pre_any_cmd(remoteport_packet *pkt, bool can_sync) { }
	virtual void post_any_cmd(remoteport_packet *pkt, bool can_sync) { }
	virtual void pre_sync_cmd(int64_t rclk, bool can_sync) { }
	virtual void post_sync_cmd(int64_t rclk, bool can_sync) { }
	virtual void pre_wire_cmd(int64_t rclk, bool can_sync) { }
	virtual void post_wire_cmd(int64_t rclk, bool can_sync) { }
	virtual void pre_memory_master_cmd(int64_t rclk, bool can_sync) { }
	virtual void post_memory_master_cmd(int64_t rclk, bool can_sync) { }
	virtual void pre_ats_inv_cmd(int64_t rclk, bool can_sync) { }
	virtual void post_ats_inv_cmd(int64_t rclk, bool can_sync) { }
};

#define RP_MAX_DEVS 512

class remoteport_tlm
: public sc_core::sc_module
{
public:
	sc_in<bool> rst;

	SC_HAS_PROCESS(remoteport_tlm);
        remoteport_tlm(sc_core::sc_module_name name,
			int fd,
			const char *sk_descr,
			Iremoteport_tlm_sync *sync = NULL,
			bool blocking_socket = true);

	void register_dev(unsigned int dev_id, remoteport_tlm_dev *dev);
	virtual void tie_off(void);

	/* Public to devs.  */
	struct rp_peer_state peer;
	uint32_t rp_pkt_id;
	Iremoteport_tlm_sync *sync;

	bool rp_process(bool sync);
	ssize_t rp_read(void *rbuf, size_t count);
	ssize_t rp_write(const void *wbuf, size_t count);
	int64_t rp_map_time(sc_time t);
	void account_time(int64_t rp_time_ns);
	// Returns true if the current SC_THREAD is the remote-port
	// thread for this adaptor.
	bool current_process_is_adaptor(void);

	void rp_pkt_main(void);
private:
	remoteport_tlm_dev *devs[RP_MAX_DEVS];
	const char *sk_descr;
	unsigned char *pktbuf_data;
	/* Socket.  */
	int fd;
	remoteport_tlm_dev dev_null;
	bool blocking_socket;

	sc_process_handle adaptor_proc;

	async_event rp_pkt_event;
	pthread_t rp_pkt_thread;
	pthread_mutex_t rp_pkt_mutex;

	void rp_sk_open(void);
	void rp_say_hello(void);
	void rp_cmd_hello(struct rp_pkt &pkt);
	void rp_cmd_sync(struct rp_pkt &pkt, bool can_sync);
	void process(void);
};

// Pre-defined sync objects.
extern Iremoteport_tlm_sync *remoteport_tlm_sync_loosely_timed_ptr;
extern Iremoteport_tlm_sync *remoteport_tlm_sync_untimed_ptr;

#endif

class TRISignals : public sc_core::sc_module
{
public:
	//--- Pico -> L1.5
	sc_signal<bool>                     l15_transducer_ack;
	sc_signal<bool>                     l15_transducer_header_ack;

	// outputs pico uses
	sc_signal<sc_bv<5> >               transducer_l15_rqtype;
	sc_signal<sc_bv<L15_AMO_OP_WIDTH> >  	transducer_l15_amo_op;
	sc_signal<sc_bv<3> >               transducer_l15_size;
	sc_signal<bool>                    transducer_l15_val;
	sc_signal<sc_bv<PHY_ADDR_WIDTH> >  transducer_l15_address;
	sc_signal<sc_bv<64> >              transducer_l15_data;
	sc_signal<bool>                    transducer_l15_nc;


	// outputs pico doesn't use
	//output [0:0]                    transducer_l15_threadid,
	sc_signal<bool>                    transducer_l15_threadid;
	sc_signal<bool>                    transducer_l15_prefetch;
	sc_signal<bool>                    transducer_l15_invalidate_cacheline;
	sc_signal<bool>                    transducer_l15_blockstore;
	sc_signal<bool>                    transducer_l15_blockinitstore;
	sc_signal<sc_bv<2> >               transducer_l15_l1rplway;
	sc_signal<sc_bv<64> >              transducer_l15_data_next_entry;
	sc_signal<sc_bv<32> >              transducer_l15_csm_data;

	//--- L1.5 -> Pico
	sc_signal<bool>                     l15_transducer_val;
	sc_signal<sc_bv<4> >                l15_transducer_returntype;

	sc_signal<sc_bv<64> >               l15_transducer_data_0;
	sc_signal<sc_bv<64> >               l15_transducer_data_1;

	sc_signal<bool>                    transducer_l15_req_ack;

	template<typename T>
	void connect(T *dev)
	{
		dev->l15_transducer_ack(l15_transducer_ack);
		dev->l15_transducer_header_ack(l15_transducer_header_ack);

		// outputs pico uses
		dev->transducer_l15_rqtype(transducer_l15_rqtype);
		dev->transducer_l15_amo_op(transducer_l15_amo_op);
		dev->transducer_l15_size(transducer_l15_size);
		dev->transducer_l15_val(transducer_l15_val);
		dev->transducer_l15_address(transducer_l15_address);
		dev->transducer_l15_data(transducer_l15_data);
		dev->transducer_l15_nc(transducer_l15_nc);


		// outputs pico doesn't use
		//output [0:0]                    transducer_l15_threadid,
		dev->transducer_l15_threadid(transducer_l15_threadid);
		dev->transducer_l15_prefetch(transducer_l15_prefetch);
		dev->transducer_l15_invalidate_cacheline(transducer_l15_invalidate_cacheline);
		dev->transducer_l15_blockstore(transducer_l15_blockstore);
		dev->transducer_l15_blockinitstore(transducer_l15_blockinitstore);
		dev->transducer_l15_l1rplway(transducer_l15_l1rplway);
		dev->transducer_l15_data_next_entry(transducer_l15_data_next_entry);
		dev->transducer_l15_csm_data(transducer_l15_csm_data);

		//--- L1.5 -> Pico
		dev->l15_transducer_val(l15_transducer_val);
		dev->l15_transducer_returntype(l15_transducer_returntype);

		dev->l15_transducer_data_0(l15_transducer_data_0);
		dev->l15_transducer_data_1(l15_transducer_data_1);

		dev->transducer_l15_req_ack(transducer_l15_req_ack);
	}

	void Trace(sc_trace_file *f)
	{
		sc_trace(f, l15_transducer_ack, l15_transducer_ack.name());
		sc_trace(f, l15_transducer_header_ack, l15_transducer_header_ack.name());

		// outputs pico uses
		sc_trace(f, transducer_l15_rqtype, transducer_l15_rqtype.name());
		sc_trace(f, transducer_l15_amo_op, transducer_l15_amo_op.name());
		sc_trace(f, transducer_l15_size, transducer_l15_size.name());
		sc_trace(f, transducer_l15_val, transducer_l15_val.name());
		sc_trace(f, transducer_l15_address, transducer_l15_address.name());
		sc_trace(f, transducer_l15_data, transducer_l15_data.name());
		sc_trace(f, transducer_l15_nc, transducer_l15_nc.name());


		// outputs pico doesn't use
		//output [0:0]                    transducer_l15_threadid,
		sc_trace(f, transducer_l15_threadid, transducer_l15_threadid.name());
		sc_trace(f, transducer_l15_prefetch, transducer_l15_prefetch.name());
		sc_trace(f, transducer_l15_invalidate_cacheline, transducer_l15_invalidate_cacheline.name());
		sc_trace(f, transducer_l15_blockstore, transducer_l15_blockstore.name());
		sc_trace(f, transducer_l15_blockinitstore, transducer_l15_blockinitstore.name());
		sc_trace(f, transducer_l15_l1rplway, transducer_l15_l1rplway.name());
		sc_trace(f, transducer_l15_data_next_entry, transducer_l15_data_next_entry.name());
		sc_trace(f, transducer_l15_csm_data, transducer_l15_csm_data.name());

		//--- L1.5 -> Pico
		sc_trace(f, l15_transducer_val, l15_transducer_val.name());
		sc_trace(f, l15_transducer_returntype, l15_transducer_returntype.name());

		sc_trace(f, l15_transducer_data_0, l15_transducer_data_0.name());
		sc_trace(f, l15_transducer_data_1, l15_transducer_data_1.name());

		sc_trace(f, transducer_l15_req_ack, transducer_l15_req_ack.name());
	}

	template<typename T>
	void connect(T& dev)
	{
		connect(&dev);
	}

	TRISignals(sc_core::sc_module_name name) :
		l15_transducer_ack("l15_transducer_ack"),
		l15_transducer_header_ack("l15_transducer_header_ack"),

		transducer_l15_rqtype("transducer_l15_rqtype"),
		transducer_l15_amo_op("transducer_l15_amo_op"),
		transducer_l15_size("transducer_l15_size"),
		transducer_l15_val("transducer_l15_val"),
		transducer_l15_address("transducer_l15_address"),
		transducer_l15_data("transducer_l15_data"),
		transducer_l15_nc("transducer_l15_nc"),


		transducer_l15_threadid("transducer_l15_threadid"),
		transducer_l15_prefetch("transducer_l15_prefetch"),
		transducer_l15_invalidate_cacheline("transducer_l15_invalidate_cacheline"),
		transducer_l15_blockstore("transducer_l15_blockstore"),
		transducer_l15_blockinitstore("transducer_l15_blockinitstore"),
		transducer_l15_l1rplway("transducer_l15_l1rplway"),
		transducer_l15_data_next_entry("transducer_l15_data_next_entry"),
		transducer_l15_csm_data("transducer_l15_csm_data"),

		l15_transducer_val("l15_transducer_val"),
		l15_transducer_returntype("l15_transducer_returntype"),

		l15_transducer_data_0("l15_transducer_data_0"),
		l15_transducer_data_1("l15_transducer_data_1"),

		transducer_l15_req_ack("transducer_l15_req_ack")
	{}
};

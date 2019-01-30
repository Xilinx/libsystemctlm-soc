// Generic attributes extension
//
// An optional extension to the Generic Payload implementing
// a selection of attributes that are available in common bus
// protocols such as AMBA (AXI, AHB, AXI-Stream) and PCI.
//
// We try to model concepts and give them generic names instead of
// matching the exact naming of specific bus protocols.
//
// Copyright 2016 (C) Xilinx Inc.
// Written by Edgar E. Iglesias <edgar.iglesias@xilinx.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//

#ifndef GENATTR_H__
#define GENATTR_H__

// Generator for Setters and Getters.
#define PROP_GETSET_GEN(name, type, def) \
	type get_ ## name (void) const { return name ; }	\
	void set_ ## name (type new_v = def) { name = new_v; }	\

// Stream extensions that for example apply to AXI-Stream.
class genattr_stream
{
private:
	// Signals End of Packet when modeling stream channels.
	bool eop;

public:
	genattr_stream() :
		eop(false)
	{}

	PROP_GETSET_GEN(eop, bool, true)
};

// Bus Extensions that for example apply to AXI-4 or PCI.
class genattr_bus
{
private:
	// Master/Source/Stream/Requester ID.
	//
	// This member carries an ID of the device that originated
	// this transaction. PCI refers to this as the Requester ID.
	// In AMBA it is commonly refered to as the Master ID or
	// some times the Stream ID.
	//
	// Requester IDs are 16 bits.
	// Master ID's vary in bit length.
	uint64_t master_id;

	// AMBA TrustZone Secure vs Non-Secure transactions.
	bool secure;

	// A hint to say that the transaction is posted and does
	// not need to be ACKed.
	bool posted;

	// For specifying if this is an AMBA AXI wrapping burst.
	bool wrap;

	// AMBA width of a single burst transfer (beat) in bytes.
	uint32_t burst_width;

	uint32_t transaction_id;

	// For AMBA AXI this marks the transaction as exclusive.
	bool exclusive;

	// For AMBA AXI3 this marks the transaction as locked.
	bool locked;

	// AMBA AXI bufferable attribute. When true, an interconnect, or any
	// component, can delay the transaction reaching its final destination
	// for any number of cycles.
	bool bufferable;

	// AMBA AXI modifiable attribute. When true, modifiable indicates that
	// the characteristics of the transaction can be modified. When
	// modifiable is false, the transaction is Non-modifiable.
	bool modifiable;

	// For AMBA AXI3 this is read allocate.
	// For AMBA AXI4 this is allocate for read transactions and other
	// allocate for write transactions.
	bool read_allocate;

	// For AMBA AXI3 this is write allocate.
	// For AMBA AXI4 this is allocate for write transactions and other
	// allocate for read transactions.
	bool write_allocate;

	// AMBA AXI QoS identifier recommended to be used as a priority
	// indicator where a higher value indicates a higher priority
	// transaction.
	uint8_t qos;

	// AMBA AXI region identifier, with AMBA AXI it can be used to uniquely
	// identify up to sixteen different regions. The region identifier can
	// provide a decode of higher order address bits. Usage of region
	// identifiers means a single physical interface on a slave can provide
	// multiple logical interfaces, each with a different location in the
	// system address map.
	uint8_t region;

	// For AMBA AXI this is set by a target slave if the transaction is
	// exclusive and was processed as an exclusive transaction.
	bool exclusive_handled;

public:
	PROP_GETSET_GEN(secure, bool, true);
	PROP_GETSET_GEN(master_id, uint64_t, 0);
	PROP_GETSET_GEN(wrap, bool, false);
	PROP_GETSET_GEN(posted, bool, false);
	PROP_GETSET_GEN(burst_width, uint32_t, 0);
	PROP_GETSET_GEN(transaction_id, uint32_t, 0);
	PROP_GETSET_GEN(exclusive, bool, false);
	PROP_GETSET_GEN(locked, bool, false);
	PROP_GETSET_GEN(bufferable, bool, false);
	PROP_GETSET_GEN(modifiable, bool, false);
	PROP_GETSET_GEN(read_allocate, bool, false);
	PROP_GETSET_GEN(write_allocate, bool, false);
	PROP_GETSET_GEN(qos, uint8_t, 0);
	PROP_GETSET_GEN(region, uint8_t, 0);
	PROP_GETSET_GEN(exclusive_handled, bool, false);

	genattr_bus() {
		set_secure();
		set_master_id();
		set_wrap();
		set_posted();
		set_burst_width();
		set_transaction_id();
		set_exclusive();
		set_locked();
		set_bufferable();
		set_modifiable();
		set_read_allocate();
		set_write_allocate();
		set_qos();
		set_region();
		set_exclusive_handled();
	}

	// Compatibility layer for older versions and other frameworks.

	// AMBA Compat.
	bool get_non_secure(void) const { return !secure; }
	void set_non_secure(bool new_non_secure = true) {
		secure = !new_non_secure;
	}
};

class genattr_extension
: public tlm::tlm_extension<genattr_extension>,
  public genattr_bus,
  public genattr_stream
{
public:
	void copy_from(const tlm_extension_base &extension) {
		const genattr_extension &ext_genattr = static_cast<genattr_extension const &>(extension);

		// Copy all members.
		set_eop(ext_genattr.get_eop());
		set_master_id(ext_genattr.get_master_id());
		set_secure(ext_genattr.get_secure());
		set_wrap(ext_genattr.get_wrap());
		set_posted(ext_genattr.get_posted());
		set_burst_width(ext_genattr.get_burst_width());
		set_transaction_id(ext_genattr.get_transaction_id());
		set_exclusive(ext_genattr.get_exclusive());
		set_locked(ext_genattr.get_locked());
		set_bufferable(ext_genattr.get_bufferable());
		set_modifiable(ext_genattr.get_modifiable());
		set_read_allocate(ext_genattr.get_read_allocate());
		set_write_allocate(ext_genattr.get_write_allocate());
		set_qos(ext_genattr.get_qos());
		set_region(ext_genattr.get_region());
		set_exclusive_handled(ext_genattr.get_exclusive_handled());
	}

	tlm::tlm_extension_base *clone(void) const
	{
		return new genattr_extension(*this);
	}
};

#endif /* GENATTR_H__ */

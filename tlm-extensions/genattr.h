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

public:
	PROP_GETSET_GEN(secure, bool, true);
	PROP_GETSET_GEN(master_id, uint64_t, 0);

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
	}

	tlm::tlm_extension_base *clone(void) const
	{
		return new genattr_extension(*this);
	}
};

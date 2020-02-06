/*
 * Shared AMBA ACE defines and helpers.
 *
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

#ifndef TLM_BRIDGES_AMBA_ACE_H__
#define TLM_BRIDGES_AMBA_ACE_H__

#include "tlm-extensions/genattr.h"

namespace AMBA {
namespace ACE {

enum {
	ACE_MODE_OFF = 0,
	ACE_MODE_ACE = 1,
	ACE_MODE_ACELITE = 2,
};

namespace Domain
{
	enum {
		NonSharable,
		Inner,
		Outer,
		System
	 };
};

namespace AR
{
	enum {
		//
		// ARDomain == NonSharable or System (0b00 or 0b11)
		//
		ReadNoSnoop = 0x0,

		//
		// ARDomain == Inner or Outer (0b01 or 0b10)
		//
		ReadOnce = 0x0,
		ReadShared = 0x1,
		ReadClean = 0x2,
		ReadNotSharedDirty = 0x3,
		ReadUnique = 0x7,
		CleanUnique = 0xb,
		MakeUnique = 0xc,

		//
		// ARDomain == NonSharable, Inner or Outer (0b00, 0b01 or 0b10)
		//
		CleanShared = 0x8,
		CleanInvalid = 0x9,
		MakeInvalid = 0xd,

		//
		// ARDomain == NonSharable, Inner, Outer or System
		//
		Barrier = 0x0,

		//
		// ARDomain == Inner or Outer (0b01 or 0b10)
		//
		DVMComplete = 0xe,
		DVMMessage = 0xf,
	 };
};

namespace AW
{
	enum {
		//
		// AWDomain == NonSharable or System (0b00 or 0b11)
		//
		WriteNoSnoop = 0x0,

		//
		// AWDomain == Inner or Outer (0b01 or 0b10)
		//
		WriteUnique = 0x0,
		WriteLineUnique = 0x1,

		//
		// AWDomain == NonSharable, Inner or Outer (0b00, 0b01 or 0b10)
		//
		WriteClean = 0x2,
		WriteBack = 0x3,

		//
		// AWDomain == Inner or Outer (0b01 or 0b10)
		//
		Evict = 0x4

		// TBD: Barrier + DVM
	 };
};

namespace AC
{
	enum {
		ReadOnce = 0x0,
		ReadShared = 0x1,
		ReadClean = 0x2,
		ReadNotSharedDirty = 0x3,
		ReadUnique = 0x7,
		CleanShared = 0x8,
		CleanInvalid = 0x9,
		MakeInvalid = 0xd,
		DVMComplete = 0xe,
		DVMMessage = 0xf,
	 };
};

namespace CR
{
	enum {
		DataTransferShift = 0,
		ErrorBitShift,
		PassDirtyShift,
		IsSharedShift,
		WasUniqueShift
	};
};


namespace DVM
{
	enum {
		CmdShift = 12,
		CmdMask = 0x7,
		CompletionShift = 15,

		CompletionBit = 1 << CompletionShift,

		CmdBranchPredictorInv = 0x1,
		CmdVirtInstCacheInv = 0x3,
		CmdSync = 0x4,
		CmdHint = 0x6,
	};
};

namespace ACE
{
	enum {
		MaxBarriers = 256,
	};
};

class ace_helpers 
{
public:
	bool ExtractDataTransfer(uint32_t resp)
	{
		//
		// rresp and cresp has the bit at the same location
		//
		return ((resp >> CR::DataTransferShift) & 0x1);
	}

	bool ExtractErrorBit(uint32_t resp)
	{
		//
		// rresp and cresp has the bit at the same location
		//
		return ((resp >> CR::ErrorBitShift) & 0x1);
	}

	bool ExtractIsShared(uint32_t resp)
	{
		//
		// rresp and cresp has the bit at the same location
		//
		return ((resp >> CR::IsSharedShift) & 0x1);
	}

	bool ExtractPassDirty(uint32_t resp)
	{
		//
		// rresp and cresp has the bit at the same location
		//
		return ((resp >> CR::PassDirtyShift) & 0x1);
	}

	bool ExtractWasUnique(uint32_t resp)
	{
		//
		// rresp and cresp has the bit at the same location
		//
		return ((resp >> CR::WasUniqueShift) & 0x1);
	}

	bool IsDVMSyncCmd(uint64_t addr)
	{
		uint64_t cmd = (addr >> DVM::CmdShift) & DVM::CmdMask;

		return cmd == DVM::CmdSync;
	}

	bool IsDVMHintCmd(uint64_t addr)
	{
		uint64_t cmd = (addr >> DVM::CmdShift) & DVM::CmdMask;

		return cmd == DVM::CmdHint;
	}

	//
	// Call this function only for read transactions.
	//
	bool HasSingleRdDataTransfer(uint8_t axdomain,
					uint8_t axsnoop, uint8_t axbar)
	{
		bool is_barrier = axbar > 0;

		// C3.2.1
		//
		// Transactions with a single data transfer
		//
		switch(axsnoop) {
		case AR::CleanUnique:
		case AR::CleanInvalid:
		case AR::CleanShared:
		case AR::MakeInvalid:
		case AR::MakeUnique:
			if (axdomain == Domain::Inner ||
				axdomain == Domain::Outer) {
				return true;
			}
			break;
		default:
			break;
		};

		if (is_barrier || IsDVM(axdomain, axsnoop)) {
			return true;
		}

		return false;
	}

	//
	// Call this function only for read transactions.
	//
	bool IsDVM(uint8_t axdomain, uint8_t axsnoop)
	{
		switch(axsnoop) {
		case AR::DVMComplete:
		case AR::DVMMessage:
			if (axdomain == Domain::Inner ||
				axdomain == Domain::Outer) {
				return true;
			}
			// Return false
			break;
		default:
			// Return false
			break;
		};

		return false;
	}

	//
	// Call below functions only for write transactions.
	//
	bool IsEvict(uint8_t axdomain, uint8_t axsnoop)
	{
		if (axsnoop == AW::Evict &&
			(axdomain == Domain::Inner ||
			 axdomain == Domain::Outer)) {
			return true;
		}
		return false;
	}

	bool IsWriteBack(uint8_t axdomain, uint8_t axsnoop)
	{
		if (axsnoop == AW::WriteBack &&
			(axdomain == Domain::NonSharable ||
			 axdomain == Domain::Inner ||
			 axdomain == Domain::Outer)) {
			return true;
		}
		return false;
	}

	bool IsWriteClean(uint8_t axdomain, uint8_t axsnoop)
	{
		if (axsnoop == AW::WriteClean &&
			(axdomain == Domain::NonSharable ||
			 axdomain == Domain::Inner ||
			 axdomain == Domain::Outer)) {
			return true;
		}
		return false;
	}

	bool IsWriteLineUnique(uint8_t axdomain, uint8_t axsnoop)
	{
		if (axsnoop == AW::WriteLineUnique &&
			(axdomain == Domain::Inner ||
			 axdomain == Domain::Outer)) {
			return true;
		}
		return false;
	}

	bool IsWriteUnique(uint8_t axdomain, uint8_t axsnoop)
	{
		if (axsnoop == AW::WriteUnique &&
			(axdomain == Domain::Inner ||
			 axdomain == Domain::Outer)) {
			return true;
		}
		return false;
	}

	uint64_t align(uint64_t addr, uint64_t alignTo)
	{
		return (addr / alignTo) * alignTo;
	}

	bool IsModifiable(uint8_t axcache)
	{
		return (axcache >> 1) & 0x1;
	}

	bool IsCacheable(uint8_t axcache)
	{
		return (axcache >> 2) & 0x3;
	}

	//
	// Call this function only for read transactions.
	//
	bool AllowPassDirty(uint8_t domain, uint8_t snoop)
	{
		// Handle AR::ReadNoSnoop
		if (snoop == AR::ReadNoSnoop) {
			if (domain == Domain::NonSharable ||
				domain == Domain::System) {
				return false;
			}
		}

		switch (snoop) {
		case AR::ReadOnce:
		case AR::ReadClean:
		case AR::CleanUnique:
		case AR::MakeUnique:
			if (domain == Domain::Inner ||
				domain == Domain::Outer) {
				return false;
			}
			break;
		case AR::CleanShared:
		case AR::CleanInvalid:
		case AR::MakeInvalid:
			if (domain == Domain::NonSharable ||
				domain == Domain::Inner ||
				domain == Domain::Outer) {
				return false;
			}
			break;
		default:
			break;
		}

		return true;
	}
};

class ace_tx_helpers :
	public ace_helpers
{
public:
	ace_tx_helpers() :
		m_gp(NULL),
		m_genattr(NULL)
	{}

	void setup_ace_helpers(tlm::tlm_generic_payload *gp)
	{
		m_gp = gp;
		assert(m_gp);

		m_gp->get_extension(m_genattr);
		assert(m_genattr);
	}

	bool IsIgnoreRead()
	{
		return m_gp->get_command() == tlm::TLM_IGNORE_COMMAND &&
			m_genattr->get_is_read_tx();
	}

	bool IsIgnoreWrite()
	{
		return m_gp->get_command() == tlm::TLM_IGNORE_COMMAND &&
			m_genattr->get_is_write_tx();
	}

	void SetDirty()
	{
		m_genattr->set_dirty(true);
	}

	void SetShared()
	{
		m_genattr->set_shared(true);
	}

	bool HasDataTransfer()
	{
		return m_genattr->get_datatransfer();
	}

	bool HasErrorBit()
	{
		return m_genattr->get_error_bit();
	}

	bool HasSingleRdDataTransfer()
	{
		if (IsIgnoreRead()) {
			uint8_t domain = m_genattr->get_domain();
			uint8_t snoop = m_genattr->get_snoop();
			uint8_t bar = m_genattr->get_barrier();

			return ace_helpers::HasSingleRdDataTransfer(domain,
								snoop,
								bar);
		}
		return false;
	}

	bool IsEvict()
	{
		if (IsIgnoreWrite()) {
			uint8_t domain = m_genattr->get_domain();
			uint8_t snoop = m_genattr->get_snoop();

			return ace_helpers::IsEvict(domain, snoop);
		}
		return false;
	}

	bool IsWriteBack()
	{
		if (m_gp->is_write()) {
			uint8_t domain = m_genattr->get_domain();
			uint8_t snoop = m_genattr->get_snoop();

			return ace_helpers::IsWriteBack(domain, snoop);
		}
		return false;
	}

	bool IsWriteClean()
	{
		if (m_gp->is_write()) {
			uint8_t domain = m_genattr->get_domain();
			uint8_t snoop = m_genattr->get_snoop();

			return ace_helpers::IsWriteClean(domain, snoop);
		}
		return false;
	}

	bool IsCleanUnique()
	{
		if (IsIgnoreRead() &&
			m_genattr->get_snoop() == AR::CleanUnique &&
			(m_genattr->get_domain() == Domain::Inner ||
			 m_genattr->get_domain() == Domain::Outer)) {
			return true;
		}
		return false;
	}

	bool IsReadClean()
	{
		if (m_gp->is_read() &&
			m_genattr->get_snoop() == AR::ReadClean &&
			(m_genattr->get_domain() == Domain::Inner ||
			 m_genattr->get_domain() == Domain::Outer)) {
			return true;
		}
		return false;
	}

	bool IsReadShared()
	{
		if (m_gp->is_read() &&
			m_genattr->get_snoop() == AR::ReadShared &&
			(m_genattr->get_domain() == Domain::Inner ||
			 m_genattr->get_domain() == Domain::Outer)) {
			return true;
		}
		return false;
	}

	bool IsDVMSync()
	{
		if (IsIgnoreRead() &&
			m_genattr->get_snoop() == AC::DVMMessage) {
			return IsDVMSyncCmd(m_gp->get_address());
		}
		return false;
	}

	bool IsDVMComplete()
	{
		if (IsIgnoreRead() &&
			m_genattr->get_snoop() == AR::DVMComplete) {
			return true;
		}
		return false;
	}

	bool IsBarrier()
	{
		if (m_gp->get_command() == tlm::TLM_IGNORE_COMMAND) {
			return m_genattr->get_barrier();
		}
		return false;
	}

	bool IsWriteBarrier()
	{
		if (IsIgnoreWrite()) {
			return m_genattr->get_barrier();
		}
		return false;
	}

	bool AllowPassDirty()
	{
		if (m_gp->is_read() || HasSingleRdDataTransfer()) {
			uint8_t domain = m_genattr->get_domain();
			uint8_t snoop = m_genattr->get_snoop();

			return ace_helpers::AllowPassDirty(domain, snoop);
		} else {
			// Writes never pass dirty
			return false;
		}

		return true;
	}

	bool IsDVM()
	{
		if (IsIgnoreRead()) {
			uint8_t snoop = m_genattr->get_snoop();
			uint8_t domain = m_genattr->get_domain();

			return ace_helpers::IsDVM(domain, snoop);
		}

		return false;
	}

	bool PassDirty() { return m_genattr->get_dirty(); }

	bool IsShared() { return m_genattr->get_shared(); }

	uint8_t GetAxSnoop()
	{
		return m_genattr->get_snoop();
	}

	uint8_t GetAxDomain()
	{
		return m_genattr->get_domain();
	}

	bool GetAxBar()
	{
		return m_genattr->get_barrier();
	}

private:
	//
	// Keep a copy of these two
	//
	tlm::tlm_generic_payload *m_gp;
	genattr_extension *m_genattr;
};

class iconnect_event
: public tlm::tlm_extension<iconnect_event>
{
public:
	iconnect_event(sc_event* event) :
		m_event(event)
	{}

	~iconnect_event()
	{
		m_event->notify();
	}

	iconnect_event(const iconnect_event& rhs) :
		m_event(rhs.m_event)
	{}

	void copy_from(const tlm_extension_base &ext) {
		const iconnect_event ie =
			static_cast<iconnect_event const &>(ext);

		m_event = ie.m_event;
	}

	tlm::tlm_extension_base *clone(void) const
	{
		return new iconnect_event(*this);
	}

private:
	sc_event *m_event;
};


// End of namespace ACE
};

// End of namespace AMBA
};

#endif

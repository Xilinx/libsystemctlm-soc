/*
 * Copyright (c) 2022 AMD Inc.
 *
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
 *
 * [1] PCI Express Base Specification Revision 5.0 Version 1.0
 *
 */

#ifndef TLM_BRIDGES_PCI_H__
#define TLM_BRIDGES_PCI_H__

namespace PCI {
namespace TLP {

	enum {
		//
		// TLP Header size in bytes (1 DW == 4 bytes)
		//
		TLPHdr_3DW_Sz = 12,
		TLPHdr_4DW_Sz = 16,

		//
		// [1] Section 2.2.7
		//
		TLPHdr_Conf_Sz = TLPHdr_3DW_Sz,
		//
		// [1] Section 2.2.9
		//
		TLPHdr_Cpl_Sz = TLPHdr_3DW_Sz,

		//
		// [1] Section 2.2.1
		//
		Type_MRdWr = 0,
		Type_CfgRdWr_type0 = 4,
		Type_CfgRdWr_type1 = 5,
		Type_Cpl = 10,

		//
		// [1] Section 2.2.1
		//
		FMT_3DW_NoData = 0,
		FMT_4DW_NoData = 1,
		FMT_3DW_WithData = 2,
		FMT_4DW_WithData = 3,
		FMT_TLP_PREFIX = 4,

		//
		// Cpl status
		//
		Cpl_SC = 0,  // Successful Completion
		Cpl_UR = 1,  // Unsupported Request
		Cpl_CRS = 2, // Configuration Request Retry Status
		Cpl_CA = 4,  // Completer Abort

		//
		// Max data length
		//
		SZ_1K = 1024,
		SZ_4K = SZ_1K * 4,
		MAX_DW_LEN = 1024,
	};

}; // namespace TLP
}; // namespace PCI

#endif /* TLM_BRIDGES_PCI_H__ */

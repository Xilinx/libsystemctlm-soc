/*
 * HSC testsuite.
 *
 * Copyright (c) 2022 Advanced Micro Devices Inc.
 * Written by Fred Konrad
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

#include <systemc>
#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>
#include "soc/crypto/xilinx/hsc/hsc.h"

#include "traffic-generators/tg-tlm.h"
#include "traffic-generators/traffic-desc.h"
#include "tests/test-modules/utils.h"
#include <iomanip>
#include <string>

using namespace sc_core;
using namespace sc_dt;
using namespace utils;

#define SWAP(a, b, c, d) d, c, b, a

static void Done_Callback(TLMTrafficGenerator *gen, int threadId);

typedef struct {
  const char *name;
  TrafficDesc traffic;
} HSCTest;

/* TEST1: This checks the following registers value:
 *        CONFIGURATION_REVISION @0x00000000 is 0x00000001 and Read Only.
 */
HSCTest Test1 = {"Test1: Revision ID register",
		  merge({
		     Write(0x00000000, DATA(0xDE, 0xAD, 0xBE, 0xEF)),
		     Read(0x0), Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x01)), 4),
		  })};

/* TEST2: Encoder SA keys check:
 *        * The first and the last keys are retrieved, there value must be
 *          zero at the reset.
 *        * The first key get written.
 *        * The value written is checked.
 */
HSCTest Test2 = {"Test2: Indirect TX SA keys accesses",
	merge(
		{
			/* Trigger a read of the SA keys #0.  */
			Write(0x00004000,
			      DATA(0x01, 0x00, 0x00, 0x00)),
			/* For the model, the trigger bit is cleared
			 * instantly.
			 */
			Read(0x00004000),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			/* The TX indirect read access register are supposed to
			 * be read only.  Write garbage to it, to check that it
			 * is the case.
			 */
			Write(0x0004C00,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C04,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C08,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C0C,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C10,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C14,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C18,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C1C,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			/* Read the register back.  Since they should be zero,
			 * the CRC32 computation should be: 0xAD550A19.
			 */
			Read(0x00004C00),
			Expect(DATA(0xAD, 0x55, 0x0A, 0x19), 4),
			Read(0x00004C04),
			/* Rest should be read a zero.  */
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C08),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C0C),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C10),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C14),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C18),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C1C),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			/* Prepare an SA key for writing.  */
			Write(0x0004800,
			      DATA(0x00, 0x01, 0x02, 0x03)),
			Write(0x0004804,
			      DATA(0x04, 0x05, 0x06, 0x07)),
			Write(0x0004808,
			      DATA(0x08, 0x09, 0x0A, 0x0B)),
			Write(0x000480C,
			      DATA(0x0C, 0x0D, 0x0E, 0x0F)),
			Write(0x0004810,
			      DATA(0x10, 0x11, 0x12, 0x13)),
			Write(0x0004814,
			      DATA(0x14, 0x15, 0x16, 0x17)),
			Write(0x0004818,
			      DATA(0x18, 0x19, 0x1A, 0x1B)),
			Write(0x000481C,
			      DATA(0x1C, 0x1D, 0x1E, 0x1F)),
			/* Trigger a write of the SA keys #0.  */
			Write(0x00004000,
			      DATA(0x03, 0x00, 0x00, 0x00)),
			/* Trigger a read of the SA keys #0.  */
			Write(0x00004000,
			      DATA(0x01, 0x00, 0x00, 0x00)),
			/* The data above should be read back.  */
			Read(0x00004C00),
			Expect(DATA(0x8A, 0x7E, 0x26, 0x91), 4),
			Read(0x00004C04),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			Read(0x00004C08),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			Read(0x00004C0C),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			Read(0x00004C10),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			Read(0x00004C14),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			Read(0x00004C18),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			Read(0x00004C1C),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),

			/* Ditto for the last key.  */
			/* Trigger a read of the SA keys #1023.  */
			Write(0x00004000,
			      DATA(0x01, 0xFF, 0x03, 0x00)),
			/* For the model, the trigger bit is cleared
			 * instantly.
			 */
			Read(0x00004000),
			Expect(DATA(0x00, 0xFF, 0x03, 0x00), 4),
			/* The TX indirect read access register are supposed to
			 * be read only.  Write garbage to it, to check that it
			 * is the case.
			 */
			Write(0x0004C00,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C04,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C08,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C0C,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C10,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C14,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C18,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0004C1C,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			/* Read the register back.  Since they should be zero,
			 * the CRC32 computation should be: 0xAD550A19.
			 */
			Read(0x00004C00),
			Expect(DATA(0xAD, 0x55, 0x0A, 0x19), 4),
			Read(0x00004C04),
			/* Rest should be read a zero.  */
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C08),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C0C),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C10),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C14),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C18),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C1C),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			/* Prepare an SA key for writing.  */
			Write(0x0004800,
			      DATA(0x20, 0x21, 0x22, 0x23)),
			Write(0x0004804,
			      DATA(0x24, 0x25, 0x26, 0x27)),
			Write(0x0004808,
			      DATA(0x28, 0x29, 0x2A, 0x2B)),
			Write(0x000480C,
			      DATA(0x2C, 0x2D, 0x2E, 0x2F)),
			Write(0x0004810,
			      DATA(0x30, 0x31, 0x32, 0x33)),
			Write(0x0004814,
			      DATA(0x34, 0x35, 0x36, 0x37)),
			Write(0x0004818,
			      DATA(0x38, 0x39, 0x3A, 0x3B)),
			Write(0x000481C,
			      DATA(0x3C, 0x3D, 0x3E, 0x3F)),
			/* Trigger a write of the SA keys #1023.  */
			Write(0x00004000,
			      DATA(0x03, 0xFF, 0x03, 0x00)),
			/* Trigger a read of the SA keys #1023.  */
			Write(0x00004000,
			      DATA(0x01, 0xFF, 0x03, 0x00)),
			/* The data above should be read back.  */
			Read(0x00004C00),
			Expect(DATA(0xE3, 0x06, 0xA6, 0xF6), 4),
			/* Rest should be read a zero.  */
			Read(0x00004C04),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C08),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C0C),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C10),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C14),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C18),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00004C1C),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
		}
		)
};

/* TEST3: Decoder SA keys check (similar of TEST2 but with RX keys):
 *        * The first and the last keys are retrieved, there value must be
 *          zero at the reset.
 *        * The first key get written.
 *        * The value written is checked.
 */
HSCTest Test3 = {"Test3: Indirect RX SA keys accesses",
	merge(
		{
			/* Trigger a read of the SA keys #0.  */
			Write(0x00006000,
			      DATA(0x01, 0x00, 0x00, 0x00)),
			/* For the model, the trigger bit is cleared
			 * instantly.
			 */
			Read(0x00006000),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			/* The TX indirect read access register are supposed to
			 * be read only.  Write garbage to it, to check that it
			 * is the case.
			 */
			Write(0x0006C00,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C04,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C08,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C0C,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C10,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C14,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C18,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C1C,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			/* Read the register back.  Since they should be zero,
			 * the CRC32 computation should be: 0xAD550A19.
			 */
			Read(0x00006C00),
			Expect(DATA(0xAD, 0x55, 0x0A, 0x19), 4),
			Read(0x00006C04),
			/* Rest should be read a zero.  */
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C08),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C0C),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C10),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C14),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C18),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C1C),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			/* Prepare an SA key for writing.  */
			Write(0x0006800,
			      DATA(0x00, 0x01, 0x02, 0x03)),
			Write(0x0006804,
			      DATA(0x04, 0x05, 0x06, 0x07)),
			Write(0x0006808,
			      DATA(0x08, 0x09, 0x0A, 0x0B)),
			Write(0x000680C,
			      DATA(0x0C, 0x0D, 0x0E, 0x0F)),
			Write(0x0006810,
			      DATA(0x10, 0x11, 0x12, 0x13)),
			Write(0x0006814,
			      DATA(0x14, 0x15, 0x16, 0x17)),
			Write(0x0006818,
			      DATA(0x18, 0x19, 0x1A, 0x1B)),
			Write(0x000681C,
			      DATA(0x1C, 0x1D, 0x1E, 0x1F)),
			/* Trigger a write of the SA keys #0.  */
			Write(0x00006000,
			      DATA(0x03, 0x00, 0x00, 0x00)),
			/* Trigger a read of the SA keys #0.  */
			Write(0x00006000,
			      DATA(0x01, 0x00, 0x00, 0x00)),
			/* The data above should be read back.  */
			Read(0x00006C00),
			Expect(DATA(0x8A, 0x7E, 0x26, 0x91), 4),
			Read(0x00006C04),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			Read(0x00006C08),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			Read(0x00006C0C),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			Read(0x00006C10),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			Read(0x00006C14),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			Read(0x00006C18),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),
			Read(0x00006C1C),
			Expect(DATA(0x00, 0x00, 0x00, 0x00), 4),

			/* Ditto for the last key.  */
			/* Trigger a read of the SA keys #1023.  */
			Write(0x00006000,
			      DATA(0x01, 0xFF, 0x03, 0x00)),
			/* For the model, the trigger bit is cleared
			 * instantly.
			 */
			Read(0x00006000),
			Expect(DATA(0x00, 0xFF, 0x03, 0x00), 4),
			/* The TX indirect read access register are supposed to
			 * be read only.  Write garbage to it, to check that it
			 * is the case.
			 */
			Write(0x0006C00,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C04,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C08,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C0C,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C10,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C14,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C18,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			Write(0x0006C1C,
			      DATA(0xDE, 0xAD, 0xDE, 0xAD)),
			/* Read the register back.  Since they should be zero,
			 * the CRC32 computation should be: 0xAD550A19.
			 */
			Read(0x00006C00),
			Expect(DATA(0xAD, 0x55, 0x0A, 0x19), 4),
			Read(0x00006C04),
			/* Rest should be read a zero.  */
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C08),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C0C),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C10),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C14),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C18),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C1C),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			/* Prepare an SA key for writing.  */
			Write(0x0006800,
			      DATA(0x20, 0x21, 0x22, 0x23)),
			Write(0x0006804,
			      DATA(0x24, 0x25, 0x26, 0x27)),
			Write(0x0006808,
			      DATA(0x28, 0x29, 0x2A, 0x2B)),
			Write(0x000680C,
			      DATA(0x2C, 0x2D, 0x2E, 0x2F)),
			Write(0x0006810,
			      DATA(0x30, 0x31, 0x32, 0x33)),
			Write(0x0006814,
			      DATA(0x34, 0x35, 0x36, 0x37)),
			Write(0x0006818,
			      DATA(0x38, 0x39, 0x3A, 0x3B)),
			Write(0x000681C,
			      DATA(0x3C, 0x3D, 0x3E, 0x3F)),
			/* Trigger a write of the SA keys #1023.  */
			Write(0x00006000,
			      DATA(0x03, 0xFF, 0x03, 0x00)),
			/* Trigger a read of the SA keys #1023.  */
			Write(0x00006000,
			      DATA(0x01, 0xFF, 0x03, 0x00)),
			/* The data above should be read back.  */
			Read(0x00006C00),
			Expect(DATA(0xE3, 0x06, 0xA6, 0xF6), 4),
			/* Rest should be read a zero.  */
			Read(0x00006C04),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C08),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C0C),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C10),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C14),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C18),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
			Read(0x00006C1C),
			Expect(DATA(SWAP(0x00, 0x00, 0x00, 0x00)), 4),
		}
		)
};

static std::vector<HSCTest *> tests({ &Test1, &Test2, &Test3 });

SC_MODULE(TestDevice)
{
public:
	SC_HAS_PROCESS(TestDevice);

	/* Block configuration.  */
	TLMTrafficGenerator tg_user;

	unsigned int m_testIdx;

	TestDevice(sc_module_name name):
		sc_module(name),
		tg_user("tg-user"),
		m_testIdx(0),
		plain_data_stream_monitor("plain_data_stream_monitor",
					  XILINX_HSC_MAX_PORT),
		encrypted_data_stream_generator("encrypted_data_generator",
						XILINX_HSC_MAX_PORT),
		encrypted_data_stream_monitor("encrypted_data_stream_monitor",
				       XILINX_HSC_MAX_PORT),
		plain_data_stream_generator("plain_data_stream_generator",
					    XILINX_HSC_MAX_PORT),
		enc_authentication_only("enc_authentication_only",
					XILINX_HSC_MAX_PORT),
		enc_crypto_bypass("enc_crypto_bypass",
				  XILINX_HSC_MAX_PORT),
		enc_crypto_cipher_suite("enc_crypto_cipher_suite",
					XILINX_HSC_MAX_PORT),
		enc_crypto_conf_offset("enc_crypto_conf_offset",
				       XILINX_HSC_MAX_PORT),
		enc_crypto_iv_salt("enc_crypto_iv_salt",
				   XILINX_HSC_MAX_PORT),
		enc_encryption_mode("enc_encryption_mode",
				    XILINX_HSC_MAX_PORT),
		enc_crypto_pkt_num("enc_crypto_pkt_num",
				   XILINX_HSC_MAX_PORT),
		enc_crypto_sa_index("enc_crypto_sa_index",
				    XILINX_HSC_MAX_PORT),
		enc_crypto_spare_in("enc_crypto_spare_in",
				    XILINX_HSC_MAX_PORT),
		enc_crypto_zlen("enc_crypto_zlen",
				XILINX_HSC_MAX_PORT),
		enc_ext_key("enc_ext_key",
			    XILINX_HSC_MAX_PORT),
		enc_macsec_sectag_an("enc_macsec_sectag_an",
				     XILINX_HSC_MAX_PORT),
		enc_macsec_sectag_sci("enc_macsec_sectag_sci",
				      XILINX_HSC_MAX_PORT),
		enc_macsec_sectag_shortlen("enc_macsec_sectag_shortlen",
				       XILINX_HSC_MAX_PORT),
		enc_macsec_sectag_ssci("enc_macsec_sectag_ssci",
				       XILINX_HSC_MAX_PORT),
		enc_macsec_sectag_tci("enc_macsec_sectag_tci",
				      XILINX_HSC_MAX_PORT),

		dec_authentication_only("dec_authentication_only",
					XILINX_HSC_MAX_PORT),
		dec_crypto_bypass("dec_crypto_bypass",
				  XILINX_HSC_MAX_PORT),
		dec_crypto_cipher_suite("dec_crypto_cipher_suite",
					XILINX_HSC_MAX_PORT),
		dec_crypto_conf_offset("dec_crypto_conf_offset",
				       XILINX_HSC_MAX_PORT),
		dec_crypto_icv("dec_crypto_icv",
			       XILINX_HSC_MAX_PORT),
		dec_crypto_iv_salt("dec_crypto_iv_salt",
				   XILINX_HSC_MAX_PORT),
		dec_encryption_mode("dec_encryption_mode",
				    XILINX_HSC_MAX_PORT),
		dec_crypto_replay_prot_en("dec_crypto_replay_prot_en",
					  XILINX_HSC_MAX_PORT),
		dec_crypto_sa_index("dec_crypto_sa_index",
				    XILINX_HSC_MAX_PORT),
		dec_crypto_spare_in("dec_crypto_spare_in",
				    XILINX_HSC_MAX_PORT),
		dec_crypto_zlen("dec_crypto_zlen",
				XILINX_HSC_MAX_PORT),
		dec_ext_key("dec_ext_key",
			    XILINX_HSC_MAX_PORT),
		dec_macsec_sa_in_use("dec_macsec_sa_in_use",
				     XILINX_HSC_MAX_PORT),
		dec_macsec_validation_mode("dec_macsec_validation_mode",
					   XILINX_HSC_MAX_PORT)
	{
		tg_user.setStartDelay(sc_time(10, SC_US));
		tg_user.addTransfers(tests[m_testIdx]->traffic,
					0, Done_Callback);

		for (int port = 0; port < XILINX_HSC_MAX_PORT; port++) {
			this->encrypted_data_stream_monitor[port]
				.register_b_transport(this,
						&TestDevice::encrypted_monitor,
						port);
			this->plain_data_stream_monitor[port]
				.register_b_transport(this,
						&TestDevice::plain_monitor,
						port);
		}
	}

	void bind(xilinx_hsc &hsc)
	{
		tg_user.socket.bind(hsc.user_if_socket);

		for (int port = 0; port < XILINX_HSC_MAX_PORT; port++) {
			this->encrypted_data_stream_generator[port].bind(
				hsc.encrypted_data_stream_inputs[port]);
			this->plain_data_stream_generator[port].bind(
				hsc.plain_data_stream_inputs[port]);
			hsc.encrypted_data_stream_outputs[port].bind(
				this->encrypted_data_stream_monitor[port]);
			hsc.plain_data_stream_outputs[port].bind(
				this->plain_data_stream_monitor[port]);

			/* Encoder Ingress.  */
			hsc.enc_igr_prtif_crypto_auth_only[port](
				this->enc_authentication_only[port]);
			hsc.enc_igr_prtif_crypto_byp[port](
				this->enc_crypto_bypass[port]);
			hsc.enc_igr_prtif_crypto_cipher_suite[port](
				this->enc_crypto_cipher_suite[port]);
			hsc.enc_igr_prtif_crypto_conf_offset[port](
				this->enc_crypto_conf_offset[port]);
			hsc.enc_igr_prtif_crypto_iv_salt[port](
				this->enc_crypto_iv_salt[port]);
			hsc.enc_igr_prtif_crypto_mode[port](
				this->enc_encryption_mode[port]);
			hsc.enc_igr_prtif_crypto_pkt_num[port](
				this->enc_crypto_pkt_num[port]);
			hsc.enc_igr_prtif_crypto_sa_index[port](
				this->enc_crypto_sa_index[port]);
			hsc.enc_igr_prtif_crypto_spare_in[port](
				this->enc_crypto_spare_in[port]);
			hsc.enc_igr_prtif_crypto_zlen[port](
				this->enc_crypto_zlen[port]);
			hsc.enc_igr_prtif_ext_key[port](
				this->enc_ext_key[port]);
			hsc.enc_igr_prtif_macsec_sectag_an[port](
				this->enc_macsec_sectag_an[port]);
			hsc.enc_igr_prtif_macsec_sectag_sci[port](
				this->enc_macsec_sectag_sci[port]);
			hsc.enc_igr_prtif_macsec_sectag_shortlen[port](
				this->enc_macsec_sectag_shortlen[port]);
			hsc.enc_igr_prtif_macsec_sectag_ssci[port](
				this->enc_macsec_sectag_ssci[port]);
			hsc.enc_igr_prtif_macsec_sectag_tci[port](
				this->enc_macsec_sectag_tci[port]);

			/* Decoder Ingress.  */
			hsc.dec_igr_prtif_crypto_auth_only[port](
				this->dec_authentication_only[port]);
			hsc.dec_igr_prtif_crypto_byp[port](
				this->dec_crypto_bypass[port]);
                        hsc.dec_igr_prtif_crypto_cipher_suite[port](
				this->dec_crypto_cipher_suite[port]);
			hsc.dec_igr_prtif_crypto_conf_offset[port](
				this->dec_crypto_conf_offset[port]);
			hsc.dec_igr_prtif_crypto_icv[port](
				this->dec_crypto_icv[port]);
			hsc.dec_igr_prtif_crypto_iv_salt[port](
				this->dec_crypto_iv_salt[port]);
			hsc.dec_igr_prtif_crypto_mode[port](
				this->dec_encryption_mode[port]);
			hsc.dec_igr_prtif_crypto_replay_prot_en[port](
				this->dec_crypto_replay_prot_en[port]);
			hsc.dec_igr_prtif_crypto_sa_index[port](
				this->dec_crypto_sa_index[port]);
			hsc.dec_igr_prtif_crypto_spare_in[port](
				this->dec_crypto_spare_in[port]);
			hsc.dec_igr_prtif_crypto_zlen[port](
				this->dec_crypto_zlen[port]);
			hsc.dec_igr_prtif_ext_key[port](
				this->dec_ext_key[port]);
			hsc.dec_igr_prtif_macsec_sa_in_use[port](
				this->dec_macsec_sa_in_use[port]);
			hsc.dec_igr_prtif_macsec_validation_mode[port](
				this->dec_macsec_validation_mode[port]);
		}
	}

	void test_loop(TLMTrafficGenerator *gen, int threadId)
	{
		assert(tests[m_testIdx]->traffic.done());
		cout << endl << " * " << tests[m_testIdx]->name << ": done!"
		     << endl;
		m_testIdx++;

		if (m_testIdx < tests.size()) {
			tg_user.addTransfers(tests[m_testIdx]->traffic,
					     0, Done_Callback);
		} else {
			this->encryption_decryption_test();
			sc_stop();
		}
	}

 private:
	sc_core::sc_vector <tlm_utils::simple_target_socket_tagged<TestDevice>>
		plain_data_stream_monitor;
	sc_core::sc_vector <tlm_utils::simple_initiator_socket<TestDevice>>
		encrypted_data_stream_generator;
	sc_core::sc_vector <tlm_utils::simple_target_socket_tagged<TestDevice>>
		encrypted_data_stream_monitor;
	sc_core::sc_vector <tlm_utils::simple_initiator_socket<TestDevice>>
		plain_data_stream_generator;

	sc_core::sc_vector<sc_signal<bool> > enc_authentication_only;
	sc_core::sc_vector<sc_signal<bool> > enc_crypto_bypass;
	sc_core::sc_vector<sc_signal<sc_int<2>> > enc_crypto_cipher_suite;
	sc_core::sc_vector<sc_signal<sc_int<6>> > enc_crypto_conf_offset;
	/* Unmodelled.  */
	sc_core::sc_vector<sc_signal<sc_bigint<96>> > enc_crypto_iv_salt;
	sc_core::sc_vector<sc_signal<sc_int<2>> > enc_encryption_mode;
	sc_core::sc_vector<sc_signal<sc_int<64>> > enc_crypto_pkt_num;
	sc_core::sc_vector<sc_signal<sc_int<20>> > enc_crypto_sa_index;
	sc_core::sc_vector<sc_signal<sc_int<32>> > enc_crypto_spare_in;
	sc_core::sc_vector<sc_signal<bool> > enc_crypto_zlen;
	sc_core::sc_vector<sc_signal<sc_bigint<256>> > enc_ext_key;
	sc_core::sc_vector<sc_signal<sc_int<2>> > enc_macsec_sectag_an;
	sc_core::sc_vector<sc_signal<sc_int<64>> > enc_macsec_sectag_sci;
	sc_core::sc_vector<sc_signal<sc_int<8>> > enc_macsec_sectag_shortlen;
	sc_core::sc_vector<sc_signal<sc_int<32>> > enc_macsec_sectag_ssci;
	sc_core::sc_vector<sc_signal<sc_int<6>> > enc_macsec_sectag_tci;

	sc_core::sc_vector<sc_signal<bool> > dec_authentication_only;
	sc_core::sc_vector<sc_signal<bool> > dec_crypto_bypass;
	sc_core::sc_vector<sc_signal<sc_int<2>> > dec_crypto_cipher_suite;
	sc_core::sc_vector<sc_signal<sc_int<6>> > dec_crypto_conf_offset;
	sc_core::sc_vector<sc_signal<sc_bigint<128>> > dec_crypto_icv;
	sc_core::sc_vector<sc_signal<sc_bigint<96>> > dec_crypto_iv_salt;
	sc_core::sc_vector<sc_signal<sc_int<2>> > dec_encryption_mode;
	sc_core::sc_vector<sc_signal<bool> > dec_crypto_replay_prot_en;
	sc_core::sc_vector<sc_signal<sc_int<20>> > dec_crypto_sa_index;
	sc_core::sc_vector<sc_signal<sc_int<32>> > dec_crypto_spare_in;
	sc_core::sc_vector<sc_signal<bool> > dec_crypto_zlen;
	sc_core::sc_vector<sc_signal<sc_bigint<256>> > dec_ext_key;
	sc_core::sc_vector<sc_signal<bool> > dec_macsec_sa_in_use;
	sc_core::sc_vector<sc_signal<bool> > dec_macsec_validation_mode;

	/* Data going to be encrypted.  */
	uint8_t *plain_data;
	size_t plain_data_size;
	/* Data encrypted.  */
	uint8_t *encrypted_data;
	size_t encrypted_data_size;
	/* Data decrypted. */
	uint8_t *decrypted_data;
	size_t decrypted_data_size;

	void check_tests()
	{
		if (this->plain_data_size != this->decrypted_data_size) {
			goto err;
		}

		for (size_t i = 0; i < this->plain_data_size; i++) {
			if (this->plain_data[i] != this->decrypted_data[i]) {
				goto err;
			}
		}

		SC_REPORT_INFO("CHECK_HSC - check_tests",
			       "Packet are matching");
		return;
	err:
		/* Something wrong happened.  */
		SC_REPORT_ERROR("CHECK_HSC - check_tests",
				"Encryption / Decryption not working");
	}

	/* Encryption / Description test:
	 *   - Put the encryption in macsec mode.
	 *   - Send a packet ethernet packet.
	 *   - Decrypt it.
	 *   - Compare input output.
	 */
	void encryption_decryption_test()
	{
		const uint8_t test_packet[] = {
			/* Dest MAC address.  */
			0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
			/* Src MAC address.  */
			0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
			/* IP.  */
			0x08, 0x00,
			/* Some data.  */
			0x4c, 0x6f, 0x72, 0x65, 0x6d, 0x20, 0x69, 0x70, 0x73,
			0x75, 0x6d, 0x20, 0x64, 0x6f, 0x6c, 0x6f, 0x72, 0x20,
			0x73, 0x69, 0x74, 0x20, 0x61, 0x6d, 0x65, 0x74, 0x2c,
			0x20, 0x63, 0x6f, 0x6e, 0x73, 0x65, 0x63, 0x74, 0x65,
			0x74, 0x75, 0x72, 0x20, 0x61, 0x64, 0x69, 0x70, 0x69,
			0x73, 0x63, 0x69, 0x6e, 0x67, 0x20, 0x65, 0x6c, 0x69,
			0x74, 0x2c, 0x20, 0x73, 0x65, 0x64, 0x20, 0x64, 0x6f,
			0x20, 0x65, 0x69, 0x75, 0x73, 0x6d, 0x6f, 0x64, 0x20,
			0x74, 0x65, 0x6d, 0x70, 0x6f, 0x72, 0x20, 0x69, 0x6e,
			0x63, 0x69, 0x64, 0x69, 0x64, 0x75, 0x6e, 0x74, 0x20,
			0x75, 0x74, 0x20, 0x6c, 0x61, 0x62, 0x6f, 0x72, 0x65,
			0x20, 0x65, 0x74, 0x20, 0x64, 0x6f, 0x6c, 0x6f, 0x72,
			0x65, 0x20, 0x6d, 0x61, 0x67, 0x6e, 0x61, 0x20, 0x61,
			0x6c, 0x69, 0x71, 0x75, 0x61, 0x2e, 0x0
		};
		sc_time delay(SC_ZERO_TIME);
		tlm::tlm_generic_payload trans;
		genattr_extension *genattr = new genattr_extension();

		std::cout << std::endl
			  << " * Test4: Encryption / Decryption test"
			  << std::endl;

		this->plain_data_size = sizeof(test_packet);
		this->plain_data = new uint8_t[this->plain_data_size];
		memcpy(this->plain_data, test_packet, this->plain_data_size);

		/* Send a stream to the HSC block and expects it to returns
		 * encrypted.  */
		/* Set the encryption mode for port 0.  */
		this->enc_encryption_mode[0].write(xilinx_hsc:: MACsec);
		sc_core::wait(SC_ZERO_TIME);
		/* Send some datas on port 0.  */
		trans.set_command(tlm::TLM_WRITE_COMMAND);
		trans.set_data_ptr((unsigned char *)this->plain_data);
		trans.set_streaming_width(4);
		trans.set_data_length(this->plain_data_size);
		genattr->set_eop(true);
		trans.set_extension(genattr);
		/* Send data to the encryption part.  */
		this->plain_data_stream_generator[0]->b_transport(trans, delay);
		trans.release_extension(genattr);
		/* Compare input / output.  */
		this->check_tests();
	}

	void encrypted_monitor(int port,
			       tlm::tlm_generic_payload& trans,
			       sc_time& delay)
	{
		genattr_extension *genattr;
		tlm::tlm_command cmd = trans.get_command();
		sc_dt::uint64 addr = trans.get_address();
		unsigned char *data = trans.get_data_ptr();
		size_t len = trans.get_data_length();
		unsigned char *byte_en = trans.get_byte_enable_ptr();

		trans.get_extension(genattr);

		if (!genattr->get_eop()
		    || byte_en
		    || cmd != tlm::TLM_WRITE_COMMAND
		    || addr) {
			goto err;
		}

		this->encrypted_data_size = len;
		this->encrypted_data = new uint8_t[this->encrypted_data_size];
		memcpy(this->encrypted_data, data, this->encrypted_data_size);

		/* Forward that packet to the decrypter.  */
		this->encrypted_data_stream_generator[0]->b_transport(trans,
								      delay);
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
		return;
	err:
		/* Something wrong happened.  */
		SC_REPORT_ERROR("CHECK_HSC - encrypted monitor",
				"Bad TXN for encrypted packet");
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		return;
	}

	void plain_monitor(int port,
			   tlm::tlm_generic_payload& trans,
			   sc_time& delay)
	{
		genattr_extension *genattr;
		tlm::tlm_command cmd = trans.get_command();
		sc_dt::uint64 addr = trans.get_address();
		unsigned char *data = trans.get_data_ptr();
		size_t len = trans.get_data_length();
		unsigned char *byte_en = trans.get_byte_enable_ptr();

		trans.get_extension(genattr);

		if (!genattr->get_eop()
		    || byte_en
		    || cmd != tlm::TLM_WRITE_COMMAND
		    || addr) {
			goto err;
		}

		this->decrypted_data_size = len;
		this->decrypted_data = new uint8_t[this->decrypted_data_size];
		memcpy(this->decrypted_data, data, this->decrypted_data_size);
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
		return;
	err:
		/* Something wrong happened.  */
		SC_REPORT_ERROR("CHECK_HSC - decrypted monitor",
				"Bad TXN for decrypted packet");
		trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
		return;
	}

	void dump_packet(const char* title, const uint8_t *data, size_t len,
			 size_t user_data_offset = 14)
	{
		std::string current_color = std::string("\x1B[48;5;01m");
		size_t i;

		std::cout << "Dumping packet: " << title << " size: "
			  << std::hex << "0x" << len << std::endl;

		for (i = 0; i < len; i++) {
			/* Colors handling.  */
			if ((i >= 6) && (i < 12)) {
				/* MAC DEST.  */
				current_color = std::string("\x1B[48;5;05m");
				std::cout << current_color;
			} else if ((i >= 12) && (i < 14)) {
				/* Ethertype.  */
				current_color = std::string("\x1B[48;5;02m");
				std::cout << current_color;
			} else if (i >= user_data_offset) {
				/* Userdata.  */
				current_color = std::string("\x1B[48;5;04m");
				std::cout << current_color;
			}

			if (!(i % 16)) {
				std::cout << "\x1B[00m";
				std::cout << std::hex << "0x"
					  << std::setfill('0')
					  << std::setw(2)
					  << (int)i
					  << ": ";
				std::cout << current_color;
			}
			std::cout << std::hex << std::setw(2) << (int)data[i];
			if (!((i + 1) % 16)) {
				std::cout << "\x1B[48;5;00m" << std::endl;
			} else if (i + 1 != len) {
				std::cout << " ";
			}
		}

		std::cout << "\x1B[00m" << "";
		if ((i + 1) % 16) {
			std::cout << std::endl;
		}
	}
};

TestDevice *glob_tester = NULL;

static void Done_Callback(TLMTrafficGenerator *gen, int threadId)
{
	assert(glob_tester);
	glob_tester->test_loop(gen, threadId);
}

SC_MODULE(Top)
{
public:
	SC_HAS_PROCESS(Top);

	xilinx_hsc hsc;
	TestDevice test;
	sc_signal<bool> rst;

	Top(sc_module_name name) :
		sc_module(name),
		hsc("hsc-device"),
		test("hsc-tester")
	{
		test.bind(hsc);
		glob_tester = &this->test;

		hsc.rst(rst);
		SC_THREAD(pull_reset);
	}

	void pull_reset(void) {
		/* Pull the reset signal.  */
		rst.write(true);
		wait(1, SC_US);
		rst.write(false);
	}
};

int sc_main(int argc, char *argv[])
{
	Top top("Top");

	sc_start();

	return 0;
}

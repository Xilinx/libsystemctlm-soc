/*
 * High Speed Crypto model.
 *
 * Copyright (c) 2022 Advanced Micro Devices Inc.
 * Written by Fred Konrad.
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

#ifndef HSC_H
#define HSC_H

#define XILINX_HSC_MAX_PORT     (4)
#define XILINX_HSC_MAX_REGS     (0x7D00 >> 2)
#define XILINX_HSC_MAX_KEY_SIZE_BYTES (256 / 8)
#define XILINX_HSC_MAX_KEY_SIZE (8)
#define XILINX_HSC_MAX_KEYS     (1024)

#include <systemc>
#include "tlm-extensions/genattr.h"

class xilinx_hsc
	: public sc_core::sc_module
{
	SC_HAS_PROCESS(xilinx_hsc);
public:
	enum CryptoCipherSuite {
		GCM_AES_128 = 0,
		GCM_AES_256 = 1,
		GCM_AES_XPN_128 = 2,
		GCM_AES_XPN_256 = 3,
	};

	enum CryptoMode {
		MACsec = 0,
		IPsec = 1,
		BulkCrypto = 2,
		BulkECB = 3,
	};

	/* User axi-lite socket for configuration and statistics access.  */
	tlm_utils::simple_target_socket<xilinx_hsc> user_if_socket;

	/* Encryption block stream input and ouput.  */
	sc_core::sc_vector <tlm_utils::simple_target_socket_tagged<xilinx_hsc>>
	    plain_data_stream_inputs;
	sc_core::sc_vector <tlm_utils::simple_initiator_socket<xilinx_hsc>>
	    encrypted_data_stream_outputs;
	sc_core::sc_vector<sc_core::sc_in<bool> >
	    enc_igr_prtif_crypto_auth_only;
	sc_core::sc_vector<sc_core::sc_in<bool> >
	    enc_igr_prtif_crypto_byp;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<2>> >
            enc_igr_prtif_crypto_cipher_suite;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<6>> >
            enc_igr_prtif_crypto_conf_offset;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_bigint<96>> >
            enc_igr_prtif_crypto_iv_salt;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<2>> >
            enc_igr_prtif_crypto_mode;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<64>> >
            enc_igr_prtif_crypto_pkt_num;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<20>> >
            enc_igr_prtif_crypto_sa_index;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<32>> >
            enc_igr_prtif_crypto_spare_in;
	sc_core::sc_vector<sc_core::sc_in<bool> >
            enc_igr_prtif_crypto_zlen;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_bigint<256>> >
            enc_igr_prtif_ext_key;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<2>> >
            enc_igr_prtif_macsec_sectag_an;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<64>> >
            enc_igr_prtif_macsec_sectag_sci;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<8>> >
            enc_igr_prtif_macsec_sectag_shortlen;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<32>> >
	    enc_igr_prtif_macsec_sectag_ssci;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<6>> >
	    enc_igr_prtif_macsec_sectag_tci;

	/* Decryption block stream input and ouput.  */
	sc_core::sc_vector <tlm_utils::simple_target_socket_tagged<xilinx_hsc>>
	    encrypted_data_stream_inputs;
	sc_core::sc_vector <tlm_utils::simple_initiator_socket<xilinx_hsc>>
	    plain_data_stream_outputs;
	/* Decryption Ingress per-port interface.  */
	sc_core::sc_vector<sc_core::sc_in<bool> >
	    dec_igr_prtif_crypto_auth_only;
	sc_core::sc_vector<sc_core::sc_in<bool> >
	    dec_igr_prtif_crypto_byp;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<2>> >
            dec_igr_prtif_crypto_cipher_suite;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<6>> >
            dec_igr_prtif_crypto_conf_offset;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_bigint<128>> >
            dec_igr_prtif_crypto_icv;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_bigint<96>> >
            dec_igr_prtif_crypto_iv_salt;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<2>> >
	    dec_igr_prtif_crypto_mode;
	sc_core::sc_vector<sc_core::sc_in<bool> >
	    dec_igr_prtif_crypto_replay_prot_en;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<20>> >
	    dec_igr_prtif_crypto_sa_index;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_int<32>> >
            dec_igr_prtif_crypto_spare_in;
	sc_core::sc_vector<sc_core::sc_in<bool> >
            dec_igr_prtif_crypto_zlen;
	sc_core::sc_vector<sc_core::sc_in<sc_dt::sc_bigint<256>> >
            dec_igr_prtif_ext_key;
	sc_core::sc_vector<sc_core::sc_in<bool> >
            dec_igr_prtif_macsec_sa_in_use;
	sc_core::sc_vector<sc_core::sc_in<bool> >
            dec_igr_prtif_macsec_validation_mode;

	sc_core::sc_in<bool> rst;
	xilinx_hsc(sc_core::sc_module_name name);
private:
	/* NOTE: GROUP_CONFIG isn't available in TX mode.  */
	enum IndirectRegisterGroup {
		GROUP_SA_KEYS = 0,
		GROUP_CONFIG = 1,
		GROUP_SECY_STAT = 2,
		GROUP_SC_STAT = 3
	};

	enum DataRate {
		DATA_RATE_2x100G = 0,
		DATA_RATE_1x200G = 1,
		DATA_RATE_1x400G_CHANNELIZED = 2,
		DATA_RATE_1x400G_FIXED = 3
	};

	void reset_thread(void);
	/* Reset the encoder port.  */
	void reset_enc_port(int port);
	/* Reset the decoder port.  */
	void reset_dec_port(int port);
	void plain_input_stream_b_transport(int id,
					    tlm::tlm_generic_payload& trans,
					    sc_core::sc_time& delay);
	void encrypted_input_stream_b_transport(int id,
						tlm::tlm_generic_payload& trans,
						sc_core::sc_time& delay);
	void user_if_b_transport(tlm::tlm_generic_payload& trans,
				 sc_core::sc_time& delay);

	uint32_t regs[XILINX_HSC_MAX_REGS];
	uint32_t encoder_keys[XILINX_HSC_MAX_KEY_SIZE][XILINX_HSC_MAX_KEYS];
	uint32_t decoder_keys[XILINX_HSC_MAX_KEY_SIZE][XILINX_HSC_MAX_KEYS];

	/* TX/RX keys and stats access helper.  */
	void reg_indirect_access(bool tx);

	/* Common configuration for encoder / decoder paths.  */
	struct fixed_common {
		/* Amount of bytes consumed since the start of the packet,
		 * if 0: the packet didn't start yet.  */
		size_t byte_count;

		/* Authenticate only:  if true, only do authentication check
		 * on non-bypassed packets, don't encrypt them.  */
		bool crypto_auth_only;

		/* Bypass enable: if true, the encryption and authentication is
		 * disabled, for that packet.  */
		bool crypto_byp;

		/* Encryption cipher suite: selects between GCM-AES-128,
		 * GCM-AES-256, GCM-AES-XPN-128 or
		 * GCM-AES-XPN-256.  (Encryption is not implemented anyway).  */
		int crypto_cipher_suite;

		/* Encryption confidentiality offset: offset in the packet or
		 * after the sectag (for MACsec mode) to begin the encryption.
		 * Only 0, 30 and 50 are valid for MACsec, others are read as
		 * 0.  */
		int crypto_conf_offset;

		/* Salt value (not used in this model).  */
		uint64_t crypto_iv_salt[2];

		/* Crypto mode in use for this port.  */
		int crypto_mode;

		/* Security Association Index (SA).  */
		int crypto_sa_index;

		/* Spare input: those data are carried through the encryption
		 * pipeline and delivered on spare_out signals.  */
		uint32_t crypto_spare_in;

		/* Zero length payload: IPSec only, must be set for 0 length
		 * payload packet.  Should be 0 for other crypto mode, must be
		 * 0 for decoder.  */
		bool crypto_zlen;

		/* External key, when SA > 1023.  */
		uint8_t crypto_ext_key[32];
	};

	/* Current per-port state of the decoder.  */
	struct fixed_dec {
		struct fixed_common common;

		/* ICV, not used in this model.  */
		uint64_t decrypt_icv[2];

		/* Enable replay protection (not modeled).  */
		bool crypto_replay_prot_env;

		/* Reflect the setting of the inUse flag.  */
		bool macsec_sa_in_use;
	} fixed_dec[XILINX_HSC_MAX_PORT];

	/* Current per-port state of the encoder.  */
	struct fixed_enc {
		/* Common configuration for encoder / decoder.  See above.  */
		struct fixed_common common;

		/* Packet number for that packet.  */
		int64_t crypto_packet_number;

		/* MACsec sectag AN field.  */
		uint8_t macsec_sectag_an;

		/* MACsec sectag SCI field.  */
		uint64_t macsec_sectag_sci;

		/* MACsec shortlen: Number of bit between SecTag and ICV in
		 * case the packet is shorter than 48 bytes.  */
		uint8_t macsec_sectag_shortlen;

		/* MACsec Short Secure Channel Identifier:
		 * Used to construct the IV for XPN cipher suite (not used).
		 */
		uint32_t macsec_sectag_ssci;

		/* MACsec tag control information: used to for the sectag.  */
		uint8_t macsec_sectag_tci;
	} fixed_enc[XILINX_HSC_MAX_PORT];
};

#endif /* HSC_H */

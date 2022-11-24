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

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <inttypes.h>
#include <stdio.h>

#include "systemc.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "utils/hexdump.h"

using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "soc/crypto/xilinx/hsc/hsc.h"
#include "utils/crc32.h"

#define HSC_REVID (0x00000001)

#define CONFIGURATION_REVISION              (0x00000 >> 2)
#define TEST_DEBUG                          (0x00004 >> 2)
#define EMA_CONFIGURATION                   (0x00008 >> 2)
#define BISR_SCRATCHPAD_DATA_31TO0          (0x0000C >> 2)
#define BISR_SCRATCHPAD_DATA_63TO31         (0x00010 >> 2)
#define CLOCK_DISABLE                       (0x00014 >> 2)
#define RSVD_MEMCELL_RX                     (0x00040 >> 2)
#define RSVD_MEMCELL_TX                     (0x00044 >> 2)
#define RSVD1_MEMCELL_RX                    (0x00048 >> 2)
#define RSVD1_MEMCELL_TX                    (0x0004C >> 2)
#define GLOBAL_CONTROL_REG_RX               (0x000F0 >> 2)
#define GLOBAL_CONTROL_REG_TOP              (0x000F4 >> 2)
#define GLOBAL_CONTROL_REG_TX               (0x000F8 >> 2)
#define GLOBAL_USER_REG                     (0x000FC >> 2)
#define OVERALL_CONTROL_REG_ENC             (0x00100 >> 2)
#define OVERALL_CONTROL_REG_DEC             (0x00200 >> 2)
#define P0_CONFIGURATION_ENC_MAIN           (0x01000 >> 2)
#define P0_CONFIGURATION_DEC_MAIN           (0x01004 >> 2)
#define P2_CONFIGURATION_ENC_MAIN           (0x01200 >> 2)
#define P2_CONFIGURATION_DEC_MAIN           (0x01204 >> 2)
#define BROAD_CONFIG_REG_ENC                (0x01208 >> 2)
#define BROAD_CONFIG_REG_DEC                (0x0120C >> 2)
#define STAT_TX_ENC_GENERAL_STATUS_REG      (0x02000 >> 2)
#define STAT_TX_ENC_CH_FIFO_STATUS_REG(n)   ((0x02004 + 4 * (n)) >> 2)
#define STAT_RX_DEC_GENERAL_STATUS_REG      (0x02800 >> 2)
#define STAT_RX_DEC_CH_FIFO_STATUS_REG(n)   ((0x02804 + 4 * (n)) >> 2)
#define CAVP_TX_ENC_REQ_PORT_REG            (0x03000 >> 2)
#define CAVP_TX_ENC_REQ_MODE_REG            (0x03004 >> 2)
#define CAVP_TX_ENC_REQ_LEN_REG             (0x03008 >> 2)
#define CAVP_TX_ENC_REQ_KEY_REG(n)          ((0x0300C + (n) * 4) >> 2)
#define CAVP_TX_ENC_REQ_IV_SALT_REG(n)      ((0x0302C + (n) * 4) >> 2)
#define CAVP_TX_ENC_REQ_TXT_REG(n,m)        ((0x03038 + 0x10 * (n) \
					      + 4 * (m)) >> 2)
#define CAVP_TX_ENC_REQ_CTRL_REG            (0x030D8 >> 2)
#define CAVP_TX_ENC_RESP_STAT_REG           (0x03400 >> 2)
#define CAVP_TX_ENC_RESP_TXT_BCNT_REG       (0x03404 >> 2)
#define CAVP_TX_ENC_RESP_TXT_REG(n,m)       ((0x03408 + 0x10 * (n) \
					      + 4 * (m)) >> 2)
#define CAVP_TX_ENC_RESP_TAG_REG            (0x03548 + 4 * (n) >> 2)
#define CAVP_TX_ENC_RESP_TMR_REG            (0x03558 >> 2)
#define CAVP_RX_DEC_REQ_PORT_REG            (0x03800 >> 2)
#define CAVP_RX_DEC_REQ_MODE_REG            (0x03804 >> 2)
#define CAVP_RX_DEC_REQ_LEN_REG             (0x03808 >> 2)
#define CAVP_RX_DEC_REQ_KEY_REG(n)          ((0x0380C + 4 * (n)) >> 2)
#define CAVP_RX_DEC_REQ_IV_SALT_REG(n)      ((0x0382C + 4 * (n))  >> 2)
#define CAVP_RX_DEC_REQ_TXT_REG(n,m)        ((0x03838 + 0x10 * (n) \
					      + 4 * (m)) >> 2)
#define CAVP_RX_DEC_REQ_TAG_REG(n)          ((0x038D8 + 4 * (n)) >> 2)
#define CAVP_RX_DEC_REQ_CTRL_REG            (0x038E8 >> 2)
#define CAVP_RX_DEC_RESP_STAT_REG           (0x03C00 >> 2)
#define CAVP_RX_DEC_RESP_TXT_BCNT_REG       (0x03C04 >> 2)
#define CAVP_RX_DEC_RESP_TXT_REG(n, m)      ((0x03C08 + 0x10 * (n) \
					      + 4 * (m)) >> 2)
#define CAVP_RX_DEC_RESP_TMR_REG            (0x03D48 >> 2)
#define TX_INDIRECT_AXS_CTRL_REG            (0x04000 >> 2)
#define TX_INDIRECT_AXS_WDATA_REG(n)        ((0x04800 + (n) * 4) >> 2)
#define TX_INDIRECT_AXS_RDATA_REG(n)        ((0x04C00 + (n) * 4) >> 2)
#define CTL_TX_ENC_RAM_ECC_STAT_CLEAR_REG   (0x04F00 >> 2)
#define STAT_TX_ENC_RAM_ECC_STATUS_REG      (0x04F04 >> 2)
#define STAT_TX_ENC_RAM_ECC_CORR_CNT_REG    (0x04F08 >> 2)
#define STAT_TX_ENC_RAM_ECC_UNCORR_CNT_REG  (0x04F0C >> 2)
#define RX_INDIRECT_AXS_CTRL_REG            (0x06000 >> 2)
#define RX_INDIRECT_AXS_WDATA_REG(n)        ((0x06800 + (n) * 4) >> 2)
#define RX_INDIRECT_AXS_RDATA_REG(n)        ((0x06C00 + (n) * 4) >> 2)
#define CTL_RX_DEC_RAM_ECC_STAT_CLEAR_REG   (0x06F00 >> 2)
#define STAT_RX_DEC_RAM_ECC_STATUS_REG      (0x06F04 >> 2)
#define STAT_RX_DEC_RAM_ECC_CORR_CNT_REG    (0x06F08 >> 2)
#define STAT_RX_DEC_RAM_ECC_UNCORR_CNT_REG  (0x06F0C >> 2)
#define CH_CTL_TX_MAIN_REG(n)               ((0x07000 + (n) * 0x20) >> 2)
#define CH_CTL_TX_MACSEC_ETHERTYPE(n)       ((0x07004 + (n) * 0x20) >> 2)
#define CH_CTL_TX_GENERAL_REG(n)            ((0x07008 + (n) * 0x20) >> 2)
#define CH_CTL_TX_EXTRA_REG(n)              ((0x0700C + (n) * 0x20) >> 2)
#define CH_CTL_RX_MAIN_REG(n)               ((0x07800 + (n) * 0x20) >> 2)
#define CH_CTL_RX_MACSEC_ETHERTYPE(n)       ((0x07804 + (n) * 0x20) >> 2)
#define CH_CTL_RX_EXTRA_REG(n)              ((0x0780C + (n) * 0x20) >> 2)

xilinx_hsc::xilinx_hsc(sc_module_name name):
	sc_module(name),
	user_if_socket("user_if"),
	plain_data_stream_inputs("plain_data_stream_input",
				 XILINX_HSC_MAX_PORT),
	encrypted_data_stream_outputs("encrypted_data_stream_output",
				      XILINX_HSC_MAX_PORT),
	enc_igr_prtif_crypto_auth_only("enc_igr_prtif_crypto_auth_only",
				       XILINX_HSC_MAX_PORT),
	enc_igr_prtif_crypto_byp("enc_igr_prtif_crypto_byp",
				 XILINX_HSC_MAX_PORT),
	enc_igr_prtif_crypto_cipher_suite("enc_igr_prtif_crypto_cipher_suite",
					  XILINX_HSC_MAX_PORT),
	enc_igr_prtif_crypto_conf_offset("enc_igr_prtif_crypto_conf_offset",
					 XILINX_HSC_MAX_PORT),
	enc_igr_prtif_crypto_iv_salt("enc_igr_prtif_crypto_iv_salt",
				     XILINX_HSC_MAX_PORT),
	enc_igr_prtif_crypto_mode("enc_igr_prtif_crypto_mode",
				  XILINX_HSC_MAX_PORT),
	enc_igr_prtif_crypto_pkt_num("enc_igr_prtif_crypto_pkt_num",
				     XILINX_HSC_MAX_PORT),
	enc_igr_prtif_crypto_sa_index("enc_igr_prtif_crypto_sa_index",
				      XILINX_HSC_MAX_PORT),
	enc_igr_prtif_crypto_spare_in("enc_igr_prtif_crypto_spare_in",
				      XILINX_HSC_MAX_PORT),
	enc_igr_prtif_crypto_zlen("enc_igr_prtif_crypto_zlen",
				  XILINX_HSC_MAX_PORT),
	enc_igr_prtif_ext_key("enc_igr_prtif_ext_key",
			      XILINX_HSC_MAX_PORT),
	enc_igr_prtif_macsec_sectag_an("enc_igr_prtif_macsec_sectag_an",
				       XILINX_HSC_MAX_PORT),
	enc_igr_prtif_macsec_sectag_sci("enc_igr_prtif_macsec_sectag_sci",
					XILINX_HSC_MAX_PORT),
	enc_igr_prtif_macsec_sectag_shortlen(
		                        "enc_igr_prtif_macsec_sectag_shortlen",
					XILINX_HSC_MAX_PORT),
	enc_igr_prtif_macsec_sectag_ssci("enc_igr_prtif_macsec_sectag_ssci",
					 XILINX_HSC_MAX_PORT),
	enc_igr_prtif_macsec_sectag_tci("enc_igr_prtif_macsec_sectag_tci",
					XILINX_HSC_MAX_PORT),
	encrypted_data_stream_inputs("encrypted_data_stream_input",
				     XILINX_HSC_MAX_PORT),
	plain_data_stream_outputs("plain_data_stream_outputs",
				  XILINX_HSC_MAX_PORT),
	dec_igr_prtif_crypto_auth_only("dec_igr_prtif_crypto_auth_only",
				       XILINX_HSC_MAX_PORT),
	dec_igr_prtif_crypto_byp("dec_igr_prtif_crypto_byp",
				 XILINX_HSC_MAX_PORT),
	dec_igr_prtif_crypto_cipher_suite("dec_igr_prtif_crypto_cipher_suite",
					  XILINX_HSC_MAX_PORT),
	dec_igr_prtif_crypto_conf_offset("dec_igr_prtif_crypto_conf_offset",
					 XILINX_HSC_MAX_PORT),
	dec_igr_prtif_crypto_icv("dec_igr_prtif_crypto_icv",
				 XILINX_HSC_MAX_PORT),
	dec_igr_prtif_crypto_iv_salt("dec_igr_prtif_crypto_iv_salt",
				     XILINX_HSC_MAX_PORT),
	dec_igr_prtif_crypto_mode("dec_igr_prtif_crypto_mode",
				  XILINX_HSC_MAX_PORT),
	dec_igr_prtif_crypto_replay_prot_en(
		"dec_igr_prtif_crypto_replay_prot_en",
		XILINX_HSC_MAX_PORT),
	dec_igr_prtif_crypto_sa_index("dec_igr_prtif_crypto_sa_index",
				      XILINX_HSC_MAX_PORT),
	dec_igr_prtif_crypto_spare_in("dec_igr_prtif_crypto_spare_in",
				      XILINX_HSC_MAX_PORT),
	dec_igr_prtif_crypto_zlen("dec_igr_prtif_crypto_zlen",
				  XILINX_HSC_MAX_PORT),
	dec_igr_prtif_ext_key("dec_igr_prtif_ext_key",
			      XILINX_HSC_MAX_PORT),
	dec_igr_prtif_macsec_sa_in_use("dec_igr_prtif_macsec_sa_in_use",
				       XILINX_HSC_MAX_PORT),
	dec_igr_prtif_macsec_validation_mode(
		"dec_igr_prtif_macsec_validation_mode",
		XILINX_HSC_MAX_PORT),
	rst("rst")
{
	for (int port = 0; port < XILINX_HSC_MAX_PORT; port++) {
		this->plain_data_stream_inputs[port].register_b_transport(this,
	                &xilinx_hsc::plain_input_stream_b_transport, port);
		this->encrypted_data_stream_inputs[port].register_b_transport(
			this,
	                &xilinx_hsc::encrypted_input_stream_b_transport,
			port);
	}

	user_if_socket.register_b_transport(this,
					    &xilinx_hsc::user_if_b_transport);

	SC_THREAD(reset_thread);
}

void xilinx_hsc::reset_thread(void)
{
	while (true) {
		wait(rst.posedge_event());
		/* Zero the keys.  */
		memset(this->encoder_keys, 0, sizeof(this->encoder_keys));
		memset(this->decoder_keys, 0, sizeof(this->decoder_keys));
		for (int port = 0; port < XILINX_HSC_MAX_PORT; port++) {
			this->reset_enc_port(port);
			this->reset_dec_port(port);
		}
	}
}

void xilinx_hsc::reset_enc_port(int port)
{
	memset(&this->fixed_enc[port], 0, sizeof(this->fixed_enc[port]));
}

void xilinx_hsc::reset_dec_port(int port)
{
	memset(&this->fixed_dec[port], 0, sizeof(this->fixed_dec[port]));
}

void xilinx_hsc::reg_indirect_access(bool tx)
{
	struct __attribute__((__packed__)) ind_access {
		/* Transfert in progress (1).  */
		uint32_t ena: 1;
		/* Write (1) or Read (0).  */
		uint32_t wr: 1;
		/*
		 * Target group:
		 *     00: SA keys,
		 *     10: SECY stats,
		 *     11: SC stats.
		 */
		uint32_t grp: 2;
		/* Keep the live stats after a read.  */
		uint32_t keep: 1;
		uint32_t rsvd: 3;
		/* Id of the register to access.  */
		uint32_t num: 10;
	} *ctrl_ptr =
		  (struct ind_access *)
		  (tx
		   ? &this->regs[TX_INDIRECT_AXS_CTRL_REG]
		   : &this->regs[RX_INDIRECT_AXS_CTRL_REG]);
	void *key_reg = (tx
			 ? &this->encoder_keys[0][ctrl_ptr->num]
			 : &this->decoder_keys[0][ctrl_ptr->num]);

	if (!ctrl_ptr->ena) {
		/* Nothing to do, the transfert hasn't been triggered.  */
		return;
	}

	/* Clear that bit directly, we don't model timing anyway.  */
	ctrl_ptr->ena = 0;

	switch (ctrl_ptr->grp) {
	case xilinx_hsc::GROUP_SA_KEYS:
		/* Reading / Writing to the SA keys storage for TX.  */
		if (ctrl_ptr->wr) {
			memcpy(key_reg,
			       tx
			       ? &this->regs[TX_INDIRECT_AXS_WDATA_REG(0)]
			       : &this->regs[RX_INDIRECT_AXS_WDATA_REG(0)],
			       XILINX_HSC_MAX_KEY_SIZE_BYTES);
		} else {
			/* Keys are not readable.  The user can read a CRC32
			 * digest of the 256bits of the keys on LSB.  */
			memset(tx
			       ? &this->regs[TX_INDIRECT_AXS_RDATA_REG(0)]
			       : &this->regs[RX_INDIRECT_AXS_RDATA_REG(0)], 0,
			       XILINX_HSC_MAX_KEY_SIZE_BYTES);
			this->regs[tx
				   ? TX_INDIRECT_AXS_RDATA_REG(0)
				   : RX_INDIRECT_AXS_RDATA_REG(0)] =
				crc32(0,
				      (unsigned char *)key_reg,
				      XILINX_HSC_MAX_KEY_SIZE_BYTES);
		}
		break;
	case xilinx_hsc::GROUP_CONFIG:
		/* Marked as reserved, only available for RX.  */
		if (tx) {
			SC_REPORT_WARNING("HSC",
					  "Using reserved TX indirect"
					  " transfert group");
			break;
		}
		// Fallthrough.
	default:
		SC_REPORT_WARNING("HSC",
				  "unimplemented TX indirect transfert");
		break;
	}
}

void xilinx_hsc::plain_input_stream_b_transport(int port,
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

	/* Output transaction.  */
	uint8_t *crypt_data = 0;
	size_t crypt_len = len;
	tlm::tlm_generic_payload out_stream_trans;
	genattr_extension *out_attr = new genattr_extension();

	/* Sanity check on the txn, and port.  */
	if (port >= XILINX_HSC_MAX_PORT) {
		SC_REPORT_ERROR("HSC", "Wrong port");
		return;
	}

	if (byte_en || cmd != tlm::TLM_WRITE_COMMAND || addr) {
		goto err;
	}

	/* For port #0, check if we are in channelized mode.  */
	if ((port == 0)
	    && (this->regs[P0_CONFIGURATION_ENC_MAIN]
		== xilinx_hsc::DATA_RATE_1x400G_CHANNELIZED)) {
		SC_REPORT_ERROR("HSC", "Channelized mode is unimplemented");
		return;
	}

	/* This is a new packet, the configuration is latched at that time, and
	 * can't be changed during the packet processing.  */
	if (!this->fixed_enc[port].common.byte_count) {
		this->fixed_enc[port].common.crypto_auth_only =
			this->enc_igr_prtif_crypto_auth_only[port].read();
		this->fixed_enc[port].common.crypto_byp =
			this->enc_igr_prtif_crypto_byp[port].read();
		this->fixed_enc[port].common.crypto_cipher_suite =
			this->enc_igr_prtif_crypto_cipher_suite[port].read();
		this->fixed_enc[port].common.crypto_conf_offset =
			this->enc_igr_prtif_crypto_conf_offset[port].read();
		this->fixed_enc[port].common.crypto_iv_salt[0] =
		       this->enc_igr_prtif_crypto_iv_salt[port].read().to_int();
		this->fixed_enc[port].common.crypto_mode =
			this->enc_igr_prtif_crypto_mode[port].read();
		this->fixed_enc[port].crypto_packet_number =
			this->enc_igr_prtif_crypto_pkt_num[port].read();
		this->fixed_enc[port].common.crypto_sa_index =
			this->enc_igr_prtif_crypto_sa_index[port].read();
		this->fixed_enc[port].common.crypto_spare_in =
			this->enc_igr_prtif_crypto_spare_in[port].read();
		this->fixed_enc[port].common.crypto_zlen =
			this->enc_igr_prtif_crypto_zlen[port].read();
		for (int i = 0; i < 32; i++) {
			this->fixed_enc[port].common.crypto_ext_key[i] =
				this->enc_igr_prtif_ext_key[port].read().range(
					(i + 1) * 8 - 1, i * 8).to_int();
		}
		this->fixed_enc[port].macsec_sectag_an =
			this->enc_igr_prtif_macsec_sectag_an[port].read();
		this->fixed_enc[port].macsec_sectag_sci =
			this->enc_igr_prtif_macsec_sectag_sci[port].read();
		this->fixed_enc[port].macsec_sectag_shortlen =
			this->enc_igr_prtif_macsec_sectag_shortlen[port].read();
		this->fixed_enc[port].macsec_sectag_ssci =
			this->enc_igr_prtif_macsec_sectag_ssci[port].read();
		this->fixed_enc[port].macsec_sectag_tci =
			this->enc_igr_prtif_macsec_sectag_tci[port].read();
	}

	switch (this->fixed_enc[port].common.crypto_mode) {
	case xilinx_hsc::MACsec: {
		/* There are two things happening for that packet:
		 *    1/ It will have the SecTAG inserted in place of the
		 *       ethernet type (16bytes).
		 *    2/ It will have the ICV tag inserted at the end of the
		 *       packet.
		 * All in all, the size must be increased.  */
		size_t offset = 0;
		size_t offset_crypt = 0;

		/* Check if the ethernet header is already computed, hence if
		 * we need to add 16 bytes for the MACsec tag.  */
		if (this->fixed_enc[port].common.byte_count < 14) {
			crypt_len += 16;
		}
		/* Check if this is the end of the packet, hence if we need to
		 * add 16 bytes for the ICV tag.  */
		if (genattr->get_eop()) {
			crypt_len += 16;
		}

		crypt_data = new uint8_t[crypt_len];
		if (!this->fixed_enc[port].common.byte_count) {
			/* This is a new packet, process the Ethernet header
			 * and datas.  */
			struct __attribute__((__packed__)) {
				uint64_t ethertype : 16;
				uint64_t tci_an : 8;
				uint64_t sl : 8;
				uint64_t pn : 32;
				uint64_t sci : 64;
			} sec_tag;

			/* This is a new packet, one limitation here is to
			 * have the ethernet header in one step.  */
			if (len < 14) {
				SC_REPORT_ERROR("HSC/MACSec",
						"Limitation: the ethernet"
						" header must comes in one"
						" transaction");
				return;
			}

			/* Copy the ethernet header.  */
			memcpy(crypt_data, data, 12);
			offset += 12;
			offset_crypt += 12;

			/* Compute the SecTag.  */
			/* TODO: Channelized mode allows to customize the
			 * EtherType, not totally sure in FixedPort mode.  */
			sec_tag.ethertype = 0xE588;
			/* The user must ensure the TCI provided is correct.  */
			sec_tag.tci_an =
				this->fixed_enc[port].macsec_sectag_tci << 2;
			sec_tag.tci_an |=
				this->fixed_enc[port].macsec_sectag_an;
			sec_tag.sl =
				this->fixed_enc[port].macsec_sectag_shortlen
				? 1
				: 0;
			sec_tag.pn = this->fixed_enc[port].crypto_packet_number
				& 0xFFFFFFFF;
			sec_tag.sci = this->fixed_enc[port].macsec_sectag_sci;

			memcpy(crypt_data + offset_crypt,
			       &sec_tag,
			       sec_tag.tci_an | 0x20 ? 16 : 8);
			offset_crypt += sec_tag.tci_an | 0x20 ? 16 : 8;
		}

		/* Data encryption:
		 * This is not implemented, for the simulation the data will
		 * be only XOR'ed with the packet.  */

		/* Compute the amount of unencrypted data:
		 *  1/ First case is that the encryption is bypassed.
		 *  2/ Second case is the opposite but we need to be sure we
		 *     go above the crypto_conf_offset.
		 */
		int unencrypted_len = 0;

		if (this->fixed_enc[port].common.crypto_byp
		    || this->fixed_enc[port].common.crypto_auth_only) {
			unencrypted_len = len - offset;
		} else if (this->fixed_enc[port].common.crypto_conf_offset == 30
		     || this->fixed_enc[port].common.crypto_conf_offset == 50) {
			/* Those are the two only value allowed, others are
			 * read as zero.  */
			unencrypted_len =
				this->fixed_enc[port].common.crypto_conf_offset
				- this->fixed_enc[port].common.byte_count
				+ 12;
		}

		memcpy(crypt_data + offset_crypt, data + offset,
		       unencrypted_len);
		offset_crypt += unencrypted_len;
		offset += unencrypted_len;

		if (offset < len) {
			/* offset within the key of the first encrypted
			 * byte.  */
			int keyoffset = 0;
			/* Keysize 128 or 256.  */
			int keysize;
			/* key in use.  */
			uint8_t *key;

			/* For SAs < 1024 the internal keys are used,
			 * enc_igr_prtif_ext_key is used otherwise.  */
			if (this->fixed_enc[port].common.crypto_sa_index
			    >= XILINX_HSC_MAX_KEYS) {
				key =
				    this->fixed_enc[port].common.crypto_ext_key;
			} else {
				key = (uint8_t *)&(this->encoder_keys[0]
				[this->fixed_enc[port].common.crypto_sa_index]);
			}

			switch (
			    this->fixed_enc[port].common.crypto_cipher_suite) {
			case xilinx_hsc::GCM_AES_128:
			case xilinx_hsc::GCM_AES_XPN_128:
				keysize = 128 / 8;
				break;
			default:
				keysize = 256 / 8;
				break;
			}
			/* Not all datas have been consumed, that means there
			 * are some data to encrypt.  */
			for (size_t i = offset; i < len; i++) {
				crypt_data[offset_crypt] = data[offset]
							^ key[(keyoffset + i) % keysize];
				offset_crypt++;
				offset++;
			}
		}

		/* TODO: No more data to process, if it's eop we must add
		 * the ICV.  */
		break;
		}
	default:
		SC_REPORT_WARNING("HSC", "Unimplemented Crypto Mode");
		goto err;
		break;
	}

	out_stream_trans.set_command(tlm::TLM_WRITE_COMMAND);
	out_stream_trans.set_data_ptr((unsigned char *)crypt_data);
	out_stream_trans.set_streaming_width(4);
	out_stream_trans.set_data_length(crypt_len);
	out_attr->set_eop(genattr->get_eop());
	out_stream_trans.set_extension(out_attr);
	this->encrypted_data_stream_outputs[port]->b_transport(out_stream_trans,
							       delay);
	out_stream_trans.release_extension(out_attr);

	delete crypt_data;
	/* XXX: check the response status??  */
	/* Everything is okay.  */
	trans.set_response_status(tlm::TLM_OK_RESPONSE);
	return;
err:
	trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
	return;
}

void xilinx_hsc::encrypted_input_stream_b_transport(int port,
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

	/* Output transaction.  */
	uint8_t *plain_data = 0;
	size_t plain_len = 0;
	tlm::tlm_generic_payload out_stream_trans;
	genattr_extension *out_attr = new genattr_extension();
	struct fixed_dec *config;

	/* Sanity check on the txn, and port.  */
	if (port >= XILINX_HSC_MAX_PORT) {
		SC_REPORT_ERROR("HSC", "Wrong port");
		return;
	}

	config = &this->fixed_dec[port];

	if (byte_en || cmd != tlm::TLM_WRITE_COMMAND || addr) {
		goto err;
	}

	/* For port #0, check if we are in channelized mode.  */
	if ((port == 0)
	    && (this->regs[P0_CONFIGURATION_DEC_MAIN]
		== xilinx_hsc::DATA_RATE_1x400G_CHANNELIZED)) {
		SC_REPORT_ERROR("HSC", "Channelized mode is unimplemented");
		return;
	}

	/* This is a new packet, the configuration is latched at that time, and
	 * can't be changed during the packet processing.  */
	if (!config->common.byte_count) {
		config->common.crypto_auth_only =
			this->dec_igr_prtif_crypto_auth_only[port].read();
		config->common.crypto_byp =
			this->dec_igr_prtif_crypto_byp[port].read();
		config->common.crypto_cipher_suite =
			this->dec_igr_prtif_crypto_cipher_suite[port].read();
		config->common.crypto_conf_offset =
			this->dec_igr_prtif_crypto_conf_offset[port].read();
		config->common.crypto_iv_salt[0] =
		       this->dec_igr_prtif_crypto_iv_salt[port].read().to_int();
		config->common.crypto_mode =
			this->dec_igr_prtif_crypto_mode[port].read();
		config->common.crypto_sa_index =
			this->dec_igr_prtif_crypto_sa_index[port].read();
		config->common.crypto_spare_in =
			this->dec_igr_prtif_crypto_spare_in[port].read();
		config->common.crypto_zlen =
			this->dec_igr_prtif_crypto_zlen[port].read();
		for (int i = 0; i < 32; i++) {
			config->common.crypto_ext_key[i] =
				this->dec_igr_prtif_ext_key[port].read().range(
					(i + 1) * 8 - 1, i * 8).to_int();
		}
	}

	switch (config->common.crypto_mode) {
	case xilinx_hsc::MACsec: {
		/* There are two things happening for that packet:
		 *    1/ It will have the SecTAG inserted in place of the
		 *       ethernet type (16bytes).
		 *    2/ It will have the ICV tag inserted at the end of the
		 *       packet.
		 * All in all, the size must be increased.  */
		size_t offset = 0;
		plain_len = 0;

		/* This is actually not totally correct, since the SecTAG and
		 * ICV will be missing in the output we are allocating a little
		 * too much here.  */
		plain_data = new uint8_t[len];
		if (!config->common.byte_count) {
			/* This is a new packet, process the Ethernet header
			 * and datas.  */
			struct __attribute__((__packed__)) SecTag {
				uint64_t ethertype : 16;
				uint64_t tci_an : 8;
				uint64_t sl : 8;
				uint64_t pn : 32;
				uint64_t sci : 64;
			} *sec_tag;

			/* This is a new packet, one limitation here is to
			 * have the ethernet header in one step.
			 * XXX: We need even more, the MACSec TAG et all.  */
			if (len < 14) {
				SC_REPORT_ERROR("HSC/MACSec",
						"Limitation: the ethernet"
						" header must comes in one"
						" transaction");
				return;
			}

			/* Copy the ethernet header.  */
			memcpy(plain_data, data, 12);
			offset += 12;
			plain_len += 12;

			/* Check the TCI_AN field, it gives the information
			 * about a 16 bytes or 8 bytes TAG (ie: jumping the
			 * SCI).  */
			sec_tag = (struct SecTag *)(data + offset);
			offset += sec_tag->tci_an | 0x20 ? 16 : 8;
			/* XXX: Check the ethertype?  */
			/* XXX: Provide pkt_num on per-port Egress.  */
		}

		/* Data decryption:
		 * This is not implemented, for the simulation the data will
		 * be only XOR'ed with the packet.  */

		/* Compute the amount of unencrypted data:
		 *  1/ First case is that the encryption is bypassed.
		 *  2/ Second case is the opposite but we need to be sure we
		 *     go above the crypto_conf_offset.
		 */
		int unencrypted_len = 0;

		if (config->common.crypto_byp
		    || config->common.crypto_auth_only) {
			unencrypted_len = len - offset;
		} else if (config->common.crypto_conf_offset == 30
		     || config->common.crypto_conf_offset == 50) {
			/* Those are the two only value allowed, others are
			 * read as zero.  */
			unencrypted_len =
				config->common.crypto_conf_offset
				- config->common.byte_count
				+ 12;
		}

		memcpy(plain_data + plain_len, data + offset,
		       unencrypted_len);
		plain_len += unencrypted_len;
		offset += unencrypted_len;

		if (offset < len) {
			/* offset within the key of the first encrypted
			 * byte.  */
			int keyoffset = 0;
			/* Keysize 128 or 256.  */
			int keysize;
			/* key in use.  */
			uint8_t *key;

			/* For SAs < 1024 the internal keys are used,
			 * enc_igr_prtif_ext_key is used otherwise.  */
			if (config->common.crypto_sa_index
			    >= XILINX_HSC_MAX_KEYS) {
				key = config->common.crypto_ext_key;
			} else {
				key = (uint8_t *)&(this->decoder_keys[0]
				        [config->common.crypto_sa_index]);
			}

			switch (
			    config->common.crypto_cipher_suite) {
			case xilinx_hsc::GCM_AES_128:
			case xilinx_hsc::GCM_AES_XPN_128:
				keysize = 128 / 8;
				break;
			default:
				keysize = 256 / 8;
				break;
			}
			/* Not all datas have been consumed, that means there
			 * are some data to encrypt, also skip the ICV at the
			 * end of that packet.  */
			for (size_t i = offset; i < len - 16; i++) {
				plain_data[plain_len] = data[offset]
					^ key[(keyoffset + i) % keysize];
				plain_len++;
				offset++;
			}
		}
		break;
		}
	default:
		SC_REPORT_WARNING("HSC", "Unimplemented Crypto Mode");
		goto err;
		break;
	}

	out_stream_trans.set_command(tlm::TLM_WRITE_COMMAND);
	out_stream_trans.set_data_ptr((unsigned char *)plain_data);
	out_stream_trans.set_streaming_width(4);
	out_stream_trans.set_data_length(plain_len);
	out_attr->set_eop(genattr->get_eop());
	out_stream_trans.set_extension(out_attr);
	this->plain_data_stream_outputs[port]->b_transport(out_stream_trans,
							   delay);
	out_stream_trans.release_extension(out_attr);

	delete plain_data;
	/* XXX: check the response status??  */
	/* Everything is okay.  */
	trans.set_response_status(tlm::TLM_OK_RESPONSE);
	return;
err:
	trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
	return;
}

void xilinx_hsc::user_if_b_transport(tlm::tlm_generic_payload& trans,
				     sc_time& delay)
{
	/* Access to the configuration address space.  */
	tlm::tlm_command cmd = trans.get_command();
	sc_dt::uint64 addr = trans.get_address();
	unsigned char *data = trans.get_data_ptr();
	unsigned int len = trans.get_data_length();
	unsigned char *byte_en = trans.get_byte_enable_ptr();
	unsigned int s_width = trans.get_streaming_width();
	uint32_t v = 0;

	if (byte_en || len > 4 || s_width < len) {
		goto err;
	}

	if ((addr >> 2) > XILINX_HSC_MAX_REGS)
		goto err;

	if (cmd == tlm::TLM_READ_COMMAND) {
		switch (addr >> 2) {
		case CONFIGURATION_REVISION:
			v = HSC_REVID;
			break;
		default:
			v = this->regs[addr >> 2];
			break;
		}
		memcpy(data, &v, len);
	} else if (cmd == tlm::TLM_WRITE_COMMAND) {
		memcpy(&v, data, len);
		switch (addr >> 2) {
		case CONFIGURATION_REVISION:
		case TX_INDIRECT_AXS_RDATA_REG(0)...
			TX_INDIRECT_AXS_RDATA_REG(7):
		case RX_INDIRECT_AXS_RDATA_REG(0)...
			RX_INDIRECT_AXS_RDATA_REG(7):
			/* Read Only.  */
			break;
		case TX_INDIRECT_AXS_CTRL_REG:
			/* Indirect access to stats and keys.  */
			this->regs[addr >> 2] = v;
			this->reg_indirect_access(true);
			break;
		case RX_INDIRECT_AXS_CTRL_REG:
			/* Indirect access to stats and keys.  */
			this->regs[addr >> 2] = v;
			this->reg_indirect_access(false);
			break;
		default:
			this->regs[addr >> 2] = v;
			break;
		}
	} else {
		goto err;
	}

	trans.set_response_status(tlm::TLM_OK_RESPONSE);
	return;

err:
	SC_REPORT_WARNING("HSC",
			  "unsupported read / write on the user interface");
	trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
}

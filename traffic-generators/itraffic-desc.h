/*
 * Copyright (c) 2018 Xilinx Inc.
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
#ifndef ITRAFFIC_DESC_H_
#define ITRAFFIC_DESC_H_

class ITrafficDesc
{
public:
	ITrafficDesc() {};

	virtual ~ITrafficDesc() {};

	virtual tlm::tlm_command getCmd() = 0;

	virtual uint64_t getAddress() = 0;

	virtual unsigned char *getData() = 0;
	virtual uint32_t getDataLength() = 0;

	virtual unsigned char *getByteEnable() = 0;
	virtual uint32_t getByteEnableLength() = 0;

	virtual uint32_t getStreamingWidth() = 0;

	virtual unsigned char *getExpect() = 0;

	virtual void setExtensions(tlm::tlm_generic_payload *gp) = 0;

	virtual bool done() = 0;
	virtual void next() = 0;
};

#endif

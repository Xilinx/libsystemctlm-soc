//
// ATS attributes extension
//
// Copyright (c) 2021 Xilinx Inc.
// Written by Francisco Iglesias.
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

#ifndef __ATSATTR_H__
#define __ATSATTR_H__

//
// Generators for Setters and Getters.
//
#define ATSATTR_PROP_GETSET_GEN(name, type) 			\
	type get_ ## name (void) const { return name ; }	\
	void set_ ## name (type new_v) { name = new_v; }

class atsattr_extension
: public tlm::tlm_extension<atsattr_extension>
{
public:
	atsattr_extension() :
		attributes(0),
		length(0),
		result(0)
	{}

	enum {
		ATTR_EXEC = 1 << 0,
		ATTR_READ = 1 << 1,
		ATTR_WRITE = 1 << 2,
		ATTR_PHYS_ADDR = 1 << 8,

		RESULT_OK = 0,
		RESULT_ERROR = 1,
	};

	void copy_from(const tlm_extension_base &extension) {
		const atsattr_extension &ext_atsattr =
			static_cast<atsattr_extension const &>(extension);

		*this = ext_atsattr;
	}

	tlm::tlm_extension_base *clone(void) const
	{
		return new atsattr_extension(*this);
	}

	ATSATTR_PROP_GETSET_GEN(attributes, uint64_t)
	ATSATTR_PROP_GETSET_GEN(length, uint64_t)
	ATSATTR_PROP_GETSET_GEN(result, uint32_t)

	bool is_phys_addr()
	{
		return attributes & ATTR_PHYS_ADDR;
	}

private:
	bool phys_addr;
	uint64_t attributes;
	uint64_t length;
	uint32_t result;
};

#undef ATSATTR_PROP_GETSET_GEN

#endif /* __ATSATTR_H__ */

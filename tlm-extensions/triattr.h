//
// TRI attributes extension
//
// Copyright (c) 2019 Xilinx Inc.
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

#ifndef __TRIATTR_H__
#define __TRIATTR_H__

//
// Generators for Setters and Getters.
//
#define TRIATTR_PROP_GETSET_GEN(name, type) 		\
	type Get ## name (void) const { return name ; }	\
	void Set ## name (type new_v) { name = new_v; }

#define TRIATTR_PROP_GETSET_GEN_FUNC_NAME(func_name, prop_name, type)	\
	type Get ## func_name (void) const { return prop_name ; }	\
	void Set ## func_name (type new_v) { prop_name = new_v; }

class triattr_extension
: public tlm::tlm_extension<triattr_extension>
{
public:
	triattr_extension()
	{}

	void copy_from(const tlm_extension_base &extension) {
		const triattr_extension &ext_triattr = static_cast<triattr_extension const &>(extension);
		*this = ext_triattr;
	}

	tlm::tlm_extension_base *clone(void) const
	{
		return new triattr_extension(*this);
	}

private:
};

#endif /* __TRIATTR_H__ */

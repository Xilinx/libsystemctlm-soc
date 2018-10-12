// Configuration Parser Unit Test Manager, this design is based
// on the Template Method pattern commonly found amongst test frameworks
//
// Copyright 2018 (C) Xilinx Inc.
// Written by Sakis Panou <sakis.panou@xilinx.com>
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
#include "abstract_test.h"

AbstractTest::AbstractTest() :
    theName("Unimplemented Test") {
}

AbstractTest::AbstractTest(const char* const name) :
    theName(name) {
}

AbstractTest::~AbstractTest(){

}

const char* AbstractTest::testName(void) const {
    return(theName);
}

bool AbstractTest::runTest(){

    if(false == setUpTest()){
        return(false);
    }

    if(false == doTest()){
        cleanUpTest();
        return(false);
    }

    cleanUpTest();
    return(true);
}

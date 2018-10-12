// Configuration Parser Unit Test
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

#ifndef TEST1_H__
#define TEST1_H__
class CmdLineParser;

class Test1 : public AbstractTest{
    public:
        bool setUpTest();
        bool doTest();
        bool cleanUpTest();
        virtual ~Test1();
        Test1();
        Test1(const char* const name);
    private:
        Test1(const Test1& rhs):
            AbstractTest(rhs.testName()),
            cmdLine(rhs.cmdLine){};
        uint32_t testResult;
        const char* fileName;
        DataTransfer deserializedDt;
        DataTransfer expectedDt;

        bool subTest1();
        bool subTest2();
        bool subTest3();
        bool subTest4();
        CmdLineParser& cmdLine; //type

};

#endif//TEST1_H__

// Input Command line parser test header
//Takes user inputs and feeds them to the options class.
//
// Copyright 2018 (C) Xilinx Inc.
// Written by Vikram<fnuv@xilinx.com>
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
#ifndef CMD_LINE_TEST_H__
#define CMD_LINE_TEST_H__

#include <string>
#include <iostream>
#include <unistd.h>
class CmdLineParser;
// CmdLineParser publicly inherit AbstractTest
class CmdLineParserTest : public AbstractTest{
    public:
        bool setUpTest();
        bool doTest();
        bool cleanUpTest();
        virtual ~CmdLineParserTest();
        CmdLineParserTest();
        CmdLineParserTest(const char* const name);
    private:
        CmdLineParserTest(const CmdLineParserTest& rhs):
            AbstractTest(rhs.testName()),
            cmdLine(rhs.cmdLine){
        };
            bool subTest1();
            bool subTest2();
            bool reverse_test(const char* const fileName);

        CmdLineParser& cmdLine; //type
};
#endif//CMD_LINE_TEST_H__

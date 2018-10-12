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
#include <iostream>
#include <vector>
#include <stdio.h>
#include <string.h>

#include "data-transfer.h"
#include "parserfacade.h"
#include "abstract_test.h"
#include "commandlineparser.h"
#include "test2.h"

Test2::~Test2(){
}

Test2::Test2():
    AbstractTest("Unimplemented Test"),
    cmdLine(CmdLineParser::InstanceCmdLineParser()){
}

Test2::Test2(const char* const name):
    AbstractTest(name),
    cmdLine(CmdLineParser::InstanceCmdLineParser()){
}

bool Test2::setUpTest(){

    memset(&deserializedDt, 0, sizeof(DataTransfer));
    memset(&expectedDt, 0, sizeof(DataTransfer));
    expectedDt.addr=0x20FF;
    expectedDt.on_heap = true;

    return(true);
}

bool Test2::doTest(){
    string json_location =  cmdLine.getPath();
    json_location += "different_addr_field.json";
    fileName = json_location.c_str();
    // std::cout<<"JSDON "<<(fileName)<<std::endl;
    // fileName = "./test_files/different_addr_field.json";
    if(false == ParserFacade::Deserialize(deserializedDt, fileName)){
        std::cout << "Test2 Failed: Error Code:"
            << ParserFacade::getLastError()
            << " Error Code Description: "
            << ParserFacade::getLastErrorDescription()
            << std::endl;
    }

    if(0 != memcmp( &deserializedDt, &expectedDt, sizeof(DataTransfer))){

        std::cout << "Test 2: Failed : deserializedDt is not equal to expectedDt "
            << std::endl
            << "deserializedDt = "
            << deserializedDt
            << std::endl
            << "expectedDt     = "
            << expectedDt
            << std::endl;

        return(false);

    } else {
        std::cout << "Test 2: Passed : deserializedDt is equal to expectedDt "
            << std::endl
            << "deserializedDt = "
            << deserializedDt
            << std::endl
            << "expectedDt     = "
            << expectedDt
            << std::endl;
        return(true);

    }

     return(false);
}

bool Test2::cleanUpTest(){
    std::cout << std::endl;
    return(false);
}

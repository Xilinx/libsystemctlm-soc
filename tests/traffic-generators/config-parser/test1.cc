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
#include <iomanip>
#include <stdio.h>
#include <string.h>

//#define SHUNT__
#include "../../traffic-generators/data-transfer.h"
//#undef SHUNT__

#include "parserfacade.h"
#include "abstract_test.h"
#include "test1.h"
#include "commandlineparser.h"

Test1::~Test1(){
}

Test1::Test1():
    AbstractTest("Unimplemented Test"),
    cmdLine(CmdLineParser::InstanceCmdLineParser()){
}

Test1::Test1(const char* const name):
    AbstractTest(name),
    cmdLine(CmdLineParser::InstanceCmdLineParser()){
}

bool Test1::setUpTest(){
    return(true);
}

bool Test1::doTest(){

    uint32_t failCount = 0;

    if(false == subTest1()){
        ++failCount;
    }

    if(false == subTest2()){
        ++failCount;
    }

    if(false == subTest3()){
        ++failCount;
    }

    if(false == subTest4()){
        ++failCount;
    }

    return((failCount)?false:true);
}

bool Test1::cleanUpTest(){
    std::cout << std::endl;
    //std::cout << "Error History Dump: "<< std::endl;
    //ParserFacade::dumpErrorHistory();
    return(false);
}


//
// Try to deserialiaze an empty json object {}
// the file for this test is ./test_files/no_object_test.json
//
bool Test1::subTest1(){
    bool result = false;
    const char* status;

    string json_location =  cmdLine.getPath();
    json_location += "no_object_test.json";
    fileName = json_location.c_str();
    memset(&deserializedDt, 0, sizeof(DataTransfer));
    memset(&expectedDt, 0, sizeof(DataTransfer));
    expectedDt.on_heap = true;

    if(false == ParserFacade::Deserialize(deserializedDt, fileName)){
        std::cout << "    Test 1.1 Failed: Error Code:"
            << ParserFacade::getLastError()
            << "Error Code Description: "
            << ParserFacade::getLastErrorDescription()
            << std::endl;
        return(result);
    }

    if(0 != memcmp(&deserializedDt, &expectedDt, sizeof(DataTransfer))){
        result=false;
    } else {
        result=true;
    }

    std::cout << "    Test 1.1: ";
    status = (result)? "Passed": "Failed";
    std::cout << status
        << std::endl
        << "    "
        << "deserializedDt = "
        << deserializedDt
        << std::endl
        << "    "
        << "expectedDt     = "
        << expectedDt
        << std::endl;

    return(result);
}

//
// Try to deserialiaze a DataTranfer json object who's address
// field has a string instead of a number
// the file for this test is ./test_files/invalid_addr_field.json
//
bool Test1::subTest2(){
    bool result = false;
    const char* status;
    string json_location =  cmdLine.getPath();
    json_location += "invalid_addr_field.json";
    fileName = json_location.c_str();
    // fileName = "./test_files/invalid_addr_field.json";
    memset(&deserializedDt, 0, sizeof(DataTransfer));

    memset(&expectedDt, 0, sizeof(DataTransfer));
    expectedDt.on_heap = true;
    expectedDt.addr= 20;

    if(false == ParserFacade::Deserialize(deserializedDt, fileName)){
        std::cout << "    Test 1.2 Failed: Error Code:"
            << ParserFacade::getLastError()
            << "Error Code Description: "
            << ParserFacade::getLastErrorDescription()
            << std::endl;
        return(result);
    }

    if(0 != memcmp(&deserializedDt, &expectedDt, sizeof(DataTransfer))){
        result=false;
    } else {
        result=true;
    }

    std::cout << "    Test 1.2: ";
    status = (result)? "Passed": "Failed";
    std::cout << status
        << std::endl
        << "    Error Code:"
        << std::setw(3) << std::setfill('0') << ParserFacade::getLastError()
        << ", Description: "
        << ParserFacade::getLastErrorDescription()
        << std::endl;

   return(result);
}

//
// Try to deserialiaze a totally invalid json file.
// the file for this test is ./test_files/invalid_json1.json
//
bool Test1::subTest3(){
    bool result = false;
    const char* status;
    string json_location =  cmdLine.getPath();
    json_location += "invalid-json01.json";
    fileName = json_location.c_str();
    // fileName = "./test_files/invalid-json01.json";
    memset(&deserializedDt, 0, sizeof(DataTransfer));

    if(false == ParserFacade::Deserialize(deserializedDt, fileName)){
        result=true;
    }

    std::cout << "    Test 1.3: ";
    status = (result)? "Passed": "Failed";
    std::cout << status
        << std::endl
        << "    Error Code:"
        << std::setw(3) << std::setfill('0') << ParserFacade::getLastError()
        << ", Description: "
        << ParserFacade::getLastErrorDescription()
        << std::endl;

   return(result);
}

//
// Try to deserialiaze a totally invalid json file.
// the file for this test is ./test_files/invalid_json2.json
//
bool Test1::subTest4(){

    bool result = false;
    const char* status;
    string json_location =  cmdLine.getPath();
    json_location += "invalid-json02.json";
    fileName = json_location.c_str();
    // fileName = "./test_files/invalid-json02.json";
    memset(&deserializedDt, 0, sizeof(DataTransfer));

    if(false == ParserFacade::Deserialize(deserializedDt, fileName)){
        result=true;
    }

    std::cout << "    Test 1.4: ";
    status = (result)? "Passed": "Failed";
    std::cout << status
        << std::endl
        << "    Error Code:"
        << std::setw(3) << std::setfill('0') << ParserFacade::getLastError()
        << ", Description: "
        << ParserFacade::getLastErrorDescription()
        << std::endl;

   return(result);
}

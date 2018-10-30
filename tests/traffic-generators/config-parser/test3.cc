// Configuration Parser Unit Test
//
// Copyright 2018 (C) Xilinx Inc.
// Written by Sakis Panou <sakis.panou@xilinx.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the 'Software'), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
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

#define SC_INCLUDE_DYNAMIC_PROCESSES
//#include <systemc>
#include <tlm>

using namespace sc_core;
using namespace sc_dt;

#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#define __SHIM__
#include "tlm2axi-bridge.h"
#undef __SHIM__
#include "axi2tlm-bridge.h"
#include "tg-tlm.h"
#include "random-traffic.h"


#include "itraffic-desc.h"
#include "traffic-desc.h"
#include "parserfacade.h"
#include "abstract_test.h"
#include "commandlineparser.h"
#include "test3.h"
#include "deserializer.h"



unsigned char data[] = { 0x02, 0xF2, 0xFE, 0xDC };
unsigned char data1[] = { 0x12, 0xD2, 0xFC, 0x44 };
unsigned char byte_enable[] = {1 ,2 ,3 ,4};
unsigned char byte_enable1[] = {5 ,6 ,7 ,8};
unsigned char expect[] = {0xFF, 0xFE, 0xFD, 0xFC, 0xFB};
unsigned char expect1[] = {0xAB, 0xDC, 0xEF, 0xA1, 0x55};


const char * const Test3::stringJson = ""
    "{"
    " \"dataTransfers\" : ["
    "   { \"addr\" : \"0xFF23\"},"
    "   { \"cmd\" : 1}"
    " ]"
    "}";


bool isDtEqual(const DataTransfer& a, const DataTransfer& b){

    bool result = false;

    result = (a.addr == b.addr) ? true : false;

    if(true == result){
        result = (a.cmd == b.cmd) ? true : false;
    }

    if(true == result){
        result = (a.length == b.length) ? true : false;
    }

    if(true == result){
        result = (a.byte_enable_length == b.byte_enable_length) ? true : false;
    }

    if(true == result){
        result = (a.streaming_width == b.streaming_width) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.enabled == b.ext.gen_attr.enabled) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.master_id == b.ext.gen_attr.master_id) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.secure == b.ext.gen_attr.secure) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.eop == b.ext.gen_attr.eop) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.wrap == b.ext.gen_attr.wrap) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.burst_width == b.ext.gen_attr.burst_width) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.transaction_id == b.ext.gen_attr.transaction_id) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.exclusive == b.ext.gen_attr.exclusive) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.locked == b.ext.gen_attr.locked) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.bufferable == b.ext.gen_attr.bufferable) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.modifiable == b.ext.gen_attr.modifiable) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.read_allocate == b.ext.gen_attr.read_allocate) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.write_allocate == b.ext.gen_attr.write_allocate) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.qos == b.ext.gen_attr.qos) ? true : false;
    }

    if(true == result){
        result = (a.ext.gen_attr.region == b.ext.gen_attr.region) ? true : false;
    }

    if(true == result){
        result = (0 != memcmp(a.data, b.data, a.length)) ? false : true;
    }

    if(true == result){
        result = (0 != memcmp(a.byte_enable, b.byte_enable, a.byte_enable_length)) ? false : true;
    }

    if(true == result){
        result = (0 != memcmp(a.expect, b.expect, a.length)) ? false : true;
    }

    return(result);
}

Test3::~Test3(){
}

Test3::Test3():
    AbstractTest("Unimplemented Test"),
    cmdLine(CmdLineParser::InstanceCmdLineParser()){
}

Test3::Test3(const char* const name):
    AbstractTest(name),
    cmdLine(CmdLineParser::InstanceCmdLineParser()){
}

bool Test3::setUpTest(){

    dt1.addr = 0x7FCA0000;
    dt1.cmd = 1;
    dt1.data = data;
    dt1.length = 4;
    dt1.byte_enable = byte_enable;
    dt1.byte_enable_length = 4;
    dt1.streaming_width = 5;
    dt1.expect = expect;
    dt1.ext.gen_attr.enabled = true;
    dt1.ext.gen_attr.master_id = 218423972309;
    dt1.ext.gen_attr.secure = true;
    dt1.ext.gen_attr.eop = false;
    dt1.ext.gen_attr.wrap = true;
    dt1.ext.gen_attr.burst_width = 20;
    dt1.ext.gen_attr.transaction_id = 0xFF00DD;
    dt1.ext.gen_attr.exclusive = false;
    dt1.ext.gen_attr.locked = false;
    dt1.ext.gen_attr.bufferable = false;
    dt1.ext.gen_attr.modifiable = true;
    dt1.ext.gen_attr.read_allocate = true;
    dt1.ext.gen_attr.write_allocate = false;
    dt1.ext.gen_attr.qos = 0x55;
    dt1.ext.gen_attr.region = 0xAA;
    dt1.on_heap = true;

    dt2.addr = 0x800FFCCDD;
    dt2.cmd = 0;
    dt2.data = data1;
    dt2.length = 4;
    dt2.byte_enable = byte_enable1;
    dt2.byte_enable_length = 4;
    dt2.streaming_width = 5;
    dt2.expect = expect1;
    dt2.ext.gen_attr.enabled = true;
    dt2.ext.gen_attr.master_id = 69873589232;
    dt2.ext.gen_attr.secure = true;
    dt2.ext.gen_attr.eop = true;
    dt2.ext.gen_attr.wrap = false;
    dt2.ext.gen_attr.burst_width = 100;
    dt2.ext.gen_attr.transaction_id = 0xAABBCCDD;
    dt2.ext.gen_attr.exclusive = false;
    dt2.ext.gen_attr.locked = true;
    dt2.ext.gen_attr.bufferable = true;
    dt2.ext.gen_attr.modifiable = false;
    dt2.ext.gen_attr.read_allocate = false;
    dt2.ext.gen_attr.write_allocate = true;
    dt2.ext.gen_attr.qos = 0x88;
    dt2.ext.gen_attr.region = 0x55;
    dt2.on_heap = true;

    dt3.addr = 2340;
    dt3.cmd = 0;
    dt3.data = 0;
    dt3.length = 0;
    dt3.byte_enable = 0;
    dt3.byte_enable_length = 0;
    dt3.streaming_width = 0;
    dt3.expect = 0;
    dt3.ext.gen_attr.enabled = 0;
    dt3.ext.gen_attr.master_id = 0;
    dt3.ext.gen_attr.secure = 0;
    dt3.ext.gen_attr.eop = 0;
    dt3.ext.gen_attr.wrap = false;
    dt3.ext.gen_attr.burst_width = 0;
    dt3.ext.gen_attr.transaction_id = 0;
    dt3.ext.gen_attr.exclusive = 0;
    dt3.ext.gen_attr.locked = 0;
    dt3.ext.gen_attr.bufferable = false;
    dt3.ext.gen_attr.modifiable = false;
    dt3.ext.gen_attr.read_allocate = false;
    dt3.ext.gen_attr.write_allocate = false;
    dt3.ext.gen_attr.qos = 0;
    dt3.ext.gen_attr.region = 0;
    dt3.on_heap = true;


    return(true);
}

bool Test3::doTest(){

    uint32_t failCount = 0;

    if(false == subTest1()){
        ++failCount;
    }

    if(false == subTest2()){
        ++failCount;
    }

    return((failCount)?false:true);

    return(false);
}

bool Test3::cleanUpTest(){
    dt1.on_heap = false;
    dt2.on_heap = false;
    dt3.on_heap = false;
    return(false);
}

// Deserialize dt1, dt2 and dt3 from dataTransferVector_single_entry.json
// compare to the static objects and if all correct pass the test
bool Test3::subTest1(){

    DataTransferVec dtv;
    string json_location =  cmdLine.getPath();
    json_location += "dataTransferVector_single_entry.json";
    const char* const fileName =json_location.c_str();
    // const char* const fileName =
    // "./test_files/dataTransferVector_single_entry.json";
    bool result = false;
    const char* status;

    if(false == ParserFacade::Deserialize(dtv,fileName)){
        std::cout << "    Test 3.1 Failed: Error Code:"
            << ParserFacade::getLastError()
            << "Error Code Description: "
            << ParserFacade::getLastErrorDescription()
            << std::endl;
        return(result);
    }

    if(dtv.size() != 3){
        std::cout << "    Test 3.1: Failed" << std::endl;
        std::cout << "    The number of deserialized dataTranfers objects in "
        "the vector is not the expected";
        std::cout << "    Expected: 3, Deserialized: " << dtv.size() << std::endl;

        return(false);
    }

    result = isDtEqual(dtv[0], dt1);

    std::cout << "    Test 3.1: ";
    status = (result)? "Passed": "Failed";
    std::cout << status
        << std::endl
        << "    "
        << "dtv[0] = "
        << dtv[0]
        << std::endl
        << "    "
        << "dt1    = "
        << dt1
        << std::endl;

    if(false == result){
        return(result);
    }

    result = isDtEqual(dtv[1], dt2);

    std::cout << "    Test 3.1: ";
    status = (result)? "Passed": "Failed";
    std::cout << status
        << std::endl
        << "    "
        << "dtv[1] = "
        << dtv[1]
        << std::endl
        << "    "
        << "dt2    = "
        << dt2
        << std::endl;

    if(false == result){
        return(result);
    }

    result = isDtEqual(dtv[2], dt3);

    std::cout << "    Test 3.1: ";
    status = (result)? "Passed": "Failed";
    std::cout << status
        << std::endl
        << "    "
        << "dtv[2] = "
        << dtv[2]
        << std::endl
        << "    "
        << "dt3    = "
        << dt3
        << std::endl;

    if(false == result){
        return(result);
    }

    return(result);
}

bool Test3::subTest2(){

    DataTransferVec dtv;
    bool result = false;
    const char* status;

    if(false == ParserFacade::Deserialize(dtv,stringJson)){
        std::cout << "    Test 3.1 Failed: Error Code:"
            << ParserFacade::getLastError()
            << "Error Code Description: "
            << ParserFacade::getLastErrorDescription()
            << std::endl;
        return(result);
    }

    DataTransfer strDt1;
    strDt1.addr = 0xFF23;

    DataTransfer strDt2;
    strDt2.cmd = 1;

    result = isDtEqual(dtv[0], strDt1);

    std::cout << "    Test 3.2: ";
    status = (result)? "Passed": "Failed";
    std::cout << status
        << std::endl
        << "    "
        << "dtv[0] = "
        << dtv[0]
        << std::endl
        << "    "
        << "strDt1 = "
        << strDt1
        << std::endl;

    if(false == result){
        return(result);
    }

    result = isDtEqual(dtv[1], strDt2);

    std::cout << "    Test 3.2: ";
    status = (result)? "Passed": "Failed";
    std::cout << status
        << std::endl
        << "    "
        << "dtv[1] = "
        << dtv[1]
        << std::endl
        << "    "
        << "strDt2 = "
        << strDt2
        << std::endl;

    if(false == result){
        return(result);
    }

    return(true);
}

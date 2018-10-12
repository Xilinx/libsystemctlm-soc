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
#include "test4.h"
#include "deserializer.h"

Test4::~Test4(){
}

Test4::Test4():
    AbstractTest("Unimplemented Test"){
}

Test4::Test4(const char* const name):
    AbstractTest(name){
}

bool Test4::setUpTest(){
    //
    // PLEASE NOTE :
    // The below calls are for development tests only. They will be removed
    // shortly. - Thanks Sakis
    // Edited this to maintain the Test  file format.
    return(true);
}

bool Test4::doTest(){
        fileName = "./test_files/dataTransferVector_single_entry.json";
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

        if(false == subTest5()){
            ++failCount;
        }

        if(false == subTest6()){
            ++failCount;
        }

        return((failCount)?false:true);
}

bool Test4::subTest1(){
  // Testing a uint8_t [] array inflation
  uint8_t* val = new uint8_t[30];
  Deserializer theDeserializer;
  bool result = false;
  const std::string strTest00("@Random(seed =  -10, size = -0030, uBound = 20, lBound = 10)");

  if (true == theDeserializer.deserialize(val, 30.1, strTest00)){
      std::cout << "Test Passed : " << strTest00 << std::endl;
      result = true;
  }
  delete [] val;
  return(result);
}

bool Test4::subTest2(){
  uint8_t* val = new uint8_t[30];
  Deserializer theDeserializer;
  bool result = false;
  const std::string strTest01("Random( seed=10, secondVal = 20, range = 10...20 )");
  if (true == theDeserializer.deserialize(val, 30, strTest01)){
      std::cout << "Test Passed : " << strTest01 << std::endl;
      result = true;
  }
    delete [] val;
    return(result);
}

bool Test4::subTest3(){
  uint8_t* val = new uint8_t[30];
  Deserializer theDeserializer;
  bool result = false;
  const std::string strTest02(" asdlakfs @Random( seed=10, secondVal = 20, range = 10...20 )");
  if (true == theDeserializer.deserialize(val, 30, strTest02)){
      std::cout << "Test Passed : " << strTest02 << std::endl;
      result = true;
  }
    delete [] val;
    return(result);
}

bool Test4::subTest4(){
  // Testing a uint32_t inflation
  uint32_t val32 = 0;
  Deserializer theDeserializer;
  bool result = false;
  const std::string strTest03("@Random()");

  if (true == theDeserializer.deserialize(val32, strTest03)){
      std::cout << "Test Passed : " << strTest03 << std::endl;
      result = true;
  }
  return(result);
}

bool Test4::subTest5(){
  // Testing a uint64_t inflation
  uint64_t val64 = 0;
  Deserializer theDeserializer;
  bool result = false;
  const std::string strTest04("@Random()");

  if (true == theDeserializer.deserialize(val64, strTest04)){
      std::cout << "Test Passed : " << strTest04 << std::endl;
      result = true;
  }
  return(result);
}

bool Test4::subTest6(){
  // Testing a uint8_t inflation
  uint8_t val8 = 0;
  Deserializer theDeserializer;
  bool result = false;
  const std::string strTest05("@Random()");

  if (true == theDeserializer.deserialize(val8, strTest05)){
      std::cout << "Test Passed : " << strTest05 << std::endl;
      result = true;
  }
  return(result);
}

bool Test4::cleanUpTest(){
    std::cout << std::endl;
    return(false);
}

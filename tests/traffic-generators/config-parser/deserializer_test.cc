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


#include "abstract_test.h"
#include "deserializer_test.h"
#include "deserializer.h"

DeserializerTest::~DeserializerTest(){
}

DeserializerTest::DeserializerTest():
    AbstractTest("Unimplemented Test"){
}

DeserializerTest::DeserializerTest(const char* const name):
    AbstractTest(name){
}

bool DeserializerTest::setUpTest(){
    return(true);
}

bool DeserializerTest::doTest(){

    //
    // PLEASE NOTE :
    // The below calls are for development tests only. They will be removed
    // shortly. - Thanks Sakis
    //
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
    return((failCount)?false:true);
}

bool DeserializerTest::subTest1(){
  bool result = false;
  Deserializer theDeserializer;
  uint8_t* val9 = new uint8_t[30];
  const std::string strTest06("@Random( seed = 10 , size = 30, randomRange = [0x55, 0x77, 0xFF, 0xDF] , uBound = 0x20,lBound = 20)");

  if (true == theDeserializer.deserialize(val9, 30, strTest06)){
      std::cout << "Deserialize Test 1.1 Passed : " << strTest06 << std::endl;
      result = true;
  }
  delete [] val9;
  return(result);
}

bool DeserializerTest::subTest2(){
  bool result = false;
  Deserializer theDeserializer;
  uint8_t* val9 = new uint8_t[30];
  const std::string strTest06("@Random( seed = 10 , size = 30, randomRange = [0x55, 0x77, 0xFF, 0xDF] , uBound = 0x20,lBound = 20)");

  if (true == theDeserializer.deserialize(val9, 10, strTest06)){
      std::cout << "Deserialize Test 1.2 Passed : " << strTest06 << std::endl;
      result = true;
  }
  delete [] val9;
  return(result);
}

bool DeserializerTest::subTest3(){
  bool result = false;
  Deserializer theDeserializer;
  // uint8_t* val9 = new uint8_t[10];
  uint8_t val9[10] = {1,2,3,4,5,6,7,8,9,10};
  const std::string strTest03("asasRandom(seed = 5 , size = 30, range = 1.0....,lBound = 20)");

  if (true == theDeserializer.deserialize(val9, 20, strTest03)){
    //wait why this passes?
      std::cout << "Deserialize Test 1.3 Passed : "<< strTest03 << std::endl;
      result = true;
  }
  return(result);
}

bool DeserializerTest::cleanUpTest(){
    return(false);
}

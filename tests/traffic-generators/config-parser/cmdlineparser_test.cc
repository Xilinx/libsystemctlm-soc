// Input Command line parser test
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
#include <iostream>
#include <vector>
#include <iomanip>
#include <cstring>
#include "abstract_test.h"
#include "commandlineparser.h"
#include "cmdlineparser_test.h"
#include "data-transfer.h"
#include "parserfacade.h"

CmdLineParserTest::~CmdLineParserTest(){
}

CmdLineParserTest::CmdLineParserTest():
  AbstractTest("Unimplemented Test"),
  cmdLine(CmdLineParser::InstanceCmdLineParser()){
}

CmdLineParserTest::CmdLineParserTest(const char* const name ):
    AbstractTest(name),
    cmdLine(CmdLineParser::InstanceCmdLineParser()){
}

bool CmdLineParserTest::setUpTest(){
    return(true);
}

bool CmdLineParserTest::doTest(){
  uint32_t failCount = 0;
  if(false == subTest1()){
    ++failCount;
  }
  if(false == subTest2()){
    ++failCount;
  }
  return((failCount)?false:true);
}

bool CmdLineParserTest::subTest1(){
  	std::cout << "Called: " << this->testName() << std::endl;

    std::cout<<"cmdLine.getParallel(): ";
  	std::cout<< std::boolalpha << cmdLine.getParallel()<<std::endl;
    std::cout<<"cmdLine.getDebugModeStatus(): ";
  	std::cout << std::boolalpha<<cmdLine.getDebugModeStatus()<<std::endl;
    // std::vector<string> v;
    std::cout<<"newboj->getConfigs() output: ";
    for(uint i = 0; i< cmdLine.getConfigs().size(); i++){
      	std::cout <<cmdLine.getConfigs()[i]<<"\t"; // getting first config file name
    }
    std::cout<<"\n";

    return true;
}

bool CmdLineParserTest::reverse_test(const char* const fileName){
  DataTransferVec deserializedDt;
  // memset(&deserializedDt, 0, sizeof(DataTransfer));

  if(false == ParserFacade::Deserialize(deserializedDt, fileName)){
      std::cout << "    Test re-feeding the config Failed: Error Code:\t"
          << ParserFacade::getLastError()
          << "Error Code Description: "
          << ParserFacade::getLastErrorDescription()
          << std::endl;
      return(false);
  }
  return(true);
}

bool CmdLineParserTest::subTest2(){
  uint32_t failCount = 0;
  for(uint i = 0; i< cmdLine.getConfigs().size(); i++){
      std::cout <<"Recalling the conf files number"<< i<<": "<<cmdLine.getConfigs()[i]<<std::endl; // getting first config file name
      string new_path = cmdLine.getPath();
      new_path += cmdLine.getConfigs()[i];
      if(true != reverse_test(new_path.c_str())){
        ++failCount;
      }
  }

  return((failCount)?false:true);
}

bool CmdLineParserTest::cleanUpTest(){
  return(true);
}

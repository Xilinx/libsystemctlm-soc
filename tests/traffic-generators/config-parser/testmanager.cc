// Configuration Parser Unit Test Manager
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

#include <vector>
#include <iostream>
#include <string>
#include <systemc>

#include "abstract_test.h"

#include "data-transfer.h"


#include "test1.h"
#include "test2.h"
#include "test3.h"
#include "test4.h"
#include "cmdlineparser_test.h"
#include "deserializer_test.h"
#include "commandlineparser.h"



// Create a distinct Test Vector type
typedef std::vector<AbstractTest*> TestVector;

//Define the Unit Test Manager
class UnitTestManager{
    public:
        void runTestVector(TestVector& tv);
        UnitTestManager() :
            testPassCount(0),
            testFailCount(0),
            totalTestCount(0){
        }

        uint32_t getTestPassCount(){
            return(testPassCount);
        }

        uint32_t getTestFailCount(){
            return(testFailCount);
        }

        uint32_t getTestTotalCount(){
            return(totalTestCount);
        }

    private:
        void startTestBanner(AbstractTest* theTest);
        void endTestBanner(AbstractTest* theTest);
        void logTestStats(bool testStatus);
        void testLogBanner();
        uint32_t testPassCount;
        uint32_t testFailCount;
        uint32_t totalTestCount;
};

void UnitTestManager::startTestBanner(AbstractTest* theTest){
    std::cout
        << "............................................................" << std::endl
        << "Test : " <<  theTest->testName() << std::endl
        << std::endl;
}

void UnitTestManager::endTestBanner(AbstractTest* theTest){
    std::cout
        << std::endl
        << std::endl;
}

void UnitTestManager::logTestStats(bool testStatus){
    if(true == testStatus){
        ++testPassCount;
    } else {
        ++testFailCount;
    }

    totalTestCount = testPassCount + testFailCount;
}

void UnitTestManager::testLogBanner(){
    std::cout
        << "============================================================" << std::endl
        << std::endl
        << " Tests Passed : " <<  testPassCount << std::endl
        << " Tests Failed : " <<  testFailCount << std::endl
        << " Total Tests  : " <<  totalTestCount << std::endl
        << std::endl
        << "============================================================" << std::endl;
}

//
// Iterates through the Test Vector and Executes the Tests
//
void UnitTestManager::runTestVector(TestVector& tv){

    for(TestVector::iterator it = tv.begin(); it != tv.end(); ++it){
        AbstractTest* theTest = *it;

        startTestBanner(theTest);
        logTestStats(theTest->runTest());
        endTestBanner(theTest);
    }
    testLogBanner();
}


int sc_main(int argc, char* argv[]){
    return(0);
}

int main(int argc, char* argv[]){

    CmdLineParser::InstanceCmdLineParser(argc, argv);

    TestVector tv;
    CmdLineParserTest cmdLineParserTest("The Command Line Parser Test");
    Test1 test1("Empty DataTransfer Json Object Test");
    Test2 test2("DataTransfer Json Object Test with an addr field");
    Test3 test3("DataTransfer Vector with Multiple Entries");
    Test4 test4("Test for random degene funtionalities");
    DeserializerTest deserializerTest("Deserializer Unit Test");

    // Add Tests to the Test Vector
    tv.push_back(&cmdLineParserTest);
    tv.push_back(&test1);
    tv.push_back(&test2);
    tv.push_back(&test3);
    tv.push_back(&test4);
    tv.push_back(&deserializerTest);

    // Create the Unit Test Manager
    UnitTestManager utm;

    // Let the Unit Test Manager run the Test Vector
    utm.runTestVector(tv);

    return(utm.getTestFailCount());
}

// Configuration Parser
//
// Parses a json format configuration file in order to serialize/deserialize
// the DataTransfer object.
//
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

#include <sstream>
#include <vector>
#include <iostream>

#define SC_INCLUDE_DYNAMIC_PROCESSES
//#include <systemc>
#include <tlm>

using namespace sc_core;
using namespace sc_dt;

#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>
#include "tlm2axi-bridge.h"
#include "axi2tlm-bridge.h"
#include "tg-tlm.h"
#include "random-traffic.h"

#include "itraffic-desc.h"
#include "traffic-desc.h"
#include "parser.h"
#include "parserfacade.h"
using namespace rapidjson;



bool ParserFacade::Serialize(const DataTransfer& dt, const char* const json){

    Parser theParser;

    return(theParser.Serialize(dt, json));
}

bool ParserFacade::Serialize(const DataTransferVec& dtv,
    const char* const json){

    Parser theParser;

    return(theParser.Serialize(dtv, json));
}

bool ParserFacade::Deserialize(DataTransfer& dt, const char* const json){

    Parser theParser;

    return(theParser.Deserialize(dt, json));
}

bool ParserFacade::Deserialize(DataTransferVec& dtv, const char* const json){

    Parser theParser;

    return(theParser.Deserialize(dtv, json));
}

unsigned int ParserFacade::getLastError(){

    Parser theParser;

    return(static_cast<unsigned int>(theParser.getLastError()));
}

const char* const ParserFacade::getLastErrorDescription(){

    Parser theParser;

    return(theParser.getLastErrorDescription());
}

ParserFacade::ParserFacade(const ParserFacade& rhs){
}

ParserFacade::~ParserFacade(){
}

ParserFacade::ParserFacade(){
}

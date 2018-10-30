// Input parser CmdLineParser
//
// Parses a json format configuration file in order to serialize/deserialize
// the DataTransfer object.
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
#include <string>
#include <iostream>
#include <unistd.h>
#include <vector>
#include <regex>
#include <thread>
#include <vector>
#include "commandlineparser.h"
#include "data-transfer.h"
#include "parserfacade.h"
#include "deserializer.h"

using namespace std;


static void show_usage()
{
	std::cerr << "Usage: " << " <option(s)> config file names\n\t" <<"For example:- '-p -d config1.json config2.json'\n"
		<< "Options:\n"
		<< "\t-h\t\tShow this help message\n"
		<< "\t-d\t\tenables the debug. Will dump out error messages if any\n"
		<< "\t-D\t\tEnables traffic debugging. Will dump out transacations\n"
		<< "\t-p\t\tthis options does the parallel parsing\n"
		<< "\t-a\t\tEnable AXI aw channel tracing\n"
		<< "\t-w\t\tEnable AXI w channel tracing\n"
		<< "\t-b\t\tEnable AXI b channel tracing\n"
		<< "\t-A\t\tEnable AXI ar channel tracing\n"
		<< "\t-r\t\tEnable AXI rr channel tracing\n"
		<< std::endl;
}

// Global static pointer used to ensure a single instance of the class.
//CmdLineParser* CmdLineParser::m_pinstance = NULL;

static std::string getCmdOption(int argc, char* argv[], const std::string& option)
{
    std::string path_local;
     for( int i = 0; i < argc; ++i)
     {
          std::string arg = argv[i];
          if(0 == arg.find(option))
          {
               path_local =arg.substr(option.length());
               return path_local;
          }
     }
     return path_local;
}

void CmdLineParser::cmd_Parse(const int argc,  char ** const argv){
	int opt;
	string input = "";
	opterr = 0;
	// std::string::size_type n;
	//check for option argument.
	while ( (opt = getopt(argc, argv, "hpdDawbAr")) != -1 ) {  // for each option...
		switch ( opt ) {
			case 'h':
        //call the function show_usage.
				show_usage();
				break;
			case 'p':
				parallel_flag = true;
				break;
			case 'd':
				enable_debug = true;
				break;
			case 'D':
				debug_traffic = true;
				break;
			case 'a':
				m_aw = true;
				break;
			case 'w':
				m_w = true;
				break;
			case 'b':
				m_b = true;
				break;
			case 'A':
				m_ar = true;
				break;
			case 'r':
				m_rr = true;
				break;
			case '?':  // unknown option...
				cerr << "Unknown option: " << char(optopt) << "' Use '-h' for help" << endl;
				break;
		}
	}
	path = getCmdOption(argc, argv, "tp=");

	// Retrieve the (non-option) argument:
	if ( (argc <= 1) || (argv[argc-1] == NULL) || (argv[argc-1][0] == '-') ) {  // there is NO input...
		cerr << "No inputs/config(json) file names provided. Use 'h' option for the help!" << endl;
	}
	else {  // there is an input, look if we have  been given a json file name.
		for (int i = 1; i <argc; i++){
			input = argv[i];
			string arg1(argv[i]);
			// An object of regex for pattern to be searched
			regex r(".json");
			// parallel_flag type for determining the matching behavior
			// here it is for matches on 'string' objects
			smatch m;
			// regex_search() for searching the regex pattern
			// 'r' in the string 's'. 'm' is parallel_flag for determining
			// matching behavior.
			if(regex_search(arg1, m, r)){
				config_file_names.push_back(argv[i]);
			}
		}
		for(uint i=0; i<config_file_names.size();i++){
			string temp = path;
			temp += config_file_names[i];
			DataTransferVec dataTransferVector;
	    	ParserFacade::Deserialize(dataTransferVector, temp.c_str());
		}
	}
}
//If user passes parameter. Come here and parse
CmdLineParser& CmdLineParser::InstanceCmdLineParser(const int argc,  char ** const argv){
		static CmdLineParser m_pinstance;

		if((argv != 0) && (argv != nullptr)){
				m_pinstance.cmd_Parse(argc, argv);
		}

		return(m_pinstance);
};

//Returns bool value of '-p' option.
bool CmdLineParser::getParallel() const{
	return(parallel_flag);
}

bool CmdLineParser::getDebugModeStatus() const{
	return(enable_debug);
}

bool CmdLineParser::getDebugTraffic() const{
	return debug_traffic;
}

std::string CmdLineParser::getPath() const{
	return(path);
}

CmdLineParser::~CmdLineParser(){
}

const vector<string> CmdLineParser::getConfigs() const{
	return config_file_names;
}

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
#ifndef COMMAND_LINE_PARSER_H__
#define COMMAND_LINE_PARSER_H__
#include <stdio.h>
#include <vector>
#include <string>
using namespace std;
//
// CmdLineParser Class
//
class CmdLineParser{
    public:
        //constructor
        static CmdLineParser& InstanceCmdLineParser(const int argc = 0,  char ** const argv = nullptr);
        //static CmdLineParser* InstanceCmdLineParser();
        //destrcutor
        virtual ~CmdLineParser();
        bool getParallel() const; //make them const
        bool getDebugModeStatus() const;
        bool getDebugTraffic() const;
        const vector<string> getConfigs() const;
        string getPath() const;

        // AXI channel trace options
        bool get_aw() const { return m_aw; }
        bool get_w() const { return m_w; }
        bool get_b() const { return m_b; }
        bool get_ar() const { return m_ar; }
        bool get_rr() const { return m_rr; }

      private:
        bool parallel_flag;
        bool enable_debug;
        bool debug_traffic;
        bool m_aw;
        bool m_w;
        bool m_b;
        bool m_ar;
        bool m_rr;
        vector<string> config_file_names;
        std::string path ;
        void cmd_Parse(const int argc,  char ** const argv);

        CmdLineParser(){
          	parallel_flag = false;
          	enable_debug = false;
            vector <char*> config_file_names;
		    path = " ";
        };
        // make copy constructor private
        CmdLineParser(CmdLineParser&){};
        //assignment operator is private too
        CmdLineParser& operator = (CmdLineParser const&);
        //static CmdLineParser* m_pinstance;
        void sequential_Run(const char* const config_file, bool debug);

};

#endif //COMMAND_LINE_PARSER_H__

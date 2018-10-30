// Configuration Parser
//
// Parses a json format configuration file in order to serialize/deserialize
// the DataTransfer object.
//
// Copyright 2018 (C) Xilinx Inc.
// Written by Sakis Panou <sakis.panou@xilinx.com>
// Edited&Tested by Vikram <fnuv@xilinx.com>
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

#ifndef XJSON_PARSER_H__
#define XJSON_PARSER_H__

#include <rapidjson/document.h>
#include <rapidjson/prettywriter.h>

//
// Parser Class
//
class Parser{
    public:

        Parser();
        virtual ~Parser();

        //
        //
        //
        bool Serialize(const DataTransfer& dt, const char* const json);
        bool Serialize(const DataTransferVec& dtv, const char* const json);

        bool Deserialize(DataTransfer& dt, const char* const json);
        bool Deserialize(DataTransferVec& dtv, const char* const json);

        enum ErrorCode {
            E_OK = 0,
            E_PARSESTRMFAIL = 1,
            E_DOMNOOBJ = 2,
            E_ADDRFLDNOTFOUND = 3,
            E_CMDFLDNOTFOUND = 4,
            E_DATFLDNOTFOUND = 5,
            E_DATFLDNOTARRAY = 6,
            E_LENFLDNOTFOUND = 7,
            E_BTLNFLDNOTFOUND = 8,
            E_BTLNFLDNOTARRAY = 9,
            E_BTENLNFLDNOTFOUND = 10,
            E_STRMWDTHNOTFOUND = 11,
            E_EXPTFLDNOTFOUND = 12,
            E_EXPTFLDNOTARRAY = 13,
            E_EXTFLDNOTFOUND = 14,
            E_EXTFLDNOTOBJ = 15,
            E_GNATRFLDNOTFOUND = 16,
            E_GNATRFLDNOTOBJ = 17,
            E_ENBLDFLDNOTFOUND = 18,
            E_MSTRIDFLDNOTFOUND = 19,
            E_SECFLDNOTFOUND = 20,
            E_EOPFLDNOTFOUND = 21,
            E_DTTRFSNOTFOUND = 22,
            E_DTTRFSNOTARRAY = 23,
            E_ARRYENTRYNOTOBJ = 24,
            E_ADDRNOTSPRTDFMT = 25,
            E_DATANOTSPRTDFMT = 26,
            E_BTENNOTSPRTDFMT = 27,
            E_EXPNOTSPRTDFMT = 28,
            E_INVALIDLENGTH = 29,
            E_INVLAIDBYTELENGTH = 30,
            E_INVALID_STREAMWIDTH = 31,
	        E_BYTELEGTHNOTEQUAL = 32,
            E_LENGTHNOTEQUAL = 33,
            E_EOPINCORRECTFORMAT = 34,
            E_SECURECORRECTFORMAT = 35,
            E_MASTERIDISNOTINT = 36,
            E_ENABLEDNOTABOOL = 37,
            E_BRSTWDTHNOTFOUND = 38,
            E_BRSTWDTHINCORRECTFORMAT = 39,
            E_TRXSIDNOTFOUND = 40,
            E_TRXSIDINCORRECTFORMAT = 41,
            E_EXCLSVNOTFOUND = 42,
            E_EXCLSVINCORRECTFORMAT = 43,
            E_LCKDNOTFOUND = 44,
            E_LCKDINCORRECTFORMAT = 45,
            E_BUFFRBLNOTFOUND = 46,
            E_BUFFRBLINCORRECTFORMAT = 47,
            E_QOSNOTFOUND = 48,
            E_QOSINCORRECTFORMAT = 49,
            E_RGNNOTFOUND = 50,
            E_RGNINCORRECTFORMAT = 51,
            E_USERSTRINGINVALID = 52,
            E_MODFBLNOTFOUND = 53,
            E_MODFBLINCORRECTFORMAT = 54,
            E_ALLC1NOTFOUND = 55,
            E_ALLC1INCORRECTFORMAT = 56,
            E_ALLC2NOTFOUND = 57,
            E_ALLC2INCORRECTFORMAT = 58,
            E_NOTJSONEXTFAIL = 59,
            E_INVDERRORCODE = 60,
            E_UNKNOWNCMD = 61,
            E_WRAPFLDNOTFOUND = 62,
            E_WRAPINCORRECTFORMAT = 63,
            E_ERROR_MAX
        };

        void setLastError(ErrorCode ec);
        ErrorCode getLastError();
        const char* const getLastErrorDescription();

        bool deserializeSingleObject(DataTransfer& dt,
            const rapidjson::Value& val);

        void serializeSingleObject(const DataTransfer& dt,
            rapidjson::PrettyWriter<rapidjson::StringBuffer>& writer);

    private:
        Parser(const Parser& rhs);
        static ErrorCode theLastErrorCode;
        bool jsonArrayToString(std::string& jsonArrayString,
            const rapidjson::Value& val);
};

#endif//XJSON_PARSER_FACADE_H__

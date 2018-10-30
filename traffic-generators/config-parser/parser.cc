// Configuration Parser
//
// Parses a json format configuration file in order to serialize/deserialize
// the DataTransfer object.
//
//
// Copyright 2018 (C) Xilinx Inc.
// Written by Sakis Panou <sakis.panou@xilinx.com>
// Edited & Tested by Vikram <fnuv@xilinx.com>

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
#include <string>
#include <vector>
#include <array>
#include <fstream>
#include <iostream>
#include <iomanip>

#include <rapidjson/filewritestream.h>
#include "data-transfer.h"
#include "parser.h"
#include "deserializer.h"
#include "commandlineparser.h"

using namespace rapidjson;


static const char * const ErrorCodes[] = {
    "Ok",
    "Failed to parse the json stream",
    "The DOM is not an object",
    "The 'addr' field of the DataTransfer object was not found",
    "The 'cmd' field of the DataTransfer object was not found",
    "The 'data' field of the DataTransfer object was not found",
    "The 'data' field of the DataTransfer is not an array",
    "The 'length' field of the DataTransfer object was not found",
    "The 'byte_enable' field of the DataTransfer object was not found",
    "The 'byte_enable' field of the DataTransfer is not an array",
    "The 'byte_enable_length' field of the DataTransfer object was not found",
    "The 'streaming_width' field of the DataTransfer object was not found",
    "The 'expect' field of the DataTransfer object was not found",
    "The 'expect' field of the DataTransfer is not an array",
    "The 'ext' nested structure of the DataTransfer object is not found",
    "The 'ext' nested structure of the DataTransfer object is not an object",
    "The 'ext.gen_attr' nested structure of the DataTransfer object is not found",
    "The 'ext.gen_attr' nested structure of the DataTransfer object is not an object",
    "The 'ext.gen_attr.enabled' nested field of the DataTransfer object was not found",
    "The 'ext.gen_attr.master_id' nested field of the DataTransfer object was not found",
    "The 'ext.gen_attr.secure' nested field of the DataTransfer object was not found",
    "The 'dataTransfers' field of the DataTransfers vector object was not found",
    "The 'dataTransfers' field of the DataTransfers vector object is not an array",
    "Entry found in the DataTransfers Vector that is not an object",
    "The 'addr' field of the DataTransfer object was not a string or a uint64_t",
    "The 'data' field of the DataTransfer object was not a string or a unsigned char",
    "The 'byte_enable' field of the DataTransfer object was not a string or a unsigned char",
    "The 'expect' field of the DataTransfer entry was not a string or a unsigned char",
    "The 'length' field of the DataTransfer object was not a integer",
    "The 'byte_enable_length' field of the DataTransfer object was not a integer",
    "The 'streaming_width' field of the DataTransfer object was not a integer",
    "'byte_enable' array length and 'byte_enable_length' are not equal",
    "'Data array' length and provided length are not equal",
    "'eop' parametere is not a boolean",
    "'secure' paraemter is not a boolean",
    "'Master_ID' is not a unsigned integer",
    "'enabled' is not a boolean",
    "The 'burst_width' field of the ext.gen_attr structure was not found",
    "The 'burst_width' field of the ext.gen_attr is neither an unsinged integer or a string",
    "The 'transaction_id' field of the ext.gen_attr structure was not found",
    "The 'transaction_id' field of the ext.gen_attr is neither an unsinged integer or a string",
    "The 'exclusive' field of the ext.gen_attr structure was not found",
    "The 'exclusive' field of the ext.gen_attr is neither an boolean or a string",
    "The 'locked' field of the ext.gen_attr structure was not found",
    "The 'locked' field of the ext.gen_attr is neither an boolean or a string",
    "The 'bufferable' field of the ext.gen_attr structure was not found",
    "The 'bufferable' field of the ext.gen_attr is neither an boolean or a string",
    "The 'qos' field of the ext.gen_attr structure was not found",
    "The 'qos' field of the ext.gen_attr is neither an unsinged integer or a string",
    "The 'region' field of the ext.gen_attr structure was not found",
    "The 'region' field of the ext.gen_attr is neither an unsinged integer or a string",
    "Couldn't process user string input"
    "The 'modifiable' field of the ext.gen_attr structure was not found",
    "The 'modifiable' field of the ext.gen_attr is neither an boolean or a string",
    "The 'read_allocate' field of the ext.gen_attr structure was not found",
    "The 'read_allocate' field of the ext.gen_attr is neither an boolean or a string",
    "The 'write_allocate' field of the ext.gen_attr structure was not found",
    "The 'write_allocate' field of the ext.gen_attr is neither an boolean or a string",
    "The file name supplied doesn't have a .json extension",
    "Unknown 'cmd' error (allowed 'cmd' values are \"r\", \"w\", \"R\", \"W\", 0 or 1.",
    "The 'wrap' field of the ext.gen_attr structure was not found",
    "'wrap' parameter is not a boolean",
    "The Error Code Supplied is Invalid, likely outside the range of supported errors."
};



template< typename T >
const std::string to_hex(T value)
{
  std::stringstream stream;
  stream << "0x" << std::hex << value;
         //<< std::setfill ('0') << std::setw(sizeof(T)*2)
  return stream.str();
}


Parser::ErrorCode Parser::theLastErrorCode = Parser::ErrorCode::E_OK;

Parser::Parser(){
};

Parser::~Parser(){
};

Parser::Parser(const Parser& rhs){
};

void Parser::setLastError(Parser::ErrorCode ec){
    theLastErrorCode = ec;
    CmdLineParser& cmdLine1 = CmdLineParser::InstanceCmdLineParser();

    if(cmdLine1.getDebugModeStatus()){
      std::cout << ErrorCodes[ec] << std::endl;
  }
}

Parser::ErrorCode Parser::getLastError(){
    return(theLastErrorCode);
}

const char* const Parser::getLastErrorDescription(){
    return(ErrorCodes[theLastErrorCode]);
}


//
//
bool Parser::Serialize(const DataTransfer& dt, const char* const json){

    setLastError(E_OK);

    const std::string jsonFileExt (".json");
    const std::string inString(json);

    // Does the file name passed in have a .json extention ?
    if(std::string::npos == inString.rfind(jsonFileExt)){
        setLastError(Parser::E_NOTJSONEXTFAIL);
        return(false);
    }

    StringBuffer sb;

    PrettyWriter<StringBuffer> writer(sb);

    serializeSingleObject(dt, writer);

    const uint64_t length = ((sb.GetSize() / sizeof(StringBuffer::Ch)) + 1);

    char* cstr = new char[length];
    std::strcpy(cstr, sb.GetString());
    //std::cout << cstr << std::endl;

    std::ofstream ofs(json, std::ofstream::out);
    ofs << cstr ;
    ofs.close();

    Document d;

    //ParseResult pr = d.Parse(cstr);
    d.Parse(cstr);

    if(0 != cstr){
        delete [] cstr;
    }

    //if(!pr){
    if(d.HasParseError()){
        setLastError(Parser::E_PARSESTRMFAIL);
        return(false);
    }

    return(true);
}


//
// Static Serialization Method for a signle DataTransfer object
// (see TODO list above)
//
bool Parser::Serialize(const DataTransferVec& dtv, const char* const json){

    setLastError(E_OK);

    const std::string jsonFileExt (".json");
    const std::string inString(json);

    // Does the file name passed in have a .json extention ?
    if(std::string::npos == inString.rfind(jsonFileExt)){
        setLastError(Parser::E_NOTJSONEXTFAIL);
        return(false);
    }

    StringBuffer sb;

    PrettyWriter<StringBuffer> writer(sb);

    writer.StartObject();
        writer.String("dataTransfers");
        writer.StartArray();
        for(DataTransferVec::const_iterator it = dtv.begin();
            it != dtv.end(); ++it){
            serializeSingleObject(*it, writer);
        }
        writer.EndArray();
    writer.EndObject();

    //std::cout << "Parser::SerializeVector()" << std::endl;

    const uint64_t length = ((sb.GetSize() / sizeof(StringBuffer::Ch)) + 1);
    char* cstr = new char[length];
    std::strcpy(cstr, sb.GetString());

    std::ofstream ofs(json, std::ofstream::out);
    ofs << cstr ;
    ofs.close();

    Document d;

    //ParseResult pr = d.Parse(cstr);
    d.Parse(cstr);

    if(0 != cstr){
        delete [] cstr;
    }

    //if(!pr){
    if(d.HasParseError()){
        setLastError(Parser::E_PARSESTRMFAIL);
        return(false);
    }

    return(true);
}

bool Parser::Deserialize(DataTransferVec& dtv, const char* const json){

    bool result = false;
    setLastError(E_OK);

    const std::string jsonFileExt (".json");
    const std::string inString(json);
    char* cstr = 0;

    // Is the string passed in a file name or simply a json string ?
    if(std::string::npos == inString.rfind(jsonFileExt)){
        //Access the raw string bytes.
        cstr = new char[inString.length() + 1];
        std::strcpy(cstr, inString.c_str());

        //std::cout << cstr << std::endl;

    } else {
        // Open the file stream for input
        std::ifstream ifs(inString.c_str(), std::ifstream::in);
        // Set up a stringstream to read the content of the file
        std::stringstream buffer;
        // Read up the entire file into the stringstream buffer
        buffer << ifs.rdbuf();

        //Create a string to receive the data
        std::string strData(buffer.str());
        //Access the raw string bytes.
        cstr = new char[strData.length() + 1];
        std::strcpy(cstr, strData.c_str());
        //std::cout << cstr << std::endl;
    }

    // If we can't process the input string then bail out
    if(0 == cstr){
        setLastError(E_USERSTRINGINVALID);
        return(false);
    }


   // Create a RapidJson string stream
    StringStream s(cstr);

    Document d;

    // Make sure that at minimum the json contents conform
    // to the DOM model
    //ParseResult ok = d.ParseStream(s);
    d.ParseStream(s);

    //
    // If we can't even create a DOM model from the json file
    // the chances are the file is corrupted and we need to exit
    // gracefully-ish ;-)
    //
    //if(!ok){
    if(d.HasParseError()){
        setLastError(Parser::E_PARSESTRMFAIL);
    } else {
        result = true;
    }


    // Need to have an object to start with
    if(true == result){
        if(false == d.IsObject()){
            setLastError(E_DOMNOOBJ);
            result = false;
        }
    }

    if(true == result){

        // deserialize the start looking for the dataTransfers moniker
        if(false == d.HasMember("dataTransfers")) {
            setLastError(E_DTTRFSNOTFOUND);
            result = false;
        } else {
            // Ensure the element has an array specified
            if(false == d["dataTransfers"].IsArray()){

                setLastError(E_DTTRFSNOTARRAY);
                result = false;

            } else {
                const Value& a = d["dataTransfers"];

                for (SizeType i = 0; i < a.Size(); i++){

                    if(a[i].IsObject()){

                        // We have the first object in the array
                        const Value& dTrnsValue = a[i];
                        DataTransfer* dt = new DataTransfer(true);

                        // Zeroize the entire structure, any unspecified fields
                        // will be set by default to 0, false, null
                        memset(dt, 0x00, sizeof(DataTransfer));
                        dt->on_heap = true;

                        //
                        // Parse a single object and then push it in
                        // the vector if successful
                        //
                        if(true == deserializeSingleObject(*dt, dTrnsValue)){
                            if( (0 == dt->data) && (0 == dt->byte_enable) &&
                                (0 == dt->expect)){
                                dt->on_heap = false;
                            }
                            dtv.emplace_back(std::move(*dt));
                            result = true;
                        } else {
                            result = false;
                            break;
                        }

                        if(nullptr != dt){
                            delete dt;
                        }

                    } else {
                        setLastError(E_ARRYENTRYNOTOBJ);
                        result = false;
                    }
                }
            }
        }
    }


    if(0 != cstr){
        delete [] cstr;
    }

    return(result);
}

//
// Static Deserialization Method for a signle DataTransfer object
// (see TODO list above)
//
bool Parser::Deserialize(DataTransfer& dt, const char* const json){

    bool result = false;
    setLastError(E_OK);

    const std::string jsonFileExt (".json");
    const std::string inString(json);
    char* cstr = 0;

    // Is the string passed in a file name or simply a json string ?
    if(std::string::npos == inString.rfind(jsonFileExt)){
        //Access the raw string bytes.
        cstr = new char[inString.length() + 1];
        std::strcpy(cstr, inString.c_str());

    } else {
        // Open the file stream for input
        std::ifstream ifs(inString.c_str(), std::ifstream::in);
        // Set up a stringstream to read the content of the file
        std::stringstream buffer;
        // Read up the entire file into the stringstream buffer
        buffer << ifs.rdbuf();

        //Create a string to receive the data
        std::string strData(buffer.str());
        //Access the raw string bytes.
        cstr = new char[strData.length() + 1];
        std::strcpy(cstr, strData.c_str());
        //std::cout << cstr << std::endl;
    }

    // If we can't process the input string then bail out
    if(0 == cstr){
        setLastError(E_USERSTRINGINVALID);
        return(false);
    }

    // Zeroize the entire structure, any unspecified fields
    // will be set by default to 0, false, null
    memset(&dt, 0x00, sizeof(dt));
    dt.on_heap = true;

    // Create a RapidJson string stream
    StringStream s(cstr);

    Document d;

    // Make sure that at minimum the json contents conform
    // to the DOM model
    //ParseResult ok = d.ParseStream(s);
    d.ParseStream(s);

    //
    // If we can't even create a DOM model from the json file
    // the chances are the file is corrupted and we need to exit
    // gracefully-ish ;-)
    //
    //if(!ok){
    if(d.HasParseError()){
        setLastError(Parser::E_PARSESTRMFAIL);
        result = false;
    } else {
        // Need to have an object to start with
        if(false == d.IsObject()){
            setLastError(E_DOMNOOBJ);
            result = false;
        } else {
            //const Value& val = d.GetObject();

            //result = deserializeSingleObject(dt, val);
            result = deserializeSingleObject(dt, d);
        }
    }

    if(0 != cstr){
        delete [] cstr;
    }

    return(result);
}

void Parser::serializeSingleObject(const DataTransfer& dt,
    PrettyWriter<StringBuffer>& writer){
    writer.StartObject();
        writer.String("addr"); writer.String(to_hex(dt.addr).c_str());

        writer.String("cmd"); writer.Uint(dt.cmd);
        writer.String("data");
            writer.StartArray();
                for(uint32_t i=0; i < dt.length; i++){
                    writer.String(to_hex(static_cast<unsigned short>(
                        dt.data[i])).c_str());
                }
            writer.EndArray();
        writer.String("length"); writer.Uint(dt.length);
        writer.String("byte_enable");
            writer.StartArray();
                for(uint32_t i=0; i < dt.byte_enable_length; i++){
                    writer.String(to_hex(static_cast<unsigned short>(
                        dt.byte_enable[i])).c_str());
                }
            writer.EndArray(dt.length);
        writer.String("byte_enable_length"); writer.Uint(dt.byte_enable_length);
        writer.String("streaming_width"); writer.Uint(dt.streaming_width);
        writer.String("expect");
            writer.StartArray();
                for(uint32_t i=0; i < dt.length; i++){
                    writer.String(to_hex(static_cast<unsigned short>(
                        dt.expect[i])).c_str());
                }
            writer.EndArray();
        writer.String("ext");
            writer.StartObject();
                writer.String("gen_attr");
                    writer.StartObject();
                       writer.String("enabled");
                       writer.Bool(dt.ext.gen_attr.enabled);

                       writer.String("master_id");
                       writer.Uint64(dt.ext.gen_attr.master_id);

                       writer.String("secure");
                       writer.Bool(dt.ext.gen_attr.secure);

                       writer.String("eop");
                       writer.Bool(dt.ext.gen_attr.eop);

                       writer.String("wrap");
                       writer.Bool(dt.ext.gen_attr.wrap);

                       writer.String("burst_width");
                       writer.Uint(dt.ext.gen_attr.burst_width);

                       writer.String("transaction_id");
                       writer.Uint(dt.ext.gen_attr.transaction_id);

                       writer.String("exclusive");
                       writer.Bool(dt.ext.gen_attr.exclusive);

                       writer.String("locked");
                       writer.Bool(dt.ext.gen_attr.locked);

                       writer.String("bufferable");
                       writer.Bool(dt.ext.gen_attr.bufferable);

                       writer.String("modifiable");
                       writer.Bool(dt.ext.gen_attr.modifiable);

                       writer.String("read_allocate");
                       writer.Bool(dt.ext.gen_attr.read_allocate);

                       writer.String("write_allocate");
                       writer.Bool(dt.ext.gen_attr.write_allocate);

                       writer.String("qos");
                       writer.Uint(dt.ext.gen_attr.qos);

                       writer.String("region");
                       writer.Uint(dt.ext.gen_attr.region);
                    writer.EndObject();
            writer.EndObject();
    writer.EndObject();
}

//
// jsonArrayToString takes as an argument a rapidjson array and returns a fully
// qualified array in string format, each element of the array is comma
// separated.
//
bool Parser::jsonArrayToString(std::string& jsonArrayString, const Value& val){

    std::ostringstream oss;
    std::string theData;
    bool result = false;

    if(false == val.IsArray()){
        setLastError(E_DATFLDNOTARRAY);
    } else {

        for (SizeType i = 0; i < val.Size(); i++){

            if(val[i].IsString()){
                theData = val[i].GetString();
                oss << theData.c_str()  << ", ";
            } else if(val[i].IsUint()){
                oss << std::hex << static_cast<int>(val[i].GetUint()) << ", " ;
            } else {
                setLastError(E_DATANOTSPRTDFMT);
            }
        }

        jsonArrayString = oss.str();
        result = true;
    }

    return(result);
}

//
// deserializeSingleObject inflates a json string representation into a fully
// fledged DataTransfer object. On successful completion the function returns
// true otherwise false. When false is returned the state of the dt parameter
// is undefined.
//
bool Parser::deserializeSingleObject(DataTransfer& dt, const Value& val){

    Deserializer ds;

    // Need to have an object to start with
    if(false == val.IsObject()){
        setLastError(E_DOMNOOBJ);
        return(false);
    }

    // deserialize the DataTransfer::addr field
    if(false == val.HasMember("addr")) {
        setLastError(E_ADDRFLDNOTFOUND);
    } else {

        if(val["addr"].IsUint64()){
            dt.addr = val["addr"].GetUint64();
         } else if(val["addr"].IsString()) {
            if( false == ds.deserialize(dt.addr, val["addr"].GetString())){
                dt.addr = 0;
            }
         } else {
            setLastError(E_ADDRNOTSPRTDFMT);
         }
    }

    // deserialize the DataTransfer::cmd field
    if(false == val.HasMember("cmd")) {
        setLastError(E_CMDFLDNOTFOUND);
        dt.cmd = 0;
    } else {
        if (val["cmd"].IsString()) {
            std::string cmd = val["cmd"].GetString();
            if(cmd == "W" || cmd == "w"){
              dt.cmd = DataTransfer::WRITE;
            } else if(cmd == "R" || cmd == "r"){
              dt.cmd = DataTransfer::READ;
            } else {
              setLastError(E_UNKNOWNCMD);
            }
        } else if(val["cmd"].IsUint()){
              dt.cmd = val["cmd"].GetUint();
        } else {
            setLastError(E_INVALIDLENGTH);
        }
    }

    // deserialize the DataTransfer::data field
    if(false == val.HasMember("data")) {
        setLastError(E_DATFLDNOTFOUND);
    } else {

        if(false == val["data"].IsArray()){
            setLastError(E_DATFLDNOTARRAY);
        } else {
            const Value& a = val["data"];
            unsigned char* data = new unsigned char[a.Size()];

            // Convert the arrray to a string first
            std::string jsonString("");
            jsonArrayToString(jsonString, a);

            // Pass the string array and size to the deserialize method
            if(true == ds.deserialize(data, a.Size(), jsonString)){
                dt.data = data;
            } else {
                delete [] data;
                dt.data = 0;
            }
        }
    }

    // deserialize the DataTransfer::length field
    if(false == val.HasMember("length")) {
        setLastError(E_LENFLDNOTFOUND);
    } else {
        if(val["length"].IsUint()){
            dt.length = val["length"].GetUint();
            //checking and validating the length of array and user input
            if(val.HasMember("data") && val["data"].Size()!= dt.length){
                setLastError(E_LENGTHNOTEQUAL);
            }
        } else if(val["length"].IsString()){
            if( false == ds.deserialize(dt.length, val["length"].GetString())){
                dt.length = 0;
            }
        }
        else{
            setLastError(E_INVALIDLENGTH);
        }

    }


    // deserialize the DataTransfer::byte_enable field
    if(false == val.HasMember("byte_enable")) {
        setLastError(E_BTLNFLDNOTFOUND);
    } else {

        if(false == val["byte_enable"].IsArray()){
            setLastError(E_BTLNFLDNOTARRAY);
        } else {
            const Value& a = val["byte_enable"];
            unsigned char* byte_enable = new unsigned char[a.Size() +1];

            std::string jsonString("");
            jsonArrayToString(jsonString, a);

            // Pass the string array and size to the deserialize method
            if(true == ds.deserialize(byte_enable, a.Size(), jsonString)){
                dt.byte_enable = byte_enable;
            } else {
                delete [] byte_enable;
                dt.byte_enable = 0;
            }
        }
    }


    // TODO: Add Check to validate byte_enable array length with the
    // byte_enable_length field.
    // deserialize the DataTransfer::byte_enable_length field
    if(false == val.HasMember("byte_enable_length")) {
        setLastError(E_BTENLNFLDNOTFOUND);
    } else {
        if(val["byte_enable_length"].IsUint()){
            dt.byte_enable_length = val["byte_enable_length"].GetUint();
            //check the byte_enable array length with provided
            //byte_enable_length
            if(val["byte_enable"].Size() != dt.byte_enable_length){
                setLastError(E_BYTELEGTHNOTEQUAL);
            }
        } else if(val["byte_enable_length"].IsString()){
            if( false == ds.deserialize(dt.byte_enable_length,
                    val["byte_enable_length"].GetString())){
                dt.byte_enable_length = 0;
            }
        }
        else{
            setLastError(E_INVLAIDBYTELENGTH);
        }
    }

    // deserialize the DataTransfer::streaming_width field
    if(false == val.HasMember("streaming_width")) {
        setLastError(E_STRMWDTHNOTFOUND);
    } else {
        if(val["streaming_width"].IsUint()){

            dt.streaming_width = val["streaming_width"].GetUint();

        } else if(val["byte_enable_length"].IsString()){

            if( false == ds.deserialize(dt.streaming_width,
                    val["streaming_width"].GetString())){
                dt.streaming_width = 0;
            }

        } else {
            setLastError(E_INVALID_STREAMWIDTH);
        }
    }

    // deserialize the DataTransfer::expect field
    if(false == val.HasMember("expect")) {
        setLastError(E_EXPTFLDNOTFOUND);
    } else {

        if(false == val["expect"].IsArray()){
            setLastError(E_EXPTFLDNOTARRAY);
            dt.expect = 0;
        } else {

            const Value& a = val["expect"];
            unsigned char* expect = new unsigned char[a.Size() +1];

            std::string jsonString("");
            jsonArrayToString(jsonString, a);

            // Pass the string array and size to the deserialize method
            if(true == ds.deserialize(expect, a.Size(), jsonString)){
                dt.expect = expect;
            } else {
                delete [] expect;
                dt.expect = 0;
            }
        }
    }

    // deserialize the DataTransfer::ext struct
    if(false == val.HasMember("ext")) {
        setLastError(E_EXTFLDNOTFOUND);
    } else {

        // Make sure it is an object
        if(false == val["ext"].IsObject()){
            setLastError(E_EXTFLDNOTOBJ);
        } else {

            const Value& ext = val["ext"];

            // deserialize the DataTransfer::ext::gen_attr struct
            if(false == ext.HasMember("gen_attr")){
                setLastError(E_GNATRFLDNOTFOUND);
            } else {

                // Make sure it is an object
                if(false == ext["gen_attr"].IsObject()){
                    setLastError(E_GNATRFLDNOTOBJ);

                } else {


                    const Value& gen_attr = ext["gen_attr"];

                    // deserialize the DataTransfer::ext::gen_attr::enabled field
                    if(false == gen_attr.HasMember("enabled")) {
                        setLastError(E_ENBLDFLDNOTFOUND);
                        dt.ext.gen_attr.enabled = false;
                    } else {
                        if(gen_attr["enabled"].IsBool()){
                            dt.ext.gen_attr.enabled = gen_attr["enabled"].GetBool();
                        } else if(gen_attr["enabled"].IsString()){

                            if( false == ds.deserialize(dt.ext.gen_attr.enabled,
                                    gen_attr["enabled"].GetString())){
                                dt.ext.gen_attr.enabled = false;
                            }

                    	} else{
                    		setLastError(E_ENABLEDNOTABOOL);
                    	}
                    }

                    // deserialize the
                    // DataTransfer::ext::gen_attr::master_id field
                    if(false == gen_attr.HasMember("master_id")) {
                        setLastError(E_MSTRIDFLDNOTFOUND);
                        dt.ext.gen_attr.master_id = 0 ;
                    } else {
                    	if(gen_attr["master_id"].IsUint64()){
	                        dt.ext.gen_attr.master_id =
                                gen_attr["master_id"].GetUint64();
                    	} else if(gen_attr["master_id"].IsString()) {

                            if( false == ds.deserialize(
                                dt.ext.gen_attr.master_id ,
                                gen_attr["master_id"].GetString())){

                                dt.ext.gen_attr.master_id = 0;
                            }

                        } else {
                            dt.ext.gen_attr.master_id = 0;
                    		setLastError(E_MASTERIDISNOTINT);
                    	}
                    }

                    // deserialize the DataTransfer::ext::gen_attr::secure field
                    if(false == gen_attr.HasMember("secure")) {
                        setLastError(E_SECFLDNOTFOUND);
                    } else {
                        if(gen_attr["secure"].IsBool()){
                            dt.ext.gen_attr.secure =
                            gen_attr["secure"].GetBool();
                        }else if(gen_attr["secure"].IsString()) {

                            if( false == ds.deserialize(dt.ext.gen_attr.secure,
                                    gen_attr["secure"].GetString())){
                                dt.ext.gen_attr.secure = 0;
                            }

                        }else {
                            dt.ext.gen_attr.secure = 0;
                            setLastError(E_SECURECORRECTFORMAT);
                        }
                    }
                    // deserialize the DataTransfer::ext::gen_attr::secure field
                    if(false == gen_attr.HasMember("secure")) {
                        setLastError(E_SECFLDNOTFOUND);
                    } else {
                        if(gen_attr["secure"].IsBool()){
                            dt.ext.gen_attr.secure =
                            gen_attr["secure"].GetBool();

                        }else if(gen_attr["secure"].IsString()) {

                            if( false == ds.deserialize(dt.ext.gen_attr.secure ,
                                    gen_attr["secure"].GetString())){
                                dt.ext.gen_attr.secure = 0;
                            }

                        }else {
                            dt.ext.gen_attr.secure = 0;
                            setLastError(E_SECURECORRECTFORMAT);
                        }
                    }

                    // deserialize the DataTransfer::ext::gen_attr::eop field
                    if(false == gen_attr.HasMember("eop")) {
                        setLastError(E_EOPFLDNOTFOUND);
                        dt.ext.gen_attr.eop = 0;
                    } else {
                        if(gen_attr["eop"].IsBool()){
                            dt.ext.gen_attr.eop = gen_attr["eop"].GetBool();
                        } else if (gen_attr["eop"].IsString()) {
                            if( false == ds.deserialize(dt.ext.gen_attr.eop ,
                                    gen_attr["eop"].GetString())){
                                dt.ext.gen_attr.eop = 0;
                            }
                        } else {
                            dt.ext.gen_attr.eop = 0;
                            setLastError(E_EOPINCORRECTFORMAT);
                        }
                    }

                    if(false == gen_attr.HasMember("wrap")) {
                        setLastError(E_WRAPFLDNOTFOUND);
                        dt.ext.gen_attr.wrap = false;
                    } else {
                        if(gen_attr["wrap"].IsBool()){
                            dt.ext.gen_attr.wrap =
					gen_attr["wrap"].GetBool();
                        } else if (gen_attr["wrap"].IsString()) {
                            if( false == ds.deserialize(dt.ext.gen_attr.wrap,
                                    gen_attr["wrap"].GetString())){
                                dt.ext.gen_attr.wrap = false;
                            }
                        } else {
                            dt.ext.gen_attr.wrap = false;
                            setLastError(E_WRAPINCORRECTFORMAT);
                        }
                    }

                    // deserialize the
                    // DataTransfer::ext::gen_attr::burst_width field
                    if(false == gen_attr.HasMember("burst_width")) {
                        dt.ext.gen_attr.burst_width = 0;
                        setLastError(E_BRSTWDTHNOTFOUND);
                    } else {
                        if(gen_attr["burst_width"].IsUint()){
                            dt.ext.gen_attr.burst_width =
                            gen_attr["burst_width"].GetUint();
                        } else if (gen_attr["burst_width"].IsString()) {
                            if( false == ds.deserialize(
                                dt.ext.gen_attr.burst_width ,
                                gen_attr["burst_width"].GetString())){

                                dt.ext.gen_attr.burst_width = 0;
                            }
                        } else {
                            dt.ext.gen_attr.burst_width = 0;
                            setLastError(E_BRSTWDTHINCORRECTFORMAT);
                        }
                    }

                    // deserialize the
                    // DataTransfer::ext::gen_attr::transaction_id field
                    if(false == gen_attr.HasMember("transaction_id")) {
                        dt.ext.gen_attr.transaction_id = 0;
                        setLastError(E_TRXSIDNOTFOUND);
                    } else {
                        if(gen_attr["transaction_id"].IsUint()){
                            dt.ext.gen_attr.transaction_id =
                            gen_attr["transaction_id"].GetUint();
                        } else if (gen_attr["transaction_id"].IsString()) {
                            if( false == ds.deserialize(
                                dt.ext.gen_attr.transaction_id ,
                                gen_attr["transaction_id"].GetString())){
                                dt.ext.gen_attr.transaction_id = 0;
                            }
                        } else {
                            dt.ext.gen_attr.transaction_id = 0;
                            setLastError(E_TRXSIDINCORRECTFORMAT);
                        }
                    }

                    // deserialize the
                    // DataTransfer::ext::gen_attr::exclusive field
                    if(false == gen_attr.HasMember("exclusive")) {
                        dt.ext.gen_attr.exclusive = 0;
                        setLastError(E_EXCLSVNOTFOUND);
                    } else {
                        if(gen_attr["exclusive"].IsBool()){
                            dt.ext.gen_attr.exclusive =
                            gen_attr["exclusive"].GetBool();

                        } else if (gen_attr["exclusive"].IsString()) {
                            if( false == ds.deserialize(
                                dt.ext.gen_attr.exclusive ,
                                gen_attr["exclusive"].GetString())){

                                dt.ext.gen_attr.exclusive = false;
                            }
                        } else {
                            dt.ext.gen_attr.exclusive = false;
                            setLastError(E_EXCLSVINCORRECTFORMAT);
                        }
                    }

                    // deserialize the DataTransfer::ext::gen_attr::locked field
                    if(false == gen_attr.HasMember("locked")) {
                        dt.ext.gen_attr.locked = 0;
                        setLastError(E_LCKDNOTFOUND);
                    } else {
                        if(gen_attr["locked"].IsBool()){
                            dt.ext.gen_attr.locked =
                            gen_attr["locked"].GetBool();
                        } else if (gen_attr["locked"].IsString()) {
                            if( false == ds.deserialize(dt.ext.gen_attr.locked ,
                                    gen_attr["locked"].GetString())){
                                dt.ext.gen_attr.locked = false;
                            }
                        } else {
                            dt.ext.gen_attr.locked = false;
                            setLastError(E_LCKDINCORRECTFORMAT);
                        }
                    }

                    // deserialize the
                    //  DataTransfer::ext::gen_attr::bufferable field
                    if(false == gen_attr.HasMember("bufferable")) {
                        dt.ext.gen_attr.bufferable = false;
                        setLastError(E_BUFFRBLNOTFOUND);
                    } else {
                        if(gen_attr["bufferable"].IsBool()){
                            dt.ext.gen_attr.bufferable =
                            gen_attr["bufferable"].GetBool();
                        } else if (gen_attr["bufferable"].IsString()) {
                            if( false == ds.deserialize(
                                dt.ext.gen_attr.bufferable ,
                                gen_attr["bufferable"].GetString())){

                                dt.ext.gen_attr.bufferable = false;
                            }
                        } else {
                            dt.ext.gen_attr.bufferable = false;
                            setLastError(E_BUFFRBLINCORRECTFORMAT);
                        }
                    }

                    // deserialize the
                    //  DataTransfer::ext::gen_attr::modifiable field
                    if(false == gen_attr.HasMember("modifiable")) {
                        dt.ext.gen_attr.modifiable = false;
                        setLastError(E_MODFBLNOTFOUND);
                    } else {
                        if(gen_attr["modifiable"].IsBool()){
                            dt.ext.gen_attr.modifiable =
                            gen_attr["modifiable"].GetBool();
                        } else if (gen_attr["modifiable"].IsString()) {
                            if( false == ds.deserialize(
                                dt.ext.gen_attr.modifiable ,
                                gen_attr["modifiable"].GetString())){

                                dt.ext.gen_attr.modifiable = false;
                            }
                        } else {
                            dt.ext.gen_attr.modifiable = false;
                            setLastError(E_MODFBLINCORRECTFORMAT);
                        }
                    }

                    // deserialize the
                    //  DataTransfer::ext::gen_attr::read_allocate field
                    if(false == gen_attr.HasMember("read_allocate")) {
                        dt.ext.gen_attr.read_allocate = false;
                        setLastError(E_ALLC1NOTFOUND);
                    } else {
                        if(gen_attr["read_allocate"].IsBool()){
                            dt.ext.gen_attr.read_allocate =
                            gen_attr["read_allocate"].GetBool();
                        } else if (gen_attr["read_allocate"].IsString()) {
                            if( false == ds.deserialize(
                                dt.ext.gen_attr.read_allocate ,
                                gen_attr["read_allocate"].GetString())){

                                dt.ext.gen_attr.read_allocate = false;
                            }
                        } else {
                            dt.ext.gen_attr.read_allocate = false;
                            setLastError(E_ALLC1INCORRECTFORMAT);
                        }
                    }

                    // deserialize the
                    //  DataTransfer::ext::gen_attr::write_allocate field
                    if(false == gen_attr.HasMember("write_allocate")) {
                        dt.ext.gen_attr.write_allocate = false;
                        setLastError(E_ALLC2NOTFOUND);
                    } else {
                        if(gen_attr["write_allocate"].IsBool()){
                            dt.ext.gen_attr.write_allocate =
                            gen_attr["write_allocate"].GetBool();
                        } else if (gen_attr["write_allocate"].IsString()) {
                            if( false == ds.deserialize(
                                dt.ext.gen_attr.write_allocate ,
                                gen_attr["write_allocate"].GetString())){

                                dt.ext.gen_attr.write_allocate = false;
                            }
                        } else {
                            dt.ext.gen_attr.write_allocate = false;
                            setLastError(E_ALLC2INCORRECTFORMAT);
                        }
                    }

                    // deserialize the DataTransfer::ext::gen_attr::qos field
                    if(false == gen_attr.HasMember("qos")) {
                        dt.ext.gen_attr.qos = 0;
                        setLastError(E_QOSNOTFOUND);
                    } else {
                        if(gen_attr["qos"].IsUint()){
                            dt.ext.gen_attr.qos = gen_attr["qos"].GetUint();
                        } else if (gen_attr["qos"].IsString()) {
                            if( false == ds.deserialize(dt.ext.gen_attr.qos ,
                                    gen_attr["qos"].GetString())){
                                dt.ext.gen_attr.qos = 0;
                            }
                        } else {
                            dt.ext.gen_attr.qos = 0;
                            setLastError(E_QOSINCORRECTFORMAT);
                        }
                    }

                    // deserialize the DataTransfer::ext::gen_attr::region field
                    if(false == gen_attr.HasMember("region")) {
                        dt.ext.gen_attr.region = 0;
                        setLastError(E_RGNNOTFOUND);
                    } else {
                        if(gen_attr["region"].IsUint()){
                            dt.ext.gen_attr.region =
                            gen_attr["region"].GetUint();

                        } else if (gen_attr["region"].IsString()) {
                            if( false == ds.deserialize(dt.ext.gen_attr.region ,
                                    gen_attr["region"].GetString())){
                                dt.ext.gen_attr.region = 0;
                            }
                        } else {
                            dt.ext.gen_attr.region = 0;
                            setLastError(E_RGNINCORRECTFORMAT);
                        }
                    }
                }
            }
        }
    }

    return(true);
}

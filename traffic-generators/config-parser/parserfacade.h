// Configuration Parser
//
// Parses a json format configuration file in order to serialize/deserialize
// the DataTransfer object.
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

#ifndef XJSON_PARSER_FACADE_H__
#define XJSON_PARSER_FACADE_H__

// Forward Declarations
//class DataTransfer;
//typedef std::vector<DataTransfer> DataTransferVec;

//
// ParserFacade
//
class ParserFacade{
    public:

        //
        // Overview:
        // The Following Parser facade methods are the main methods used to
        // serialize and deserialize both individual DataTransfer objects
        // as well as DataTransfer Vectors. See declarations in data-transfer.h
        //
        // Furthermore, the following parser facade methods are atomic,
        // they complete in a single function call and do not carry any
        // state information (are stateless) between subsequent calls.
        // They are stateless by design and are designed in a manner that
        // pass minimal dependencies on their clients.
        //
        // Thread Safety:
        // Even though the methods are atomic in nature they make no assumptions
        // as to the threading model used. As such there is not thread
        // safeguarding the client should assume responsibility in completing
        // the call in an single thread call model.
        //
        // Invokation Model:
        // Moreover the following methods are static by design and as such
        // they do not necessitate any object creation requirements prior to
        // invocation.As the name of the class suggests this is a facade to an
        // internal construct that provides the actual implementation.
        // It is strongly suggested to always use this facade when deserializing
        // and/or deserializing DataTransfer objects, the underlying implementation
        // may change, calls made directly to the underlying imlmenetation will
        // not be supported. Additionally this class cannot be instantiated as
        // the default constructor, copy constructor and destructor are made private,
        // this is by design and must not be modified. You may not inherit from this
        // class.
        //
        // Return Values:
        // The following methods return true on successful completion, false
        // otherwise. If a method returns false the client can retrieve more
        // information through the utillity methods getLastError() and
        // getErrorDescription() respectively.
        //
        // Resource Utilization:
        // The following methods expect a fully instantiated parameters, looking
        // at the DataTransfer and DataTranfers are passed by ref in calls, calls
        // to the methods may, if required, allocated additional resources for
        // dynamic data when deserializing them. It is the responsibility of the
        // caller to free additional memory allocated using the corresponding
        // member pointer fields.
        //

        static bool Serialize(const DataTransfer& dt,
            const char* const json);

        static bool Serialize(const DataTransferVec& dtv,
            const char* const json);

        static bool Deserialize(DataTransfer& dt,
            const char* const json);

        static bool Deserialize(DataTransferVec& dtv,
            const char* const json);

        static unsigned int getLastError();
        static const char* const getLastErrorDescription();

    private:
        ParserFacade(const ParserFacade& rhs);
        virtual ~ParserFacade();
        ParserFacade();
};



#endif//XJSON_PARSER_FACADE_H__

// Deserializer
//
// Accepts a string as a means of determining how to deserialize the data.
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

#ifndef DESERIALIZER_H__
#define DESERIALIZER_H__

//
// Deserializer Class
//
class Deserializer{
    public:

        Deserializer();
        virtual ~Deserializer();

        //
        //
        //
        bool deserialize(uint32_t& val, const std::string& str);
        bool deserialize(uint8_t& val, const std::string& str);
        bool deserialize(uint64_t& val, const std::string& str);
        bool deserialize(bool& val, const std::string& str);
        bool deserialize(uint8_t* val, size_t arrayLen, const std::string& str);

        //
        // Lookahead positive and negative regular expresssions.
        // std::regex rgxDecVal("^[0-9]+(?!x|X)");
        // std::regex rgxHexVal("^0(?=x|X)(x|X){1}(?=[0-9a-fA-F])[0-9a-fA-F]+");
        //

    private:
        Deserializer(const Deserializer& rhs);



        enum Consts {
            HEX=16,
            DEC=10
        };

        //
        // The scope of this class is to determine the policy as
        // it can be determined from the string passed. The policies
        // supported are:
        //
        // @Random
        // @Discrete
        // @String
        //
        class InflationPolicy{
          public:
              enum Policy {
                RANDOM=0,
                DISCRETE,
                STRING,
                INVALID,
                SZ = INVALID
              };

              InflationPolicy();
              virtual ~InflationPolicy();
              Policy getPolicy(const std::string& str);
          private:
              static const std::string policyQualifiers[SZ];
        };

        class StringUtilities{
            public:
                //
                // String utility methods
                //
                static const std::string trimSpace(const std::string& str);

                static std::vector<std::string> stringSpliter(
                    const std::string& str,
                    char delimeter);
        };

        class GenericInflator{
            public:
                virtual bool inflate(uint8_t* val, size_t arrayLen,
                     const std::string& str) = 0;
                virtual bool inflate(bool& val, const std::string& str) = 0;
                virtual bool inflate(uint32_t& val, const std::string& str) = 0;
                virtual bool inflate(uint64_t& val, const std::string& str) = 0;
                virtual bool inflate(uint8_t& val, const std::string& str) = 0;

                virtual ~GenericInflator(){
                }
            // protected:
            //     GenericInflator(const GenericInflator& rhs){
            //     }
        };

        class RandomInflator : public GenericInflator{
            public:
                virtual bool inflate(uint8_t* val, size_t arrayLen,
                    const std::string& str);
                virtual bool inflate(bool& val, const std::string& str);
                virtual bool inflate(uint32_t& val, const std::string& str);
                virtual bool inflate(uint64_t& val, const std::string& str);
                virtual bool inflate(uint8_t& val, const std::string& str);

                virtual ~RandomInflator(){
                }
            private:
                uint64_t seed;
                uint64_t size;
                uint64_t lBound;
                uint64_t uBound;
                std::vector<uint8_t> randomRange;

                void processSeed(const std::string& text);
                void processSize(const std::string& text);
                void processLowerBound(const std::string& text);
                void processUpperBound(const std::string& text);
                void processRandomRange(const std::string& text);

                const std::string getParamList(const std::string& annotation);
                void getParams(const std::string& params);
                // RandomInflator(const RandomInflator& rhs) :
                //     GenericInflator(rhs) {
                // }
        };

        class DiscreteInflator : public GenericInflator{
            public:
                virtual bool inflate(uint8_t* val, size_t arrayLen,
                    const std::string& str);

                virtual bool inflate(bool& val, const std::string& str);
                virtual bool inflate(uint32_t& val, const std::string& str);
                virtual bool inflate(uint64_t& val, const std::string& str);
                virtual bool inflate(uint8_t& val, const std::string& str);

                virtual ~DiscreteInflator(){
                }
            private:
                // DiscreteInflator(const DiscreteInflator& rhs):
                //     GenericInflator(rhs) {
                // }
        };

        class StringInflator : public GenericInflator{
            public:
                virtual bool inflate(uint8_t* val, size_t arrayLen,
                    const std::string& str);

                virtual bool inflate(bool& val, const std::string& str);
                virtual bool inflate(uint32_t& val, const std::string& str);
                virtual bool inflate(uint64_t& val, const std::string& str);
                virtual bool inflate(uint8_t& val, const std::string& str);

                virtual ~StringInflator(){
                }
            private:
                // StringInflator(const StringInflator& rhs):
                //     GenericInflator(rhs) {
                // }
        };

        GenericInflator* createInflator(InflationPolicy::Policy policy);
};

#endif//DESERIALIZER_H__

// Deserializer
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
#include <string>
#include <cstdint>
#include <cstdlib>
#include <regex>

#include "deserializer.h"



Deserializer::Deserializer(){

}

Deserializer::~Deserializer(){

}

bool Deserializer::deserialize(uint32_t& val, const std::string& str){
    bool result = false;
    Deserializer::GenericInflator* inflator = 0 ;

    if(0==str.length())
        return(result);

    try{
        // Determine the inflation policy passed by the user
        InflationPolicy theInflationPolicy;
        InflationPolicy::Policy thePolicy = theInflationPolicy.getPolicy(str);

        // Did we match an expected annotation? If not bail out.
        if(InflationPolicy::Policy::INVALID != thePolicy) {

            // Create the appropriate inflator based on the policy
            inflator = createInflator(thePolicy);

            // Use the inflate method to populate the data
            if(0 != inflator){
                result = inflator->inflate(val, str);
            }
        }
    } catch(const std::regex_error& e){
        // Don't let the exception propagate,
        // return gracefully
        result = false;
    } catch(...){
        // Don't let the exception propagate,
        // return gracefully
        result = false;
    }

    if(0 != inflator){
        delete inflator;
    }

    // return the inflation result
    return(result);
}

bool Deserializer::deserialize(uint8_t& val, const std::string& str){
    bool result = false;
    Deserializer::GenericInflator* inflator = 0;

    if(0==str.length())
        return(result);

    try{
        // Determine the inflation policy passed by the user
        InflationPolicy theInflationPolicy;
        InflationPolicy::Policy thePolicy = theInflationPolicy.getPolicy(str);

        // Did we match an expected annotation? If not bail out.
        if( InflationPolicy::Policy::INVALID != thePolicy) {
            // Create the appropriate inflator based on the policy
            inflator = createInflator(thePolicy);

            // Use the inflate method to populate the data
            if( 0 != inflator ){
                result = inflator->inflate(val, str);
            }
        }
    } catch(const std::regex_error& e){
        // Don't let the exception propagate,
        // return gracefully
        result = false;
    } catch(...){
        // Don't let any exception propagate,
        // return gracefully
        result = false;
    }

    if(0 != inflator){
        delete inflator;
    }

    // return the inflation result
    return(result);
}

bool Deserializer::deserialize(uint64_t& val, const std::string& str){
    bool result = false;
    Deserializer::GenericInflator* inflator = 0;

    if(0==str.length())
        return(result);

    try{
        // Determine the inflation policy passed by the user
        InflationPolicy theInflationPolicy;
        InflationPolicy::Policy thePolicy = theInflationPolicy.getPolicy(str);

        // Did we match an expected annotation? If not bail out.
        if( InflationPolicy::Policy::INVALID != thePolicy) {

            // Create the appropriate inflator based on the policy
            inflator = createInflator(thePolicy);

            // Use the inflate method to populate the data
            if( 0 != inflator ){
                result = inflator->inflate(val, str);
            }
        }
    } catch(const std::regex_error& e){
        // Don't let the exception propagate,
        // return gracefully
        result = false;
    } catch(...){
        // Don't let any exception propagate,
        // return gracefully
        result = false;
    }

    if(0 != inflator){
        delete inflator;
    }

    // return the inflation result
    return(result);
}

bool Deserializer::deserialize(bool& val, const std::string& str){
    bool result = false;
    Deserializer::GenericInflator* inflator = 0;

    if(0==str.length())
        return(result);

    try{
        // Determine the inflation policy passed by the user
        InflationPolicy theInflationPolicy;
        InflationPolicy::Policy thePolicy = theInflationPolicy.getPolicy(str);

        // Did we match an expected annotation? If not bail out.
        if( InflationPolicy::Policy::INVALID != thePolicy) {
            // Create the appropriate inflator based on the policy
            inflator = createInflator(thePolicy);

            // Use the inflate method to populate the data
            if( 0 != inflator ){
                result = inflator->inflate(val, str);
            }
        }
    } catch(const std::regex_error& e){
        // Don't let the exception propagate,
        // return gracefully
        result = false;
    } catch(...){
        // Don't let any exception propagate,
        // return gracefully
        result = false;
    }

    if(0 != inflator){
        delete inflator;
    }

    // return the inflation result
    return(result);
}

bool Deserializer::deserialize(uint8_t* val, size_t arrayLen,
    const std::string& str){

    bool result = false;
    Deserializer::GenericInflator* inflator = 0;

    if( (0==str.length()) || (0 == val) || (0==arrayLen))
        return(result);

    try{
        // Determine the inflation policy passed by the user
        InflationPolicy theInflationPolicy;
        InflationPolicy::Policy thePolicy = theInflationPolicy.getPolicy(str);

        // Did we match an expected annotation? If not bail out.
        if( InflationPolicy::Policy::INVALID != thePolicy) {

            // Create the appropriate inflator based on the policy
            inflator = createInflator(thePolicy);

            // Use the inflate method to populate the data
            if( 0 != inflator ){
                result = inflator->inflate(val, arrayLen, str);
            }
        }
    } catch(const std::regex_error& e){
        // Don't let the exception propagate,
        // return gracefully
        result = false;
    } catch(...){
        // Don't let any exception propagate,
        // return gracefully
        result = false;
    }

    if(0 != inflator){
        delete inflator;
    }

    // return the inflation result
    return(result);
}

Deserializer::Deserializer(const Deserializer& rhs){
}

const std::string Deserializer::
    InflationPolicy::
    policyQualifiers[Deserializer::InflationPolicy::SZ] = {
    "^[[:blank:]]*(@Random){1}[[:blank:]]*\\({1}.{0,}\\){1}",
    "^[[:blank:]]*(@Discrete){1}[[:blank:]]*\\({1}.{0,}\\){1}",
    "^([[:blank:]]*[0-9|x|X|A-F|a-f]+[[:blank:]]*,?[[:blank:]]*)*"

};

const std::string Deserializer::StringUtilities::trimSpace(const std::string& str){
    std::regex startSpace("^[[:blank:]]*");
    std::regex endSpace("[[:blank:]]*$");
    std::smatch sm;

    std::string trx1("");

    if(regex_search(str, sm, startSpace)){
        trx1 = regex_replace(str, startSpace, "");
    } else {
        trx1 = str;
    }

    std::string trx2("");
    if(regex_search(trx1, sm, startSpace)){
        trx2 = regex_replace(trx1, endSpace, "");
    } else{
        trx2 = trx1;
    }

    return(trx2);
}

std::vector<std::string>  Deserializer::StringUtilities::stringSpliter(const std::string& str,
    char delimeter){

    std::vector<std::string> tokens;
    std::stringstream ss;
    std::string strFound;
    ss << str ;

    while(std::getline(ss, strFound, delimeter)){
        tokens.push_back(trimSpace(strFound));
    }

    return(tokens);
}

Deserializer::InflationPolicy::InflationPolicy(){
}

Deserializer::InflationPolicy::~InflationPolicy(){

}

//
// Examines the string value against a set of policy patterns, if a match it is
// found it returns the appropriate enum value, if it fails it returns
// Policy::INVALID
//
Deserializer::InflationPolicy::Policy Deserializer::InflationPolicy::getPolicy(
    const std::string& str){
    // Set the policy to an invalid value
    Policy thePolicy = INVALID;

    std::regex  rgxRandomAnnotation(policyQualifiers[RANDOM]);
    std::regex  rgxDiscreteAnnotation(policyQualifiers[DISCRETE]);
    std::regex  rgxStringAnnotation(policyQualifiers[STRING]);
    std::smatch sm;

    // Iterate through the policy patterns if one matches
    // return immediately the policy value

    // Check for the @Random Annotation
    if(std::regex_search(str, sm, rgxRandomAnnotation)){
        return(static_cast<Policy>(RANDOM));
    // Check for the @Discrete Annotation
    } else if(std::regex_search(str, sm, rgxDiscreteAnnotation)){
        return(static_cast<Policy>(DISCRETE));
    // Check for a comma seperated generic string
    } else if(std::regex_search(str, sm, rgxStringAnnotation)){
        return(static_cast<Policy>(STRING));
    }

    // If we have managed to come this far without a match then we need to
    // bail out gracefully by returning an invalid value
    return(thePolicy);
}

//
// Mini Factory, it takes in the policy ID and returns the appropriate Inflator.
// If successful a downcasted pointer to the appropriate Inflator is returned.
// Otherwise a null pointer is returned.
//
Deserializer::GenericInflator* Deserializer::createInflator(
    Deserializer::InflationPolicy::Policy policy){

    switch (policy) {
        case InflationPolicy::Policy::RANDOM:
            return(new Deserializer::RandomInflator());
        case InflationPolicy::Policy::DISCRETE:
            return(new Deserializer::DiscreteInflator());
        case InflationPolicy::Policy::STRING:
            return(new Deserializer::StringInflator());
        case InflationPolicy::Policy::INVALID:
        default:
            return(0);
    }
    return(0);
}

//
// Process the seed parameter,it returns the value of the text in uint32_t
//
void Deserializer::RandomInflator::processSeed(const std::string& text){

    std::regex rgxSeed(
        "seed{1}[[:blank:]]*={1}[[:blank:]]*([[:alnum:]])+[[:blank:]]*");

    std::regex rgxKey("^[[:blank:]]*seed[[:blank:]]*={1}[[:blank:]]*");

    // Hex and Decimal Patterns
    std::regex rgxDecVal("^[0-9]+(?!x|X)");
    std::regex rgxHexVal("^0(?=x|X)(x|X){1}(?=[0-9a-fA-F])[0-9a-fA-F]+");

    std::string val;
    std::smatch sm;

    // Search for the seed
    if(std::regex_search(text, sm, rgxSeed)){

        //Retrieve the whole match and strip the last comma
        const std::string seedParam(sm.str());

        // Strip the "seed = " part and keep the value
        val = Deserializer::StringUtilities::trimSpace(
            std::regex_replace(seedParam, rgxKey, ""));

        // Is the value passed in Hexadecimal?
        if(std::regex_search(val, sm, rgxHexVal)){
            this->seed = strtoull(sm.str().c_str(), 0, Consts::HEX);
        }

        // Is the value passed in Decimal?
        if(std::regex_search(val, sm, rgxDecVal)){
            this->seed = strtoull(sm.str().c_str(), 0, Consts::DEC);
        }
    }
}

//
// Process the seed parameter,it returns the value of the text in uint32_t
//
void Deserializer::RandomInflator::processRandomRange(
    const std::string& text){
    // Full Range Pattern
    std::regex rgxRandRange("[[:blank:]]*(randomRange)[[:blank:]]*="
        "[[:blank:]]*\\[[[:blank:]]*([[:alnum:]]+[[:blank:]]*,{0,1}"
        "[[:blank:]]*)*\\]");
    // Key Pattern
    std::regex rgxKey("[[:blank:]]*(randomRange)[[:blank:]]*=[[:blank:]]"
        "*\\[[[:blank:]]*");

    // End of Array Pattern
    std::regex rgxEnd("[[:blank:]]*][[:blank:]]*,*[[:blank:]]*");
    // Values Pattern
    std::regex rgxVal("[[:alnum:]]+");

    // Hex and Decimal Patterns
    std::regex rgxDecVal("^[0-9]+(?!x|X)");
    std::regex rgxHexVal("^0(?=x|X)(x|X){1}(?=[0-9a-fA-F])[0-9a-fA-F]+");

    std::string valArray;
    std::smatch smArray;

    // Wipe off the vector before we start building up the range
    this->randomRange.clear();

    // Search for the key and equal sign "seed ="
    if(std::regex_search(text, smArray, rgxRandRange)){

        //Retrieve the whole match
        const std::string randomRangeParam(smArray.str());

        std::string temp( std::regex_replace(randomRangeParam, rgxKey, ""));

        valArray = std::regex_replace(temp, rgxEnd, "");

        while(std::regex_search(valArray,smArray,rgxVal)){

            const std::string val(Deserializer::StringUtilities::trimSpace(
                smArray.str()));

            std::smatch sm;

            //Is the value passed in Hexadecimal?
            if(std::regex_search(val, sm, rgxHexVal)){
                uint64_t result = strtoull(sm.str().c_str(), 0, Consts::HEX);
                randomRange.push_back(static_cast<uint8_t>(result));
            }

            // Is the value passed in Decimal?
            if(std::regex_search(val, sm, rgxDecVal)){
                uint64_t result = strtoull(sm.str().c_str(), 0, Consts::DEC);
                randomRange.push_back(static_cast<uint8_t>(result));
            }

            valArray = smArray.suffix().str();
        }
    }

    //for(uint64_t i = 0; i < randomRange.size(); i++){
    //    std::cout << std::hex << static_cast<int>(randomRange[i]) << std::endl;
    //}
}

//
// Process the size parameter,it returns the value of the text in uint32_t
//
void Deserializer::RandomInflator::processSize(const std::string& text){
    std::regex rgxSize("[[:blank:]]*size[[:blank:]]*="
        "[[:blank:]]*[[:alnum:]]+[[:blank:]]*");

    std::regex rgxKey("^[[:blank:]]*size[[:blank:]]*={1}[[:blank:]]*");

    // Hex and Decimal Patterns
    std::regex rgxDecVal("^[0-9]+(?!x|X)");
    std::regex rgxHexVal("^0(?=x|X)(x|X){1}(?=[0-9a-fA-F])[0-9a-fA-F]+");

    std::string val;
    std::smatch sm;

    // Search for the key and equal sign "seed ="
    if(std::regex_search(text, sm, rgxSize)){

        //Retrieve the whole match and strip the last comma
        const std::string sizeParam(sm.str());

        // Strip the "size = " part and keep the value
        val = Deserializer::StringUtilities::trimSpace(std::regex_replace(
            sizeParam, rgxKey, ""));

        if(std::regex_search(val, sm, rgxHexVal)){
            this->size = strtoull(sm.str().c_str(), 0, Consts::HEX);
        }

        if(std::regex_search(val, sm, rgxDecVal)){
            this->size = strtoull(sm.str().c_str(), 0, Consts::DEC);
        }
    }
}
//
// Process the lBound parameter,it returns the value of the text in uint32_t
//
void Deserializer::RandomInflator::processLowerBound(const std::string& text){
    std::regex rgxlBound("[[:blank:]]*lBound[[:blank:]]*="
        "[[:blank:]]*[[:alnum:]]+[[:blank:]]*");

    std::regex rgxKey("^[[:blank:]]*lBound[[:blank:]]*={1}[[:blank:]]*");

    // Hex and Decimal Patterns
    std::regex rgxDecVal("^[0-9]+(?!x|X)");
    std::regex rgxHexVal("^0(?=x|X)(x|X){1}(?=[0-9a-fA-F])[0-9a-fA-F]+");

    std::string val;
    std::smatch sm;

    if(std::regex_search(text, sm, rgxlBound)){

        //Retrieve the whole match and strip the last comma
        const std::string lBoundParam(sm.str());

        // Strip the "size = " part and keep the value
        val = Deserializer::StringUtilities::trimSpace(std::regex_replace(
            lBoundParam, rgxKey, ""));

        if(std::regex_search(val, sm, rgxHexVal)){
            this->lBound = strtoull(sm.str().c_str(), 0, Consts::HEX);
        }

        if(std::regex_search(val, sm, rgxDecVal)){
            this->lBound = strtoull(sm.str().c_str(), 0, Consts::DEC);
        }
    }
}
//
// Process the uBound parameter,it returns the value of the text in uint32_t
//
void Deserializer::RandomInflator::processUpperBound(const std::string& text){
        std::regex rgxuBound("[[:blank:]]*uBound[[:blank:]]*="
            "[[:blank:]]*[[:alnum:]]+[[:blank:]]*");

        std::regex rgxKey("^[[:blank:]]*uBound[[:blank:]]*={1}[[:blank:]]*");

        // Hex and Decimal Patterns
        std::regex rgxDecVal("^[0-9]+(?!x|X)");
        std::regex rgxHexVal("^0(?=x|X)(x|X){1}(?=[0-9a-fA-F])[0-9a-fA-F]+");

        std::string val;
        std::smatch sm;

        // Search for the key and equal sign "seed ="
        if(std::regex_search(text, sm, rgxuBound)){

            //Retrieve the whole match and strip the last comma
            const std::string uBoundParam(sm.str());

            // Strip the "size = " part and keep the value
            val = Deserializer::StringUtilities::trimSpace(std::regex_replace(
                uBoundParam, rgxKey, ""));

            if(std::regex_search(val, sm, rgxHexVal)){
                this->uBound = strtoull(sm.str().c_str(), 0, Consts::HEX);
            }

            if(std::regex_search(val, sm, rgxDecVal)){
                this->uBound = strtoull(sm.str().c_str(), 0, Consts::DEC);
            }
        }
}

//
// Removes the annotation and return the parameter list if any has been
// specified
//
const std::string Deserializer::RandomInflator::getParamList(
    const std::string& annotation){

    // Strip the @Random( Annotation
    std::string input(annotation);
    const std::string randStr("@Random(");
    size_t randOpen = input.find(randStr);

    std::string temp(input.replace(randOpen, randStr.length(), ""));

    // Strip the closing paranethesis
    const std::string closeParnthesis(")");
    size_t randClose = temp.find(closeParnthesis);

    // Here is your final string
    const std::string params(temp.replace(randClose,
        closeParnthesis.length(), ""));

    // Return through the copy c'actor
    return(params);
}

//
// Goes through the comma seperated parameter list and updates the relevant
// RandomInflator member properties
//
void Deserializer::RandomInflator::getParams(const std::string& params){
    //
    // If the user has passed in a parameter list go ahead and parse it to
    // update the Random class member properties
    //
    if(0 != params.length()){
        processSeed(params);
        processSize(params);
        processLowerBound(params);
        processUpperBound(params);
        processRandomRange(params);
    }
}

//
// Inflates and array of uint8_ts the arrayLen is a mandatory parameter
// if the user neglects to specify it we assume a length of zero to keep on
// going. This function always succeeds for now.
//
bool Deserializer::RandomInflator::inflate(uint8_t* val, size_t arrayLen,
    const std::string& str){

    //
    // Set the behaviour for an array rand
    //
    this->seed = time(0);
    this->uBound = 0xFF;
    this->lBound = 0x00;
    this->size = 0;

    //
    // Remove the annotation text and retrieve the values for the
    // Random class member properties
    //
    getParams(getParamList(str));

    // Initialize the seed before calling the rand()
    srand(this->seed);

    // If the caller provided buffer is not large enough to take the size
    // specified in the annotation then ensure we only copy the amount of
    // data we have been allocated.
    if(this->size > arrayLen)
        this->size = arrayLen;

    // Fill the array with random values between the lower and upper bounds
    for(uint32_t i=0; i < this->size; i++){
        val[i] = rand() % this->uBound + this->lBound;
    }

    return(true);
}

//
// Inflates a bool value, the size parameter doesn't apply, we ignore it
// even if the user specifies it. This function always succeeds for now.
//
bool Deserializer::RandomInflator::inflate(bool& val, const std::string& str){

    //
    // Set the behaviour for an array rand
    //
    this->seed = time(0);
    this->uBound = 1;
    this->lBound = 0;
    this->size = 0;

    //
    // Remove the annotation text and retrieve the values for the
    // Random class member properties
    //
    getParams(getParamList(str));

    // Initialize the seed before calling the rand()
    srand(this->seed);


    val = static_cast<bool>(rand() % this->uBound + this->lBound);

    return(true);
}

//
// Inflates a uint32_t value, the size parameter doesn't apply, we ignore it
// even if the user specifies it. This function always succeeds for now.
//
bool Deserializer::RandomInflator::inflate(uint32_t& val,
    const std::string& str){

    //
    // Set the behaviour for an uint32_t rand
    //
    this->seed = time(0);
    this->uBound = 0xFFFFFFFF;
    this->lBound = 0;
    this->size = 0;

    //
    // Remove the annotation text and retrieve the values for the
    // Random class member properties
    //
    getParams(getParamList(str));

    // Initialize the seed before calling the rand()
    srand(this->seed);

    // Fill the array with random values between the lower and upper bounds
    val = rand() % this->uBound + this->lBound;

    return(true);
}

//
// Inflates a uint64_t value, the size parameter doesn't apply, we ignore it
// even if the user specifies it. This function always succeeds for now.
//
bool Deserializer::RandomInflator::inflate(uint64_t& val,
    const std::string& str){

    //
    // Set the behaviour for an array rand
    //
    this->seed = time(0);
    this->uBound = 0xFFFFFFFF;
    this->lBound = 0;
    this->size = 0;

    //
    // Remove the annotation text and retrieve the values for the
    // Random class member properties
    //
    getParams(getParamList(str));

    // Initialize the seed before calling the rand()
    srand(this->seed);

    // Fill the array with random values between the lower and upper bounds
    val = 0;
    uint64_t tmp = 0 ;
    tmp = rand() % this->uBound + this->lBound;

    tmp <<= 32;
    val |= tmp;

    tmp = 0;
    tmp = rand() % this->uBound + this->lBound;
    val |= tmp;

    return(true);
}

//
// Inflates a uint8_t value, the size parameter doesn't apply, we ignore it
// even if the user specifies it. This function always succeeds for now.
//
bool Deserializer::RandomInflator::inflate(uint8_t& val,
    const std::string& str){

    //
    // Set the behaviour for an array rand
    //
    this->seed = time(0);
    this->uBound = 0xFF;
    this->lBound = 0;
    this->size = 0;

    //
    // Remove the annotation text and retrieve the values for the
    // Random class member properties
    //
    getParams(getParamList(str));

    // Initialize the seed before calling the rand()
    srand(this->seed);

    // Fill the array with random values between the lower and upper bounds
    val = rand() % this->uBound + this->lBound;

    return(true);
}

bool Deserializer::DiscreteInflator::inflate(uint8_t* val, size_t arrayLen,
    const std::string& str){

    return(false);
}

bool Deserializer::DiscreteInflator::inflate(bool& val,
    const std::string& str){

    return(false);
}

bool Deserializer::DiscreteInflator::inflate(uint32_t& val,
    const std::string& str){

    return(false);
}

bool Deserializer::DiscreteInflator::inflate(uint64_t& val,
    const std::string& str){

    return(false);
}

bool Deserializer::DiscreteInflator::inflate(uint8_t& val,
    const std::string& str){

    return(false);
}


bool Deserializer::StringInflator::inflate(uint8_t* val, size_t arrayLen,
    const std::string& str){

    bool result = false;
    // The string input has to be at least 1 character length otherwise
    // bail out. val must be not null otherwise bail out
    if((0 == arrayLen) || (0 == str.length()) || (0 == val))
        return(result);

    // Split the string using the coma as a delimeter.
    std::vector<std::string> tokens =
        Deserializer::StringUtilities::stringSpliter(str, ',');

    // Hex and Decimal Patterns ( Look Ahead Positive and Look Ahead Negative)
    std::regex rgxDecVal("^[0-9]+(?!x|X)");
    std::regex rgxHexVal("^0(?=x|X)(x|X){1}(?=[0-9a-fA-F])[0-9a-fA-F]+");

    std::smatch sm;

    std::vector<std::string>::iterator it;
    uint64_t idx = 0;
    for(it = tokens.begin(); it != tokens.end(); ++it){

        if(std::regex_search(*it, sm, rgxHexVal)){
            val[idx] = static_cast<uint8_t>(
                strtoull(sm.str().c_str(), 0, Consts::HEX));
            result = true;
        } else if(std::regex_search(*it, sm, rgxDecVal)){
            val[idx] = static_cast<uint8_t>(
                strtoull(sm.str().c_str(), 0, Consts::DEC));
            result = true;
        } else {
            result = false;
            break;
        }

        // Ensure the arrayLen of the input array is larger or equal
        // to the size of the data we have in the string, if not copy only
        // what we can.
        if(++idx == arrayLen){
            break;
        }
    }

    return(true);
}

bool Deserializer::StringInflator::inflate(bool& val,
    const std::string& str){
    bool result = false;

    if(0==str.length())
        return(result);

    // True and False Patterns
    std::regex rgxBoolTrueVal("^[[:blank:]]*(true){1}[[:blank:]]*",
        std::regex_constants::icase);
    std::regex rgxBoolFalseVal("^[[:blank:]]*(false){1}[[:blank:]]*",
            std::regex_constants::icase);

    std::smatch sm;
    std::string text(Deserializer::StringUtilities::trimSpace(str));

    if(std::regex_search(text, sm, rgxBoolTrueVal)){
        val = true ;
        result = true;

    } else if(std::regex_search(text, sm, rgxBoolFalseVal)){
        val = false;
        result = true;
    } else {
        // Do nothing result is already false
        // let the function fail gracefully.
    }

    return(result);
}

bool Deserializer::StringInflator::inflate(uint32_t& val,
    const std::string& str){

    bool result = false;

    if(0==str.length())
        return(result);

    // Hex and Decimal Patterns
    // Lookahead positive and negative regular expresssions.
    std::regex rgxDecVal("^[0-9]+(?!x|X)");
    std::regex rgxHexVal("^0(?=x|X)(x|X){1}(?=[0-9a-fA-F])[0-9a-fA-F]+");
    std::smatch sm;

    std::string text(Deserializer::StringUtilities::trimSpace(str));

    if(std::regex_search(text, sm, rgxHexVal)){

        val = static_cast<uint32_t>(
            strtoull(sm.str().c_str(), 0, Consts::HEX));

        result = true;

    } else if(std::regex_search(text, sm, rgxDecVal)){

        val = static_cast<uint32_t>(
            strtoull(sm.str().c_str(), 0, Consts::DEC));

        result = true;

    } else {
        // Do nothing result is already false
        // let the function fail gracefully.
    }

    return(result);
}

bool Deserializer::StringInflator::inflate(uint64_t& val,
    const std::string& str){

    bool result = false;

    if(0==str.length())
        return(result);

    // Hex and Decimal Patterns
    std::regex rgxDecVal("^[0-9]+(?!x|X)");
    std::regex rgxHexVal("^0(?=x|X)(x|X){1}(?=[0-9a-fA-F])[0-9a-fA-F]+");
    std::smatch sm;

    std::string text(Deserializer::StringUtilities::trimSpace(str));

    if(std::regex_search(text, sm, rgxHexVal)){

        val = static_cast<uint64_t>(
            strtoull(sm.str().c_str(), 0, Consts::HEX));

        result = true;

    } else if(std::regex_search(text, sm, rgxDecVal)){

        val = static_cast<uint64_t>(
            strtoull(sm.str().c_str(), 0, Consts::DEC));

        result = true;

    } else {
        // Do nothing result is already false
        // let the function fail gracefully.
    }

    return(result);
}

bool Deserializer::StringInflator::inflate(uint8_t& val,
    const std::string& str){

    bool result = false;

    if(0==str.length())
        return(result);

    // Hex and Decimal Patterns
    std::regex rgxDecVal("^[0-9]+(?!x|X)");
    std::regex rgxHexVal("^0(?=x|X)(x|X){1}(?=[0-9a-fA-F])[0-9a-fA-F]+");
    std::smatch sm;

    std::string text(Deserializer::StringUtilities::trimSpace(str));

    if(std::regex_search(text, sm, rgxHexVal)){

        val = static_cast<uint8_t>(
            strtoull(sm.str().c_str(), 0, Consts::HEX));

        result = true;

    } else if(std::regex_search(text, sm, rgxDecVal)){

        val = static_cast<uint8_t>(
            strtoull(sm.str().c_str(), 0, Consts::DEC));

        result = true;

    } else {
        // Do nothing result is already false
        // let the function fail gracefully.
    }

    return(result);
}

/***********************************************************************
 * (c) Copyright 
* Copyright (c) 2019 Xilinx Inc. 
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy 
* of this software and associated documentation files (the 'Software'), to deal 
* in the Software without restriction, including without limitation the rights 
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
* copies of the Software, and to permit persons to whom the Software is 
* furnished to do so, subject to the following conditions: 
* 
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
 * Filename:    defines_common.v
 * Description: 
 * Author:  Meera Bagdai                Company:  Xilinx
 * Created: 2019-06-25 10:47:23 IST
 * Revised: 2019-06-25 10:47:23 IST
 *
 *
 **********************************************************************/

// Used for Calculating DATA RAM address bits
`define CLOG2(x) \
   (x <= 2)             ? 1     : \
   (x <= 4)             ? 2     : \
   (x <= 8)             ? 3     : \
   (x <= 16)            ? 4     : \
   (x <= 32)            ? 5     : \
   (x <= 64)            ? 6     : \
   (x <= 128)           ? 7     : \
   (x <= 256)           ? 8     : \
   (x <= 512)           ? 9     : \
   (x <= 1024)          ? 10    : \
   (x <= 2048)          ? 11    : \
   (x <= 4096)          ? 12    : \
   (x <= 8192)          ? 13    : \
   (x <= 16384)         ? 14    : \
   (x <= 32768)         ? 15    : \
   (x <= 65536)         ? 16    : \
   (x <= 131072)         ? 17    : \
   -1



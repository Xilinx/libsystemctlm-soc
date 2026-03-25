/*
 * Trace utils.
 *
 * Copyright (c) 2015 Xilinx Inc.
 * Written by Edgar E. Iglesias
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef TRACE_H__
#define TRACE_H__

#include <systemc>

void trace(sc_core::sc_trace_file* tf, const sc_core::sc_module& mod, const char *txt);

/*
 * Return true only if ALL of the following are true:
 * 1. trace.cc is built and linked, and
 * 2. @env_var environment variable is set, and
 * 3. @env_var environment variable is a list of comma-separated
 *    regular expressions, and
 * 4. @key matches, as whole string, one of those regular expressions
 *
 * E.g.
 *   export FOO='a.*bc,e[.]g'
 * Then,
 *   trace_on("FOO", "abc") returns true
 *   trace_on("FOO", "e.g") returns true
 *   trace_on("FOO", "e_g") returns false
 *
 * The optional linkage is meant for backward compatibility when
 * trace.cc is not in the built source list of existing simulation
 * builds.
 */
#if defined(__clang__) || defined(__GNUC__) || defined(__GNUG__)
bool trace_on_impl(const char *env_var, const char *key) __attribute__((weak));

static inline bool trace_on(const char *env_var, const char *key) {
    return trace_on_impl ? trace_on_impl(env_var, key) : false;
}
#else
static inline bool trace_on(const char *env_var, const char *key) {
    return false;
}
#endif

#endif

#!/usr/bin/env python3
#
# Generate DCMAC registers from:
#   https://download.amd.com/docnav/documents/ip_attachments/dcmac-reg-map.zip
#
# Copyright (C) 2025 Advanced Micro Devices, Inc.
#
# SPDX-License-Identifier: MIT
#

import sys
import getopt
import datetime
import re
import openpyxl
import urllib.request
import zipfile
from io import BytesIO

gTemplate = '''\
/*
 * Versal Soc 600G DCMAC Registers
 *
 * Auto-generated from
 *   https://download.amd.com/docnav/documents/ip_attachments/dcmac-reg-map.zip
 *
 * SPDX-License-Identifier: MIT
 */
#ifndef VERSAL_600G_DCMAC_REGS_H_
#define VERSAL_600G_DCMAC_REGS_H_

{defs}
#endif /* VERSAL_600G_DCMAC_REGS_H_ */

/*
 * For C++, the designated initializers must be listed in the
 * order same as 'struct regapi_info' defined in utils/regapi.h
 */
#ifdef VERSAL_600G_DCMAC_GREGS_INIT
#undef VERSAL_600G_DCMAC_GREGS_INIT
{greg}
    {{}},
#endif /* VERSAL_600G_DCMAC_GREGS_INIT */

#ifdef VERSAL_600G_DCMAC_CREGS_INIT
#undef VERSAL_600G_DCMAC_CREGS_INIT
{creg}
    {{}},
#endif /* VERSAL_600G_DCMAC_CREGS_INIT */

#ifdef VERSAL_600G_DCMAC_PREGS_INIT
#undef VERSAL_600G_DCMAC_PREGS_INIT
{preg}
    {{}},
#endif /* VERSAL_600G_DCMAC_PREGS_INIT */\
'''

def mesg(s):
    print(s, end='', file=sys.stderr, flush=True)

# Fetch remote
def src_dl():
    url = 'https://download.amd.com/docnav/documents/ip_attachments/' + \
          'dcmac-reg-map.zip'
    mesg('Retrieving %s ...' % url)
    wget = urllib.request.urlopen(url=url)
    dl = BytesIO(wget.read())
    mesg('\n')
    return dl

# Read from local (e.g., avoid remote during local debug)
def src_open():
    return './dcmac-reg-map.zip'

def src_rdr():
    dl = src_dl()
    xl = 'dcmac-reg-map/dcmac-reg-map.xlsx'
    mesg('Extract %s ...' % xl)
    zf = zipfile.ZipFile(dl)
    rdr = zf.open(xl)
    mesg('\n')
    return rdr

def src_ws():
    rdr = src_rdr()
    mesg('Load workbook ...')
    wb = openpyxl.load_workbook(rdr, data_only=True, read_only=True)
    sn = 'Description'
    try:
        mesg('\n')
        return wb[sn]
    except:
        mesg('-- Sheet "%s" not found\n' % sn)
        mesg('-- Available sheets: %r\n' % wb.sheetnames)
        sys.exit(1)

def cell(ws, r, c):
    return ws.cell(row=r, column=c)

def cell_empty(c):
    return c.value is None

def cell_eqs(c, s):
    return c.data_type == 's' and c.value == s

def cell_int(c):
    if c.data_type == 'n':
        return c.value
    if c.data_type != 's':
        return 0

    tok = c.value.split('h')
    if len(tok) == 2:
        return int(tok[1], 16)
    else:
        return 0

def row_type(ws, r):
    col_A = cell(ws, r, 1)
    col_B = cell(ws, r, 2)

    if cell_eqs(col_A, 'Address') and cell_eqs(col_B, 'Bits'):
        return 'reg'

    # 2 consecutive empty rows: end of registers
    # 1 empty row: end of bit fields
    if cell_empty(col_A) and cell_empty(col_B):
        col_A = cell(ws, r + 1, 1)
        col_B = cell(ws, r + 1, 2)
        if cell_empty(col_A) and cell_empty(col_B):
            return 'end-of-reg'
        else:
            return 'end-of-fld'

    return 'fld'

class Fld:
    def __init__(self, reg, row):
        bits = cell(reg.ws, row, 2)
        if bits.data_type == 'n':
            self.bit = bits.value
            self.width = 1
        elif bits.data_type == 's':
            n = bits.value.split(':')
            self.bit = int(n[1], 0)
            self.width = int(n[0], 0) - self.bit + 1
        self.name = cell(reg.ws, row, 6).value
        self.attr = cell(reg.ws, row, 4).value
        self.dval = cell_int(cell(reg.ws, row, 3))
        self.reg = reg
        self.row = row

    def emit_def(self):
        return f'    FIELD({self.reg.name}, {self.name}, {self.bit}, {self.width})'

class Reg:
    def __init__(self, ws, row):
        self.ws = ws
        self.row = row - 1
        self.name = cell(ws, self.row, 1).value
        self.addr = int(cell(ws, self.row + 2, 1).value, 0)
        self.flds = list(fld_generator(self))
        self.dval = 0
        self.ro = 0

        for f in self.flds:
            self.dval |= f.dval << f.bit

        fo = [f for f in self.flds if f.attr.startswith('RO')]
        for f in fo:
            fm = (1 << f.width) - 1
            self.ro |= fm << f.bit

    def emit_def(self):
        t = []
        t.append(f'REG32({self.name}, 0x{self.addr:04x})')
        t.extend([f.emit_def() for f in self.flds])
        return t

    def emit_init(self):
        t = []
        # Add conditional truncate of STAT_TX_ECC global registers.
        # For C++, the designated initializers must be listed in the
        # order same as 'struct regapi_info' defined in utils/regapi.h
        #
        t.append(    f'    {{ .name = "{self.name}"')
        if self.ro != 0:
            t.append(f'      .ro = 0x{self.ro:02x}')
        if self.dval != 0:
            t.append(f'      .reset = 0x{self.dval:02x}')

        t.append(    f'      .addr = A_{self.name} }}')
        return [k + ',' for k in t]

def fld_generator(reg):
    row = reg.row + 1
    while True:
        row = row + 1
        rt = row_type(reg.ws, row)
        if rt == 'end-of-fld' or rt == 'end-of-reg':
            break
        if rt == 'fld':
            fld = Fld(reg, row)
            yield fld

# Extract a list of register, until end of C0_*
# Display progress every 20 registers
# C0_* registers are sorted into 2 groups, with their
# 'address' offsets adjusted
# 1. Those common for all 40 channels; -0x1000 adjusted
# 2. Those common for all 6 ports; -0x1040 adjusted
def reg_generator(ws):
    row = 3
    while True:
        row = row + 1
        rt = row_type(ws, row)
        if rt == 'end-of-reg':
            break
        if rt == 'reg':
            reg = Reg(ws, row)
            row = row + len(reg.flds)
            if reg.name.startswith('C1_CHANNEL'):
                break
            if reg.name.startswith('C0_CHANNEL_'):
                reg.addr -= 0x1000
            elif reg.name.startswith('C0_'):
                reg.addr -= 0x1040

            mesg('\rrow %u' % row)
            yield reg
    mesg('\n')

def main():
    ws = src_ws()
    regs = list(reg_generator(ws))

    # Bin C0_* regs
    # Emit hard-coded channel/port base-offset from device base
    # Note:
    #   Registers 0x12D0 and 0x12D8 are rather odd ball:
    #   1. They are in the C0 port range; but
    #   2. They are not present in ranges of the other 5 ports; so
    #   3. They do not seem to be C0 port specific
    inig = []
    defs = []

    inic = []
    defc = ['']
    for c in range(0, 40):
        defc.append(f'REG32(C{c}_CHANNEL_BASE, 0x{(0x1000 + c*0x1000):06x})')

    inip = []
    defp = ['']
    for c in range(0, 6):
        defp.append(f'REG32(C{c}_PORT_BASE, 0x{(0x1040 + c*0x1000):06x})')

    for reg in regs:
        if reg.name.startswith('C0_CHANNEL_'):
            defc.extend(reg.emit_def())
            inic.extend(reg.emit_init())
        elif reg.name.startswith('C0_'):
            defp.extend(reg.emit_def())
            inip.extend(reg.emit_init())
        else:
            defs.extend(reg.emit_def())
            if reg.name == 'STAT_TX_ECC_ERR_REG':
                inig.append('    #ifndef R_STAT_TX_ECC_DROPPED')
            inig.extend(reg.emit_init())
            if reg.name == 'STAT_TX_ECC_UNCORRECTABLE_COUNT':
                inig.append('    #endif /* !R_STAT_TX_ECC_DROPPED */')

    defs.extend(defc)
    defs.extend(defp)

    print(gTemplate.format(defs = '\n'.join(defs),
                           greg = '\n'.join(inig),
                           creg = '\n'.join(inic),
                           preg = '\n'.join(inip)))

if __name__ == "__main__":
    main()

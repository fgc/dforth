import re, fileinput, sys
from pyPEG import parse
from pyPEG import keyword, _and, _not

def comment(): return re.compile(r";.*")

def dasm():           return (-1,[op, label, let, macrodef, macrocall])
def op():             return instr, 0, operand, -1, (",", operand)
def label():          return ":", [macrosub, symbol]
def let():            return "#let", letvar, ",", [literal, macrosub]
def macrodef():       return "#macro", symbol,"(", macroparamdef, ")", "{", dasm, "}"
def macrocall():      return symbol, "(", macroparamlist, ")"
def instr():          return re.compile(r"set|add|sub|mul|div|mod|shl|shr|and|bor|xor|ife|ifn|ifg|ifb|dat")
def operand():        return [expr, macrosub, letvar, symbol, literal, address]
def macrosub():       return [macrovar, (symbol, macrovar)]
def symbol():         return re.compile(r"[a-zA-Z_]+[a-zA-Z0-9_]*")
def letvar():         return "$",symbol
def macroparamdef():  return -1, (symbol, -1, (",", symbol))
def macroparamlist(): return -1, (operand, -1, (",", operand))
def expr():           return [letvar, macrovar, symbol, literal], operator, [letvar, macrovar, symbol, literal]
def literal():        return [hex, decimal, string]
def address():        return "[", operand, "]"
def macrovar():       return "\\", symbol
def operator():       return re.compile(r"\+|\-")
def hex():            return "0x", hexdigits
def decimal():        return re.compile(r'\d+')
def string():         return re.compile(r'".*?"')
def hexdigits():      return re.compile(r"[0-9a-fA-F]+")


pos = 0
unresolved_labels = []
labels = []
special_symbols = {
    'a': 0,
    'b': 1,
    'c': 2,
    'x': 3,
    'y': 4,
    'z': 5,
    'i': 6,
    'j': 7,
    'pop': 24,
    'peek': 25,
    'push': 26,
    'sp': 27,
    'pc': 28,
    'o': 29
}

def do_symbol(op):
    symbol = op[1]
    print "symbol: ", symbol
    if symbol in special_symbols:
        return ('spec',special_symbols[symbol])
    unresolved_labels.append((pos,symbol))
    return ('addr',30)

def do_literal(op):
    type = op[1][0][0]
    val = -1000
    print "type is: ", type
    if type == 'hex':
        val = op[1][0][1][0][1]
    else:
        val = op[1][0][1]
    print type,": ", val
    if type == 'string':
        return ('val',val)
    if type == 'decimal':
        return ('val',int(val,10))
    if type == 'hex':
        return ('val',int(val,16))
    print "Bad literal type: ", type
    sys.exit()
    
def do_address(addr):
    print "Ima address",addr
    print addr[1][0][1]
    op = do_operand(addr[1][0])
    return ('addr',op[1])

operands = {
    'symbol':  do_symbol,
    'literal': do_literal,
    'address': do_address
    
}


def do_operand(op):
    print "do_operand", op
    return operands[op[1][0][0]](op[1][0])

def do_operands(ops):
    return map(do_operand,ops)

def do_set(set):
    global pos
    print "Got a set"
    retval = [1]
    op1,op2 = do_operands(set.what[1:])
    if op1[0] == 'val':
        print "Cannot write into literal: ", set, " pos: ",pos
        sys.exit()
    else:
        if op1[0] == 'spec':
            retval[0] = retval[0] | (op1[1] << 4)
        else: 
            if op1[0] == 'addr':
                retval[0] = retval[0] | (30 << 4)
                retval.append(op1[1])
            else:
                print "Unhandled parameter 1: ", op1, " pos:", pos
                sys.exit()

    if op2[0] == 'val':
        retval[0] = retval[0] | (31 << 10)
        retval.append(op2[1])
    else:
        if op2[0] == 'spec':
            retval[0] = retval[0] | (op2[1] << 10)
        else:
            if op2[0] == 'addr':
                retval[0] = retval[0] | (30 << 10)
                retval.append(op2[1])
            else:
                print "Unhandled parameter 2: ", op2, " pos:", pos
                sys.exit()
    print retval
    pos += len(retval)
    return retval
    
    

def do_dat(dat):
    print "dat:", do_operands(dat.what[1:])

def do_label(label):
    return ('label',label)

instrfuns = {
    'set': do_set,
    'dat': do_dat
}

def do_instr(instr):
    return instrfuns[instr[1][0][1]](instr)

nodefuns = {
    'op': do_instr,
    'label': do_label
    }

def do_node(node):
    print "Node:", node[0]
    print "labels:", labels
    print "label refs:", unresolved_labels
    return nodefuns[node[0]](node)




#-----------------------------------------
files = fileinput.input()
print_trace = True
result = parse(dasm(), files, True, comment())
for r in result:
    print r
nodes = filter(lambda(r): r[0] == 'op' or r[0] == 'label', result)

print map(do_node, nodes)



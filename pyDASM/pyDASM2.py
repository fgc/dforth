import re, fileinput
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
def address():        return "[", aoperand, "]"
def macrovar():       return "\\", symbol
def operator():       return re.compile(r"\+|\-")
def hex():            return "0x", hexdigits
def decimal():        return re.compile(r'\d+')
def string():         return re.compile(r'".*?"')
def aoperand():       return [expr, macrosub, letvar, symbol, literal]
def hexdigits():      return re.compile(r"[0-9a-fA-F]+")

def do_operands(ops):
    print ops[0].what[0].what

def do_set(setop):
    print "Got a set"
    do_operands(setop.what[1:])

instructions = {
    'set': do_set
    }

def do_op(op):
    instructions[op.what[0].what](op)

files = fileinput.input()
print_trace = True
result = parse(dasm(), files, True, comment())

ops = filter(lambda(r): r[0] == 'op', result)

map(do_op, ops)



import re, fileinput
from pyPEG import parse
from pyPEG import keyword, _and, _not

def comment(): return re.compile(r";.*")
def macro(): return ".macro", symbol, decimal, macrobody,".endm"
def macrobody(): return -2, line
def macroparam(): return "\\",decimal
def macrosub(): return [(symbol,macroparam),macroparam, symbol]
def macrocall(): return [symbol, (symbol, 0, operand, -1, (",", operand))]
def let(): return ".let", letvar, ",", [literal, macrosub]
def letvar(): return "$", symbol
def literal(): return [hex, decimal, string]
def string(): return re.compile(r'".*?"')
def hex(): return "0x", hexdigits
def hexdigits(): return re.compile(r"[0-9a-fA-F]+")
def decimal(): return re.compile(r'\d+')
def symbol(): return re.compile(r"[a-zA-Z_]+[a-zA-Z0-9_]*")
def label(): return ":", macrosub
def address(): return "(", aoperand, -1, (aoperator, aoperand),")"
def aoperator(): return re.compile(r"\+|\-")
def aoperand(): return [macroparam, letvar, hex, decimal, symbol]
def op(): return [(instr, 0, operand, -1, (",", operand)), macrocall]
def operand(): return [preexpr, macroparam, macrosub, letvar, symbol, literal, address]
def preexpr(): return [letvar,macroparam,], aoperator, [letvar,macroparam]
def line(): return [macro, let, label, op, (label, op)]
def dasm(): return -2, line
def instr(): return ["set","add","sub","mul","div","mod","shl","shr","and","bor","xor","ife","ifn","ifg","ifb","dat","wdat","push","pop","peek"]

re.DEBUG = True
files = fileinput.input()
print_trace = True
result = parse(dasm(), files, True, comment())

for r in result:
    print r[1][0].__name__,r[1][0][1]

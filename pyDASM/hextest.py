import re


hex = re.compile(r'0x([0-9A-Fa-f]+)')

def test(S):
    print S, hex.match(S).group(1)

test('0x1')
test('0x1d')
test('0x1a')
test('0x1d')
test('0x1k')


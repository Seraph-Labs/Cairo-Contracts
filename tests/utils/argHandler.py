""" lib for handling array arguments"""
# to unpack tuples in a list for tx calls
def unpack_tpl(_list) -> int:
    x = []
    for i in _list:
        x.append(i[0])
        x.append(i[1])
    return (x)

def arr_res(_list) -> int:
    x = []
    y = len(_list)
    for i in _list:
        x.append(i[0])
        x.append(i[1])
    return ([y,*x])

def string_to_ascii_arr_with_len(string):
    arr = bytes(string, 'ascii')
    x = []
    y = 0
    for byte in arr:
        x.append(byte)
        y += 1
    return ([y,*x])

def string_to_ascii_arr(string):
    arr = bytes(string, 'ascii')
    x = []
    for byte in arr:
        x.append(byte)
    return ([*x])
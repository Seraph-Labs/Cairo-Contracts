""" lib for handling array arguments"""
# to unpack tuples in a list for tx calls
def unpack_tpl(_list) -> int:
    x = []
    for i in _list:
        x.append(i[0])
        x.append(i[1])
    return x


def arr_res(_list) -> int:
    x = []
    y = len(_list)
    for i in _list:
        x.append(i[0])
        x.append(i[1])
    return [y, *x]


def string_to_ascii_arr_with_len(string):
    arr = bytes(string, "ascii")
    x = []
    y = 0
    for byte in arr:
        x.append(byte)
        y += 1
    return [y, *x]


def string_to_ascii_arr(string):
    arr = bytes(string, "ascii")
    x = []
    for byte in arr:
        x.append(byte)
    return [*x]


def ascii_to_string(data):
    (L,) = data.result
    x = "".join(chr(i) for i in L)
    return x


def to_starknet_args(data):
    items = []
    values = data.values() if type(data) is dict else data
    for d in values:
        if type(d) is dict:
            items.extend([*to_starknet_args(d)])
        elif type(d) is tuple:
            items.extend([*to_starknet_args(d)])
        elif type(d) is list:
            items.append(len(d))
            items.extend([*to_starknet_args(tuple(d))])
        else:
            items.append(d)

    return tuple(items)

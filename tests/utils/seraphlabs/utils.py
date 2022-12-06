from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.business_logic.execution.objects import Event


def assert_sorted_event_emitted(tx_exec_info, from_address, name, data):
    """Assert events are fired with correct data."""
    event_obj = Event(
        from_address=from_address,
        keys=[get_selector_from_name(name)],
        data=data,
    )

    event_list = tx_exec_info.get_sorted_events()
    assert event_obj in event_list


def felt_to_ascii(felt):
    bytes_object = bytes.fromhex(hex(felt)[2:])
    ascii_string = str(bytes_object.decode("ascii"))
    return ascii_string


def ascii_to_felt(s):
    return int.from_bytes(s.encode("ascii"), "big")


def eth_to_felt(eth):
    return eth * (10**18)


def felt_to_eth(felt):
    return felt / (10**18)


class TxData:
    # converts transcation retdata (call_info.retdata)
    # and convert the array into a string
    def toString(_list):
        str = ""
        for i in _list[2:]:
            x = felt_to_ascii(i)
            str += x
        return str

    # generates an array into retdata format
    # [{number of return values}, *values]
    def result(*data):
        arr = []
        for i in data:
            if type(i) is tuple:
                arr.extend([*TxData.result(*i)][1:])
            elif type(i) is list:
                arr.append(len(i))
                arr.extend([*TxData.result(*i)][1:])
            else:
                arr.append(i)
        return [len(arr), *arr]

// SPDX-License-Identifier: AGPL-3.0
// SeraphLabs Contracts for Cairo >=v2.1.0 (tokens/erc2114/utils.cairo)
use starknet::ContractAddress;
use starknet::storage_access::StorePacking;

#[derive(Copy, Drop, Serde, PartialEq, starknet::Store, Default)]
enum AttrType {
    #[default]
    Empty,
    String: u64,
    Number: u8,
}

#[generate_trait]
impl AttrTypeImpl of AttrTypeTrait {
    #[inline(always)]
    fn is_empty(self: AttrType) -> bool {
        self == AttrType::Empty
    }

    #[inline(always)]
    fn get_list_id(self: AttrType) -> u64 {
        match self {
            AttrType::Empty => 0,
            AttrType::String(x) => x,
            AttrType::Number(x) => 0,
        }
    }

    #[inline(always)]
    fn get_decimal(self: AttrType) -> u8 {
        match self {
            AttrType::Empty => 0,
            AttrType::String(x) => 0,
            AttrType::Number(x) => x,
        }
    }
}

// -------------------------------------------------------------------------- //
//                               Attribute Base                               //
// -------------------------------------------------------------------------- //
// @dev used to store the base information of an attribute
//  to save gas compared to storing both type and name separately
//  gas save 10040 gas
#[derive(Copy, Drop, Serde, PartialEq, starknet::Store)]
struct AttrBase {
    name: felt252,
    val_type: AttrType,
}

#[generate_trait]
impl AttrBaseImpl of AttrBaseTrait {
    #[inline(always)]
    fn new(name: felt252, val_type: AttrType) -> AttrBase {
        // @dev name MUST NOT be zero and val_type MUST NOT be Empty
        if name.is_zero() || val_type == AttrType::Empty {
            panic_with_felt252('ERC2114: Invalid attribute')
        }

        AttrBase { name: name, val_type: val_type, }
    }
    #[inline(always)]
    fn is_valid(self: AttrBase) -> bool {
        // @dev return true if name is not zero and type is not Empty
        self.name.is_non_zero() && self.val_type != AttrType::Empty
    }
}

// -------------------------------------------------------------------------- //
//                               Attribute Pack                               //
// -------------------------------------------------------------------------- //
// @dev Constants for shifting data
// 2^186
const SHIFT_DATA_1: felt252 = 0x40000000000000000000000000000000000000000000000;
// 2^122
const SHIFT_DATA_2: felt252 = 0x4000000000000000000000000000000;
// 2^58
const SHIFT_DATA_3: felt252 = 0x400000000000000;
// @dev Consatnts for masking out data from a packed felt
//  uses u256 as cairo does not support bitwise operations or Divs on felts
// 2^250 - 2^186 -> get first attr_id pack
const MASK_DATA_1: u256 = 0x3fffffffffffffffc0000000000000000000000000000000000000000000000_u256;
// 2^186 - 2^122 -> get second attr_id pack
const MASK_DATA_2: u256 = 0x3fffffffffffffffc000000000000000000000000000000_u256;
// 2^122 - 2^58 -> get third attr_id pack
const MASK_DATA_3: u256 = 0x3fffffffffffffffc00000000000000_u256;
// 2^58 -1 -> get length stored in the last 58 bits of pack
const MASK_LEN: u256 = 0x3ffffffffffffff_u256;


// @dev used to store a pack of 3 attr_ids of size u64
// @param `pack` stores the packed felt of 1- 3 u64 
// @param `len` stores the number of attr_ids in the pack
#[derive(Copy, Drop, Serde, PartialEq)]
struct AttrPack {
    pack: felt252,
    len: u8
}

// @dev functions for manipulating attr_id packs

#[generate_trait]
impl AttrPackImpl of AttrPackTrait {
    // @dev creates a new pack from an array of attr_ids
    //  `attr_ids` MUST NOT be empty, contain zeros or have a len bigger than 3 or have duplicates 
    //   this function DOES NOT check if have repreats must check externaly
    fn new(mut attr_ids: Span<u64>) -> AttrPack {
        // make sure attr_id span is not empty and len is < 3
        if attr_ids.is_empty() || attr_ids.len() > 3 {
            panic_with_felt252('ERC2114: Invalid attr id pack');
        }

        let mut len: u8 = 0;
        let mut pack: felt252 = 0;
        loop {
            match attr_ids.pop_front() {
                Option::Some(val) => {
                    // shift attr_id based on len 
                    let shifted_attr = AttrPackBitShiftImpl::shift_to(*val, len);
                    pack += shifted_attr;
                    len += 1;
                },
                Option::None(_) => { break; },
            };
        };
        AttrPack { pack: pack, len: len }
    }

    // @dev checks if pack is valid for storing
    #[inline(always)]
    fn is_valid(self: AttrPack) -> bool {
        self.len.is_non_zero() && self.len <= 3 && self.pack.is_non_zero()
    }

    // @dev checks if pack contains attr_id
    fn has_attr(self: AttrPack, attr_id: u64) -> bool {
        // check if pack is empty
        if self.len == 0 || attr_id == 0 {
            return false;
        }

        let mut pos = 0;
        // loop through pack and check if attr_id is in pack
        // if pos is >= len means we have checked all attr_ids in pack
        let is_in_pack: bool = loop {
            if pos >= self.len {
                break false;
            }
            match AttrPackBitShiftImpl::mask_pack(self.pack, pos) == attr_id {
                bool::False => pos += 1,
                bool::True => { break true; },
            };
        };
        is_in_pack
    }

    // @dev retrive attr_id at position from pack
    #[inline(always)]
    fn get_attr_id(self: AttrPack, pos: u8) -> u64 {
        match pos >= self.len {
            bool::False => AttrPackBitShiftImpl::mask_pack(self.pack, pos),
            bool::True => 0_u64,
        }
    }

    // @dev retrive all attr_ids in pack
    fn unpack_all(self: AttrPack) -> Span<u64> {
        let mut attr_ids = ArrayTrait::<u64>::new();
        let mut pos = 0;
        loop {
            match pos >= self.len {
                bool::False => {
                    attr_ids.append(AttrPackBitShiftImpl::mask_pack(self.pack, pos));
                    pos += 1;
                },
                bool::True => { break; },
            };
        };
        attr_ids.span()
    }

    // @dev adds an attr_id into pack if have space
    //  this function does not check if attr_id is already in pack
    fn add_to_pack(ref self: AttrPack, attr_id: u64) {
        if self.len >= 3 {
            panic_with_felt252('ERC2114: AttrPack is full');
        }
        // get position to fit attr_id in by its len
        // as pos starts from 0 we can use len as pos
        let shifted_attr = AttrPackBitShiftImpl::shift_to(attr_id, self.len);
        self.pack += shifted_attr;
        self.len += 1;
    }

    fn add_batch_to_pack(ref self: AttrPack, mut attr_ids: Span<u64>) {
        loop {
            match attr_ids.pop_front() {
                Option::Some(val) => {
                    // if attr_ids len exceeds max of 3 this will panic
                    self.add_to_pack(*val);
                },
                Option::None(_) => { break; },
            };
        };
    }

    // @dev removes an attr_id from pack if it exists
    fn remove_from_pack(ref self: AttrPack, attr_id: u64) {
        if self.len == 0 {
            panic_with_felt252('ERC2114: AttrPack is empty');
        }

        let mut attr_ids = ArrayTrait::<u64>::new();
        let mut pos = 0;
        loop {
            match pos >= self.len {
                bool::False => {
                    let retrived_attr_id = AttrPackBitShiftImpl::mask_pack(self.pack, pos);
                    // append attr_ids that are not for removal to array 
                    // new array of attr_ids will be used to create new pack 
                    if retrived_attr_id != attr_id {
                        attr_ids.append(retrived_attr_id);
                    }
                    pos += 1;
                },
                bool::True => { break; },
            };
        };

        // if attr_ids length is the same as self.len means attr_id was not in pack 
        if attr_ids.len() == self.len.into() {
            panic_with_felt252('ERC2114: AttrPack remove failed');
        }

        // if attr_ids array length is 0 means pack is empty
        // initialize empty struct else repack the pack
        match attr_ids.len().into() {
            0 => { self = AttrPack { pack: 0, len: 0 }; },
            _ => { self = AttrPackImpl::new(attr_ids.span()); }
        }
    }
}

// @dev functions for shifting and masking data in attr_id packs

#[generate_trait]
impl AttrPackBitShiftImpl of AttrPackBitShiftTrait {
    // @dev shifts attr_id bits based on which position it is suppose to be in the pack
    #[inline(always)]
    fn shift_to(attr_id: u64, pos: u8) -> felt252 {
        if pos > 2 {
            panic_with_felt252('ERC2114: Invalid pack pos');
        }
        if attr_id == 0 {
            panic_with_felt252('ERC2114: cant pack 0 attr_id');
        }

        let value: felt252 = if pos == 0 {
            attr_id.into() * SHIFT_DATA_1
        } else if pos == 1 {
            attr_id.into() * SHIFT_DATA_2
        } else {
            attr_id.into() * SHIFT_DATA_3
        };

        value
    }
    // @dev mask data at pos to extract attr_id
    //  this function does not check if pack is empty
    #[inline(always)]
    fn mask_pack(pack: felt252, pos: u8) -> u64 {
        if pos > 2 {
            panic_with_felt252('ERC2114: Invalid pack pos');
        }
        // turn pack into u256 so we can perform bitwise operations and div operations
        let pack_u256: u256 = pack.into();
        let attr_id: u256 = if pos == 0 {
            (pack_u256 & MASK_DATA_1) / SHIFT_DATA_1.into()
        } else if pos == 1 {
            (pack_u256 & MASK_DATA_2) / SHIFT_DATA_2.into()
        } else {
            (pack_u256 & MASK_DATA_3) / SHIFT_DATA_3.into()
        };

        attr_id.try_into().unwrap()
    }
}

// @dev implementation for packing AttrPack into felt
impl AttrPackPackableimpl of StorePacking<AttrPack, felt252> {
    // @dev packs AttrPack by adding its packed value to its len 
    // if len is 0 means empty pack so return pack 
    #[inline(always)]
    fn pack(value: AttrPack) -> felt252 {
        match value.len.into() {
            0 => 0,
            _ => value.pack + value.len.into()
        }
    }
    #[inline(always)]
    fn unpack(value: felt252) -> AttrPack {
        if value == 0 {
            return AttrPack { pack: 0, len: 0 };
        }
        // convert value into u256 to perform bitwise operations 
        let value_u256: u256 = value.into();
        // get len and minus from value to get pack
        let len = value_u256 & MASK_LEN;
        let pack = value_u256 - len;
        AttrPack { pack: pack.try_into().unwrap(), len: len.try_into().unwrap() }
    }
}

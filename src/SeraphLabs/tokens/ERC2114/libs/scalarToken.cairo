// SPDX-License-Identifier: AGPL-3.0
// SeraphLabs Contracts for Cairo v0.3.0 (tokens/ERC2114/libs/scalarToken.cairo)
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.math_cmp import is_not_zero, is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    uint256_le,
    uint256_lt,
    uint256_eq,
)
from starkware.cairo.common.alloc import alloc

from openzeppelin.security.safemath.library import SafeUint256
from SeraphLabs.math.simple_checks import is_uint_valid
from SeraphLabs.models.StringObject import StrObj

struct ScalarToken {
    tokenId: Uint256,
    from_: felt,
}

struct TokenAttr {
    value: StrObj,
    ammount: Uint256,
}

namespace ScalarTokenHandler {
    func check_has_tokenOwner{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        SToken: ScalarToken
    ) -> (res: felt) {
        let (is_zero) = uint256_le(SToken.tokenId, Uint256(0, 0));
        if (is_zero == TRUE) {
            return (FALSE,);
        } else {
            return (TRUE,);
        }
    }
}

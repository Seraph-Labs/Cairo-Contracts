use array::ArrayTrait;
use seraphlabs_libs::arrays::SeraphArrayTrait;

#[test]
#[available_gas(2000000)]
fn reverse(){
    let mut data = ArrayTrait::new();
    data.append(2114);
    data.append(3525);
    data.append(721);
    data.reverse();
    assert(data.len() == 3,'length is not 3');
    assert(*data.at(0) == 721,'should be 721');
    assert(*data.at(1) == 3525,'should be 3525');
    assert(*data.at(2) == 2114,'should be 2114');
}

#[test]
#[available_gas(2000000)]
fn concat(){
    let mut data = ArrayTrait::new();
    data.append(2114);

    let mut data2 = ArrayTrait::new();
    data2.append(3525);
    data2.append(721);
    data.concat(ref data2);
    assert (data.len() == 3,'length is not 3');
    assert (*data.at(0) == 2114,'should be 2114');
    assert(*data.at(1) == 3525,'should be 3525');
    assert(*data.at(2) == 721,'should be 721');
}
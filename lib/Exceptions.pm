package Exceptions;
use strict;
use warnings;

use Exception::Class (
    'Exception',
    'ValidationException' => {
        isa => 'Exception'
    },
    'SmallObjectNumberException' => {
        isa => 'Exception'
    },
    'BigObjectNumberException' => {
        isa => 'Exception'
    },
    'NonUniqueObjectException' => {
        isa => 'Exception'
    },
    'InvalidOperationException' => {
        isa => 'Exception'
    }
);

1;

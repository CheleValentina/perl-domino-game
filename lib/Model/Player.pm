package Model::Player;
use Moose;
use Moose::Util::TypeConstraints;
use Model::Piece;
use Exceptions;

has name => (
    documentation => q{The player's name},
    is            => "rw",
    isa           => "Str",
    writer        => "set_name",
    required      => 1,
    trigger       => sub { _validate_name( $_[0]->name ) }
);

has pieces => (
    documentation => q{The player's pieces},
    is            => "rw",
    isa           => 'ArrayRef[Model::Piece]',
    traits        => ['Array'],
    predicate     => 'has_pieces',
    default       => sub { [] },
    handles       => {
        add_piece    => 'push',
        pieces_count => 'count'
    }
);

=pod
=item stringify_pieces()

Returns a string with all the player's pieces.

=cut

sub stringify_pieces {
    my ($self) = @_;

    my $string      = '';
    my $piece_count = 0;

    foreach ( @{ $self->pieces } ) {
        $string .= $piece_count++ . ": " . $_->to_string . " ";
    }

    return $string;
}

=pod
=item remove_piece($piece_index)

Removes a piece from the player's pieces.

$piece_index is the index of the piece that has to be removed

=cut

sub remove_piece {
    my ( $self, $piece_index ) = @_;

    splice( @{ $self->pieces }, $piece_index, 1 );
}

=pod
=item _validate_name($name)

Throws ValidationException if the name is null.

$name is the name of the player

=cut

sub _validate_name {
    my ($name) = @_;

    ValidationException->throw( error => 'The name shouldn\'t be empty!' )
      if $name eq '';
}

=pod
=item get_score()

Returns the score of the player, consisting in the total number of dots on its cards.

=cut

sub get_score {
    my ($self) = @_;

    my $score = 0;

    foreach ( @{ $self->pieces } ) {
        $score += $_->get_total_dots;
    }

    return $score;
}

1;
